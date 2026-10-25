extends Node3D
## Cinta transportadora (mejora "Cinta transportadora"). Oculta hasta que se compra.
## En el anfitrión empuja los objetos sueltos que hay encima en su dirección (-X local →
## +X local) y, al llegar al final, los sube a la mesa de destino.

@export var speed := 1.6
## Punto donde se dejan los objetos al final de la cinta (encima de la mesa).
@export var drop_target: Node3D

var active := false

@onready var _belt: StaticBody3D = $Belt
@onready var _carry_zone: Area3D = $CarryZone
@onready var _end_zone: Area3D = $EndZone
@onready var _belt_mesh: MeshInstance3D = $Belt/Mesh


func _ready() -> void:
	set_active(false)
	_connect_state.call_deferred()


func _connect_state() -> void:
	var g := get_tree().get_first_node_in_group("game") as Game
	if g == null:
		return
	g.state.changed.connect(func(): set_active(g.state.level(Upgrades.CONVEYOR) > 0))
	set_active(g.state.level(Upgrades.CONVEYOR) > 0)


func set_active(on: bool) -> void:
	active = on
	visible = on
	_belt.collision_layer = 1 if on else 0
	_carry_zone.monitoring = on
	_end_zone.monitoring = on


func _physics_process(_delta: float) -> void:
	if not active or not multiplayer.is_server():
		return
	var dir := global_basis.x.normalized()
	for body in _carry_zone.get_overlapping_bodies():
		if body is Carryable and body.is_available():
			var v: Vector3 = body.linear_velocity
			body.linear_velocity = Vector3(dir.x * speed, v.y, dir.z * speed)
	if drop_target:
		for body in _end_zone.get_overlapping_bodies():
			if body is Carryable and body.is_available():
				body.global_position = drop_target.global_position
				body.linear_velocity = Vector3.ZERO


func _process(delta: float) -> void:
	if active:
		var mat := _belt_mesh.get_active_material(0) as StandardMaterial3D
		if mat:
			mat.uv1_offset.x -= delta * speed
