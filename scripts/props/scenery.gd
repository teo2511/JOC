@tool
extends Node3D
## Paisaje de fondo: llanura nevada, bosque de abetos y colinas alrededor del taller y del patio.
## Es solo decorado: no tiene colisión y se genera igual en todos los PC (semilla fija).

## Zona de juego que no hay que tapar con árboles (en el mundo, X y Z).
@export var play_min := Vector2(-18, -18)
@export var play_max := Vector2(48, 18)
@export var tree_count := 420
@export var radius := 120.0
@export var seed := 2511

const SNOW := preload("res://materials/snow.tres")


func _ready() -> void:
	for child in get_children():
		child.queue_free()
	var center := Vector3((play_min.x + play_max.x) * 0.5, 0, (play_min.y + play_max.y) * 0.5)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(radius * 3, radius * 3)
	ground.mesh = plane
	ground.material_override = SNOW
	ground.position = center + Vector3(0, -0.03, 0)
	add_child(ground)

	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var transforms: Array[Transform3D] = []
	while transforms.size() < tree_count:
		var p := Vector3(center.x + rng.randf_range(-radius, radius), 0, center.z + rng.randf_range(-radius, radius))
		if p.distance_to(center) > radius:
			continue
		var margin := 3.0
		if p.x > play_min.x - margin and p.x < play_max.x + margin and p.z > play_min.y - margin and p.z < play_max.y + margin:
			continue
		# Cuanto más cerca de la zona de juego, más pequeños, para que no tapen la vista.
		var s := rng.randf_range(1.0, 1.8) + clampf((p.distance_to(center) - 40.0) / 60.0, 0.0, 1.0) * 1.2
		var basis := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(s, s * rng.randf_range(0.85, 1.2), s))
		transforms.append(Transform3D(basis, p))
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = _pine_mesh()
	multimesh.instance_count = transforms.size()
	for i in transforms.size():
		multimesh.set_instance_transform(i, transforms[i])
	var forest := MultiMeshInstance3D.new()
	forest.multimesh = multimesh
	add_child(forest)

	# Colinas nevadas muy lejos para que el horizonte no sea plano.
	for i in range(14):
		var angle := TAU * i / 14.0 + rng.randf_range(-0.15, 0.15)
		var dist := radius * rng.randf_range(0.95, 1.25)
		var hill := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = rng.randf_range(25, 45)
		sphere.height = sphere.radius * 2
		hill.mesh = sphere
		hill.material_override = SNOW
		hill.scale = Vector3(1.6, rng.randf_range(0.25, 0.45), 1.0)
		hill.rotation.y = angle
		hill.position = center + Vector3(cos(angle) * dist, -2.0, sin(angle) * dist)
		hill.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(hill)


## Abeto de tres pisos con nieve encima de cada piso, en una sola malla con colores por vértice.
func _pine_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.18
	trunk.bottom_radius = 0.25
	trunk.height = 0.8
	_append(st, trunk, Transform3D(Basis(), Vector3(0, 0.4, 0)), Color(0.28, 0.17, 0.09))
	var tiers := [[1.6, 1.9, 0.6], [1.25, 1.7, 1.6], [0.85, 1.5, 2.5]]
	for tier in tiers:
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = tier[0]
		cone.height = tier[1]
		cone.radial_segments = 9
		cone.rings = 1
		var y: float = tier[2] + tier[1] * 0.5
		_append(st, cone, Transform3D(Basis(), Vector3(0, y, 0)), Color(0.07, 0.24, 0.14))
		var cap := CylinderMesh.new()
		cap.top_radius = 0.0
		cap.bottom_radius = tier[0] * 0.55
		cap.height = tier[1] * 0.55
		cap.radial_segments = 9
		cap.rings = 1
		_append(st, cap, Transform3D(Basis(), Vector3(0, y + tier[1] * 0.25, 0)), Color(0.92, 0.95, 1.0))
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.9
	st.set_material(mat)
	return st.commit()


func _append(st: SurfaceTool, mesh: PrimitiveMesh, xform: Transform3D, color: Color) -> void:
	var arrays := mesh.get_mesh_arrays()
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	for idx in indices:
		st.set_color(color)
		st.set_normal((xform.basis * normals[idx]).normalized())
		st.add_vertex(xform * verts[idx])
