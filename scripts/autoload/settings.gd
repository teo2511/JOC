extends Node
## Opciones del jugador (sensibilidad, eje Y, volumen, controles).
## Se guardan en user://settings.cfg y se cargan al arrancar.

signal changed

const SAVE_PATH := "user://settings.cfg"

## Controles por defecto. Cada acción tiene una tecla o botón de ratón.
## Las teclas usan physical_keycode para que WASD funcione igual en teclados AZERTY/QWERTZ.
const DEFAULT_BINDINGS := {
	"move_forward": {"key": KEY_W},
	"move_back": {"key": KEY_S},
	"move_left": {"key": KEY_A},
	"move_right": {"key": KEY_D},
	"jump": {"key": KEY_SPACE},
	"interact": {"key": KEY_E},
	"throw": {"mouse": MOUSE_BUTTON_LEFT},
	"pause": {"key": KEY_ESCAPE},
}

var mouse_sensitivity := 0.25 # grados por píxel
var invert_y := false
var master_volume := 0.8 # 0..1
var bindings := {}


func _ready() -> void:
	bindings = DEFAULT_BINDINGS.duplicate(true)
	load_settings()
	apply()


func apply() -> void:
	_apply_bindings()
	var bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(master_volume, 0.0001)))
	changed.emit()


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	mouse_sensitivity = cfg.get_value("controles", "sensibilidad", mouse_sensitivity)
	invert_y = cfg.get_value("controles", "invertir_y", invert_y)
	master_volume = cfg.get_value("audio", "volumen_general", master_volume)
	for action in DEFAULT_BINDINGS:
		var saved = cfg.get_value("teclas", action, null)
		if saved is Dictionary:
			bindings[action] = saved


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("controles", "sensibilidad", mouse_sensitivity)
	cfg.set_value("controles", "invertir_y", invert_y)
	cfg.set_value("audio", "volumen_general", master_volume)
	for action in bindings:
		cfg.set_value("teclas", action, bindings[action])
	cfg.save(SAVE_PATH)


func rebind(action: String, event: InputEvent) -> void:
	if event is InputEventKey:
		bindings[action] = {"key": event.physical_keycode}
	elif event is InputEventMouseButton:
		bindings[action] = {"mouse": event.button_index}
	else:
		return
	apply()
	save_settings()


func _apply_bindings() -> void:
	for action in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		InputMap.action_erase_events(action)
		var binding: Dictionary = bindings[action]
		if binding.has("key"):
			var ev := InputEventKey.new()
			ev.physical_keycode = binding["key"]
			InputMap.action_add_event(action, ev)
		elif binding.has("mouse"):
			var ev := InputEventMouseButton.new()
			ev.button_index = binding["mouse"]
			InputMap.action_add_event(action, ev)
