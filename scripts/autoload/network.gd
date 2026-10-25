extends Node
## Conexión multijugador: crear partida, unirse, salir y lista de jugadores.
##
## Arquitectura: anfitrión autoritativo. El jugador que crea la partida es el servidor
## (peer 1) y decide todo lo importante. El transporte es ENet (IP y puerto); más adelante
## se podrá cambiar por SteamMultiplayerPeer sin tocar el resto del juego.
##
## Lista de jugadores: solo el anfitrión la modifica y la reenvía a todos.

signal players_changed
## Solo en el anfitrión: un jugador nuevo se ha presentado y hay que crear su elfo.
signal player_registered(peer_id: int)
## Solo en el anfitrión: un jugador se ha ido.
signal player_left(peer_id: int)
## En el cliente: la conexión con el anfitrión está lista.
signal connected
## La partida ha terminado. reason vacío = el propio jugador ha salido.
signal session_ended(reason: String)

const DEFAULT_PORT := 24680
const MAX_PLAYERS := 4
const ELF_COLORS: Array[Color] = [
	Color(0.13, 0.55, 0.25), # verde
	Color(0.2, 0.4, 0.85), # azul
	Color(0.85, 0.5, 0.1), # naranja
	Color(0.6, 0.25, 0.75), # morado
]

## peer_id -> {"name": String, "color": int}
var players := {}


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func is_online() -> bool:
	return not (multiplayer.multiplayer_peer is OfflineMultiplayerPeer)


func local_id() -> int:
	return multiplayer.get_unique_id()


## Crea una partida en este PC. Devuelve OK o un código de error (por ejemplo, puerto ocupado).
func host(port := DEFAULT_PORT) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(port, MAX_PLAYERS - 1)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	_reset_players_as_server()
	return OK


## Se conecta a la partida de otro jugador. El resultado llega con connected o session_ended.
func join(address: String, port := DEFAULT_PORT) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(address, port)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	players.clear()
	return OK


## Partida de un solo jugador sin red (para pruebas). Usa el mismo código que el online.
func start_solo() -> void:
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	_reset_players_as_server()


## Sale de la partida actual (como anfitrión la cierra para todos).
func leave() -> void:
	_close_peer()
	session_ended.emit("")


func player_name(peer_id: int) -> String:
	return players.get(peer_id, {}).get("name", "Elfo")


func player_color(peer_id: int) -> Color:
	return ELF_COLORS[players.get(peer_id, {}).get("color", 0) % ELF_COLORS.size()]


func _reset_players_as_server() -> void:
	players = {1: {"name": _clean_name(Settings.player_name), "color": 0}}
	players_changed.emit()
	player_registered.emit(1)


func _close_peer() -> void:
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	players.clear()
	players_changed.emit()


func _clean_name(raw: String) -> String:
	var n := raw.strip_edges().left(16)
	return n if n != "" else "Elfo"


func _free_color() -> int:
	var used := players.values().map(func(p): return p["color"])
	for i in ELF_COLORS.size():
		if i not in used:
			return i
	return 0


# --- Mensajes entre jugadores ---

## El cliente se presenta al anfitrión con su nombre.
@rpc("any_peer", "reliable")
func _register(raw_name: String) -> void:
	if not multiplayer.is_server():
		return
	var id := multiplayer.get_remote_sender_id()
	if players.has(id):
		return
	if players.size() >= MAX_PLAYERS:
		multiplayer.multiplayer_peer.disconnect_peer(id)
		return
	players[id] = {"name": _clean_name(raw_name), "color": _free_color()}
	_sync_players.rpc(players)
	players_changed.emit()
	player_registered.emit(id)


@rpc("authority", "reliable")
func _sync_players(new_players: Dictionary) -> void:
	players = new_players
	players_changed.emit()


# --- Eventos de conexión ---

func _on_peer_connected(_id: int) -> void:
	pass # El jugador se registra él mismo con _register al conectarse.


func _on_peer_disconnected(id: int) -> void:
	if not multiplayer.is_server() or not players.has(id):
		return
	players.erase(id)
	_sync_players.rpc(players)
	players_changed.emit()
	player_left.emit(id)


func _on_connected_to_server() -> void:
	connected.emit()
	_register.rpc_id(1, Settings.player_name)


func _on_connection_failed() -> void:
	_close_peer()
	session_ended.emit("No se ha podido conectar con la partida.")


func _on_server_disconnected() -> void:
	_close_peer()
	session_ended.emit("El anfitrión ha cerrado la partida.")
