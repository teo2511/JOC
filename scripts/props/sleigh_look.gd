@tool
extends Node3D
## Aspecto del trineo de Santa: caja roja con remates dorados, patines curvados, asiento,
## saco lleno de regalos y un farol delante. Mide lo mismo que su colisión (2,8 x 1,2 x 1,5 m).
## El frente mira hacia +X.

const GIFT_COLORS := [Color(0.85, 0.12, 0.12), Color(0.15, 0.5, 0.25), Color(0.2, 0.35, 0.8), Color(0.9, 0.75, 0.2), Color(0.6, 0.25, 0.7)]


func _ready() -> void:
	MeshKit.clear(self)
	var red := MeshKit.color(Color(0.72, 0.06, 0.08), 0.35, 0.1)
	var gold := MeshKit.color(Color(0.95, 0.72, 0.22), 0.3, 0.85)
	var green := MeshKit.color(Color(0.1, 0.35, 0.18), 0.9)
	var sack := MeshKit.color(Color(0.5, 0.33, 0.18), 1.0)

	# Patines con la punta doblada hacia arriba, y sus soportes.
	for z in [-0.6, 0.6]:
		MeshKit.box(self, Vector3(2.6, 0.08, 0.1), gold, Vector3(-0.1, 0.04, z))
		MeshKit.box(self, Vector3(0.5, 0.08, 0.1), gold, Vector3(1.35, 0.2, z), Vector3(0, 0, 40))
		MeshKit.torus(self, 0.1, 0.17, gold, Vector3(1.58, 0.42, z), Vector3(90, 0, 0))
		for x in [-1.0, 0.0, 0.9]:
			MeshKit.box(self, Vector3(0.08, 0.3, 0.08), gold, Vector3(x, 0.2, z))
	# Caja del trineo.
	MeshKit.box(self, Vector3(2.3, 0.55, 1.4), red, Vector3(-0.15, 0.62, 0))
	MeshKit.box(self, Vector3(0.6, 0.45, 1.4), red, Vector3(1.05, 0.72, 0), Vector3(0, 0, 25))
	for z in [-0.72, 0.72]:
		MeshKit.box(self, Vector3(2.4, 0.06, 0.06), gold, Vector3(-0.1, 0.9, z))
		MeshKit.box(self, Vector3(2.4, 0.06, 0.06), gold, Vector3(-0.1, 0.36, z))
		MeshKit.sphere(self, 0.12, gold, Vector3(0.3, 0.63, z * 1.01), Vector3(1, 1, 0.3))
	# Respaldo alto con volutas.
	MeshKit.box(self, Vector3(0.22, 0.85, 1.4), red, Vector3(-1.2, 1.25, 0))
	MeshKit.box(self, Vector3(0.26, 0.07, 1.46), gold, Vector3(-1.2, 1.68, 0))
	for z in [-0.68, 0.68]:
		MeshKit.torus(self, 0.08, 0.16, gold, Vector3(-1.2, 1.7, z), Vector3(0, 0, 90))
	# Asiento.
	MeshKit.box(self, Vector3(0.7, 0.18, 1.3), green, Vector3(-0.85, 0.98, 0))
	# Saco con regalos asomando.
	MeshKit.sphere(self, 0.55, sack, Vector3(-0.4, 1.3, 0), Vector3(1.0, 0.85, 1.0))
	MeshKit.cylinder(self, 0.18, 0.2, sack, Vector3(-0.4, 1.8, 0), Vector3.ZERO, 0.28)
	var rng := RandomNumberGenerator.new()
	rng.seed = 25
	var spots := [Vector3(0.25, 1.05, 0.35), Vector3(0.35, 1.0, -0.3), Vector3(-0.1, 1.75, 0.25), Vector3(0.6, 1.05, 0.0), Vector3(-0.05, 1.55, -0.4)]
	for i in spots.size():
		var size := Vector3.ONE * rng.randf_range(0.28, 0.4)
		var gift := MeshKit.box(self, size, MeshKit.color(GIFT_COLORS[i % GIFT_COLORS.size()], 0.5), spots[i], Vector3(0, rng.randf_range(-30, 30), rng.randf_range(-15, 15)))
		var ribbon := MeshKit.color(Color(0.98, 0.9, 0.5), 0.4, 0.3)
		MeshKit.box(gift, Vector3(size.x + 0.01, size.y + 0.01, 0.06), ribbon, Vector3.ZERO)
		MeshKit.box(gift, Vector3(0.06, size.y + 0.01, size.z + 0.01), ribbon, Vector3.ZERO)
	# Farol en la punta.
	MeshKit.cylinder(self, 0.025, 0.5, gold, Vector3(1.25, 1.15, 0.62))
	MeshKit.sphere(self, 0.09, MeshKit.glow(Color(1, 0.8, 0.45), 4.0), Vector3(1.25, 1.45, 0.62))
	var light := OmniLight3D.new()
	light.light_color = Color(1, 0.8, 0.5)
	light.light_energy = 0.8
	light.omni_range = 4.0
	light.position = Vector3(1.25, 1.45, 0.62)
	add_child(light)
