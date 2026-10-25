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
	await _test_money_and_upgrades()
	await _test_automation()
	await _test_pushes()
	await _test_snowballs_and_lever()
	await _test_delivery()
	await _test_night_cycle()
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


func _test_money_and_upgrades() -> void:
	print("Dinero y mejoras")
	var zone := await _load_zone()
	var player: Player = _player(zone)
	var state: WorkshopState = zone.state
	var machine = zone.get_node("TestZone/Workshop/ToyMachine")
	check(state.money == 0, "se empieza sin dinero")
	state.server_add_gift()
	check(state.money == WorkshopState.GIFT_VALUE, "cada regalo da %d monedas" % WorkshopState.GIFT_VALUE)
	check(not state.server_buy(Upgrades.FAST_MACHINE), "sin dinero suficiente no se compra")
	check(state.level(Upgrades.FAST_MACHINE) == 0, "la mejora sigue a nivel 0")

	state.money = 1000
	var first := state.next_price(Upgrades.FAST_MACHINE)
	var bought := [""]
	state.upgrade_bought.connect(func(i, who): bought[0] = "%d:%s" % [i, who])
	check(state.server_buy(Upgrades.FAST_MACHINE, "Teo"), "con dinero se compra")
	await _frames(1)
	check(state.money == 1000 - first, "se descuenta el precio")
	check(state.next_price(Upgrades.FAST_MACHINE) > first, "el siguiente nivel es más caro")
	check(bought[0] == "%d:Teo" % Upgrades.FAST_MACHINE, "se anuncia quién ha comprado qué")
	check(absf(machine.craft_time - machine.base_craft_time * 0.75) < 0.001, "la fábrica es un 25%% más rápida (%.2f s)" % machine.craft_time)
	state.server_buy(Upgrades.FAST_MACHINE)
	state.server_buy(Upgrades.FAST_MACHINE)
	check(state.level(Upgrades.FAST_MACHINE) == 3, "se puede subir hasta el nivel 3")
	var money_before := state.money
	check(not state.server_buy(Upgrades.FAST_MACHINE), "no se puede pasar del máximo")
	check(state.money == money_before, "al máximo no se cobra nada")

	state.server_buy(Upgrades.BIG_MACHINE)
	check(machine.capacity == machine.base_capacity + 2, "la fábrica grande admite 2 bloques más")
	state.server_buy(Upgrades.FAST_BOOTS)
	check(absf(player.speed_multiplier - 1.15) < 0.001, "las botas hacen al elfo un 15% más rápido")

	var button = zone.get_node("TestZone/UpgradeBoard/Upgrade%d" % Upgrades.CONVEYOR)
	player.global_position = button.global_position + Vector3(1.5, 0, 0)
	await _frames(2)
	button.request_use()
	await _frames(1)
	check(state.level(Upgrades.CONVEYOR) == 1, "el botón del tablón compra la mejora")
	await _unload(zone)


func _test_automation() -> void:
	print("Automatización")
	var zone := await _load_zone()
	var state: WorkshopState = zone.state
	var conveyor = zone.get_node("TestZone/Workshop/Conveyor")
	var table = zone.get_node("TestZone/Workshop/WrapTable")
	var machine = zone.get_node("TestZone/Workshop/ToyMachine")
	check(not conveyor.visible and not conveyor.active, "la cinta está oculta hasta comprarla")
	state.money = 1000
	state.server_buy(Upgrades.CONVEYOR)
	await _frames(1)
	check(conveyor.visible and conveyor.active, "al comprarla aparece la cinta")

	# Un bloque en la fábrica: el juguete debe acabar solo en la mesa.
	zone.spawn_item(preload("res://scenes/items/wood_block.tscn"), machine.global_position + Vector3(0, 1.8, 0))
	await _seconds(machine.craft_time + 4.5)
	check(table.has_toy, "la cinta lleva el juguete de la fábrica a la mesa")

	state.server_buy(Upgrades.AUTO_WRAP)
	await _frames(1)
	check(table.auto_wrap, "la mesa pasa a ser automática")
	var gifts_before := _items_of_kind("gift").size()
	await _seconds(table.auto_wrap_time + 0.5)
	check(_items_of_kind("gift").size() == gifts_before + 1, "la mesa envuelve sola, sin pulsar nada")
	await _unload(zone)


## Añade un elfo "remoto" de mentira (sin red) en una posición, para probar bromas.
func _fake_player(zone: Node, id: int, pos: Vector3) -> Player:
	var p: Player = zone._spawn_player({"id": id, "name": "Amigo%d" % id, "color": id % 4})
	zone.get_node("Players").add_child(p)
	p.global_position = pos
	p.sync_position = pos
	return p


func _test_pushes() -> void:
	print("Empujones")
	var zone := await _load_zone()
	var me: Player = _player(zone)
	var pranks: Pranks = zone.pranks
	me.global_position = Vector3(0, 0.1, 0)
	var friend := _fake_player(zone, 2, Vector3(0, 0.1, 1.5))
	var gift: Carryable = zone.get_node("TestZone/Items/Gift4")
	gift.global_position = me.get_hold_transform().origin
	gift.server_try_pick(1)
	await _frames(3)
	var hits := [0]
	me.hit_received.connect(func(_k): hits[0] += 1)
	check(pranks.server_push_player(2, 1), "un amigo te empuja")
	check(gift.holder_peer == 0, "al recibir el empujón se te cae lo que llevas")
	check(hits[0] == 1, "tu pantalla recibe el aviso del golpe")
	await _frames(1)
	check(Vector2(me.velocity.x, me.velocity.z).length() > 3.0, "sales despedido (%.1f m/s)" % Vector2(me.velocity.x, me.velocity.z).length())
	check(me.velocity.z < 0, "en dirección contraria a quien empuja")
	check(not pranks.can_push(2), "quien empuja tiene que esperar")
	var other := _fake_player(zone, 3, me.global_position + Vector3(1, 0, 0))
	check(not pranks.server_push_player(3, 1), "durante unos segundos eres inmune a otro empujón")
	await _seconds(Pranks.IMMUNITY_TIME + 0.1)
	other.global_position = me.global_position + Vector3(1, 0, 0)
	other.sync_position = other.global_position
	check(pranks.server_push_player(3, 1), "pasada la inmunidad te pueden volver a empujar")
	friend.sync_position = Vector3(10, 0.1, 10)
	await _seconds(Pranks.PUSH_COOLDOWN + 0.1)
	check(not pranks.server_push_player(2, 1), "no se puede empujar desde lejos")
	check(not pranks.server_push_player(1, 1), "no te puedes empujar a ti mismo")

	var ball: Carryable = zone.get_node("TestZone/Items/Ball1")
	ball.global_position = me.global_position + Vector3(0, 0.3, -1.2)
	ball.linear_velocity = Vector3.ZERO
	await _frames(2)
	check(pranks.server_push_item(1, ball), "puedes empujar un objeto suelto")
	check(ball.linear_velocity.length() > 3.0, "el objeto sale volando")
	await _unload(zone)


func _test_snowballs_and_lever() -> void:
	print("Bolas de nieve y palanca")
	var zone := await _load_zone()
	var me: Player = _player(zone)
	var pile = zone.get_node("TestZone/SnowPile")
	me.global_position = pile.global_position + Vector3(0, 0, -1.5)
	await _frames(2)
	check(pile.server_use(me), "el montón de nieve responde a E")
	await _frames(2)
	check(me.interaction.held != null and me.interaction.held.kind == "snowball", "tienes una bola de nieve en las manos")
	me.interaction.drop_held()
	await _frames(1)

	# Un amigo lanza una bola contra ti.
	me.global_position = Vector3(0, 0.1, 0)
	var friend := _fake_player(zone, 2, Vector3(0, 0.1, 4))
	await _frames(2)
	var ball: Carryable = zone.spawn_item(preload("res://scenes/items/snowball.tscn"), Vector3(0, 1.0, 3.2))
	await _frames(1)
	ball.server_try_pick(2)
	await _frames(2)
	var hits := [""]
	me.hit_received.connect(func(k): hits[0] = k)
	ball.server_release(2, Vector3(0, 1.0, -12))
	await _seconds(0.6)
	check(hits[0] == "snow", "la bola de nieve te da (escarcha en la pantalla)")
	check(not is_instance_valid(ball), "la bola se deshace al golpear")

	var dropped: Carryable = zone.spawn_item(preload("res://scenes/items/snowball.tscn"), Vector3(3, 0.5, 0))
	await _frames(2)
	dropped.server_try_pick(1)
	dropped.server_release(1, Vector3.ZERO)
	await _seconds(0.6)
	check(is_instance_valid(dropped), "una bola soltada (no lanzada) no se rompe")

	var conveyor = zone.get_node("TestZone/Workshop/Conveyor")
	var lever = zone.get_node("TestZone/Workshop/ConveyorLever")
	check(not lever.visible, "la palanca no aparece sin cinta")
	zone.state.money = 500
	zone.state.server_buy(Upgrades.CONVEYOR)
	await _frames(1)
	check(lever.visible, "con la cinta aparece la palanca")
	check(lever.server_use(me), "se puede tirar de la palanca")
	check(conveyor.reversed, "la cinta va al revés")
	check(not lever.server_use(me), "la palanca tarda en recargarse")
	await _seconds(lever.reverse_seconds + 0.3)
	check(not conveyor.reversed, "la cinta vuelve a ir bien sola")
	await _unload(zone)


## Deja caer un regalo nuevo en la chimenea de una casa.
func _drop_in_chimney(zone: Node, house: Node3D) -> Carryable:
	var mouth: Node3D = house.get_node("Chimney/CollisionShape3D")
	var gift: Carryable = zone.spawn_item(preload("res://scenes/items/gift_box.tscn"), mouth.global_position)
	await _seconds(0.4)
	return gift


func _test_delivery() -> void:
	print("Reparto")
	var zone := await _load_zone()
	var me: Player = _player(zone)
	var state: WorkshopState = zone.state
	var sleigh = zone.get_node("TestZone/Yard/Sleigh")
	var sack = zone.get_node("TestZone/Workshop/SantaSack")
	var houses: Array = [1, 2, 3, 4].map(func(n): return zone.get_node("TestZone/Yard/House%d" % n))
	check(not sleigh.visible, "el trineo no está hasta que se llena el saco")
	var early := await _drop_in_chimney(zone, houses[0])
	check(is_instance_valid(early) and not early.consumed and houses[0].received == 0, "antes del reparto la chimenea no acepta regalos")
	early.queue_free()

	var banners: Array[String] = []
	state.announced.connect(func(t): banners.append(t))
	check(state.server_start_night(), "empieza la noche")
	await _frames(1)
	var wanted := 0
	for h in houses:
		wanted += h.wanted
	check(wanted == state.goal, "las casas piden tantos regalos como pide la noche (%d)" % wanted)
	for i in state.goal:
		state.server_add_gift()
	await _frames(2)
	check(state.delivering and sleigh.visible, "con el saco lleno llega el trineo")
	check(state.sleigh_gifts == state.goal and state.gifts_in_sack == 0, "los regalos del saco pasan al trineo")
	check(banners.any(func(t): return t.contains("trineo")), "aviso: el trineo ha llegado")

	me.global_position = sleigh.global_position + Vector3(0, 0, 2)
	await _frames(2)
	check(sleigh.server_use(me), "el trineo responde a E")
	await _frames(2)
	var gift: Carryable = me.interaction.held
	check(gift != null and gift.kind == "gift", "el trineo te da un regalo en las manos")
	check(state.sleigh_gifts == state.goal - 1, "queda uno menos en el trineo")
	await _seconds(0.4) # recarga del trineo
	sleigh.server_use(me)
	await _frames(2)
	check(state.sleigh_gifts == state.goal - 1, "con las manos ocupadas no te da otro")

	# Llevar el regalo del trineo al saco no vale: lo escupe.
	gift.server_release(1, Vector3.ZERO)
	await _frames(1)
	gift.global_position = sack.global_position + Vector3(0, 1.3, 0)
	gift.linear_velocity = Vector3.ZERO
	await _seconds(0.5)
	check(not gift.consumed and state.gifts_in_sack == 0, "el saco no acepta regalos que ya salieron del trineo")

	# Lanzarlo a la chimenea desde el suelo, con el lanzamiento normal del jugador. Se prueba
	# con varias inclinaciones de cabeza, como haría alguien que no ha jugado nunca.
	var house: Node3D = houses[0]
	var mouth: Node3D = house.get_node("Chimney/CollisionShape3D")
	var money_before := state.money
	var hit_pitch := -1
	for pitch in range(20, 75, 5):
		me.global_position = Vector3(mouth.global_position.x, 0.1, mouth.global_position.z + 4.0)
		me.velocity = Vector3.ZERO
		me.rotation = Vector3.ZERO # mirando hacia -Z, hacia la casa
		me.head.rotation.x = deg_to_rad(pitch)
		gift.global_position = me.global_position + Vector3(0, 0.6, -0.6)
		gift.linear_velocity = Vector3.ZERO
		await _frames(2)
		gift.server_try_pick(1)
		await _frames(3)
		me.interaction.throw_held()
		if await _wait_until(func(): return house.received == 1, 1.6):
			hit_pitch = pitch
			break
	check(hit_pitch > 0, "un regalo lanzado desde el suelo entra por la chimenea (mirando %d° hacia arriba)" % hit_pitch)
	check(state.money == money_before + WorkshopState.DELIVERY_VALUE, "cada regalo entregado da %d monedas" % WorkshopState.DELIVERY_VALUE)
	check(state.delivered == 1, "cuenta un regalo entregado")

	var small: Node3D = houses[1]
	for i in small.wanted:
		await _drop_in_chimney(zone, small)
	check(small.is_satisfied() and small.status_text == "¡Gracias!", "la casa da las gracias al tener sus regalos")
	var extra := await _drop_in_chimney(zone, small)
	check(is_instance_valid(extra) and not extra.consumed, "una casa servida escupe los regalos que sobran")
	extra.queue_free()

	var results: Array[Dictionary] = []
	state.results_ready.connect(func(r): results.append(r))
	for h in houses:
		for i in h.wanted - h.received:
			await _drop_in_chimney(zone, h)
	await _frames(2)
	check(not state.delivering and not sleigh.visible, "con todas las casas servidas el trineo se va")
	check(state.phase == WorkshopState.Phase.RESULTS and results.size() == 1, "salen los resultados de la noche")
	check(results.size() == 1 and results[0]["happy"] == 4 and results[0]["delivered"] == state.goal, "resultados: 4 casas contentas y todo entregado")
	check(zone.hud.results_panel.visible and zone.hud.results_label.text.contains("perfecta"), "la pantalla muestra «¡Noche perfecta!»")
	check(houses.all(func(h): return h.received == 0), "las casas vuelven a pedir regalos")
	# Del trineo solo salió un regalo: los otros vuelven al saco.
	check(state.sleigh_gifts == 0 and state.gifts_in_sack == state.goal - 1, "lo que sobraba en el trineo vuelve al saco")
	await _unload(zone)


func _test_night_cycle() -> void:
	print("Ciclo de noches")
	var zone := await _load_zone()
	var me: Player = _player(zone)
	var state: WorkshopState = zone.state
	state.record_path = "user://test_records.cfg"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(state.record_path))
	var start = zone.get_node("TestZone/StartButton")
	var restart = zone.get_node("TestZone/RestartButton")
	check(WorkshopState.goal_for(1, 1) == 6 and WorkshopState.goal_for(5, 1) == 14, "un elfo: de 6 regalos la primera noche a 14 en Nochebuena")
	check(WorkshopState.goal_for(1, 4) == 12, "con 4 elfos la primera noche pide 12")
	check(WorkshopState.goal_for(6, 1) > WorkshopState.goal_for(5, 1), "en modo infinito sigue subiendo")
	check(state.phase == WorkshopState.Phase.LOBBY and start.visible and not restart.visible, "se empieza esperando, con el botón EMPEZAR")
	await _seconds(0.3)
	check(state.seconds_left == 0, "en la espera no corre el reloj")
	me.global_position = start.global_position + Vector3(0, 0, 1.5)
	await _frames(2)
	check(start.server_use(me), "el botón EMPEZAR responde a E")
	check(state.phase == WorkshopState.Phase.PRODUCTION and state.goal == 6, "empieza la noche 1 (6 regalos)")
	check(not start.visible, "el botón desaparece durante la noche")
	check(state.seconds_left == int(WorkshopState.PRODUCTION_TIME), "reloj de producción: %d s" % state.seconds_left)
	await _seconds(1.2)
	check(state.seconds_left < int(WorkshopState.PRODUCTION_TIME), "el reloj baja")

	# Se acaba el tiempo con el saco a medias: el trineo se lleva lo que hay.
	state.server_add_gift()
	state.server_add_gift()
	state.server_skip_phase()
	await _frames(2)
	check(state.phase == WorkshopState.Phase.DELIVERY and state.sleigh_gifts == 2, "sin tiempo, el trineo se lleva lo que hay (2)")
	check(state.seconds_left == int(WorkshopState.DELIVERY_TIME), "reloj de reparto: %d s" % state.seconds_left)
	var results: Array[Dictionary] = []
	state.results_ready.connect(func(r): results.append(r))
	state.server_skip_phase()
	await _frames(2)
	check(state.phase == WorkshopState.Phase.RESULTS and results.size() == 1, "sin tiempo de reparto, salen los resultados")
	check(results[0]["happy"] == 0 and results[0]["sacked"] == 2, "resultados: 2 al saco, ninguna casa contenta")
	check(zone.hud.results_label.text.contains("sin regalo"), "la pantalla lo dice")
	check(state.gifts_in_sack == 2, "los regalos no repartidos vuelven al saco")
	state.server_skip_phase()
	await _frames(2)
	check(state.night == 2 and state.phase == WorkshopState.Phase.PRODUCTION and state.goal == 8, "tras los resultados empieza la noche 2 (8 regalos)")
	check(not zone.hud.results_panel.visible, "los resultados se cierran")

	# Llenar el saco antes de tiempo da monedas extra.
	var money_before := state.money
	for i in state.goal - state.gifts_in_sack:
		state.server_add_gift()
	await _frames(2)
	var bonus := state.money - money_before - (8 - 2) * WorkshopState.GIFT_VALUE
	check(state.phase == WorkshopState.Phase.DELIVERY and bonus > 0, "acabar antes da monedas extra (%d)" % bonus)

	# Pasar por las noches que faltan hasta Nochebuena.
	while state.phase != WorkshopState.Phase.FINISHED:
		state.server_skip_phase()
		await _frames(2)
	check(state.night == WorkshopState.NIGHTS, "la partida acaba tras la noche %d" % WorkshopState.NIGHTS)
	check(results[-1]["final"] and results[-1]["record"] == results[-1]["run_delivered"], "el final enseña el récord")
	check(FileAccess.file_exists(state.record_path), "el récord se guarda en el PC del anfitrión")
	check(start.visible and restart.visible, "aparecen SEGUIR JUGANDO y PARTIDA NUEVA")
	check(zone.hud.results_label.text.contains("NOCHEBUENA"), "pantalla final de Nochebuena")

	await _seconds(1.1) # espera del botón
	check(start.server_use(me) and state.phase == WorkshopState.Phase.PRODUCTION and state.night == 6, "SEGUIR JUGANDO empieza la noche 6")
	check(state.endless and state.goal == WorkshopState.goal_for(6, 1), "modo infinito, con más regalos")
	while state.phase != WorkshopState.Phase.RESULTS:
		state.server_skip_phase()
		await _frames(2)
	state.server_skip_phase()
	await _frames(2)
	check(state.night == 7 and state.phase == WorkshopState.Phase.PRODUCTION, "en modo infinito no se acaba")

	# Partida nueva.
	state.phase = WorkshopState.Phase.FINISHED
	state.money = 300
	state.server_buy(Upgrades.FAST_BOOTS)
	await _frames(1)
	me.global_position = restart.global_position + Vector3(0, 0, 1.5)
	await _frames(2)
	check(restart.server_use(me), "el botón PARTIDA NUEVA responde a E")
	check(state.phase == WorkshopState.Phase.LOBBY and state.night == 1 and state.money == 0 and state.level(Upgrades.FAST_BOOTS) == 0, "partida nueva: noche 1, sin dinero ni mejoras")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(state.record_path))
	await _unload(zone)


func _wait_until(cond: Callable, timeout: float) -> bool:
	var end := Time.get_ticks_msec() + int(timeout * 1000)
	while Time.get_ticks_msec() < end:
		if cond.call():
			return true
		await get_tree().physics_frame
	return cond.call()

