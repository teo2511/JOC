class_name Interactable
extends StaticBody3D
## Objeto fijo del escenario que se puede usar con [E] (botones, palancas, máquinas).
## No se puede coger. El jugador pide usarlo con request_use y el anfitrión decide;
## la señal "used" solo se emite en el anfitrión.

signal used(by: Player)

@export var action_text := "Usar"
## Segundos mínimos entre dos usos, para que no se pueda spamear.
@export var cooldown := 0.5

const MAX_USE_DISTANCE := 4.0

var _ready_at := 0.0


func _ready() -> void:
	add_to_group("interactable")
	collision_layer = (1 << 0) | (1 << 3) # mundo + interactuables


func get_interaction_text() -> String:
	return action_text


func can_use() -> bool:
	return Time.get_ticks_msec() / 1000.0 >= _ready_at


@rpc("any_peer", "call_local", "reliable")
func request_use() -> void:
	if not multiplayer.is_server():
		return
	var id := multiplayer.get_remote_sender_id()
	if id == 0:
		id = multiplayer.get_unique_id()
	var player := Player.find(get_tree(), id)
	if player == null or player.latest_position().distance_to(global_position) > MAX_USE_DISTANCE:
		return
	server_use(player)


## Regla del anfitrión: usa el objeto si ha pasado el tiempo de espera.
func server_use(by: Player) -> bool:
	if not can_use():
		return false
	_ready_at = Time.get_ticks_msec() / 1000.0 + cooldown
	Sfx.broadcast("click", global_position)
	used.emit(by)
	return true
