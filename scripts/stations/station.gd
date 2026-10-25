class_name Station
extends Interactable
## Base de las estaciones del taller (caja de madera, fábrica, mesa de envolver, saco).
##
## Toda la lógica corre en el anfitrión: cada SCAN_INTERVAL mira qué objetos libres hay en
## sus zonas (server_scan) y cada frame avanza su trabajo (server_tick). Lo que deben ver
## los demás (status_text y lo que añada cada estación) va en su MultiplayerSynchronizer.

## Nombre grande que aparece encima de la estación.
@export var title := ""

const SCAN_INTERVAL := 0.15

## Segunda línea del cartel ("Fabricando 40%"). Lo cambia el anfitrión.
var status_text := "":
	set(value):
		status_text = value
		_update_label()

var _scan_left := 0.0
var _label: Label3D


func _ready() -> void:
	super()
	_label = get_node_or_null("Label") as Label3D
	_update_label()
	_connect_state.call_deferred() # la partida (Game) termina de prepararse después


func _connect_state() -> void:
	var g := game()
	if g == null:
		return
	g.state.changed.connect(func(): on_state_changed(g.state))
	on_state_changed(g.state)


## Para las estaciones: se llama al cambiar el estado del taller (dinero, mejoras, saco).
func on_state_changed(_state: WorkshopState) -> void:
	pass


func _physics_process(delta: float) -> void:
	if not multiplayer.is_server():
		return
	_scan_left -= delta
	if _scan_left <= 0.0:
		_scan_left = SCAN_INTERVAL
		server_scan()
	server_tick(delta)


## Para las estaciones: revisa las zonas de entrada (solo anfitrión).
func server_scan() -> void:
	pass


## Para las estaciones: avanza el trabajo en curso (solo anfitrión).
func server_tick(_delta: float) -> void:
	pass


## Objetos libres (nadie los lleva, no gastados) dentro de una zona, opcionalmente de un tipo.
func items_in(area: Area3D, wanted_kind := "") -> Array[Carryable]:
	var result: Array[Carryable] = []
	for body in area.get_overlapping_bodies():
		if body is Carryable and body.is_available() and (wanted_kind == "" or body.kind == wanted_kind):
			result.append(body)
	return result


func game() -> Game:
	return get_tree().get_first_node_in_group("game") as Game


func _update_label() -> void:
	if _label == null:
		return
	_label.text = title if status_text == "" else title + "\n" + status_text
