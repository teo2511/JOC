class_name Interactable
extends StaticBody3D
## Objeto fijo del escenario que se puede usar con [E] (botones, palancas, máquinas).
## No se puede coger. Emite "used" cuando un elfo lo activa.

signal used(by: Node3D)

@export var action_text := "Usar"
## Segundos mínimos entre dos usos, para que no se pueda spamear.
@export var cooldown := 0.5

var _ready_at := 0.0


func _ready() -> void:
	add_to_group("interactable")
	collision_layer = (1 << 0) | (1 << 3) # mundo + interactuables


func get_interaction_text() -> String:
	return action_text


func can_use() -> bool:
	return Time.get_ticks_msec() / 1000.0 >= _ready_at


func use(by: Node3D) -> bool:
	if not can_use():
		return false
	_ready_at = Time.get_ticks_msec() / 1000.0 + cooldown
	used.emit(by)
	return true
