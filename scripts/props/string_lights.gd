extends Node3D
## Guirnalda de bombillas de colores entre este punto y `end_point` (en local), con una
## pequeña caída en el centro. Cada color es un MultiMesh (pocas llamadas de dibujo) y
## parpadea despacio. Solo es decoración: no tiene colisión ni red.

@export var end_point := Vector3(10, 0, 0)
@export var spacing := 0.7
@export var sag := 0.35
@export var colors: Array[Color] = [Color(1, 0.2, 0.15), Color(0.2, 0.9, 0.3), Color(1, 0.8, 0.2), Color(0.3, 0.5, 1)]

var _materials: Array[StandardMaterial3D] = []
var _time := 0.0


func _ready() -> void:
	var count := maxi(int(end_point.length() / spacing), 1)
	var bulb := SphereMesh.new()
	bulb.radius = 0.07
	bulb.height = 0.14
	bulb.radial_segments = 8
	bulb.rings = 4
	for c in colors.size():
		var mat := StandardMaterial3D.new()
		mat.albedo_color = colors[c]
		mat.emission_enabled = true
		mat.emission = colors[c]
		mat.emission_energy_multiplier = 2.0
		_materials.append(mat)
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = bulb
		var indices := range(c, count + 1, colors.size())
		mm.instance_count = indices.size()
		for k in indices.size():
			var f := float(indices[k]) / count
			var pos := end_point * f + Vector3.DOWN * sag * 4.0 * f * (1.0 - f)
			mm.set_instance_transform(k, Transform3D(Basis(), pos))
		var inst := MultiMeshInstance3D.new()
		inst.multimesh = mm
		inst.material_override = mat
		inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(inst)


func _process(delta: float) -> void:
	_time += delta
	for c in _materials.size():
		_materials[c].emission_energy_multiplier = 1.4 + 0.9 * sin(_time * 1.7 + c * 1.6)
