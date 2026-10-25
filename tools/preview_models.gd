extends Node3D
## Captura de prueba de modelos sueltos (herramienta de desarrollo).
## Uso: godot res://tools/preview_models.tscn -- <salida.png> <modelo1.glb> <modelo2.glb> ...

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var x := 0.0
	for path in args.slice(1):
		var node: Node3D = load(path).instantiate()
		add_child(node)
		node.position.x = x
		var ap := node.find_child("AnimationPlayer", true, false) as AnimationPlayer
		if ap:
			print(path, " animaciones: ", ap.get_animation_list())
		var aabb := _aabb(node)
		print(path, " tamaño: ", aabb.size, " desde ", aabb.position)
		x += maxf(aabb.size.x, 1.0) + 0.5
	var cam := Camera3D.new()
	add_child(cam)
	cam.position = Vector3(x * 0.5 - 0.5, x * 0.25 + 0.3, x * 0.6 + 0.6)
	cam.look_at(Vector3(x * 0.5 - 0.5, 0.4, 0))
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 30, 0)
	add_child(sun)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.3, 0.35, 0.45)
	env.environment.ambient_light_color = Color(0.7, 0.7, 0.8)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	add_child(env)
	for i in 5:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(args[0])
	get_tree().quit()


func _aabb(node: Node) -> AABB:
	var box := AABB()
	var first := true
	for m in node.find_children("*", "MeshInstance3D", true, false):
		var b: AABB = m.global_transform * m.get_aabb()
		box = b if first else box.merge(b)
		first = false
	return box
