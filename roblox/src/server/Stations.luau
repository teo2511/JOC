--!strict
-- Cadena de producción del taller (como la Fase 5 de Godot):
-- cajón de madera -> fábrica de juguetes -> mesa de envolver -> saco de Santa.
-- Todo corre en el servidor; los clientes solo ven las piezas y los carteles.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Build = require(script.Parent.Build)
local Items = require(script.Parent.Items)

local Stations = {}

local WOOD_DARK = Color3.fromRGB(78, 46, 28)
local GOLD = Color3.fromRGB(240, 185, 60)
local IRON = Color3.fromRGB(40, 40, 46)

local state: Folder -- ReplicatedStorage.GameState (atributos Gifts, Goal, Money)
local scanners: { () -> () } = {}
local tickers: { (number) -> () } = {}

local function prompt(parent: BasePart, action: string, object: string): ProximityPrompt
	local p = Instance.new("ProximityPrompt")
	p.ActionText = action
	p.ObjectText = object
	p.KeyboardKeyCode = Enum.KeyCode.E
	p.MaxActivationDistance = 12
	p.HoldDuration = 0
	p.RequiresLineOfSight = false
	p.Parent = parent
	return p
end

local function station(parent: Instance, name: string): Model
	local model = Instance.new("Model")
	model.Name = name
	model.Parent = parent
	return model
end

-- Cajón de madera: con [E] te da un bloque de madera en las manos.
local function materialBin(parent: Instance, at: Vector3)
	local model = station(parent, "CajonMadera")
	local crate = Build.part(model, { name = "Cajon", size = Vector3.new(4.2, 2.8, 4.2), cframe = CFrame.new(at + Vector3.new(0, 1.4, 0)), color = Color3.fromRGB(160, 110, 62), material = Enum.Material.WoodPlanks })
	for _, x in { -2, 2 } do
		for _, z in { -2, 2 } do
			Build.deco(model, { size = Vector3.new(0.4, 3, 0.4), cframe = CFrame.new(at + Vector3.new(x, 1.5, z)), color = WOOD_DARK, material = Enum.Material.Wood })
		end
	end
	for i = 0, 3 do
		Build.deco(model, { size = Vector3.new(3.6, 0.65, 0.65), cframe = CFrame.new(at + Vector3.new(0, 3.1, -1.2 + i * 0.8)) * CFrame.Angles(0, math.rad(90), 0), color = Color3.fromRGB(120, 80, 45), material = Enum.Material.Wood, shape = Enum.PartType.Cylinder })
	end
	Build.label(crate, "MADERA", 4)
	local p = prompt(crate, "Coger madera", "Cajón")
	p.Triggered:Connect(function(player)
		if Items.heldBy(player) then
			return
		end
		local character = player.Character
		local hrp = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not hrp then
			return
		end
		local wood = Items.spawn("material", (hrp.CFrame * Config.HOLD_OFFSET).Position)
		Items.pick(player, wood)
	end)
end

-- Fábrica: se echa madera por arriba y sale un coche de juguete por delante.
local function toyMachine(parent: Instance, at: Vector3)
	local model = station(parent, "Fabrica")
	local bodyH = 3.0
	local body = Build.part(model, { name = "Cuerpo", size = Vector3.new(5.6, bodyH, 4.9), cframe = CFrame.new(at + Vector3.new(0, bodyH / 2, 0)), color = Color3.fromRGB(40, 130, 140), material = Enum.Material.Metal })
	Build.deco(model, { size = Vector3.new(1.2, 4.2, 4.2), cframe = CFrame.new(at + Vector3.new(0, bodyH + 0.6, 0)) * CFrame.Angles(0, 0, math.rad(90)), color = GOLD, material = Enum.Material.Metal, shape = Enum.PartType.Cylinder })
	for _, y in { 0.3, bodyH - 0.3 } do
		Build.deco(model, { size = Vector3.new(5.8, 0.3, 5.1), cframe = CFrame.new(at + Vector3.new(0, y, 0)), color = GOLD, material = Enum.Material.Metal })
	end
	local gear = Build.deco(model, { name = "Engranaje", size = Vector3.new(0.3, 2.2, 2.2), cframe = CFrame.new(at + Vector3.new(0, 1.6, 2.6)) * CFrame.Angles(0, math.rad(90), 0), color = GOLD, material = Enum.Material.Metal, shape = Enum.PartType.Cylinder })
	-- Bastones de caramelo a los lados de la salida, chimenea y lucecitas.
	for _, x in { -1.6, 1.6 } do
		for k = 0, 5 do
			Build.deco(model, { size = Vector3.new(0.4, 0.4, 0.4), cframe = CFrame.new(at + Vector3.new(x, 0.2 + k * 0.4, 2.6)), color = if k % 2 == 0 then Color3.fromRGB(220, 30, 35) else Color3.new(1, 1, 1), material = Enum.Material.SmoothPlastic })
		end
	end
	Build.deco(model, { size = Vector3.new(2.4, 0.9, 0.9), cframe = CFrame.new(at + Vector3.new(2, bodyH + 1.2, -1.6)) * CFrame.Angles(0, 0, math.rad(90)), color = IRON, material = Enum.Material.Metal, shape = Enum.PartType.Cylinder })
	local lamp = Build.deco(model, { size = Vector3.new(0.5, 0.5, 0.5), cframe = CFrame.new(at + Vector3.new(2.3, bodyH - 0.6, 2.47)), color = Color3.fromRGB(255, 70, 60), material = Enum.Material.Neon, shape = Enum.PartType.Ball })
	local hopper = Build.zone(model, "Tolva", Vector3.new(5.6, 4.5, 4.9), CFrame.new(at + Vector3.new(0, bodyH + 2.2, 0)))
	local output = at + Vector3.new(0, 1.2, 3.6)
	local label = Build.label(body, "FÁBRICA DE JUGUETES\nEsperando madera", 6.5)

	local queued, progress = 0, 0.0
	local function refresh()
		if queued == 0 then
			label.Text = "FÁBRICA DE JUGUETES\nEsperando madera"
			lamp.Color = Color3.fromRGB(255, 70, 60)
		else
			label.Text = string.format("FÁBRICA DE JUGUETES\nFabricando %d%% · cola %d/%d", math.floor(progress * 10) * 10, queued, Config.MACHINE_CAPACITY)
			lamp.Color = Color3.fromRGB(70, 255, 90)
		end
	end
	table.insert(scanners, function()
		for _, wood in Items.inZone(hopper, "material") do
			if queued >= Config.MACHINE_CAPACITY then
				break
			end
			if Items.consume(wood) then
				queued += 1
			end
		end
		refresh()
	end)
	table.insert(tickers, function(dt)
		if queued == 0 then
			return
		end
		gear.CFrame *= CFrame.Angles(dt * 4, 0, 0)
		progress += dt / Config.MACHINE_CRAFT_TIME
		if progress >= 1 then
			progress = 0
			queued -= 1
			Items.spawn("toy", output, Vector3.new(0, 8, 14))
		end
	end)
	refresh()
end

-- Mesa de envolver: deja un juguete encima y pulsa [E] tres veces.
local function wrapTable(parent: Instance, at: Vector3)
	local model = station(parent, "MesaEnvolver")
	local topY = 3.1
	local top = Build.part(model, { name = "Tablero", size = Vector3.new(6, 0.4, 3.9), cframe = CFrame.new(at + Vector3.new(0, topY - 0.2, 0)), color = Color3.fromRGB(150, 98, 58), material = Enum.Material.WoodPlanks })
	for _, x in { -2.6, 2.6 } do
		for _, z in { -1.6, 1.6 } do
			Build.part(model, { size = Vector3.new(0.4, topY - 0.4, 0.4), cframe = CFrame.new(at + Vector3.new(x, (topY - 0.4) / 2, z)), color = WOOD_DARK, material = Enum.Material.Wood })
		end
	end
	local colors = { Color3.fromRGB(220, 35, 45), Color3.fromRGB(40, 130, 65), Color3.fromRGB(60, 100, 220), Color3.fromRGB(245, 215, 80) }
	for i, c in colors do
		Build.deco(model, { size = Vector3.new(4.5, 0.5, 0.5), cframe = CFrame.new(at + Vector3.new(0, 0.6 + (i % 2) * 0.5, -1.2 + i * 0.5)), color = c, shape = Enum.PartType.Cylinder })
	end
	Build.deco(model, { size = Vector3.new(4, 0.6, 0.6), cframe = CFrame.new(at + Vector3.new(0, topY + 0.3, -1.5)), color = Color3.fromRGB(245, 215, 80), shape = Enum.PartType.Cylinder })
	local zone = Build.zone(model, "Encima", Vector3.new(6, 3, 3.9), CFrame.new(at + Vector3.new(0, topY + 1.5, 0)))
	local label = Build.label(top, "MESA DE ENVOLVER", 4.5)
	local wrap = prompt(top, "Envolver", "Mesa")
	-- [F] y no [E]: el juguete que hay encima ya usa [E] para cogerlo.
	wrap.KeyboardKeyCode = Enum.KeyCode.F
	wrap.GamepadKeyCode = Enum.KeyCode.ButtonY
	wrap.Enabled = false

	local presses = 0
	local function refresh(toys: { Part })
		wrap.Enabled = #toys > 0
		wrap.ActionText = string.format("Envolver (%d/%d)", presses, Config.WRAP_PRESSES)
		label.Text = if #toys > 0 then "MESA DE ENVOLVER\nPulsa F para envolver" else "MESA DE ENVOLVER\nDeja aquí un juguete"
	end
	table.insert(scanners, function()
		local toys = Items.inZone(zone, "toy")
		if #toys == 0 then
			presses = 0 -- se han llevado el juguete a medias
		end
		refresh(toys)
	end)
	wrap.Triggered:Connect(function()
		local toys = Items.inZone(zone, "toy")
		if #toys == 0 then
			return
		end
		presses += 1
		if presses >= Config.WRAP_PRESSES then
			presses = 0
			local pos = toys[1].Position + Vector3.new(0, 1, 0)
			if Items.consume(toys[1]) then
				Items.spawn("gift", pos, Vector3.new(0, 10, 0))
			end
		end
		refresh(Items.inZone(zone, "toy"))
	end)
	refresh({})
end

-- Saco de Santa: cada regalo que entra cuenta para el objetivo y da monedas.
local function santaSack(parent: Instance, at: Vector3)
	local model = station(parent, "SacoSanta")
	local bag = Build.part(model, { name = "Saco", size = Vector3.new(6, 5.4, 6), cframe = CFrame.new(at + Vector3.new(0, 2.5, 0)), color = Color3.fromRGB(190, 25, 30), material = Enum.Material.Fabric, shape = Enum.PartType.Ball })
	Build.deco(model, { size = Vector3.new(0.9, 4.6, 4.6), cframe = CFrame.new(at + Vector3.new(0, 4.9, 0)) * CFrame.Angles(0, 0, math.rad(90)), color = Color3.fromRGB(250, 245, 235), material = Enum.Material.Fabric, shape = Enum.PartType.Cylinder })
	Build.deco(model, { size = Vector3.new(1.3, 1.3, 0.2), cframe = CFrame.new(at + Vector3.new(0, 2.6, 3)) * CFrame.Angles(0, 0, math.rad(45)), color = GOLD, material = Enum.Material.Metal })
	Build.deco(model, { size = Vector3.new(0.2, 7, 7), cframe = CFrame.new(at + Vector3.new(0, 0.1, 0)) * CFrame.Angles(0, 0, math.rad(90)), color = Color3.fromRGB(140, 30, 30), material = Enum.Material.Fabric, shape = Enum.PartType.Cylinder })
	local mouth = Build.zone(model, "Boca", Vector3.new(5, 5, 5), CFrame.new(at + Vector3.new(0, 5.5, 0)))
	local label = Build.label(bag, "", 6)

	local function refresh()
		local gifts = state:GetAttribute("Gifts") :: number
		local goal = state:GetAttribute("Goal") :: number
		label.Text = if gifts >= goal then "SACO DE SANTA\n¡Lleno!" else string.format("SACO DE SANTA\n%d / %d regalos", gifts, goal)
		local fill = math.clamp(gifts / math.max(goal, 1), 0, 1)
		bag.Size = Vector3.new(6, 5.4, 6) * (0.85 + 0.3 * fill)
	end
	table.insert(scanners, function()
		for _, gift in Items.inZone(mouth, "gift") do
			if Items.consume(gift) then
				state:SetAttribute("Gifts", (state:GetAttribute("Gifts") :: number) + 1)
				state:SetAttribute("Money", (state:GetAttribute("Money") :: number) + Config.GIFT_VALUE)
			end
		end
	end)
	state:GetAttributeChangedSignal("Gifts"):Connect(refresh)
	state:GetAttributeChangedSignal("Goal"):Connect(refresh)
	refresh()
end

function Stations.init(gameState: Folder)
	state = gameState
	local folder = Instance.new("Folder")
	folder.Name = "Estaciones"
	folder.Parent = workspace
	-- Mismas posiciones que en Godot (pared norte del taller), pasadas a studs.
	local z = -12.5 * Config.STUDS_PER_METER
	materialBin(folder, Vector3.new(-11 * Config.STUDS_PER_METER, 0, z))
	toyMachine(folder, Vector3.new(-6.5 * Config.STUDS_PER_METER, 0, z))
	wrapTable(folder, Vector3.new(-2 * Config.STUDS_PER_METER, 0, z))
	santaSack(folder, Vector3.new(2.5 * Config.STUDS_PER_METER, 0, z))

	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		for _, tick in tickers do
			tick(dt)
		end
		acc += dt
		if acc >= 0.15 then
			acc = 0
			for _, scan in scanners do
				scan()
			end
		end
	end)
end

return Stations
