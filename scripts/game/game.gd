class_name Game
extends Node3D
## Partida en curso: crea y elimina los elfos de los jugadores y prepara los objetos en red.
##
## La escena la crea el anfitrión y el LevelSpawner de Main la replica en los clientes.
## - Elfos: PlayerSpawner con una función propia que recibe {id, name, color}.
## - Objetos: ItemSpawner vigila el nodo Items del nivel. Los objetos colocados a mano en
##   el nivel se sustituyen al empezar por copias creadas por el anfitrión, para que el
##   spawner los conozca y los envíe a quien se una más tarde.

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const SPAWN_ORIGIN := Vector3(0, 0.1, 3)

@onready var players_root: Node3D = $Players
@onready var player_spawner: MultiplayerSpawner = $PlayerSpawner
@onready var items_root: Node3D = $TestZone/Items
@onready var hud = $HUD


func _ready() -> void:
	player_spawner.spawn_function = _spawn_player
	_take_over_placed_items()
	if multiplayer.is_server():
		Network.player_registered.connect(_on_player_registered)
		Network.player_left.connect(_on_player_left)
		for id in Network.players:
			_on_player_registered(id)


func get_local_player() -> Player:
	return Player.find(get_tree(), multiplayer.get_unique_id())


func _take_over_placed_items() -> void:
	for item in items_root.get_children():
		if not item is Carryable:
			continue
		items_root.remove_child(item)
		if multiplayer.is_server():
			var copy: Node3D = load(item.scene_file_path).instantiate()
			copy.name = item.name
			copy.transform = item.transform
			items_root.add_child(copy, true)
		item.free()


# --- Solo en el anfitrión ---

func _on_player_registered(id: int) -> void:
	if Player.find(get_tree(), id) != null:
		return
	var info: Dictionary = Network.players.get(id, {})
	player_spawner.spawn({"id": id, "name": info.get("name", "Elfo"), "color": info.get("color", 0)})


func _on_player_left(id: int) -> void:
	for item in get_tree().get_nodes_in_group("carryable"):
		if item.holder_peer == id:
			item.server_force_release()
	var p := Player.find(get_tree(), id)
	if p:
		p.queue_free()


# --- En todos los PCs ---

func _spawn_player(data: Dictionary) -> Node:
	var id: int = data["id"]
	var color_index: int = data["color"]
	var p: Player = PLAYER_SCENE.instantiate()
	p.name = str(id)
	p.peer_id = id
	p.display_name = data["name"]
	p.elf_color = Network.ELF_COLORS[color_index % Network.ELF_COLORS.size()]
	p.position = SPAWN_ORIGIN + Vector3(color_index * 1.2 - 1.8, 0, 0)
	p.set_multiplayer_authority(id)
	if id == multiplayer.get_unique_id():
		hud.set_player.call_deferred(p)
	return p
