extends CanvasLayer
## Interfaz de la partida: punto de mira, aviso de interacción, lista de jugadores y
## menú de pausa con las opciones básicas (sensibilidad, invertir eje Y, volumen).
## La pausa no detiene la partida: los demás siguen jugando.

var player: Player

@onready var crosshair: Label = %Crosshair
@onready var prompt: Label = %Prompt
@onready var player_list: Label = %PlayerList
@onready var sack_counter: Label = %SackCounter
@onready var banner: Label = %Banner
@onready var pause_menu: Control = %PauseMenu
@onready var sensitivity_slider: HSlider = %SensitivitySlider
@onready var sensitivity_value: Label = %SensitivityValue
@onready var invert_y_check: CheckBox = %InvertYCheck
@onready var volume_slider: HSlider = %VolumeSlider


func _ready() -> void:
	pause_menu.visible = false
	prompt.text = ""
	sensitivity_slider.value = Settings.mouse_sensitivity
	invert_y_check.button_pressed = Settings.invert_y
	volume_slider.value = Settings.master_volume
	_update_sensitivity_label()
	sensitivity_slider.value_changed.connect(_on_sensitivity_changed)
	invert_y_check.toggled.connect(_on_invert_y_toggled)
	volume_slider.value_changed.connect(_on_volume_changed)
	%ResumeButton.pressed.connect(close_pause)
	%LeaveButton.pressed.connect(_on_leave_pressed)
	Network.players_changed.connect(_update_player_list)
	_update_player_list()
	banner.visible = false
	var state := get_parent().get_node_or_null("State") as WorkshopState
	if state:
		state.changed.connect(_update_sack.bind(state))
		state.goal_reached.connect(_show_banner.bind("¡Saco lleno! Noche completada"))
		state.upgrade_bought.connect(func(index, buyer):
			_show_banner("¡%s ha comprado %s!" % [buyer, Upgrades.LIST[index]["name"]]))
		_update_sack(state)


func set_player(p: Player) -> void:
	player = p
	player.interaction.prompt_changed.connect(_on_prompt_changed)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if pause_menu.visible:
			close_pause()
		else:
			open_pause()
		get_viewport().set_input_as_handled()
	elif not pause_menu.visible and event is InputEventMouseButton and event.pressed \
			and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and player:
		# Si el ratón se ha liberado (por ejemplo al cambiar de ventana), un clic lo recupera.
		player.set_mouse_captured(true)
		get_viewport().set_input_as_handled()


func open_pause() -> void:
	pause_menu.visible = true
	if player:
		player.set_mouse_captured(false)


func close_pause() -> void:
	pause_menu.visible = false
	Settings.save_settings()
	if player:
		player.set_mouse_captured(true)


func _on_leave_pressed() -> void:
	Settings.save_settings()
	Network.leave()


func _update_sack(state: WorkshopState) -> void:
	sack_counter.text = "Saco: %d / %d     Monedas: %d" % [state.gifts_in_sack, state.goal, state.money]


func _show_banner(text: String) -> void:
	banner.text = text
	banner.visible = true
	banner.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(3.0)
	tween.tween_property(banner, "modulate:a", 0.0, 1.0)
	tween.tween_callback(func(): banner.visible = false)


func _update_player_list() -> void:
	var lines: Array[String] = []
	var ids := Network.players.keys()
	ids.sort()
	for id in ids:
		var tag := " (anfitrión)" if id == 1 else ""
		var you := " ← tú" if id == multiplayer.get_unique_id() else ""
		lines.append("● " + Network.player_name(id) + tag + you)
	player_list.text = "Elfos %d/%d\n%s" % [ids.size(), Network.MAX_PLAYERS, "\n".join(lines)]


func _on_prompt_changed(text: String) -> void:
	prompt.text = text
	crosshair.modulate = Color(1, 0.9, 0.4) if text != "" else Color(1, 1, 1, 0.8)


func _on_sensitivity_changed(value: float) -> void:
	Settings.mouse_sensitivity = value
	_update_sensitivity_label()


func _update_sensitivity_label() -> void:
	sensitivity_value.text = "%.2f" % Settings.mouse_sensitivity


func _on_invert_y_toggled(on: bool) -> void:
	Settings.invert_y = on


func _on_volume_changed(value: float) -> void:
	Settings.master_volume = value
	Settings.apply()
