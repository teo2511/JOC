extends Node
## Hace capturas de la zona de pruebas para revisar el aspecto sin abrir el editor.
## Uso: godot res://tools/screenshot.tscn -- <carpeta_salida>
## (Necesita pantalla; no funciona con --headless.)

const VIEWS := [
	{"name": "inicio", "pos": Vector3(0, 0.1, 3), "yaw": 0.0, "pitch": -10.0},
	{"name": "mesa_regalos", "pos": Vector3(-3, 0.1, -1.5), "yaw": 0.0, "pitch": -25.0},
	{"name": "boton", "pos": Vector3(-6, 0.1, -8.4), "yaw": 0.0, "pitch": -30.0},
]


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var out_dir: String = args[0] if args.size() > 0 else "user://screenshots"
	DirAccess.make_dir_recursive_absolute(out_dir)
	var zone: Node = load("res://scenes/test/test_zone.tscn").instantiate()
	add_child(zone)
	var player: Player = zone.get_node("Player")
	player.set_physics_process(false)
	await get_tree().create_timer(1.0).timeout
	for view in VIEWS:
		player.global_position = view["pos"]
		player.rotation.y = deg_to_rad(view["yaw"])
		player.head.rotation.x = deg_to_rad(view["pitch"])
		for i in 10:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		img.save_png(out_dir.path_join(view["name"] + ".png"))
		print("Captura: ", view["name"])
	get_tree().quit()
