class_name WorkshopState
extends Node
## Estado compartido del taller: regalos en el saco, objetivo, dinero común, mejoras y reparto.
## Solo el anfitrión lo cambia; el MultiplayerSynchronizer lo envía a todos.
## El dinero es del equipo: solo se gasta comprando mejoras, nadie puede quitárselo a otro.

signal changed
signal goal_reached
## En todos los PCs, cuando alguien compra una mejora.
signal upgrade_bought(index: int, buyer_name: String)
## En todos los PCs: aviso grande para el equipo ("¡El trineo ha llegado!").
signal announced(text: String)

## Monedas que da cada regalo que entra en el saco.
const GIFT_VALUE := 10
## Monedas extra por cada regalo que entra en una chimenea.
const DELIVERY_VALUE := 5

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
## Noche en curso (empieza en 1). Sube al terminar cada reparto.
var night := 1:
	set(value):
		night = value
		changed.emit()
## true mientras el trineo está en el patio esperando a que se repartan los regalos.
var delivering := false:
	set(value):
		delivering = value
		changed.emit()
## Regalos que quedan en el trineo.
var sleigh_gifts := 0:
	set(value):
		sleigh_gifts = value
		changed.emit()
## Regalos entregados en chimeneas esta noche.
var delivered := 0:
	set(value):
		delivered = value
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


## Saco lleno: sus regalos pasan al trineo y empieza el reparto.
func server_start_delivery() -> bool:
	if not multiplayer.is_server() or delivering or not is_complete():
		return false
	sleigh_gifts += gifts_in_sack
	gifts_in_sack = 0
	delivered = 0
	delivering = true
	server_announce("¡El trineo ha llegado al patio! Llevad los regalos a las chimeneas")
	return true


## Saca un regalo del trineo. Devuelve si quedaba alguno.
func server_take_from_sleigh() -> bool:
	if not multiplayer.is_server() or not delivering or sleigh_gifts <= 0:
		return false
	sleigh_gifts -= 1
	return true


## Un regalo ha entrado en una chimenea.
func server_deliver() -> void:
	if not multiplayer.is_server():
		return
	delivered += 1
	money += DELIVERY_VALUE
	total_earned += DELIVERY_VALUE


## Todas las casas tienen sus regalos: termina la noche. Lo que sobre en el trineo vuelve
## al saco para la noche siguiente.
func server_finish_night() -> void:
	if not multiplayer.is_server() or not delivering:
		return
	delivering = false
	gifts_in_sack += sleigh_gifts
	sleigh_gifts = 0
	night += 1
	server_announce("¡Reparto completado! Empieza la noche %d" % night)


func server_announce(text: String) -> void:
	_announce_text.rpc(text)


@rpc("authority", "call_local", "reliable")
func _announce_text(text: String) -> void:
	announced.emit(text)


@rpc("authority", "call_local", "reliable")
func _announce_purchase(index: int, buyer_name: String) -> void:
	upgrade_bought.emit(index, buyer_name)
