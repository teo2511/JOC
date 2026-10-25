class_name PlayerInteraction
extends Node
## Detecta qué está mirando el elfo y gestiona coger, soltar, lanzar y usar.
##
## [E] coge el objeto que miras, lo suelta si ya llevas uno, o usa un botón/máquina.
## [Clic izquierdo] lanza el objeto que llevas.

signal prompt_changed(text: String)
signal held_changed(item: Carryable)

@export var throw_speed := 11.0
@export var drop_forward_speed := 1.5

@onready var player: Player = get_parent()
@onready var ray: RayCast3D = %InteractRay
@onready var hold_point: Node3D = %HoldPoint

var held: Carryable = null
var _focused: Node = null
var _last_prompt := ""


func _ready() -> void:
	ray.add_exception(player)


func _physics_process(_delta: float) -> void:
	_update_focus()
	if not player.input_enabled:
		return
	if Input.is_action_just_pressed("interact"):
		interact()
	elif Input.is_action_just_pressed("throw"):
		throw_held()


## Acción principal [E]. Devuelve true si ha hecho algo.
func interact() -> bool:
	if held != null:
		drop_held()
		return true
	if _focused is Carryable:
		return pick_up(_focused)
	if _focused is Interactable:
		return _focused.use(player)
	return false


func pick_up(item: Carryable) -> bool:
	if held != null or not item.try_pick(player, hold_point):
		return false
	held = item
	held.tree_exiting.connect(_on_held_freed, CONNECT_ONE_SHOT)
	held_changed.emit(held)
	return true


func drop_held() -> void:
	if held == null:
		return
	var item := held
	_clear_held()
	item.drop(player.velocity + _aim_direction() * drop_forward_speed)


func throw_held() -> bool:
	if held == null:
		return false
	var item := held
	_clear_held()
	# Un poco hacia arriba para que el arco sea agradable.
	var dir := (_aim_direction() + Vector3.UP * 0.15).normalized()
	item.throw(dir, throw_speed, player.velocity)
	return true


func _aim_direction() -> Vector3:
	return -player.camera.global_basis.z


func _clear_held() -> void:
	if held and held.tree_exiting.is_connected(_on_held_freed):
		held.tree_exiting.disconnect(_on_held_freed)
	held = null
	held_changed.emit(null)


func _on_held_freed() -> void:
	held = null
	held_changed.emit(null)


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
		if _focused is Carryable and is_instance_valid(_focused):
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
