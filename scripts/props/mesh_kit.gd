class_name MeshKit
## Funciones para montar decorado con piezas sencillas (cajas, cilindros...) desde código.
## Lo usan las casas, el trineo y las máquinas para tener más detalle sin modelos externos.


## Añade una pieza a parent. rot en grados.
static func part(parent: Node3D, mesh: Mesh, material: Material, pos: Vector3, rot := Vector3.ZERO, scl := Vector3.ONE) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material
	node.position = pos
	node.rotation_degrees = rot
	node.scale = scl
	parent.add_child(node)
	return node


static func box(parent: Node3D, size: Vector3, material: Material, pos: Vector3, rot := Vector3.ZERO) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return part(parent, mesh, material, pos, rot)


static func cylinder(parent: Node3D, radius: float, height: float, material: Material, pos: Vector3, rot := Vector3.ZERO, top_radius := -1.0, segments := 16) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = radius
	mesh.top_radius = radius if top_radius < 0.0 else top_radius
	mesh.height = height
	mesh.radial_segments = segments
	mesh.rings = 1
	return part(parent, mesh, material, pos, rot)


static func sphere(parent: Node3D, radius: float, material: Material, pos: Vector3, scl := Vector3.ONE) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 12
	mesh.rings = 6
	return part(parent, mesh, material, pos, Vector3.ZERO, scl)


static func torus(parent: Node3D, inner: float, outer: float, material: Material, pos: Vector3, rot := Vector3.ZERO) -> MeshInstance3D:
	var mesh := TorusMesh.new()
	mesh.inner_radius = inner
	mesh.outer_radius = outer
	mesh.rings = 20
	mesh.ring_segments = 8
	return part(parent, mesh, material, pos, rot)


static func color(c: Color, roughness := 0.8, metallic := 0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = c
	mat.roughness = roughness
	mat.metallic = metallic
	return mat


static func glow(c: Color, energy := 2.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = c
	mat.emission_enabled = true
	mat.emission = c
	mat.emission_energy_multiplier = energy
	return mat


## Copia de un material de tablones con otros colores (para pintar cada casa distinta).
static func planks(base: ShaderMaterial, a: Color, b: Color) -> ShaderMaterial:
	var mat: ShaderMaterial = base.duplicate()
	mat.set_shader_parameter("color_a", a)
	mat.set_shader_parameter("color_b", b)
	return mat


## Quita los hijos generados antes (los scripts @tool se vuelven a montar en el editor).
static func clear(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()
