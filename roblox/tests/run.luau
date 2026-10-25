--!nocheck
-- Tests de la lógica que no depende de Roblox. Uso (desde roblox/):
--   luau tests/run.luau

local Config = require("../src/shared/Rules")

local passed, failed = 0, 0
local function check(ok, name)
	if ok then
		passed += 1
		print("  OK   " .. name)
	else
		failed += 1
		print("  FALLO " .. name)
	end
end

check(Config.goalFor(1, 1) == 6, "noche 1 con 1 elfo: 6 regalos")
check(Config.goalFor(1, 4) == 12, "noche 1 con 4 elfos: 6 + 2*3 = 12")
check(Config.goalFor(5, 2) == 16, "noche 5 con 2 elfos: 14 + 2 = 16")
check(Config.goalFor(7, 1) == 18, "modo infinito, noche 7: 14 + 2*2 = 18")
check(Config.goalFor(3, 0) == 10, "sin jugadores cuenta como 1")
check(Config.goalFor(2, 1) == 8 and Config.goalFor(4, 1) == 12, "noches 2 y 4: 8 y 12 regalos")
check(Config.MACHINE_CAPACITY >= 1 and Config.WRAP_PRESSES >= 1, "la fábrica y la mesa aceptan algo")

print(string.format("\n%d pruebas correctas, %d fallos", passed, failed))
if failed > 0 then
	error("hay fallos")
end
