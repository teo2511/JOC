extends Node
## Test de multijugador real con dos procesos de Godot conectados por ENet en este PC.
## Lo lanza tools/run_net_test.sh (o a mano, en dos terminales):
##   godot --headless res://tests/net_test.tscn -- --role=host
##   godot --headless res://tests/net_test.tscn -- --role=client
## Cada proceso comprueba lo que ve él y termina con código 0 si todo pasa.

const PORT := 24699
const STEP_TIMEOUT := 10.0

var _failures := 0
var _passes := 0
var _role := ""
var main: Node


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--role="):
			_role = arg.trim_prefix("--role=")
	main = load("res://scenes/main/main.tscn").instantiate()
	add_child(main)
	_run.call_deferred()


func _run() -> void:
	if _role == "host":
		await _run_host()
	elif _role == "client":
		await _run_client()
	else:
		printerr("Falta --role=host o --role=client")
		_failures += 1
	print("\n[%s] %d pruebas correctas, %d fallos" % [_role, _passes, _failures])
	get_tree().quit(1 if _failures > 0 else 0)


func check(cond: bool, label: String) -> void:
	if cond:
		_passes += 1
		print("  [%s] OK   %s" % [_role, label])
	else:
		_failures += 1
		printerr("  [%s] FALLO %s" % [_role, label])


## Espera hasta que cond() sea cierta o pase el tiempo. Devuelve si se cumplió.
func wait_for(cond: Callable, timeout := STEP_TIMEOUT) -> bool:
	var end := Time.get_ticks_msec() + int(timeout * 1000)
	while Time.get_ticks_msec() < end:
		if cond.call():
			return true
		await get_tree().physics_frame
	return cond.call()


func wait_seconds(s: float) -> void:
	await get_tree().create_timer(s).timeout


func item(path: String) -> Carryable:
	var game: Game = main.get_game()
	return game.get_node_or_null("TestZone/Items/" + path) if game else null


func _run_host() -> void:
	Settings.player_name = "Anfitrion"
	check(main.host_game(PORT), "crea la partida en el puerto %d" % PORT)
	check(await wait_for(func(): return Network.players.size() == 2, 20.0), "el cliente se une (2 jugadores)")
	check(await wait_for(func(): return main.get_game().get_node("Players").get_child_count() == 2), "hay 2 elfos en la partida")
	var client_id: int = Network.players.keys().filter(func(id): return id != 1)[0]
	check(Network.player_name(client_id) == "Cliente", "el anfitrión conoce el nombre del cliente")
	check(Network.players[client_id]["color"] != Network.players[1]["color"], "cada elfo tiene un color distinto")

	var gift := item("Gift4")
	check(await wait_for(func(): return gift.holder_peer == client_id), "el cliente coge el regalo (el anfitrión lo confirma)")
	check(not gift.server_try_pick(1), "el anfitrión no puede coger el regalo que lleva el cliente")
	var picked_at := gift.global_position
	check(await wait_for(func(): return gift.holder_peer == 0), "el cliente lanza el regalo")
	await wait_seconds(0.6)
	check(gift.global_position.distance_to(picked_at) > 1.5, "el regalo lanzado se ha movido en el anfitrión (%.1f m)" % gift.global_position.distance_to(picked_at))

	# El anfitrión coge otro regalo; el cliente debe verlo.
	var gift1 := item("Gift1")
	var host_player: Player = main.get_game().get_local_player()
	host_player.global_position = gift1.global_position + Vector3(0, 0, 1.5)
	await wait_seconds(0.2)
	gift1.request_pick()
	check(gift1.holder_peer == 1, "el anfitrión coge otro regalo")

	# Botón: lo pulsa el cliente; el regalo nuevo debe existir en ambos.
	check(await wait_for(func(): return item("GiftBox") != null), "el cliente pulsa el botón y aparece un regalo nuevo")

	# Taller: el cliente coge madera de la caja; el anfitrión alimenta la fábrica y llena el saco.
	var game: Game = main.get_game()
	check(await wait_for(func(): return get_tree().get_nodes_in_group("carryable").any(
		func(i): return i.kind == "material" and i.holder_peer == client_id)), "el cliente saca madera de la caja")
	var machine = game.get_node("TestZone/Workshop/ToyMachine")
	game.spawn_item(preload("res://scenes/items/wood_block.tscn"), machine.global_position + Vector3(0, 1.8, 0))
	check(await wait_for(func(): return machine.working), "la fábrica empieza a trabajar")
	var sack = game.get_node("TestZone/Workshop/SantaSack")
	gift.global_position = sack.global_position + Vector3(0, 1.3, 0)
	gift.linear_velocity = Vector3.ZERO
	check(await wait_for(func(): return game.state.gifts_in_sack == 1), "el regalo entra en el saco")

	check(await wait_for(func(): return Network.players.size() == 1, 20.0), "el cliente sale de la partida")
	await wait_seconds(0.3)
	check(main.get_game().get_node("Players").get_child_count() == 1, "su elfo desaparece")
	check(main.get_game() != null, "la partida sigue para el anfitrión")


func _run_client() -> void:
	Settings.player_name = "Cliente"
	await wait_seconds(0.5)
	check(main.join_game("127.0.0.1", PORT), "intenta conectarse")
	check(await wait_for(func(): return main.get_game() != null), "recibe la partida del anfitrión")
	var game: Game = main.get_game()
	check(await wait_for(func(): return game.get_local_player() != null), "aparece su propio elfo")
	check(await wait_for(func(): return Player.find(get_tree(), 1) != null), "ve el elfo del anfitrión")
	var me := game.get_local_player()
	var host_player := Player.find(get_tree(), 1)
	check(host_player.display_name == "Anfitrion", "ve el nombre del anfitrión")
	check(not host_player.is_local() and me.is_local(), "solo controla su propio elfo")
	check(await wait_for(func(): return item("Gift4") != null and item("Gift1") != null), "recibe los regalos del nivel")

	# Coger: se coloca delante del regalo y pulsa E.
	var gift := item("Gift4")
	me.global_position = gift.global_position + Vector3(0, -0.2, 1.3)
	me.rotation = Vector3.ZERO
	me.head.rotation.x = deg_to_rad(-25)
	await wait_seconds(0.3) # una persona no se teletransporta: deja llegar la posición al anfitrión
	check(await wait_for(func(): return me.interaction._focused == gift, 3.0), "mira el regalo")
	me.interaction.interact()
	check(await wait_for(func(): return me.interaction.held == gift), "el anfitrión le da el regalo")
	await wait_seconds(0.3)
	check(gift.global_position.distance_to(me.get_hold_transform().origin) < 0.3, "ve el regalo en sus manos")

	# Lanzar.
	var start := gift.global_position
	check(me.interaction.throw_held(), "lanza el regalo")
	check(await wait_for(func(): return me.interaction.held == null), "el regalo sale de sus manos")
	await wait_seconds(0.8)
	check(gift.global_position.distance_to(start) > 1.5, "ve el regalo volar (%.1f m)" % gift.global_position.distance_to(start))

	var gift1 := item("Gift1")
	check(await wait_for(func(): return gift1.holder_peer == 1), "ve que el anfitrión ha cogido otro regalo")

	# Botón.
	var button: Interactable = game.get_node("TestZone/SpawnButton")
	me.global_position = button.global_position + Vector3(0, 0, 1.6)
	me.head.rotation.x = deg_to_rad(-30)
	await wait_seconds(0.3)
	check(await wait_for(func(): return me.interaction._focused == button, 3.0), "mira el botón")
	me.interaction.interact()
	check(await wait_for(func(): return item("GiftBox") != null), "ve aparecer el regalo creado por el botón")

	# Taller.
	var bin = game.get_node("TestZone/Workshop/MaterialBin")
	me.global_position = bin.global_position + Vector3(0, 0, 1.5)
	me.head.rotation.x = deg_to_rad(-25)
	await wait_seconds(0.3)
	check(await wait_for(func(): return me.interaction._focused == bin, 3.0), "mira la caja de madera")
	me.interaction.interact()
	check(await wait_for(func(): return me.interaction.held != null and me.interaction.held.kind == "material"), "recibe madera en las manos")
	var machine = game.get_node("TestZone/Workshop/ToyMachine")
	check(await wait_for(func(): return machine.working and machine.status_text.begins_with("Fabricando")), "ve la fábrica trabajando")
	check(await wait_for(func(): return game.state.gifts_in_sack == 1), "ve el saco con 1 regalo")
	check(game.hud.sack_counter.text == "Saco: 1 / 10", "su pantalla muestra Saco: 1 / 10")

	await wait_seconds(0.5)
	Network.leave()
	await wait_seconds(0.3)
	check(main.get_game() == null, "al salir vuelve al menú")
