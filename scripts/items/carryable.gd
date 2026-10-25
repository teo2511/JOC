class_name Carryable
extends RigidBody3D
## Objeto que un elfo puede coger, soltar y lanzar (regalos, juguetes, materiales).
##
## Mientras alguien lo lleva, el objeto se congela y sigue el punto de agarre del elfo.
## Solo puede tener un portador a la vez: try_pick() devuelve false si ya está cogido.
## En la Fase 4 estas llamadas pasarán por el anfitrión, que decidirá quién lo coge.

signal picked(by: Node3D)
signal dropped

## Nombre que aparece en el aviso de interacción ("[E] Coger Regalo").
@export var display_name := "Objeto"
## Altura por debajo de la cual el objeto vuelve a su punto de aparición.
@export var respawn_below_y := -10.0

const FOLLOW_SPEED := 25.0

static var _highlight_material: StandardMaterial3D

var holder: Node3D = null
var _hold_point: Node3D = null
var _spawn_transform: Transform3D
var _mesh: MeshInstance3D


func _ready() -> void:
	add_to_group("carryable")
	collision_layer = 1 << 2 # capa "objetos"
	collision_mask = 0b0111 # mundo, jugadores y objetos
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	continuous_cd = true
	_spawn_transform = global_transform
	_mesh = _find_mesh(self)


func get_interaction_text() -> String:
	return "Coger " + display_name


func is_held() -> bool:
	return holder != null


func try_pick(new_holder: Node3D, hold_point: Node3D) -> bool:
	if holder != null:
		return false
	holder = new_holder
	_hold_point = hold_point
	freeze = true
	# Sin colisión con el portador, para que no lo empuje ni lo levante.
	if new_holder is PhysicsBody3D:
		add_collision_exception_with(new_holder)
	set_highlighted(false)
	picked.emit(new_holder)
	return true


func drop(inherited_velocity := Vector3.ZERO) -> void:
	release(inherited_velocity)


func throw(direction: Vector3, speed: float, inherited_velocity := Vector3.ZERO) -> void:
	release(direction.normalized() * speed + inherited_velocity)


func release(velocity: Vector3) -> void:
	if holder == null:
		return
	var old_holder := holder
	holder = null
	_hold_point = null
	freeze = false
	linear_velocity = velocity
	angular_velocity = Vector3(randf_range(-2, 2), randf_range(-2, 2), randf_range(-2, 2))
	# Se recupera la colisión con el portador un instante después, cuando ya se ha alejado.
	if old_holder is PhysicsBody3D:
		get_tree().create_timer(0.3).timeout.connect(
			func():
				if is_instance_valid(old_holder) and holder != old_holder:
					remove_collision_exception_with(old_holder)
		)
	dropped.emit()


func set_highlighted(on: bool) -> void:
	if _mesh == null:
		return
	if _highlight_material == null:
		_highlight_material = StandardMaterial3D.new()
		_highlight_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_highlight_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_highlight_material.albedo_color = Color(1.0, 0.95, 0.6, 0.35)
	_mesh.material_overlay = _highlight_material if on else null


func respawn() -> void:
	if holder != null:
		release(Vector3.ZERO)
	global_transform = _spawn_transform
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO


func _physics_process(delta: float) -> void:
	if holder != null and is_instance_valid(_hold_point):
		var target := _hold_point.global_transform
		global_position = global_position.lerp(target.origin, minf(1.0, FOLLOW_SPEED * delta))
		global_basis = global_basis.slerp(target.basis.orthonormalized(), minf(1.0, FOLLOW_SPEED * delta)).orthonormalized()
	elif global_position.y < respawn_below_y:
		respawn()


func _find_mesh(node: Node) -> MeshInstance3D:
	for child in node.get_children():
		if child is MeshInstance3D:
			return child
		var found := _find_mesh(child)
		if found:
			return found
	return null
