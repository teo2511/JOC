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
@onready var frost: ColorRect = %Frost
@onready var results_panel: PanelContainer = %ResultsPanel
@onready var results_label: Label = %Results
@onready var sleigh_hint: Control = %SleighHint
@onready var sleigh_arrow: Label = %SleighArrow

var _last_phase := -1
var _last_seconds := -1
var _asked_results := false
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
		state.announced.connect(_show_banner)
		state.upgrade_bought.connect(func(index, buyer):
			_show_banner("¡%s ha comprado %s!" % [buyer, Upgrades.LIST[index]["name"]]))
		state.results_ready.connect(show_results)
		_update_sack(state)


func set_player(p: Player) -> void:
	player = p
	player.interaction.prompt_changed.connect(_on_prompt_changed)
	player.hit_received.connect(_on_hit)


## Bola de nieve: escarcha en la pantalla un momento. Empujón: un destello suave.
func _on_hit(kind: String) -> void:
	frost.color = Color(0.92, 0.97, 1.0, 0.75) if kind == "snow" else Color(1, 0.85, 0.7, 0.25)
	var tween := create_tween()
	tween.tween_property(frost, "color:a", 0.0, 1.2 if kind == "snow" else 0.3)


func _process(_delta: float) -> void:
	_update_sleigh_hint()


## Durante el reparto, si estás lejos del trineo, una flecha te indica hacia dónde está.
func _update_sleigh_hint() -> void:
	var game := get_parent() as Game
	var sleigh := game.get_node_or_null("TestZone/Yard/Sleigh") as Node3D if game else null
	var show := player != null and sleigh != null and is_instance_valid(player) and game.state.delivering \
			and player.global_position.distance_to(sleigh.global_position) > 8.0
	sleigh_hint.visible = show
	if not show:
		return
	var to := sleigh.global_position - player.global_position
	var local := player.global_basis.inverse() * to
	# 0 = delante; el texto "↑" apunta hacia arriba en la pantalla, que es "hacia delante".
	sleigh_arrow.rotation = atan2(local.x, -local.z)
	sleigh_arrow.pivot_offset = sleigh_arrow.size / 2


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
	var night := "Noche %d/%d" % [state.night, WorkshopState.NIGHTS] if not state.endless else "Noche %d" % state.night
	var clock := "%d:%02d" % [state.seconds_left / 60, state.seconds_left % 60]
	var money := "Monedas: %d" % state.money
	match state.phase:
		WorkshopState.Phase.LOBBY:
			sack_counter.text = "Pulsad EMPEZAR en el taller     Saco: %d / %d     %s" % [
				state.gifts_in_sack, state.goal, money]
		WorkshopState.Phase.PRODUCTION:
			sack_counter.text = "%s     %s     Saco: %d / %d     %s" % [
				night, clock, state.gifts_in_sack, state.goal, money]
		WorkshopState.Phase.DELIVERY:
			var wanted := 0
			for house in get_tree().get_nodes_in_group("house"):
				wanted += house.wanted
			sack_counter.text = "%s     %s     Reparto: %d / %d     Trineo: %d     %s" % [
				night, clock, state.delivered, wanted, state.sleigh_gifts, money]
		WorkshopState.Phase.RESULTS:
			sack_counter.text = "%s terminada     Siguiente en %s     %s" % [night, clock, money]
		WorkshopState.Phase.FINISHED:
			sack_counter.text = "¡Nochebuena superada!     %s" % money
	# Los resultados se cierran al empezar otra noche. Solo al cambiar de fase: el aviso de
	# resultados (RPC) puede llegar antes que la fase nueva, y no hay que cerrarlo entonces.
	if state.phase != _last_phase and state.phase in [WorkshopState.Phase.LOBBY, WorkshopState.Phase.PRODUCTION]:
		results_panel.visible = false
	_last_phase = state.phase
	if state.phase in [WorkshopState.Phase.RESULTS, WorkshopState.Phase.FINISHED] \
			and not results_panel.visible and not _asked_results and not multiplayer.is_server():
		_asked_results = true # he entrado a mitad de los resultados: se los pido al anfitrión
		state.request_results.rpc_id(1)
	elif state.phase == WorkshopState.Phase.PRODUCTION:
		_asked_results = false
	# Tic-tac en los últimos 10 segundos de producción o reparto.
	if state.seconds_left != _last_seconds:
		_last_seconds = state.seconds_left
		if state.phase in [WorkshopState.Phase.PRODUCTION, WorkshopState.Phase.DELIVERY] \
				and state.seconds_left > 0 and state.seconds_left <= 10:
			Sfx.play("tick")


## Resumen de la noche que manda el anfitrión al terminar el reparto.
func show_results(r: Dictionary) -> void:
	var verdict := "Algunos niños se han quedado sin regalo..."
	if r["happy"] == r["houses"]:
		verdict = "¡Noche perfecta!"
	elif r["happy"] * 2 >= r["houses"]:
		verdict = "¡Bien hecho!"
	var lines := PackedStringArray([
		"NOCHE %d TERMINADA" % r["night"],
		verdict,
		"",
		"Regalos al saco: %d" % r["sacked"],
		"Regalos entregados: %d / %d" % [r["delivered"], r["goal"]],
		"Casas contentas: %d / %d" % [r["happy"], r["houses"]],
		"Monedas ganadas: %d" % r["coins"],
	])
	if r["final"]:
		lines[0] = "¡FELIZ NOCHEBUENA!"
		lines.append("")
		lines.append("Regalos repartidos en la partida: %d" % r["run_delivered"])
		lines.append("Récord: %d" % r["record"])
		lines.append("Pulsad SEGUIR JUGANDO o PARTIDA NUEVA en el taller")
	results_label.text = "\n".join(lines)
	results_panel.visible = true


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
