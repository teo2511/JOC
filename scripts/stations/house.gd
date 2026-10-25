extends Station
## Casita del patio. Durante el reparto pide unos regalos: hay que echarlos (o lanzarlos)
## por la chimenea. Entre todas las casas piden el objetivo de la noche (state.goal): cada
## una calcula su parte según su house_index, igual en todos los PCs. Cada regalo da monedas extra. Cuando tiene los suyos se encienden las
## ventanas y escupe lo que le sobre. Fuera del reparto la chimenea no acepta nada.

## Posición de la casa en el reparto (0, 1, 2...). Las primeras piden uno más si no es exacto.
@export var house_index := 0
@export var spit_speed := 3.0

## Regalos que pide esta noche (ver on_state_changed).
var wanted := 2
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
			Sfx.broadcast("house_done" if is_satisfied() else "chimney", _chimney.global_position + Vector3(0.8, 0, 0))
			game().state.server_deliver()
			game().server_check_delivery()
	else:
		var away := item.global_position - global_position
		away.y = 0
		item.linear_velocity = away.normalized() * spit_speed + Vector3.UP * spit_speed
		Sfx.broadcast("boing", item.global_position)


## Lo llama Game en el anfitrión al empezar una noche nueva.
func server_reset() -> void:
	received = 0


func on_state_changed(state: WorkshopState) -> void:
	_delivering = state.delivering
	var count := maxi(get_tree().get_nodes_in_group("house").size(), 1)
	wanted = state.goal / count + (1 if house_index < state.goal % count else 0)
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
