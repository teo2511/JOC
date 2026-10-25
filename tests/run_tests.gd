extends Node
## Tests automáticos sin pantalla. Ejecutar desde la carpeta del proyecto:
##   godot --headless res://tests/run_tests.tscn
## Termina con código 0 si todo pasa y 1 si algo falla.
## (Es una escena y no un script -s para que los autoloads como Settings estén cargados.)

var _failures := 0
var _passes := 0


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	await _test_settings_bindings()
	await _test_pickup_drop_throw()
	await _test_single_holder()
	await _test_spawn_button()
	await _test_respawn_on_fall()
	print("\n%d pruebas correctas, %d fallos" % [_passes, _failures])
	get_tree().quit(1 if _failures > 0 else 0)


func check(cond: bool, label: String) -> void:
	if cond:
		_passes += 1
		print("  OK   ", label)
	else:
		_failures += 1
		printerr("  FALLO ", label)


## Carga una partida de un jugador (sin red) y devuelve la escena Game.
func _load_zone() -> Node:
	Network.start_solo()
	var zone: Node = load("res://scenes/game/game.tscn").instantiate()
	get_tree().root.add_child(zone)
	await _frames(3)
	return zone


func _player(zone: Node) -> Player:
	return zone.get_local_player()


func _unload(zone: Node) -> void:
	zone.queue_free()
	await _frames(2)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


## Coloca un objeto justo delante de la cámara del jugador.
func _place_in_front(player: Player, item: Node3D, distance := 1.2) -> void:
	item.global_position = player.camera.global_position - player.camera.global_basis.z * distance
	item.linear_velocity = Vector3.ZERO


func _test_settings_bindings() -> void:
	print("Ajustes y controles")
	var settings = get_tree().root.get_node("Settings")
	for action in ["move_forward", "move_back", "move_left", "move_right", "jump", "interact", "throw", "pause"]:
		check(InputMap.has_action(action) and InputMap.action_get_events(action).size() == 1, "acción '%s' configurada" % action)
	var old_inv: bool = settings.invert_y
	var zone := await _load_zone()
	var player: Player = _player(zone)
	settings.invert_y = false
	var before := player.head.rotation.x
	player.look(Vector2(0, 10))
	check(player.head.rotation.x < before, "ratón hacia abajo mira hacia abajo")
	settings.invert_y = true
	before = player.head.rotation.x
	player.look(Vector2(0, 10))
	check(player.head.rotation.x > before, "eje Y invertido funciona")
	player.look(Vector2(0, -100000))
	check(absf(player.head.rotation.x) <= deg_to_rad(85.01), "la cámara no da la vuelta")
	settings.invert_y = old_inv
	await _unload(zone)


func _test_pickup_drop_throw() -> void:
	print("Coger, soltar y lanzar")
	var zone := await _load_zone()
	var player: Player = _player(zone)
	var gift: Carryable = zone.get_node("TestZone/Items/Gift4")
	_place_in_front(player, gift)
	await _frames(2)
	check(player.interaction._focused == gift, "el rayo detecta el regalo que miras")
	check(player.interaction.interact(), "E coge el regalo")
	await _frames(1)
	check(gift.is_held() and player.interaction.held == gift, "el regalo está en las manos")
	await _frames(20)
	var hold := player.hold_point.global_position
	check(gift.global_position.distance_to(hold) < 0.1, "el regalo sigue al punto de agarre")
	player.interaction.interact()
	await _frames(1)
	check(not gift.is_held() and player.interaction.held == null, "E de nuevo lo suelta")
	await _frames(60)
	check(gift.global_position.y < 0.5, "el regalo soltado cae al suelo")

	_place_in_front(player, gift)
	await _frames(2)
	player.interaction.interact()
	await _frames(1)
	var start := gift.global_position
	var forward := -player.camera.global_basis.z
	check(player.interaction.throw_held(), "clic lanza el regalo")
	await _frames(20)
	var travelled := (gift.global_position - start).dot(forward)
	check(travelled > 2.0, "el regalo lanzado avanza (%.1f m)" % travelled)
	await _unload(zone)


func _test_single_holder() -> void:
	print("Un objeto, un portador")
	var zone := await _load_zone()
	var player: Player = _player(zone)
	var gift: Carryable = zone.get_node("TestZone/Items/Gift4")
	check(gift.server_try_pick(1), "el jugador 1 lo coge")
	check(not gift.server_try_pick(2), "el jugador 2 no puede cogerlo a la vez")
	check(gift.holder_peer == 1, "sigue en manos del jugador 1")
	check(not gift.server_release(2, Vector3.ZERO), "el jugador 2 no puede soltarlo")
	check(gift.server_release(1, Vector3(0, 0, 500)), "el jugador 1 lo lanza")
	check(gift.linear_velocity.length() <= Carryable.MAX_RELEASE_SPEED + 0.01, "la velocidad de lanzamiento está limitada")
	check(gift.server_try_pick(99), "un jugador remoto lo coge")
	zone._on_player_left(99)
	check(gift.holder_peer == 0, "si ese jugador se va, el objeto queda libre")
	var ball: Carryable = zone.get_node("TestZone/Items/Ball1")
	player.global_position = ball.global_position + Vector3(0, 0, 20)
	await _frames(1)
	ball.request_pick()
	check(ball.holder_peer == 0, "no se puede coger un objeto lejano")
	await _unload(zone)


func _test_spawn_button() -> void:
	print("Botón (objeto usable)")
	var zone := await _load_zone()
	var player: Player = _player(zone)
	var button: Interactable = zone.get_node("TestZone/SpawnButton")
	var count_before := get_tree().get_nodes_in_group("carryable").size()
	player.global_position = button.global_position + Vector3(0, 0, 1.6)
	player.rotation = Vector3.ZERO
	player.head.rotation.x = deg_to_rad(-30)
	await _frames(3)
	check(player.interaction._focused == button, "el rayo detecta el botón")
	check(player.interaction.interact(), "E pulsa el botón")
	await _frames(2)
	check(get_tree().get_nodes_in_group("carryable").size() == count_before + 1, "aparece un regalo nuevo")
	check(not button.server_use(player), "el botón tiene tiempo de espera")
	await _unload(zone)


func _test_respawn_on_fall() -> void:
	print("Nada se pierde")
	var zone := await _load_zone()
	var player: Player = _player(zone)
	var ball: Carryable = zone.get_node("TestZone/Items/Ball1")
	var ball_spawn := ball.global_position
	ball.global_position = Vector3(0, -20, 0)
	player.global_position = Vector3(0, -20, 0)
	await _frames(3)
	check(ball.global_position.distance_to(ball_spawn) < 0.5, "un objeto que cae del mapa reaparece")
	check(player.global_position.y > -1.0, "un elfo que cae del mapa reaparece")
	await _unload(zone)
