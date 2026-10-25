@tool
extends Node3D
## Detalles de decoración de las estaciones del taller (solo se ven, no tienen colisión).
## Se pone como hijo "Look" de cada estación y `kind` dice qué montar. Las piezas que los
## scripts de las estaciones usan (cuerpo de la fábrica, engranaje, saco...) no se tocan.

@export_enum("bin", "machine", "table", "sack", "conveyor", "pedestal", "snow") var kind := "bin"

const WOOD := preload("res://materials/wood_wall.tres")
const WOOD_FLOOR := preload("res://materials/wood_floor.tres")
const WOOD_DARK := preload("res://materials/wood_dark.tres")
const SNOW := preload("res://materials/snow.tres")

var _iron := MeshKit.color(Color(0.18, 0.18, 0.2), 0.45, 0.8)
var _gold := MeshKit.color(Color(0.95, 0.72, 0.22), 0.3, 0.85)


func _ready() -> void:
	MeshKit.clear(self)
	match kind:
		"bin": _bin()
		"machine": _machine()
		"table": _table()
		"sack": _sack()
		"conveyor": _conveyor()
		"pedestal": _pedestal()
		"snow": _snow()


func _sibling(node_name: String) -> MeshInstance3D:
	return get_parent().get_node_or_null(node_name) as MeshInstance3D if get_parent() else null


func _bin() -> void:
	var crate := _sibling("Crate")
	if crate:
		var mat := MeshKit.planks(WOOD, Color(0.5, 0.33, 0.18), Color(0.62, 0.42, 0.24))
		mat.set_shader_parameter("vertical", true)
		mat.set_shader_parameter("baseboard_height", 0.0)
		mat.set_shader_parameter("plank_width", 0.2)
		crate.material_override = mat
	for x in [-0.6, 0.6]:
		for z in [-0.6, 0.6]:
			MeshKit.box(self, Vector3(0.1, 0.86, 0.1), WOOD_DARK, Vector3(x, 0.43, z))
	for y in [0.15, 0.7]:
		MeshKit.box(self, Vector3(1.24, 0.06, 1.24), _iron, Vector3(0, y, 0))
	var logs := MeshKit.color(Color(0.45, 0.3, 0.17), 0.9)
	for i in 4:
		MeshKit.cylinder(self, 0.09, 1.0, logs, Vector3(-0.35 + i * 0.23, 0.82, 0), Vector3(90, 0, 0), -1.0, 8)
	# Tocón con un hacha clavada al lado del cajón.
	MeshKit.cylinder(self, 0.25, 0.4, logs, Vector3(0.95, 0.2, 0.55), Vector3.ZERO, 0.23, 10)
	MeshKit.cylinder(self, 0.24, 0.02, MeshKit.color(Color(0.8, 0.65, 0.42)), Vector3(0.95, 0.41, 0.55), Vector3.ZERO, -1.0, 10)
	var axe := Node3D.new()
	axe.position = Vector3(0.95, 0.42, 0.55)
	axe.rotation_degrees = Vector3(0, 30, -25)
	add_child(axe)
	MeshKit.cylinder(axe, 0.025, 0.6, MeshKit.color(Color(0.6, 0.4, 0.2)), Vector3(0, 0.3, 0))
	MeshKit.box(axe, Vector3(0.2, 0.1, 0.03), _iron, Vector3(0.08, 0.03, 0))


func _machine() -> void:
	# Patas, remaches, tuberías, panel de control, luces y una chimenea que echa vapor.
	for x in [-0.7, 0.7]:
		for z in [-0.6, 0.6]:
			MeshKit.box(self, Vector3(0.2, 0.08, 0.2), _iron, Vector3(x, 0.04, z))
	for y in [0.12, 1.33]:
		for z in [-0.72, 0.72]:
			MeshKit.box(self, Vector3(1.64, 0.08, 0.04), _gold, Vector3(0, y, z))
		for x in [-0.82, 0.82]:
			MeshKit.box(self, Vector3(0.04, 0.08, 1.44), _gold, Vector3(x, y, 0))
	for i in 7:
		var x := -0.7 + i * 0.233
		MeshKit.sphere(self, 0.025, _iron, Vector3(x, 1.24, 0.71))
		MeshKit.sphere(self, 0.025, _iron, Vector3(x, 0.22, 0.71))
	var copper := MeshKit.color(Color(0.75, 0.42, 0.25), 0.35, 0.8)
	MeshKit.cylinder(self, 0.07, 1.0, copper, Vector3(-0.88, 0.7, -0.3))
	MeshKit.cylinder(self, 0.07, 0.5, copper, Vector3(-0.88, 1.2, 0.0), Vector3(90, 0, 0))
	MeshKit.cylinder(self, 0.07, 0.9, copper, Vector3(-0.88, 0.75, 0.25))
	MeshKit.torus(self, 0.06, 0.1, _iron, Vector3(-0.88, 0.45, -0.3))
	# Panel con relojes al lado del engranaje.
	MeshKit.box(self, Vector3(0.5, 0.35, 0.05), MeshKit.color(Color(0.12, 0.12, 0.14)), Vector3(-0.5, 0.95, 0.72))
	for x in [-0.62, -0.38]:
		MeshKit.cylinder(self, 0.08, 0.03, MeshKit.color(Color(0.95, 0.93, 0.85)), Vector3(x, 0.98, 0.75), Vector3(90, 0, 0))
		MeshKit.box(self, Vector3(0.012, 0.07, 0.01), MeshKit.color(Color(0.8, 0.1, 0.1)), Vector3(x, 1.0, 0.77), Vector3(0, 0, 30))
	MeshKit.sphere(self, 0.05, MeshKit.glow(Color(0.2, 1.0, 0.3), 3.0), Vector3(0.55, 1.2, 0.72))
	MeshKit.sphere(self, 0.05, MeshKit.glow(Color(1.0, 0.25, 0.2), 3.0), Vector3(0.7, 1.2, 0.72))
	# Bastón de caramelo a cada lado de la boca de salida.
	for x in [-0.42, 0.42]:
		for k in 6:
			var mat := MeshKit.color(Color(0.9, 0.1, 0.12) if k % 2 == 0 else Color(0.97, 0.97, 0.95), 0.4)
			MeshKit.cylinder(self, 0.045, 0.1, mat, Vector3(x, 0.05 + k * 0.1, 0.78), Vector3.ZERO, -1.0, 8)
	MeshKit.cylinder(self, 0.1, 0.5, _iron, Vector3(0.5, 1.65, -0.4))
	MeshKit.cylinder(self, 0.14, 0.08, _iron, Vector3(0.5, 1.92, -0.4))
	var steam := _puffs(Vector3(0.5, 2.0, -0.4), Color(0.9, 0.92, 0.95, 0.4), 8, 0.12)
	steam.lifetime = 1.6


func _table() -> void:
	var table := _sibling("Table")
	if table:
		table.visible = false
	MeshKit.box(self, Vector3(1.7, 0.1, 1.1), WOOD_FLOOR, Vector3(0, 0.85, 0))
	for x in [-0.75, 0.75]:
		for z in [-0.45, 0.45]:
			MeshKit.box(self, Vector3(0.1, 0.8, 0.1), WOOD_DARK, Vector3(x, 0.4, z))
	MeshKit.box(self, Vector3(1.55, 0.05, 0.95), WOOD_DARK, Vector3(0, 0.25, 0))
	var colors := [Color(0.85, 0.12, 0.15), Color(0.15, 0.5, 0.25), Color(0.25, 0.4, 0.85), Color(0.95, 0.85, 0.3)]
	for i in colors.size():
		MeshKit.cylinder(self, 0.07, 0.8, MeshKit.color(colors[i], 0.5), Vector3(-0.1, 0.35 + (i % 2) * 0.13, -0.3 + i * 0.18), Vector3(0, 0, 90), -1.0, 10)
	# Carretes de cinta, tijeras y un rollo de papel abierto encima de la mesa.
	for i in 3:
		var spool := MeshKit.color(colors[(i + 1) % colors.size()], 0.4, 0.2)
		MeshKit.cylinder(self, 0.06, 0.05, spool, Vector3(0.55, 0.925 + i * 0.05, 0.35), Vector3.ZERO, -1.0, 12)
	MeshKit.box(self, Vector3(0.22, 0.01, 0.03), _iron, Vector3(-0.55, 0.905, 0.3), Vector3(0, 20, 0))
	MeshKit.box(self, Vector3(0.22, 0.01, 0.03), _iron, Vector3(-0.55, 0.905, 0.3), Vector3(0, -20, 0))
	MeshKit.torus(self, 0.02, 0.04, MeshKit.color(Color(0.85, 0.12, 0.15)), Vector3(-0.66, 0.905, 0.26))
	MeshKit.box(self, Vector3(0.8, 0.005, 0.5), MeshKit.color(Color(0.85, 0.15, 0.2), 0.6), Vector3(0.1, 0.903, 0.12))


func _sack() -> void:
	var bag := get_parent().get_node_or_null("Bag") as Node3D if get_parent() else null
	var root: Node3D = bag if bag else self
	var old := root.get_node_or_null("SackDetails")
	if old:
		old.free()
	var holder := Node3D.new()
	holder.name = "SackDetails"
	root.add_child(holder)
	# Cuerda en el cuello, estrella dorada y regalos asomando por la boca (crecen con el saco).
	MeshKit.torus(holder, 0.6, 0.66, MeshKit.color(Color(0.75, 0.6, 0.35), 1.0), Vector3(0, 1.02, 0))
	MeshKit.box(holder, Vector3(0.3, 0.3, 0.04), _gold, Vector3(0, 0.65, 0.84), Vector3(0, 0, 45))
	MeshKit.box(holder, Vector3(0.3, 0.3, 0.04), _gold, Vector3(0, 0.65, 0.84))
	var colors := [Color(0.15, 0.5, 0.25), Color(0.25, 0.4, 0.85), Color(0.95, 0.85, 0.3)]
	for i in colors.size():
		var angle := TAU * i / colors.size()
		MeshKit.box(holder, Vector3.ONE * 0.32, MeshKit.color(colors[i], 0.5), Vector3(cos(angle) * 0.22, 1.2, sin(angle) * 0.22), Vector3(10, rad_to_deg(angle), 15))
	MeshKit.cylinder(self, 1.0, 0.04, MeshKit.color(Color(0.55, 0.12, 0.12), 1.0), Vector3(0, 0.02, 0), Vector3.ZERO, -1.0, 24)


func _conveyor() -> void:
	var dark := MeshKit.color(Color(0.15, 0.15, 0.17), 0.6, 0.5)
	for x in [-2.3, 2.3]:
		MeshKit.cylinder(self, 0.16, 0.84, _iron, Vector3(x, 0.16, 0), Vector3(90, 0, 0), -1.0, 12)
	for z in [-0.41, 0.41]:
		MeshKit.box(self, Vector3(4.6, 0.26, 0.03), dark, Vector3(0, 0.15, z))
	for x in [-1.5, -0.5, 0.5, 1.5]:
		for z in [-0.42, 0.42]:
			MeshKit.sphere(self, 0.025, _gold, Vector3(x, 0.2, z * 1.02))


func _pedestal() -> void:
	var base := _sibling("Base")
	var w := 0.7
	if base and base.mesh is BoxMesh:
		w = (base.mesh as BoxMesh).size.x
	MeshKit.box(self, Vector3(w + 0.12, 0.12, w + 0.12), WOOD_DARK, Vector3(0, 0.06, 0))
	MeshKit.box(self, Vector3(w + 0.06, 0.06, w + 0.06), _gold, Vector3(0, 0.98, 0))


func _snow() -> void:
	var mound := _sibling("Mound")
	if mound:
		mound.material_override = SNOW
	for p in [Vector3(0.85, 0.12, 0.4), Vector3(0.95, 0.1, 0.1), Vector3(0.75, 0.3, 0.25)]:
		MeshKit.sphere(self, 0.13, SNOW, p)
	# Pala clavada en el montón.
	var shovel := Node3D.new()
	shovel.position = Vector3(-0.3, 0.5, -0.2)
	shovel.rotation_degrees = Vector3(15, 0, 20)
	add_child(shovel)
	MeshKit.cylinder(shovel, 0.03, 0.9, MeshKit.color(Color(0.6, 0.4, 0.2)), Vector3(0, 0.45, 0))
	MeshKit.box(shovel, Vector3(0.28, 0.32, 0.03), MeshKit.color(Color(0.75, 0.15, 0.15), 0.5, 0.3), Vector3(0, -0.05, 0))


func _puffs(pos: Vector3, c: Color, amount: int, radius: float) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.position = pos
	p.amount = amount
	p.lifetime = 2.5
	p.preprocess = 2.5
	p.direction = Vector3.UP
	p.spread = 15.0
	p.gravity = Vector3(0, 0.3, 0)
	p.initial_velocity_min = 0.3
	p.initial_velocity_max = 0.6
	var curve := Curve.new()
	curve.add_point(Vector2(0, 0.4))
	curve.add_point(Vector2(1, 1.8))
	p.scale_amount_curve = curve
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2
	mesh.radial_segments = 8
	mesh.rings = 4
	var mat := StandardMaterial3D.new()
	mat.albedo_color = c
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.material = mat
	p.mesh = mesh
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(p)
	return p
