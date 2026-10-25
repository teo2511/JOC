class_name ElfModel
extends Node3D
## Aspecto del elfo: personaje animado de Kenney (CC0) vestido de elfo.
## Al modelo original (un gladiador) se le quita el penacho del casco, se cambian los colores
## de su paleta y se le pone un gorro de elfo con borla y orejas puntiagudas.

const MODEL := preload("res://assets/models/kenney/mini_arena/character-soldier.glb")
const PALETTE := preload("res://assets/models/kenney/mini_arena/Textures/colormap.png")
## El modelo mide 0,67 m sin penacho; así el elfo llega a unos 1,2 m.
const MODEL_SCALE := 1.8
## Zona de la paleta del penacho y la cresta del casco: esos triángulos de la cabeza se quitan.
const CREST_UV := Rect2(352.0 / 512.0, 256.0 / 512.0, 32.0 / 512.0, 128.0 / 512.0)
## Y también lo que quede por encima de esta altura (el soporte del penacho).
const PLUME_CUT_Y := 0.66
## Altura del hueso de la cabeza y de lo alto del casco, para colocar gorro y orejas.
const HEAD_TOP := 0.64

const SKIN := Color(0.93, 0.72, 0.57)
const STOCKINGS := Color(0.78, 0.13, 0.13)
const BELT := Color(0.95, 0.75, 0.2)
const HAIR := Color(0.42, 0.25, 0.13)
const FUR := Color(0.97, 0.97, 0.97)

const RUN_SPEED := 4.5
const WALK_SPEED := 0.4

var _anim: AnimationPlayer
var _skeleton: Skeleton3D
var _meshes: Array[MeshInstance3D] = []
var _hat_material := StandardMaterial3D.new()
var _current := ""
var _one_shot_left := 0.0

static var _cut_head_mesh: ArrayMesh


func _ready() -> void:
	var model: Node3D = MODEL.instantiate()
	model.scale = Vector3.ONE * MODEL_SCALE
	model.rotation.y = PI # el modelo mira a +Z y el elfo a -Z
	add_child(model)
	_skeleton = model.find_child("Skeleton3D", true, false)
	_anim = model.find_child("AnimationPlayer", true, false)
	for mesh in model.find_children("*", "MeshInstance3D", true, false):
		_meshes.append(mesh)
		if mesh.name == "head-mesh":
			mesh.mesh = _head_without_plume(mesh.mesh)
	for loop_name in ["idle", "walk", "sprint", "holding-both"]:
		_anim.get_animation(loop_name).loop_mode = Animation.LOOP_LINEAR
	_build_hat()
	set_color(Color(0.13, 0.55, 0.25))
	_play("idle")


## Color de la túnica (cada jugador tiene el suyo). El gorro va a juego.
func set_color(tunic: Color) -> void:
	var image := PALETTE.get_image()
	image.decompress()
	_recolor(image, Rect2i(288, 384, 32, 128), tunic) # túnica y mangas
	_recolor(image, Rect2i(416, 384, 32, 128), STOCKINGS) # piernas
	_recolor(image, Rect2i(352, 256, 32, 128), BELT) # cinturón
	var body := StandardMaterial3D.new()
	body.albedo_texture = ImageTexture.create_from_image(image)
	body.roughness = 0.8
	# En la cabeza ese mismo color era el casco: ahí pasa a ser el pelo.
	_recolor(image, Rect2i(288, 384, 32, 128), HAIR)
	_recolor(image, Rect2i(352, 256, 32, 128), HAIR) # cejas
	var head := StandardMaterial3D.new()
	head.albedo_texture = ImageTexture.create_from_image(image)
	head.roughness = 0.8
	for mesh in _meshes:
		mesh.material_override = head if mesh.name == "head-mesh" else body
	_hat_material.albedo_color = tunic.darkened(0.1)


## Capa de dibujo de todas las piezas (el elfo propio va en una capa que su cámara no ve).
func set_layers(layers: int) -> void:
	for node in find_children("*", "VisualInstance3D", true, false):
		node.layers = layers


func set_cast_shadows(on: bool) -> void:
	for node in find_children("*", "GeometryInstance3D", true, false):
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if on else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## Elige la animación según cómo se mueve. Se llama cada fotograma.
func update_motion(horizontal_speed: float, on_floor: bool, holding: bool, delta: float) -> void:
	if _one_shot_left > 0.0:
		_one_shot_left -= delta
		return
	if not on_floor:
		_play("jump")
	elif horizontal_speed > RUN_SPEED:
		_play("sprint")
	elif horizontal_speed > WALK_SPEED:
		_play("walk")
		_anim.speed_scale = clampf(horizontal_speed / 2.5, 0.6, 1.6)
		return
	elif holding:
		_play("holding-both")
	else:
		_play("idle")
	_anim.speed_scale = 1.0


## Animación suelta (empujar, usar...) que tapa a las de movimiento un momento.
func play_once(anim_name: String) -> void:
	if not _anim.has_animation(anim_name):
		return
	_current = anim_name
	_anim.speed_scale = 1.0
	_anim.play(anim_name, 0.05)
	_one_shot_left = _anim.get_animation(anim_name).length


func current_animation() -> String:
	return _current


func _play(anim_name: String) -> void:
	if _current == anim_name:
		return
	_current = anim_name
	_anim.play(anim_name, 0.15)


func _build_hat() -> void:
	var attach := BoneAttachment3D.new()
	attach.bone_name = "head"
	_skeleton.add_child(attach)
	var head_y := _skeleton.get_bone_global_rest(_skeleton.find_bone("head")).origin.y
	var root := Node3D.new()
	root.position = Vector3(0, HEAD_TOP - head_y - 0.02, -0.02)
	attach.add_child(root)

	_hat_material.roughness = 0.85
	var fur := StandardMaterial3D.new()
	fur.albedo_color = FUR
	fur.roughness = 1.0
	var skin := StandardMaterial3D.new()
	skin.albedo_color = SKIN
	skin.roughness = 0.8

	var brim := TorusMesh.new()
	brim.inner_radius = 0.16
	brim.outer_radius = 0.24
	brim.rings = 16
	brim.ring_segments = 8
	_part(root, brim, fur, Vector3(0, 0.0, 0), Vector3.ZERO, Vector3(1.05, 1.2, 0.95))
	var cone := CylinderMesh.new()
	cone.top_radius = 0.07
	cone.bottom_radius = 0.2
	cone.height = 0.3
	_part(root, cone, _hat_material, Vector3(0, 0.15, 0), Vector3.ZERO)
	# La punta se dobla hacia atrás.
	var tip := CylinderMesh.new()
	tip.top_radius = 0.0
	tip.bottom_radius = 0.075
	tip.height = 0.28
	_part(root, tip, _hat_material, Vector3(0, 0.35, -0.08), Vector3(deg_to_rad(-50), 0, 0))
	var ball := SphereMesh.new()
	ball.radius = 0.045
	ball.height = 0.09
	_part(root, ball, fur, Vector3(0, 0.41, -0.21), Vector3.ZERO)
	# Orejas puntiagudas a los lados de la cabeza.
	for side in [-1.0, 1.0]:
		var ear := CylinderMesh.new()
		ear.top_radius = 0.0
		ear.bottom_radius = 0.06
		ear.height = 0.2
		ear.radial_segments = 6
		_part(root, ear, skin, Vector3(side * 0.24, -0.13, 0.02), Vector3(0, 0, -side * deg_to_rad(65)), Vector3(1, 1, 0.5))


func _part(parent: Node3D, mesh: PrimitiveMesh, material: Material, pos: Vector3, rot: Vector3, scl := Vector3.ONE) -> void:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material
	node.position = pos
	node.rotation = rot
	node.scale = scl
	parent.add_child(node)


func _recolor(image: Image, rect: Rect2i, target: Color) -> void:
	# Mantiene el degradado de la paleta (claro arriba, oscuro abajo) con el nuevo color.
	var mid := image.get_pixel(rect.position.x + rect.size.x / 2, rect.position.y + rect.size.y / 2).get_luminance()
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var c := image.get_pixel(x, y)
			var k := clampf(c.get_luminance() / maxf(mid, 0.01), 0.5, 1.4)
			image.set_pixel(x, y, Color(target.r * k, target.g * k, target.b * k, c.a))


## Copia de la malla de la cabeza sin los triángulos del penacho (se calcula una vez).
static func _head_without_plume(source: Mesh) -> ArrayMesh:
	if _cut_head_mesh:
		return _cut_head_mesh
	var arrays := source.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var kept := PackedInt32Array()
	for i in range(0, indices.size(), 3):
		var a := verts[indices[i]]
		var b := verts[indices[i + 1]]
		var c := verts[indices[i + 2]]
		var uv := (uvs[indices[i]] + uvs[indices[i + 1]] + uvs[indices[i + 2]]) / 3.0
		if (a.y + b.y + c.y) / 3.0 <= PLUME_CUT_Y and not CREST_UV.has_point(uv):
			kept.append_array([indices[i], indices[i + 1], indices[i + 2]])
	arrays[Mesh.ARRAY_INDEX] = kept
	_cut_head_mesh = ArrayMesh.new()
	_cut_head_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	_cut_head_mesh.surface_set_material(0, source.surface_get_material(0))
	return _cut_head_mesh
