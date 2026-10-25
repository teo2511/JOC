class_name Pranks
extends Node
## Reglas de las bromas entre elfos (empujones y bolas de nieve). Solo actúa en el anfitrión.
##
## Límites para que el caos no se convierta en acoso:
## - Cada elfo puede empujar una vez cada PUSH_COOLDOWN segundos.
## - Quien recibe un golpe es inmune durante IMMUNITY_TIME segundos.
## - Nadie muere ni pierde nada: lo que llevaba se le cae al suelo y lo puede recoger.

const PUSH_RANGE := 2.3
const PUSH_COOLDOWN := 1.5
const IMMUNITY_TIME := 2.0
const PUSH_FORCE := 7.0
const PUSH_LIFT := 2.5
const ITEM_SHOVE_SPEED := 6.0

## peer_id -> instante (s) a partir del cual puede volver a empujar / ser golpeado.
var _push_ready_at := {}
var _immune_until := {}


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


func can_push(pusher_id: int) -> bool:
	return _now() >= _push_ready_at.get(pusher_id, 0.0)


func is_immune(peer_id: int) -> bool:
	return _now() < _immune_until.get(peer_id, 0.0)


## Un elfo empuja a otro. Devuelve si el empujón se ha aplicado.
func server_push_player(pusher_id: int, target_id: int) -> bool:
	if pusher_id == target_id or not can_push(pusher_id):
		return false
	var pusher := Player.find(get_tree(), pusher_id)
	var target := Player.find(get_tree(), target_id)
	if pusher == null or target == null:
		return false
	var offset := target.latest_position() - pusher.latest_position()
	offset.y = 0
	if offset.length() > PUSH_RANGE:
		return false
	_push_ready_at[pusher_id] = _now() + PUSH_COOLDOWN
	var dir := offset.normalized() if offset.length() > 0.01 else -pusher.global_basis.z
	pusher.play_prank_anim.rpc("push")
	return server_hit(target_id, dir * PUSH_FORCE + Vector3.UP * PUSH_LIFT, "push")


## Un elfo da un empujón a un objeto suelto.
func server_push_item(pusher_id: int, item: Carryable) -> bool:
	if not can_push(pusher_id) or item == null or not item.is_available():
		return false
	var pusher := Player.find(get_tree(), pusher_id)
	if pusher == null:
		return false
	var offset := item.global_position - pusher.latest_position()
	if offset.length() > PUSH_RANGE + 0.5:
		return false
	_push_ready_at[pusher_id] = _now() + PUSH_COOLDOWN
	offset.y = 0
	item.linear_velocity += offset.normalized() * ITEM_SHOVE_SPEED + Vector3.UP * 2.0
	return true


## Golpea a un elfo (empujón o bola de nieve): suelta lo que lleva y sale despedido.
## Respeta la inmunidad, así que no se puede encadenar golpes sobre la misma persona.
func server_hit(target_id: int, impulse: Vector3, kind: String) -> bool:
	if is_immune(target_id):
		return false
	var target := Player.find(get_tree(), target_id)
	if target == null:
		return false
	_immune_until[target_id] = _now() + IMMUNITY_TIME
	Sfx.broadcast(kind if Sfx.has_sound(kind) else "push", target.latest_position() + Vector3.UP)
	target.play_prank_anim.rpc("hit")
	for item in get_tree().get_nodes_in_group("carryable"):
		if item.holder_peer == target_id:
			item.server_release(target_id, impulse * 0.4)
	if target_id == multiplayer.get_unique_id():
		target.apply_hit(impulse, kind)
	else:
		target.receive_hit.rpc_id(target_id, impulse, kind)
	return true


func forget(peer_id: int) -> void:
	_push_ready_at.erase(peer_id)
	_immune_until.erase(peer_id)
