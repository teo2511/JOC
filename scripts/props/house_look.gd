@tool
extends Node3D
## Aspecto de una casita del patio: paredes de tablones pintados, tejado nevado con carámbanos,
## chimenea de ladrillo con humo, puerta con corona y ventanas que se iluminan.
## Las medidas coinciden con las colisiones de house.tscn (cuerpo de 3 x 2,2 x 3 m).

## Color de la pintura de cada casa, según su house_index.
const PAINTS := [
	[Color(0.55, 0.16, 0.13), Color(0.66, 0.22, 0.17)],
	[Color(0.16, 0.36, 0.26), Color(0.22, 0.45, 0.32)],
	[Color(0.2, 0.3, 0.5), Color(0.26, 0.38, 0.6)],
	[Color(0.7, 0.55, 0.25), Color(0.8, 0.65, 0.32)],
]
const DOORS := [Color(0.15, 0.35, 0.2), Color(0.6, 0.12, 0.1), Color(0.55, 0.12, 0.1), Color(0.15, 0.3, 0.2)]
const WALL := preload("res://materials/wood_wall.tres")
const ROOF := preload("res://materials/roof.tres")
const SNOW := preload("res://materials/snow.tres")
const BRICK := preload("res://materials/brick.tres")
const WOOD_DARK := preload("res://materials/wood_dark.tres")
const LIGHTS := preload("res://scenes/props/string_lights.tscn")

const W := 1.5 # media anchura
const H := 2.2 # altura de las paredes
const RIDGE := 3.4

## Material de los cristales: house.gd cambia su brillo al servir la casa.
var window_material := MeshKit.glow(Color(1.0, 0.75, 0.35), 0.35)


func _ready() -> void:
	MeshKit.clear(self)
	var index: int = get_parent().get("house_index") if get_parent() else 0
	var paint: Array = PAINTS[index % PAINTS.size()]
	var walls := MeshKit.planks(WALL, paint[0], paint[1])
	walls.set_shader_parameter("baseboard_height", 0.0)
	var white := MeshKit.color(Color(0.92, 0.9, 0.85))
	window_material.albedo_color = Color(0.2, 0.15, 0.1)

	MeshKit.box(self, Vector3(W * 2, H, W * 2), walls, Vector3(0, H / 2, 0))
	MeshKit.box(self, Vector3(W * 2 + 0.2, 0.25, W * 2 + 0.2), MeshKit.color(Color(0.35, 0.35, 0.38)), Vector3(0, 0.12, 0))
	for x in [-W, W]:
		for z in [-W, W]:
			MeshKit.box(self, Vector3(0.16, H, 0.16), white, Vector3(x, H / 2, z))
	_roof(walls)
	_chimney()
	_front(index, white)
	for x in [-W - 0.01, W + 0.01]:
		_window(Vector3(x, 1.35, 0), Vector3(0, 90 if x > 0 else -90, 0), white)
	_window(Vector3(0, 1.35, -W - 0.01), Vector3(0, 180, 0), white)
	var lights: Node3D = LIGHTS.instantiate()
	lights.position = Vector3(-W, H + 0.02, W + 0.12)
	lights.set("end_point", Vector3(W * 2, 0, 0))
	lights.set("spacing", 0.35)
	lights.set("sag", 0.15)
	add_child(lights)


func _roof(walls: Material) -> void:
	var span := W + 0.3
	var rise := RIDGE - H
	var slope := rad_to_deg(atan2(rise, span))
	var length := sqrt(span * span + rise * rise)
	var depth := W * 2 + 0.5
	for side in [-1.0, 1.0]:
		var pivot := Node3D.new()
		pivot.position = Vector3(side * span / 2, H + rise / 2 + 0.05, 0)
		pivot.rotation_degrees.z = -side * slope
		add_child(pivot)
		MeshKit.box(pivot, Vector3(length, 0.14, depth), ROOF, Vector3.ZERO)
		MeshKit.box(pivot, Vector3(length + 0.04, 0.12, depth + 0.04), SNOW, Vector3(0, 0.12, 0))
		# Carámbanos colgando del alero.
		var rng := RandomNumberGenerator.new()
		rng.seed = 7 + int(side)
		var z := -depth / 2 + 0.15
		while z < depth / 2 - 0.1:
			var h := rng.randf_range(0.12, 0.32)
			MeshKit.cylinder(self, 0.035, h, SNOW, Vector3(side * (span - 0.05), H - 0.1 - h / 2 + 0.1, z), Vector3(180, 0, 0), 0.0, 5)
			z += rng.randf_range(0.18, 0.32)
	# Triángulos de pared bajo el tejado (delante y detrás).
	var gable := PrismMesh.new()
	gable.size = Vector3(W * 2, rise, W * 2)
	MeshKit.part(self, gable, walls, Vector3(0, H + rise / 2, 0))


func _chimney() -> void:
	MeshKit.box(self, Vector3(0.8, 1.8, 0.8), BRICK, Vector3(0.8, 3.3, 0))
	MeshKit.box(self, Vector3(0.95, 0.15, 0.95), MeshKit.color(Color(0.3, 0.3, 0.32)), Vector3(0.8, 4.2, 0))
	MeshKit.box(self, Vector3(0.97, 0.06, 0.97), SNOW, Vector3(0.8, 4.3, 0))
	var smoke := CPUParticles3D.new()
	smoke.position = Vector3(0.8, 4.4, 0)
	smoke.amount = 14
	smoke.lifetime = 3.5
	smoke.preprocess = 3.5
	smoke.direction = Vector3(0.15, 1, 0)
	smoke.spread = 12.0
	smoke.gravity = Vector3(0.2, 0.25, 0)
	smoke.initial_velocity_min = 0.4
	smoke.initial_velocity_max = 0.7
	smoke.scale_amount_min = 0.6
	smoke.scale_amount_max = 1.2
	var curve := Curve.new()
	curve.add_point(Vector2(0, 0.3))
	curve.add_point(Vector2(1, 1.6))
	smoke.scale_amount_curve = curve
	var puff := SphereMesh.new()
	puff.radius = 0.22
	puff.height = 0.44
	puff.radial_segments = 8
	puff.rings = 4
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.7, 0.72, 0.78, 0.35)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	puff.material = mat
	smoke.mesh = puff
	smoke.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(smoke)


func _front(index: int, white: Material) -> void:
	var z := W + 0.01
	var door := MeshKit.color(DOORS[index % DOORS.size()], 0.6)
	MeshKit.box(self, Vector3(0.95, 1.55, 0.06), white, Vector3(0, 0.78, z))
	MeshKit.box(self, Vector3(0.75, 1.4, 0.1), door, Vector3(0, 0.72, z + 0.02))
	MeshKit.sphere(self, 0.04, MeshKit.color(Color(0.95, 0.8, 0.3), 0.3, 0.8), Vector3(0.25, 0.7, z + 0.1))
	# Corona de Navidad con lazo.
	MeshKit.torus(self, 0.12, 0.22, MeshKit.color(Color(0.08, 0.35, 0.15)), Vector3(0, 1.1, z + 0.1), Vector3(90, 0, 0))
	var bow := MeshKit.color(Color(0.85, 0.1, 0.12), 0.5)
	MeshKit.box(self, Vector3(0.16, 0.08, 0.05), bow, Vector3(0, 0.92, z + 0.13))
	# Escalón con nieve y un farolillo junto a la puerta.
	MeshKit.box(self, Vector3(1.2, 0.18, 0.5), MeshKit.color(Color(0.35, 0.35, 0.38)), Vector3(0, 0.09, z + 0.25))
	MeshKit.box(self, Vector3(1.22, 0.04, 0.52), SNOW, Vector3(0, 0.2, z + 0.25))
	_window(Vector3(-0.95, 1.35, z), Vector3.ZERO, white)
	_window(Vector3(0.95, 1.35, z), Vector3.ZERO, white)


## Ventana de 0,7 x 0,6 m mirando hacia +Z local.
func _window(pos: Vector3, rot: Vector3, white: Material) -> void:
	var root := Node3D.new()
	root.position = pos
	root.rotation_degrees = rot
	add_child(root)
	var quad := QuadMesh.new()
	quad.size = Vector2(0.6, 0.5)
	MeshKit.part(root, quad, window_material, Vector3(0, 0, 0.02))
	MeshKit.box(root, Vector3(0.72, 0.06, 0.06), white, Vector3(0, 0.28, 0.03))
	MeshKit.box(root, Vector3(0.72, 0.06, 0.06), white, Vector3(0, -0.28, 0.03))
	MeshKit.box(root, Vector3(0.06, 0.56, 0.06), white, Vector3(-0.33, 0, 0.03))
	MeshKit.box(root, Vector3(0.06, 0.56, 0.06), white, Vector3(0.33, 0, 0.03))
	MeshKit.box(root, Vector3(0.04, 0.5, 0.04), white, Vector3(0, 0, 0.03))
	MeshKit.box(root, Vector3(0.6, 0.04, 0.04), white, Vector3(0, 0, 0.03))
	MeshKit.box(root, Vector3(0.8, 0.05, 0.14), SNOW, Vector3(0, -0.3, 0.06))
	# Contraventanas.
	for x in [-0.45, 0.45]:
		MeshKit.box(root, Vector3(0.18, 0.6, 0.04), WOOD_DARK, Vector3(x, 0, 0.03))
