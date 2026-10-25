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
	await _test_production_chain()
	await _test_sack_rules()
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


func _seconds(t: float) -> void:
	await get_tree().create_timer(t).timeout


func _items_of_kind(kind: String) -> Array:
	return get_tree().get_nodes_in_group("carryable").filter(
		func(i): return i.kind == kind and i.is_available())


func _test_production_chain() -> void:
	print("Cadena de producción")
	var zone := await _load_zone()
	var player: Player = _player(zone)
	var bin = zone.get_node("TestZone/Workshop/MaterialBin")
	var machine = zone.get_node("TestZone/Workshop/ToyMachine")
	var table = zone.get_node("TestZone/Workshop/WrapTable")
	var sack = zone.get_node("TestZone/Workshop/SantaSack")
	var state: WorkshopState = zone.state

	player.global_position = bin.global_position + Vector3(0, 0, 1.5)
	await _frames(2)
	check(bin.server_use(player), "la caja de madera responde a E")
	await _frames(2)
	check(player.interaction.held != null and player.interaction.held.kind == "material", "la madera aparece en las manos")
	var wood: Carryable = player.interaction.held
	wood.server_release(1, Vector3.ZERO)
	await _frames(1)
	wood.global_position = machine.global_position + Vector3(0, 1.8, 0)
	await _seconds(0.5)
	check(machine.queued == 1 and not is_instance_valid(wood), "la fábrica se traga la madera")
	check(machine.working, "la fábrica está trabajando")
	var toys_before := _items_of_kind("toy").size()
	await _seconds(machine.craft_time + 0.3)
	var toys := _items_of_kind("toy")
	check(toys.size() == toys_before + 1, "sale un juguete de la fábrica")
	check(machine.queued == 0 and machine.status_text == "Esperando madera", "la fábrica vuelve a esperar")

	var toy: Carryable = toys.filter(func(t): return t.name.begins_with("ToyCar"))[0]
	toy.global_position = table.global_position + Vector3(0, 1.2, 0)
	toy.linear_velocity = Vector3.ZERO
	await _seconds(0.6)
	check(table.has_toy, "la mesa detecta el juguete")
	var gifts_before := _items_of_kind("gift").size()
	for i in table.presses_needed:
		table.server_use(player)
		await _seconds(table.cooldown + 0.05)
	check(not is_instance_valid(toy), "el juguete se ha envuelto")
	var gifts := _items_of_kind("gift")
	check(gifts.size() == gifts_before + 1, "aparece un regalo en la mesa")

	var gift: Carryable = gifts.filter(func(g): return g.global_position.distance_to(table.global_position) < 2.0)[0]
	gift.global_position = sack.global_position + Vector3(0, 1.3, 0)
	gift.linear_velocity = Vector3.ZERO
	await _seconds(0.4)
	check(state.gifts_in_sack == 1, "el saco cuenta el regalo")
	check(not is_instance_valid(gift), "el regalo desaparece dentro del saco")
	await _unload(zone)


func _test_sack_rules() -> void:
	print("Reglas del saco")
	var zone := await _load_zone()
	var sack = zone.get_node("TestZone/Workshop/SantaSack")
	var state: WorkshopState = zone.state
	var gift: Carryable = zone.get_node("TestZone/Items/Gift4")
	check(gift.server_try_pick(1), "alguien coge un regalo")
	check(not gift.server_consume(), "un regalo en las manos no se puede gastar")
	gift.server_release(1, Vector3.ZERO)
	check(gift.server_consume(), "un regalo libre se gasta")
	check(not gift.server_consume(), "el mismo regalo no se gasta dos veces")

	var ball: Carryable = zone.get_node("TestZone/Items/Ball1")
	ball.global_position = sack.global_position + Vector3(0, 1.3, 0)
	ball.linear_velocity = Vector3.ZERO
	await _seconds(0.5)
	check(is_instance_valid(ball) and state.gifts_in_sack == 0, "el saco no cuenta lo que no es un regalo")
	check(ball.global_position.distance_to(sack.global_position) > 1.0, "el saco lo escupe fuera")

	var reached := [false]
	state.goal_reached.connect(func(): reached[0] = true)
	state.goal = 2
	state.server_add_gift()
	check(not reached[0], "1/2 aún no completa el objetivo")
	state.server_add_gift()
	check(reached[0] and state.is_complete(), "2/2 completa el objetivo")
	await _unload(zone)
