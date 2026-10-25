class_name WorkshopState
extends Node
## Estado compartido del taller: regalos en el saco y objetivo de la noche.
## Solo el anfitrión lo cambia; el MultiplayerSynchronizer lo envía a todos.

signal changed
signal goal_reached

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


func is_complete() -> bool:
	return gifts_in_sack >= goal


func server_add_gift() -> void:
	if multiplayer.is_server():
		gifts_in_sack += 1
