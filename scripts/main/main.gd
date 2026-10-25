extends Node
## Escena raíz del juego. Muestra el menú y carga la partida.
##
## La partida (Game) se añade bajo Level. El LevelSpawner la replica en los clientes,
## por eso solo el anfitrión la crea; los clientes la reciben al conectarse.
##
## Argumentos útiles para probar con varias ventanas (Depurar → Personalizar instancias):
##   --host            crea partida al arrancar
##   --join=IP         se une a esa IP al arrancar
##   --name=Nombre     nombre del elfo

const GAME_SCENE := preload("res://scenes/game/game.tscn")

@onready var level: Node = $Level
@onready var menu_layer: CanvasLayer = $MenuLayer
@onready var menu = $MenuLayer/MainMenu


func _ready() -> void:
	menu.host_requested.connect(host_game)
	menu.join_requested.connect(join_game)
	menu.solo_requested.connect(solo_game)
	Network.connected.connect(_on_connected)
	Network.session_ended.connect(_on_session_ended)
	_handle_command_line.call_deferred()


func host_game(port := Network.DEFAULT_PORT) -> bool:
	var err := Network.host(port)
	if err != OK:
		menu.show_message("No se ha podido crear la partida (¿puerto %d ocupado?)." % port)
		return false
	_start_game()
	return true


func join_game(address: String, port := Network.DEFAULT_PORT) -> bool:
	var err := Network.join(address, port)
	if err != OK:
		menu.show_message("Dirección no válida.")
		return false
	return true


func solo_game() -> void:
	Network.start_solo()
	_start_game()


## Solo en el anfitrión: crea la partida (el LevelSpawner la envía a los clientes).
func _start_game() -> void:
	_clear_level()
	level.add_child(GAME_SCENE.instantiate(), true)
	menu_layer.visible = false


func get_game() -> Game:
	return level.get_child(0) as Game if level.get_child_count() > 0 else null


func _on_connected() -> void:
	menu_layer.visible = false


func _on_session_ended(reason: String) -> void:
	_clear_level()
	menu_layer.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	menu.show_message(reason)


func _clear_level() -> void:
	for child in level.get_children():
		level.remove_child(child)
		child.queue_free()


func _handle_command_line() -> void:
	for arg in OS.get_cmdline_user_args() + OS.get_cmdline_args():
		if arg.begins_with("--name="):
			Settings.player_name = arg.trim_prefix("--name=")
	for arg in OS.get_cmdline_user_args() + OS.get_cmdline_args():
		if arg == "--host":
			host_game()
			return
		if arg.begins_with("--join="):
			join_game(arg.trim_prefix("--join="))
			return
