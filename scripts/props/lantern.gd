@tool
extends OmniLight3D
## Farol: añade a la luz su forma visible. Colgado del techo con un cordón, o en lo alto de
## una farola que llega hasta el suelo.

## true = cuelga del techo; false = farola de pie.
@export var hanging := true
## Altura (en el mundo) del techo del que cuelga.
@export var ceiling_y := 3.3

const IRON := Color(0.08, 0.08, 0.09)


func _ready() -> void:
	for child in get_children():
		child.queue_free()
	var iron := StandardMaterial3D.new()
	iron.albedo_color = IRON
	iron.metallic = 0.7
	iron.roughness = 0.4
	var glow := StandardMaterial3D.new()
	glow.albedo_color = light_color
	glow.emission_enabled = true
	glow.emission = light_color
	glow.emission_energy_multiplier = 4.0
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	var glass := SphereMesh.new()
	glass.radius = 0.16
	glass.height = 0.38
	glass.radial_segments = 12
	glass.rings = 6
	_part(glass, glow, Vector3.ZERO)
	var cap := CylinderMesh.new()
	cap.top_radius = 0.04
	cap.bottom_radius = 0.2
	cap.height = 0.14
	_part(cap, iron, Vector3(0, 0.22, 0))
	var base := CylinderMesh.new()
	base.top_radius = 0.12
	base.bottom_radius = 0.08
	base.height = 0.06
	_part(base, iron, Vector3(0, -0.2, 0))

	var y := global_position.y if is_inside_tree() else position.y
	var rod := CylinderMesh.new()
	if hanging:
		var length := maxf(ceiling_y - y - 0.29, 0.05)
		rod.top_radius = 0.012
		rod.bottom_radius = 0.012
		rod.height = length
		_part(rod, iron, Vector3(0, 0.29 + length * 0.5, 0))
	else:
		var length := y - 0.23
		rod.top_radius = 0.05
		rod.bottom_radius = 0.08
		rod.height = length
		_part(rod, iron, Vector3(0, -0.23 - length * 0.5, 0))
		var foot := CylinderMesh.new()
		foot.top_radius = 0.12
		foot.bottom_radius = 0.2
		foot.height = 0.25
		_part(foot, iron, Vector3(0, -y + 0.125, 0))


func _part(mesh: PrimitiveMesh, material: Material, pos: Vector3) -> void:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material
	node.position = pos
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node)
