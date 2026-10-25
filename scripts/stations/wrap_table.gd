extends Station
## Mesa de envolver: se deja un juguete encima y se pulsa [E] varias veces para envolverlo.
## Al terminar el juguete desaparece y aparece un regalo en su lugar.

const GIFT_SCENE := preload("res://scenes/items/gift_box.tscn")

@export var presses_needed := 3
## Con la mejora "Envolvedora automática", segundos que tarda en envolver sola.
@export var auto_wrap_time := 2.0

## Visibles para todos (sincronizados): sirven para el aviso de interacción.
var has_toy := false
var wrap_progress := 0
var auto_wrap := false

var _auto_progress := 0.0

@onready var _top: Area3D = $Top


func _ready() -> void:
	super()
	used.connect(_on_used)


func get_interaction_text() -> String:
	if has_toy:
		return "Envolver (%d/%d)" % [wrap_progress, presses_needed]
	return "Deja aquí un juguete"


func server_scan() -> void:
	var toys := items_in(_top, "toy")
	if toys.is_empty() and has_toy:
		wrap_progress = 0 # se han llevado el juguete a medias
	has_toy = not toys.is_empty()
	status_text = "Envolviendo..." if wrap_progress > 0 else ""


func on_state_changed(state: WorkshopState) -> void:
	auto_wrap = state.level(Upgrades.AUTO_WRAP) > 0
	title = "MESA DE ENVOLVER\n(automática)" if auto_wrap else "MESA DE ENVOLVER"
	_update_label()


func server_tick(delta: float) -> void:
	if not auto_wrap or not has_toy:
		_auto_progress = 0.0
		return
	_auto_progress += delta / auto_wrap_time
	if _auto_progress >= 1.0:
		_auto_progress = 0.0
		_wrap_first_toy()


func _on_used(_by: Player) -> void:
	var toys := items_in(_top, "toy")
	if toys.is_empty():
		return
	wrap_progress += 1
	if wrap_progress < presses_needed:
		status_text = "Envolviendo..."
		return
	_wrap_first_toy()


func _wrap_first_toy() -> void:
	var toys := items_in(_top, "toy")
	if toys.is_empty():
		return
	var toy: Carryable = toys[0]
	var pos := toy.global_position + Vector3.UP * 0.25
	if toy.server_consume():
		game().spawn_item(GIFT_SCENE, pos, Vector3.UP * 1.5)
	wrap_progress = 0
	status_text = ""
	server_scan()
