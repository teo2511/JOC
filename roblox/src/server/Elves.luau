--!strict
-- Viste de elfo a cada jugador: gorro de su color con borla y orejas puntiagudas.
-- Cada uno conserva su avatar de Roblox; esto solo se suelda a la cabeza.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Build = require(script.Parent.Build)

local Elves = {}

local FUR = Color3.fromRGB(250, 250, 248)

local function colorFor(player: Player): Color3
	-- Color fijo por orden de llegada (como en Godot), guardado en el jugador.
	local saved = player:GetAttribute("ElfColor") :: number?
	if saved then
		return Config.ELF_COLORS[saved]
	end
	local used: { [number]: boolean } = {}
	for _, other in Players:GetPlayers() do
		local i = other:GetAttribute("ElfColor") :: number?
		if i then
			used[i] = true
		end
	end
	local index = 1
	while used[index] and index < #Config.ELF_COLORS do
		index += 1
	end
	player:SetAttribute("ElfColor", index)
	return Config.ELF_COLORS[index]
end

local function dressUp(player: Player, character: Model)
	local head = character:WaitForChild("Head", 10) :: BasePart?
	if not head or character:FindFirstChild("GorroElfo") then
		return
	end
	local color = colorFor(player)
	local hat = Instance.new("Model")
	hat.Name = "GorroElfo"
	local top = head.CFrame * CFrame.new(0, head.Size.Y / 2, 0)
	local function piece(size: Vector3, offset: CFrame, c: Color3, shape: Enum.PartType?, material: Enum.Material?)
		local p = Build.deco(hat, { size = size, cframe = top * offset, color = c, shape = shape, material = material or Enum.Material.Fabric })
		p.CastShadow = false
		Build.weldTo(head, p)
	end
	-- Borde de pelo blanco, cono hecho de discos cada vez más pequeños y punta doblada.
	piece(Vector3.new(0.45, 1.75, 1.75), CFrame.new(0, 0.1, 0) * CFrame.Angles(0, 0, math.rad(90)), FUR, Enum.PartType.Cylinder)
	for i = 0, 5 do
		local d = 1.5 - i * 0.22
		piece(Vector3.new(0.3, d, d), CFrame.new(0, 0.4 + i * 0.28, 0.06 * i) * CFrame.Angles(0, 0, math.rad(90)), color, Enum.PartType.Cylinder)
	end
	piece(Vector3.new(0.45, 0.45, 0.45), CFrame.new(0, 2.1, 0.75), FUR, Enum.PartType.Ball)
	-- Orejas puntiagudas (cuñas) a cada lado.
	for _, side in { -1, 1 } do
		local ear = Instance.new("WedgePart")
		ear.Size = Vector3.new(0.15, 0.6, 0.5)
		ear.CFrame = head.CFrame * CFrame.new(side * (head.Size.X / 2 + 0.05), 0.15, 0) * CFrame.Angles(0, 0, math.rad(-side * 50))
		ear.Color = head.Color
		ear.Material = Enum.Material.SmoothPlastic
		ear.CanCollide = false
		ear.CanTouch = false
		ear.CanQuery = false
		ear.Parent = hat
		Build.weldTo(head, ear)
	end
	hat.Parent = character
end

function Elves.init()
	local function onPlayer(player: Player)
		player.CharacterAppearanceLoaded:Connect(function(character)
			dressUp(player, character)
		end)
		if player.Character then
			dressUp(player, player.Character)
		end
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		onPlayer(player)
	end
end

return Elves
