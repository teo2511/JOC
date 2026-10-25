extends CanvasLayer
## Interfaz de la zona de pruebas: punto de mira, aviso de interacción y menú de pausa
## con las opciones básicas (sensibilidad, invertir eje Y, volumen).

@export var player: Player

@onready var crosshair: Label = %Crosshair
@onready var prompt: Label = %Prompt
@onready var pause_menu: Control = %PauseMenu
@onready var sensitivity_slider: HSlider = %SensitivitySlider
@onready var sensitivity_value: Label = %SensitivityValue
@onready var invert_y_check: CheckBox = %InvertYCheck
@onready var volume_slider: HSlider = %VolumeSlider


func _ready() -> void:
	pause_menu.visible = false
	prompt.text = ""
	if player:
		player.interaction.prompt_changed.connect(_on_prompt_changed)
	sensitivity_slider.value = Settings.mouse_sensitivity
	invert_y_check.button_pressed = Settings.invert_y
	volume_slider.value = Settings.master_volume
	_update_sensitivity_label()
	sensitivity_slider.value_changed.connect(_on_sensitivity_changed)
	invert_y_check.toggled.connect(_on_invert_y_toggled)
	volume_slider.value_changed.connect(_on_volume_changed)
	%ResumeButton.pressed.connect(close_pause)
	%QuitButton.pressed.connect(func(): get_tree().quit())


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
