extends Station
## Casita del patio. Durante el reparto pide unos regalos: hay que echarlos (o lanzarlos)
## por la chimenea. Cada regalo da monedas extra. Cuando tiene los suyos se encienden las
## ventanas y escupe lo que le sobre. Fuera del reparto la chimenea no acepta nada.

@export var wanted := 2
@export var spit_speed := 3.0

## Regalos recibidos esta noche. Lo cambia el anfitrión.
var received := 0:
	set(value):
		received = value
		_refresh()

@onready var _chimney: Area3D = $Chimney
@onready var _windows: MeshInstance3D = $Windows

var _delivering := false


func _ready() -> void:
	super()
	add_to_group("house")
	# Material propio para encender las ventanas de esta casa sin encender las demás.
	_windows.set_surface_override_material(0, (_windows.mesh as BoxMesh).material.duplicate())
	_refresh()
	# Un regalo lanzado cruza la boca muy deprisa: se cuenta al entrar, sin esperar al escaneo.
	_chimney.body_entered.connect(func(body):
		if multiplayer.is_server() and body is Carryable and body.is_available():
			_handle(body))


func get_interaction_text() -> String:
	if not _delivering:
		return "Aquí se reparte cuando llegue el trineo"
	return "Echa los regalos por la chimenea"


func is_satisfied() -> bool:
	return received >= wanted


func server_scan() -> void:
	for item in items_in(_chimney):
		_handle(item)


func _handle(item: Carryable) -> void:
	if _delivering and item.kind == "gift" and not is_satisfied():
		if item.server_consume():
			received += 1
			game().state.server_deliver()
			game().server_check_delivery()
	else:
		var away := item.global_position - global_position
		away.y = 0
		item.linear_velocity = away.normalized() * spit_speed + Vector3.UP * spit_speed


## Lo llama Game en el anfitrión al empezar una noche nueva.
func server_reset() -> void:
	received = 0


func on_state_changed(state: WorkshopState) -> void:
	_delivering = state.delivering
	_refresh()


func _refresh() -> void:
	if not is_node_ready():
		return
	if is_satisfied():
		status_text = "¡Gracias!"
	elif _delivering:
		status_text = "%d / %d regalos" % [received, wanted]
	else:
		status_text = "Quiere %d regalos" % wanted
	var mat := _windows.get_surface_override_material(0) as StandardMaterial3D
	if mat:
		mat.emission_energy_multiplier = 2.5 if is_satisfied() else 0.0
