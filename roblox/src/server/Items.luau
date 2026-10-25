--!strict
-- Objetos que se cogen y se lanzan: madera, juguetes y regalos.
--
-- Todo lo decide el servidor (como el anfitrión en Godot):
-- - Para coger, cada objeto tiene un ProximityPrompt ([E] en PC, botón en móvil).
-- - Mientras alguien lo lleva, el objeto va soldado delante de su personaje y el prompt se apaga.
-- - Para soltar o lanzar, el cliente manda Remotes.Release con la dirección de su cámara.
-- Atributos del objeto: Kind ("material", "toy", "gift") y Holder (UserId de quien lo lleva o 0).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Build = require(script.Parent.Build)

local Items = {}

local folder = Instance.new("Folder")
folder.Name = "Items"
folder.Parent = workspace
Items.folder = folder

local NAMES = { material = "Madera", toy = "Coche de juguete", gift = "Regalo" }
local GIFT_COLORS = {
	{ Color3.fromRGB(210, 25, 35), Color3.fromRGB(250, 215, 90) },
	{ Color3.fromRGB(30, 115, 55), Color3.fromRGB(240, 50, 50) },
	{ Color3.fromRGB(50, 90, 205), Color3.fromRGB(245, 245, 245) },
	{ Color3.fromRGB(140, 50, 165), Color3.fromRGB(250, 215, 90) },
	{ Color3.fromRGB(245, 200, 50), Color3.fromRGB(205, 25, 30) },
}
local CAR_COLORS = { Color3.fromRGB(230, 50, 40), Color3.fromRGB(50, 115, 230), Color3.fromRGB(245, 190, 40), Color3.fromRGB(40, 155, 75) }

local rng = Random.new()

local function decorate(root: Part, kind: string)
	local cf = root.CFrame
	local function piece(size: Vector3, offset: CFrame, color: Color3, material: Enum.Material?, shape: Enum.PartType?)
		local p = Build.deco(root, { size = size, cframe = cf * offset, color = color, material = material, shape = shape })
		Build.weldTo(root, p)
	end
	if kind == "material" then
		root.Size = Vector3.new(2.2, 1, 1.3)
		root.Color = Color3.fromRGB(190, 135, 80)
		root.Material = Enum.Material.Wood
	elseif kind == "toy" then
		root.Size = Vector3.new(2.2, 0.75, 1.25)
		local paint = CAR_COLORS[rng:NextInteger(1, #CAR_COLORS)]
		root.Color = paint
		root.Material = Enum.Material.SmoothPlastic
		cf = root.CFrame
		piece(Vector3.new(1.1, 0.55, 1.05), CFrame.new(-0.15, 0.62, 0), paint)
		piece(Vector3.new(0.9, 0.4, 1.08), CFrame.new(-0.15, 0.64, 0), Color3.fromRGB(110, 160, 220), Enum.Material.Glass)
		for _, x in { -0.7, 0.7 } do
			for _, z in { -0.62, 0.62 } do
				piece(Vector3.new(0.25, 0.65, 0.65), CFrame.new(x, -0.3, z), Color3.fromRGB(30, 30, 34), nil, Enum.PartType.Cylinder)
			end
		end
		for _, z in { -0.4, 0.4 } do
			piece(Vector3.new(0.2, 0.2, 0.2), CFrame.new(1.1, 0.05, z), Color3.fromRGB(255, 245, 190), Enum.Material.Neon, Enum.PartType.Ball)
		end
	elseif kind == "gift" then
		root.Size = Vector3.new(1.9, 1.9, 1.9)
		local colors = GIFT_COLORS[rng:NextInteger(1, #GIFT_COLORS)]
		root.Color = colors[1]
		root.Material = Enum.Material.SmoothPlastic
		cf = root.CFrame
		piece(Vector3.new(1.96, 1.96, 0.4), CFrame.new(), colors[2], Enum.Material.Metal)
		piece(Vector3.new(0.4, 1.96, 1.96), CFrame.new(), colors[2], Enum.Material.Metal)
		for _, side in { -1, 1 } do
			piece(Vector3.new(0.7, 0.5, 0.35), CFrame.new(side * 0.35, 1.15, 0) * CFrame.Angles(0, 0, math.rad(side * 30)), colors[2], Enum.Material.Metal, Enum.PartType.Ball)
		end
	end
end

-- Crea un objeto suelto en `position`, con velocidad inicial opcional.
function Items.spawn(kind: string, position: Vector3, velocity: Vector3?): Part
	local root = Instance.new("Part")
	root.Name = NAMES[kind] or kind
	root.Size = Vector3.new(1.5, 1.5, 1.5)
	root.CFrame = CFrame.new(position)
	root.TopSurface = Enum.SurfaceType.Smooth
	root.BottomSurface = Enum.SurfaceType.Smooth
	root:SetAttribute("Kind", kind)
	root:SetAttribute("Holder", 0)
	root:SetAttribute("Spawn", position)
	decorate(root, kind)

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "PickPrompt"
	prompt.ActionText = "Coger"
	prompt.ObjectText = root.Name
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.MaxActivationDistance = 10
	prompt.HoldDuration = 0
	prompt.Parent = root
	prompt.Triggered:Connect(function(player)
		Items.pick(player, root)
	end)

	root.Parent = folder
	root:SetNetworkOwner(nil)
	if velocity then
		root.AssemblyLinearVelocity = velocity
	end
	return root
end

function Items.holderOf(item: BasePart): number
	return (item:GetAttribute("Holder") :: number?) or 0
end

function Items.heldBy(player: Player): Part?
	for _, item in folder:GetChildren() do
		if item:IsA("Part") and Items.holderOf(item) == player.UserId then
			return item
		end
	end
	return nil
end

-- Libre, sin gastar y dentro del mundo: una estación lo puede usar.
function Items.isAvailable(item: Instance): boolean
	return item:IsA("BasePart") and item.Parent == folder and Items.holderOf(item) == 0
end

local function rootPartOf(player: Player): BasePart?
	local character = player.Character
	return if character then character:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
end

-- Da el objeto a `player` si nadie lo lleva, está cerca y no lleva ya otro.
function Items.pick(player: Player, item: Part): boolean
	local hrp = rootPartOf(player)
	if not hrp or item.Parent ~= folder or Items.holderOf(item) ~= 0 or Items.heldBy(player) then
		return false
	end
	if (hrp.Position - item.Position).Magnitude > Config.MAX_PICK_DISTANCE then
		return false
	end
	item:SetAttribute("Holder", player.UserId)
	item.CanCollide = false
	item.Massless = true
	item.AssemblyLinearVelocity = Vector3.zero
	item.CFrame = hrp.CFrame * Config.HOLD_OFFSET
	local weld = Instance.new("Weld")
	weld.Name = "HoldWeld"
	weld.Part0 = hrp
	weld.Part1 = item
	weld.C0 = Config.HOLD_OFFSET
	weld.Parent = item
	local prompt = item:FindFirstChild("PickPrompt") :: ProximityPrompt?
	if prompt then
		prompt.Enabled = false
	end
	return true
end

-- Suelta el objeto que lleva `player` con la velocidad dada (limitada).
function Items.release(player: Player, velocity: Vector3): boolean
	local item = Items.heldBy(player)
	if not item then
		return false
	end
	local weld = item:FindFirstChild("HoldWeld")
	if weld then
		weld:Destroy()
	end
	item:SetAttribute("Holder", 0)
	item.Massless = false
	local speed = math.min(velocity.Magnitude, Config.THROW_SPEED + Config.THROW_UP)
	item.AssemblyLinearVelocity = if velocity.Magnitude > 0 then velocity.Unit * speed else Vector3.zero
	item:SetNetworkOwner(nil)
	-- La colisión vuelve un momento después, cuando ya ha salido de las manos.
	task.delay(0.25, function()
		if item.Parent == folder and Items.holderOf(item) == 0 then
			item.CanCollide = true
		end
	end)
	local prompt = item:FindFirstChild("PickPrompt") :: ProximityPrompt?
	if prompt then
		prompt.Enabled = true
	end
	return true
end

-- Lo gasta una estación. false si alguien lo lleva o ya no existe (nunca cuenta dos veces).
function Items.consume(item: BasePart): boolean
	if not Items.isAvailable(item) then
		return false
	end
	item.Parent = nil
	item:Destroy()
	return true
end

-- Objetos que hay dentro de una zona (pieza invisible) y que cumplen `kind`.
function Items.inZone(zone: BasePart, kind: string?): { Part }
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { folder }
	local found = {}
	for _, part in workspace:GetPartBoundsInBox(zone.CFrame, zone.Size, params) do
		if part.Parent == folder and part:IsA("Part") and Items.holderOf(part) == 0 then
			if kind == nil or part:GetAttribute("Kind") == kind then
				table.insert(found, part)
			end
		end
	end
	return found
end

function Items.init()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local releaseEvent = remotes:WaitForChild("Release") :: RemoteEvent
	releaseEvent.OnServerEvent:Connect(function(player, throw: unknown, direction: unknown)
		if typeof(direction) ~= "Vector3" or typeof(throw) ~= "boolean" then
			return
		end
		local dir = if (direction :: Vector3).Magnitude > 0 then (direction :: Vector3).Unit else Vector3.zero
		local velocity = if throw then dir * Config.THROW_SPEED + Vector3.new(0, Config.THROW_UP, 0) else dir * Config.DROP_SPEED
		Items.release(player, velocity)
	end)
	local function dropOf(player: Player)
		Items.release(player, Vector3.zero)
	end
	Players.PlayerRemoving:Connect(dropOf)
	Players.PlayerAdded:Connect(function(player)
		player.CharacterRemoving:Connect(function()
			dropOf(player)
		end)
	end)
	-- Lo que se cae del mapa vuelve a donde apareció.
	task.spawn(function()
		while true do
			task.wait(1)
			for _, item in folder:GetChildren() do
				if item:IsA("Part") and item.Position.Y < -40 then
					local spawnPos = item:GetAttribute("Spawn") :: Vector3?
					item.AssemblyLinearVelocity = Vector3.zero
					item.CFrame = CFrame.new(spawnPos or Vector3.new(0, 5, 0))
				end
			end
		end
	end)
end

return Items
