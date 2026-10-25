--!strict
-- Arranque del servidor: construye el mapa, crea el estado de la partida y las estaciones.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local MapBuilder = require(script.Parent.MapBuilder)
local Items = require(script.Parent.Items)
local Stations = require(script.Parent.Stations)
local Elves = require(script.Parent.Elves)

-- Estado compartido: los atributos se copian solos a todos los clientes (los lee el HUD).
local state = Instance.new("Folder")
state.Name = "GameState"
state:SetAttribute("Gifts", 0)
state:SetAttribute("Money", 0)
state:SetAttribute("Night", 1)
state:SetAttribute("Goal", Config.goalFor(1, 1))
state.Parent = ReplicatedStorage

MapBuilder.build()
Items.init()
Stations.init(state)
Elves.init()

-- El objetivo depende de cuántos elfos hay (más adelante solo cambiará entre noches).
local function updateGoal()
	state:SetAttribute("Goal", Config.goalFor(state:GetAttribute("Night") :: number, math.max(#Players:GetPlayers(), 1)))
end
Players.PlayerAdded:Connect(updateGoal)
Players.PlayerRemoving:Connect(function()
	task.defer(updateGoal)
end)

-- Unos regalos sueltos para probar a coger y lanzar nada más entrar.
for i = 1, 3 do
	Items.spawn("gift", Vector3.new(-8 + i * 4, 3, 0))
end
