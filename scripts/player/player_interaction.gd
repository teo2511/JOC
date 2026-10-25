class_name PlayerInteraction
extends Node
## Detecta qué está mirando el elfo y gestiona coger, soltar, lanzar y usar.
##
## [E] coge el objeto que miras, lo suelta si ya llevas uno, o usa un botón/máquina.
## [Clic izquierdo] lanza el objeto que llevas.
## Solo funciona en el elfo propio. Coger y usar son peticiones al anfitrión: el objeto
## pasa a tus manos cuando él lo confirma (on_item_holder_changed).

signal prompt_changed(text: String)
signal held_changed(item: Carryable)

@export var throw_speed := 11.0
@export var drop_forward_speed := 1.5

@onready var player: Player = get_parent()
@onready var ray: RayCast3D = %InteractRay

var held: Carryable = null
var _focused: Node = null
var _last_prompt := ""


func _ready() -> void:
	ray.add_exception(player)
	if player.is_local():
		add_to_group("local_interaction")
	else:
		set_physics_process(false)
		ray.enabled = false


func _physics_process(_delta: float) -> void:
	if held != null and not is_instance_valid(held):
		_set_held(null)
	_update_focus()
	if not player.input_enabled:
		return
	if Input.is_action_just_pressed("interact"):
		interact()
	elif Input.is_action_just_pressed("throw"):
		throw_held()


## Acción principal [E]. Devuelve true si ha enviado alguna petición.
func interact() -> bool:
	if held != null:
		drop_held()
		return true
	if _focused is Carryable:
		_focused.request_pick.rpc_id(1)
		return true
	if _focused is Interactable:
		_focused.request_use.rpc_id(1)
		return true
	return false


func drop_held() -> void:
	if held == null:
		return
	held.request_release.rpc_id(1, player.velocity + _aim_direction() * drop_forward_speed)


func throw_held() -> bool:
	if held == null:
		return false
	# Un poco hacia arriba para que el arco sea agradable.
	var dir := (_aim_direction() + Vector3.UP * 0.15).normalized()
	held.request_release.rpc_id(1, dir * throw_speed + player.velocity)
	return true


## Lo llama cada Carryable (grupo "local_interaction") cuando cambia quién lo lleva.
func on_item_holder_changed(item: Carryable, old_peer: int, new_peer: int) -> void:
	var me := player.peer_id
	if new_peer == me:
		_set_held(item)
	elif old_peer == me and held == item:
		_set_held(null)


func _set_held(item: Carryable) -> void:
	held = item
	held_changed.emit(item)


func _aim_direction() -> Vector3:
	return -player.camera.global_basis.z


func _update_focus() -> void:
	if _focused != null and not is_instance_valid(_focused):
		_focused = null
	var target: Node = null
	if held == null and ray.is_colliding():
		var hit := ray.get_collider()
		if hit is Carryable and not hit.is_held():
			target = hit
		elif hit is Interactable:
			target = hit

	if target != _focused:
		if _focused is Carryable:
			_focused.set_highlighted(false)
		_focused = target
		if _focused is Carryable:
			_focused.set_highlighted(true)

	var prompt := ""
	if held != null:
		prompt = "[E] Soltar   [Clic] Lanzar"
	elif _focused != null:
		prompt = "[E] " + _focused.get_interaction_text()
	if prompt != _last_prompt:
		_last_prompt = prompt
		prompt_changed.emit(prompt)
