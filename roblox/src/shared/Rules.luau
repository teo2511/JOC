--!strict
-- Reglas del juego que no dependen de Roblox (se pueden probar con `luau tests/run.luau`).
-- Los números vienen de la versión de Godot (workshop_state.gd).

local Rules = {}

-- Producción
Rules.GIFT_VALUE = 10 -- monedas por regalo metido en el saco
Rules.MACHINE_CRAFT_TIME = 3.0 -- segundos por juguete
Rules.MACHINE_CAPACITY = 3 -- bloques de madera en cola
Rules.WRAP_PRESSES = 3 -- pulsaciones para envolver un juguete

-- Noches (se usarán en la fase R3)
Rules.NIGHTS = 5
Rules.BASE_GOALS = { 6, 8, 10, 12, 14 }
Rules.GOAL_PER_EXTRA_PLAYER = 2

-- Regalos que hay que meter en el saco en una noche, igual que en Godot.
function Rules.goalFor(night: number, players: number): number
	local index = math.min(night, #Rules.BASE_GOALS)
	local base = Rules.BASE_GOALS[index]
	if night > #Rules.BASE_GOALS then
		base += 2 * (night - #Rules.BASE_GOALS) -- modo infinito
	end
	return base + Rules.GOAL_PER_EXTRA_PLAYER * math.max(players - 1, 0)
end

return Rules
