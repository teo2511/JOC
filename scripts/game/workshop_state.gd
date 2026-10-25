class_name WorkshopState
extends Node
## Estado compartido del taller: regalos en el saco, objetivo, dinero común y mejoras.
## Solo el anfitrión lo cambia; el MultiplayerSynchronizer lo envía a todos.
## El dinero es del equipo: solo se gasta comprando mejoras, nadie puede quitárselo a otro.

signal changed
signal goal_reached
## En todos los PCs, cuando alguien compra una mejora.
signal upgrade_bought(index: int, buyer_name: String)

## Monedas que da cada regalo que entra en el saco.
const GIFT_VALUE := 10

var gifts_in_sack := 0:
	set(value):
		var was_complete := is_complete()
		gifts_in_sack = value
		changed.emit()
		if not was_complete and is_complete():
			goal_reached.emit()
var goal := 10:
	set(value):
		goal = value
		changed.emit()
var money := 0:
	set(value):
		money = value
		changed.emit()
var total_earned := 0:
	set(value):
		total_earned = value
		changed.emit()
## Nivel de cada mejora, en el orden de Upgrades.LIST. Se reasigna entero al cambiar para
## que el MultiplayerSynchronizer detecte el cambio.
var upgrade_levels := PackedInt32Array([0, 0, 0, 0, 0]):
	set(value):
		upgrade_levels = value
		changed.emit()


func is_complete() -> bool:
	return gifts_in_sack >= goal


func level(index: int) -> int:
	return upgrade_levels[index] if index < upgrade_levels.size() else 0


func next_price(index: int) -> int:
	return Upgrades.price(index, level(index))


func server_add_gift() -> void:
	if not multiplayer.is_server():
		return
	gifts_in_sack += 1
	money += GIFT_VALUE
	total_earned += GIFT_VALUE


## Compra el siguiente nivel de una mejora si hay dinero. Devuelve si se ha comprado.
func server_buy(index: int, buyer_name := "") -> bool:
	if not multiplayer.is_server() or index < 0 or index >= Upgrades.LIST.size():
		return false
	var cost := next_price(index)
	if cost < 0 or money < cost:
		return false
	money -= cost
	var levels := upgrade_levels.duplicate()
	levels[index] += 1
	upgrade_levels = levels
	_announce_purchase.rpc(index, buyer_name)
	return true


@rpc("authority", "call_local", "reliable")
func _announce_purchase(index: int, buyer_name: String) -> void:
	upgrade_bought.emit(index, buyer_name)
