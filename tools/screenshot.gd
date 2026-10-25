extends Node
## Hace capturas de la zona de pruebas para revisar el aspecto sin abrir el editor.
## Añade un segundo elfo de mentira (sin red) para ver cómo se ven los demás jugadores.
## Uso: godot res://tools/screenshot.tscn -- <carpeta_salida>
## (Necesita pantalla; no funciona con --headless.)

const VIEWS := [
	{"name": "inicio", "pos": Vector3(0, 0.1, 3), "yaw": 0.0, "pitch": -10.0},
	{"name": "empezar", "pos": Vector3(4.5, 0.1, 3.5), "yaw": 15.0, "pitch": -12.0},
	{"name": "mesa_regalos", "pos": Vector3(-3, 0.1, -1.5), "yaw": 0.0, "pitch": -25.0},
	{"name": "boton", "pos": Vector3(-6, 0.1, -8.4), "yaw": 0.0, "pitch": -30.0},
	{"name": "otro_elfo", "pos": Vector3(0, 0.1, 6), "yaw": 0.0, "pitch": -5.0},
	{"name": "taller", "pos": Vector3(-4, 0.1, -6.5), "yaw": 0.0, "pitch": -8.0},
	{"name": "tablon", "pos": Vector3(-9.0, 0.1, -5.8), "yaw": 90.0, "pitch": -5.0},
	{"name": "taller_mejorado", "pos": Vector3(-4, 0.1, -6.5), "yaw": 0.0, "pitch": -8.0, "upgrade": true},
	{"name": "nieve", "pos": Vector3(7, 0.1, 7.5), "yaw": 180.0, "pitch": -12.0, "snow": true},
	{"name": "patio", "pos": Vector3(16, 0.1, 0), "yaw": -90.0, "pitch": -2.0, "delivery": true},
	{"name": "chimenea", "pos": Vector3(28, 0.1, -3.5), "yaw": 20.0, "pitch": 22.0, "delivery": true},
	{"name": "resultados", "pos": Vector3(0, 0.1, 3), "yaw": 0.0, "pitch": -10.0, "results": true},
]


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var out_dir: String = args[0] if args.size() > 0 else "user://screenshots"
	DirAccess.make_dir_recursive_absolute(out_dir)
	Network.start_solo()
	var zone: Game = load("res://scenes/game/game.tscn").instantiate()
	add_child(zone)
	await get_tree().process_frame
	var other: Player = zone._spawn_player({"id": 2, "name": "Amigo", "color": 1})
	zone.get_node("Players").add_child(other)
	other.sync_position = Vector3(0.5, 0.1, 3.5)
	var player: Player = zone.get_local_player()
	player.set_physics_process(false)
	await get_tree().create_timer(1.0).timeout
	for view in VIEWS:
		if view.get("upgrade", false):
			zone.state.money = 1000
			for i in [Upgrades.FAST_MACHINE, Upgrades.FAST_MACHINE, Upgrades.CONVEYOR, Upgrades.AUTO_WRAP]:
				zone.state.server_buy(i, "Teo")
			zone.state.server_add_gift()
		if view.get("delivery", false) and not zone.state.delivering:
			zone.state.server_start_night()
			while not zone.state.is_complete():
				zone.state.server_add_gift()
			var house: Node = zone.get_node("TestZone/Yard/House2")
			house.received = house.wanted
			other.sync_position = Vector3(22, 0.1, 2)
		if view.get("results", false):
			var house: Node = zone.get_node("TestZone/Yard/House1")
			house.received = house.wanted
			zone.state.delivered = 4
			zone.state.server_end_delivery()
		if view.get("snow", false):
			other.sync_position = Vector3(5.2, 0.1, 10.5)
			for i in 3:
				zone.spawn_item(preload("res://scenes/items/snowball.tscn"), Vector3(6.5 + i * 0.4, 1.4 + i * 0.3, 9.5 - i))
		player.global_position = view["pos"]
		player.rotation.y = deg_to_rad(view["yaw"])
		player.head.rotation.x = deg_to_rad(view["pitch"])
		for i in 10:
			await get_tree().process_frame
		if view.get("snow", false):
			zone.hud._on_hit("snow") # justo antes de la captura, que la escarcha se desvanece
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		img.save_png(out_dir.path_join(view["name"] + ".png"))
		print("Captura: ", view["name"])
	get_tree().quit()
