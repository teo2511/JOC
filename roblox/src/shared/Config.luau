--!strict
-- Ajustes propios de Roblox (medidas en studs, colores). Las reglas están en Rules.
-- 1 metro de Godot = 3,5 studs.

local Rules = require(script.Parent.Rules)

local Config = setmetatable({}, { __index = Rules })

Config.STUDS_PER_METER = 3.5

-- Coger y lanzar
Config.MAX_PICK_DISTANCE = 14 -- studs desde el personaje
Config.THROW_SPEED = 70 -- studs/s
Config.THROW_UP = 18 -- empujón hacia arriba al lanzar
Config.DROP_SPEED = 8
Config.HOLD_OFFSET = CFrame.new(0, 0.6, -3.2) -- delante del pecho

-- Colores de gorro por jugador (verde, azul, naranja, morado).
Config.ELF_COLORS = {
	Color3.fromRGB(33, 140, 64),
	Color3.fromRGB(51, 102, 217),
	Color3.fromRGB(217, 128, 26),
	Color3.fromRGB(153, 64, 191),
}

return Config
