@tool
extends Node3D
## Detalles de los objetos que se cogen (regalos, juguetes, madera). Va como hijo "Look" de la
## malla "Mesh" de cada objeto, así se mueve con ella. El color sale del nombre del nodo, que
## es igual en todos los PC, para que cada jugador vea el mismo regalo.

@export_enum("gift", "car", "wood", "ball") var kind := "gift"

const WOOD := preload("res://materials/wood_wall.tres")
## Papel y cinta de los regalos.
const GIFTS := [
	[Color(0.82, 0.1, 0.14), Color(0.98, 0.85, 0.35)],
	[Color(0.12, 0.45, 0.22), Color(0.95, 0.2, 0.2)],
	[Color(0.2, 0.35, 0.8), Color(0.95, 0.95, 0.95)],
	[Color(0.55, 0.2, 0.65), Color(0.98, 0.85, 0.35)],
	[Color(0.95, 0.78, 0.2), Color(0.8, 0.1, 0.12)],
	[Color(0.95, 0.95, 0.92), Color(0.15, 0.5, 0.25)],
]
const CARS := [Color(0.9, 0.2, 0.15), Color(0.2, 0.45, 0.9), Color(0.95, 0.75, 0.15), Color(0.15, 0.6, 0.3)]


func _ready() -> void:
	MeshKit.clear(self)
	var mesh := get_parent() as MeshInstance3D
	if mesh == null:
		return
	var pick := absi(hash(String(mesh.get_parent().name))) if mesh.get_parent() else 0
	match kind:
		"gift": _gift(mesh, pick)
		"car": _car(mesh, pick)
		"wood": _wood(mesh)
		"ball": _ball(mesh, pick)


func _gift(mesh: MeshInstance3D, pick: int) -> void:
	var colors: Array = GIFTS[pick % GIFTS.size()]
	mesh.material_override = MeshKit.color(colors[0], 0.55)
	var ribbon := MeshKit.color(colors[1], 0.35, 0.3)
	for child in mesh.get_children():
		if child is MeshInstance3D:
			child.material_override = ribbon
	# Lazo de dos bucles y un nudo encima.
	for side in [-1.0, 1.0]:
		MeshKit.torus(self, 0.03, 0.08, ribbon, Vector3(side * 0.07, 0.26, 0), Vector3(0, 0, side * 35), )
	MeshKit.sphere(self, 0.035, ribbon, Vector3(0, 0.24, 0))


func _car(mesh: MeshInstance3D, pick: int) -> void:
	var paint := MeshKit.color(CARS[pick % CARS.size()], 0.3, 0.2)
	mesh.material_override = paint
	var cabin := mesh.get_node_or_null("Cabin") as MeshInstance3D
	if cabin:
		cabin.material_override = paint
	var glass := MeshKit.color(Color(0.4, 0.6, 0.85), 0.1, 0.4)
	for z in [-0.122, 0.122]:
		MeshKit.box(self, Vector3(0.18, 0.07, 0.005), glass, Vector3(-0.04, 0.15, z))
	MeshKit.box(self, Vector3(0.005, 0.07, 0.2), glass, Vector3(0.081, 0.15, 0))
	var chrome := MeshKit.color(Color(0.85, 0.85, 0.88), 0.2, 0.9)
	for z in [-0.09, 0.09]:
		MeshKit.sphere(self, 0.025, MeshKit.glow(Color(1, 0.95, 0.7), 2.0), Vector3(0.25, 0.02, z))
	for x in [-0.16, 0.16]:
		for z in [-0.178, 0.178]:
			MeshKit.cylinder(self, 0.035, 0.01, chrome, Vector3(x, -0.08, z), Vector3(90, 0, 0), -1.0, 10)
	MeshKit.box(self, Vector3(0.52, 0.03, 0.29), chrome, Vector3(0, -0.06, 0))


func _wood(mesh: MeshInstance3D) -> void:
	var mat := MeshKit.planks(WOOD, Color(0.62, 0.42, 0.24), Color(0.74, 0.52, 0.3))
	mat.set_shader_parameter("object_space", true)
	mat.set_shader_parameter("baseboard_height", 0.0)
	mat.set_shader_parameter("plank_width", 0.115)
	mat.set_shader_parameter("plank_length", 0.52)
	mesh.material_override = mat


func _ball(mesh: MeshInstance3D, pick: int) -> void:
	# Pelota a franjas: una banda blanca y otra de color.
	MeshKit.torus(self, 0.19, 0.205, MeshKit.color(Color(0.97, 0.97, 0.95), 0.35), Vector3.ZERO)
	MeshKit.torus(self, 0.19, 0.205, MeshKit.color(CARS[(pick + 2) % CARS.size()], 0.35), Vector3.ZERO, Vector3(90, 0, 0))
