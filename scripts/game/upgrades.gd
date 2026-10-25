class_name Upgrades
extends RefCounted
## Catálogo de mejoras del taller. El índice de cada una es su posición en LIST
## y coincide con WorkshopState.upgrade_levels.

enum { FAST_MACHINE, BIG_MACHINE, FAST_BOOTS, CONVEYOR, AUTO_WRAP }

const LIST := [
	{"name": "Fábrica rápida", "prices": [30, 60, 120], "effect": "Juguetes un 25% más rápido"},
	{"name": "Fábrica grande", "prices": [40, 90], "effect": "+2 bloques en la cola"},
	{"name": "Botas de elfo", "prices": [35, 80], "effect": "Elfos un 15% más rápidos"},
	{"name": "Cinta transportadora", "prices": [80], "effect": "Lleva los juguetes a la mesa"},
	{"name": "Envolvedora automática", "prices": [150], "effect": "La mesa envuelve sola"},
]


static func max_level(index: int) -> int:
	return LIST[index]["prices"].size()


## Precio del siguiente nivel, o -1 si ya está al máximo.
static func price(index: int, current_level: int) -> int:
	var prices: Array = LIST[index]["prices"]
	return prices[current_level] if current_level < prices.size() else -1
