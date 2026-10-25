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


func _load_zone() -> Node:
	var zone: Node = load("res://scenes/test/test_zone.tscn").instantiate()
	get_tree().root.add_child(zone)
	await _frames(3)
	return zone


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
	var player: Player = zone.get_node("Player")
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
	var player: Player = zone.get_node("Player")
	var gift: Carryable = zone.get_node("Items/Gift4")
	_place_in_front(player, gift)
	await _frames(2)
	check(player.interaction._focused == gift, "el rayo detecta el regalo que miras")
	check(player.interaction.interact(), "E coge el regalo")
	check(gift.is_held() and player.interaction.held == gift, "el regalo está en las manos")
	await _frames(20)
	var hold := player.interaction.hold_point.global_position
	check(gift.global_position.distance_to(hold) < 0.1, "el regalo sigue al punto de agarre")
	player.interaction.interact()
	check(not gift.is_held() and player.interaction.held == null, "E de nuevo lo suelta")
	await _frames(60)
	check(gift.global_position.y < 0.5, "el regalo soltado cae al suelo")

	_place_in_front(player, gift)
	await _frames(2)
	player.interaction.interact()
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
	var player: Player = zone.get_node("Player")
	var gift: Carryable = zone.get_node("Items/Gift4")
	var other := Node3D.new()
	zone.add_child(other)
	check(gift.try_pick(player, player.interaction.hold_point), "el primero lo coge")
	check(not gift.try_pick(other, other), "el segundo no puede cogerlo a la vez")
	check(gift.holder == player, "sigue en manos del primero")
	await _unload(zone)


func _test_spawn_button() -> void:
	print("Botón (objeto usable)")
	var zone := await _load_zone()
	var player: Player = zone.get_node("Player")
	var button: Interactable = zone.get_node("SpawnButton")
	var count_before := get_tree().get_nodes_in_group("carryable").size()
	player.global_position = button.global_position + Vector3(0, 0, 1.6)
	player.rotation = Vector3.ZERO
	player.head.rotation.x = deg_to_rad(-30)
	await _frames(3)
	check(player.interaction._focused == button, "el rayo detecta el botón")
	check(player.interaction.interact(), "E pulsa el botón")
	await _frames(2)
	check(get_tree().get_nodes_in_group("carryable").size() == count_before + 1, "aparece un regalo nuevo")
	check(not player.interaction.interact(), "el botón tiene tiempo de espera")
	await _unload(zone)


func _test_respawn_on_fall() -> void:
	print("Nada se pierde")
	var zone := await _load_zone()
	var player: Player = zone.get_node("Player")
	var ball: Carryable = zone.get_node("Items/Ball1")
	var ball_spawn := ball.global_position
	ball.global_position = Vector3(0, -20, 0)
	player.global_position = Vector3(0, -20, 0)
	await _frames(3)
	check(ball.global_position.distance_to(ball_spawn) < 0.5, "un objeto que cae del mapa reaparece")
	check(player.global_position.y > -1.0, "un elfo que cae del mapa reaparece")
	await _unload(zone)
