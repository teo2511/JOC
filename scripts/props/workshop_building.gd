@tool
extends Node3D
## Construye la parte bonita del edificio del taller: tejado a dos aguas con nieve, vigas,
## postes, ventanas y faroles. Las paredes y el suelo con colisión siguen en la escena.
## Todo se genera al cargar, así que se ve también en el editor y no hay que colocar piezas a mano.

## Medidas del taller (coinciden con las paredes de la escena).
@export var half_size := 15.0
@export var wall_height := 3.0
## Altura de la cumbrera del tejado.
@export var ridge_height := 6.2
## Ancho del hueco de la puerta en la pared este.
@export var door_width := 4.0

const WOOD_DARK := preload("res://materials/wood_dark.tres")
const WOOD_WALL := preload("res://materials/wood_wall.tres")
const ROOF := preload("res://materials/roof.tres")
const SNOW := preload("res://materials/snow.tres")
const OVERHANG := 0.8


func _ready() -> void:
	for child in get_children():
		child.queue_free()
	_build_roof()
	_build_frame()
	_build_windows()


func _build_roof() -> void:
	var eave := wall_height + 0.15
	var span := half_size + OVERHANG
	var rise := ridge_height - eave
	var slope := atan2(rise, span)
	var length := sqrt(span * span + rise * rise)
	for side in [-1.0, 1.0]:
		var pivot := Node3D.new()
		pivot.position = Vector3(0, (eave + ridge_height) * 0.5, side * span * 0.5)
		pivot.rotation.x = side * slope
		add_child(pivot)
		_box(pivot, Vector3.ZERO, Vector3(half_size * 2 + OVERHANG * 2, 0.25, length), ROOF, true)
		_box(pivot, Vector3(0, 0.2, 0), Vector3(half_size * 2 + OVERHANG * 2 + 0.1, 0.15, length + 0.05), SNOW)
	# Hastiales: los triángulos de pared entre las paredes y el tejado.
	for x in [-half_size, half_size]:
		var prism := PrismMesh.new()
		prism.size = Vector3(half_size * 2, ridge_height - wall_height, 0.5)
		var mesh := MeshInstance3D.new()
		mesh.mesh = prism
		mesh.material_override = WOOD_WALL
		mesh.position = Vector3(x, wall_height + (ridge_height - wall_height) * 0.5 - 0.05, 0)
		mesh.rotation.y = PI / 2
		add_child(mesh)
		var body := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		shape.shape = prism.create_convex_shape()
		body.add_child(shape)
		mesh.add_child(body)


func _build_frame() -> void:
	var h := half_size
	var post := Vector3(0.6, wall_height + 0.3, 0.6)
	var py := (wall_height + 0.3) * 0.5
	# Postes en las esquinas y cada 7,5 m.
	for i in range(5):
		var t := -h + i * h * 0.5
		for p in [Vector3(t, py, -h), Vector3(t, py, h), Vector3(-h, py, t)]:
			_box(self, p, post, WOOD_DARK)
		if absf(t) > door_width:
			_box(self, Vector3(h, py, t), post, WOOD_DARK)
	for z in [-door_width * 0.5, door_width * 0.5]:
		_box(self, Vector3(h, py, z), post, WOOD_DARK)
	# Dintel de la puerta y viga de remate encima de las paredes.
	_box(self, Vector3(h, wall_height - 0.15, 0), Vector3(0.6, 0.3, door_width + 0.4), WOOD_DARK)
	var top := wall_height + 0.15
	_box(self, Vector3(0, top, -h), Vector3(h * 2 + 0.6, 0.3, 0.6), WOOD_DARK)
	_box(self, Vector3(0, top, h), Vector3(h * 2 + 0.6, 0.3, 0.6), WOOD_DARK)
	# Tirantes de lado a lado, pendolón y cumbrera.
	for i in range(6):
		var x := -h + 2.5 + i * 5.0
		_box(self, Vector3(x, top, 0), Vector3(0.3, 0.35, h * 2), WOOD_DARK)
		var king := ridge_height - top - 0.3
		_box(self, Vector3(x, top + king * 0.5, 0), Vector3(0.25, king, 0.25), WOOD_DARK)
	_box(self, Vector3(0, ridge_height - 0.35, 0), Vector3(h * 2, 0.35, 0.3), WOOD_DARK)


func _build_windows() -> void:
	var h := half_size - 0.26
	for x in [-9.0, -1.0, 7.0]:
		_window(Vector3(x, 1.8, -h), 0.0)
		_window(Vector3(x, 1.8, h), PI)
	for z in [-8.5, 8.5]:
		_window(Vector3(h, 1.8, z), -PI / 2) # por dentro
		_window(Vector3(h + 0.52, 1.8, z), PI / 2) # por fuera, se ve desde el patio


## Ventana de 1,4 x 1,1 m mirando hacia +Z local (rot_y la gira hacia el interior).
func _window(pos: Vector3, rot_y: float) -> void:
	var root := Node3D.new()
	root.position = pos
	root.rotation.y = rot_y
	add_child(root)
	var glass := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(1.3, 1.0)
	glass.mesh = quad
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.08, 0.12, 0.25)
	mat.emission_enabled = true
	mat.emission = Color(0.25, 0.38, 0.7)
	mat.emission_energy_multiplier = 0.6
	mat.roughness = 0.1
	mat.metallic = 0.3
	glass.material_override = mat
	glass.position.z = 0.01
	root.add_child(glass)
	var frame := 0.1
	_box(root, Vector3(0, 0.55, 0.04), Vector3(1.5, frame, 0.08), WOOD_DARK)
	_box(root, Vector3(0, -0.55, 0.06), Vector3(1.6, frame * 1.4, 0.14), WOOD_DARK)
	_box(root, Vector3(-0.7, 0, 0.04), Vector3(frame, 1.2, 0.08), WOOD_DARK)
	_box(root, Vector3(0.7, 0, 0.04), Vector3(frame, 1.2, 0.08), WOOD_DARK)
	_box(root, Vector3(0, 0, 0.03), Vector3(0.05, 1.0, 0.05), WOOD_DARK)
	_box(root, Vector3(0, 0, 0.03), Vector3(1.3, 0.05, 0.05), WOOD_DARK)
	# Nieve acumulada en el alféizar.
	_box(root, Vector3(0, -0.47, 0.06), Vector3(1.3, 0.04, 0.1), SNOW)


func _box(parent: Node, pos: Vector3, size: Vector3, material: Material, collide := false) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = material
	mesh.position = pos
	parent.add_child(mesh)
	if collide:
		var body := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var col := BoxShape3D.new()
		col.size = size
		shape.shape = col
		body.add_child(shape)
		mesh.add_child(body)
	return mesh
