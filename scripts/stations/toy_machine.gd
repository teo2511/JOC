extends Station
## Fábrica de juguetes: se echa madera por la tolva de arriba y, tras craft_time segundos,
## sale un coche de juguete por la rampa de delante. Admite varios bloques en cola.

const TOY_SCENE := preload("res://scenes/items/toy_car.tscn")

## Segundos por juguete. Las mejoras de la Fase 6 lo reducirán.
@export var craft_time := 3.0
## Bloques que caben en la cola a la vez.
@export var capacity := 3
@export var eject_speed := 2.5

## Visibles para todos (sincronizados).
var queued := 0
var working := false

var _progress := 0.0

@onready var _hopper: Area3D = $Hopper
@onready var _output: Node3D = $Output
@onready var _gear: Node3D = $Gear


func get_interaction_text() -> String:
	return "Echa madera por arriba"


func server_scan() -> void:
	for wood in items_in(_hopper, "material"):
		if queued >= capacity:
			break
		if wood.server_consume():
			queued += 1
	working = queued > 0
	_refresh_status()


func server_tick(delta: float) -> void:
	if queued == 0:
		return
	_progress += delta / craft_time
	if _progress >= 1.0:
		_progress = 0.0
		queued -= 1
		var out_dir := _output.global_basis.z.normalized()
		game().spawn_item(TOY_SCENE, _output.global_position, out_dir * eject_speed + Vector3.UP)
		working = queued > 0
	_refresh_status()


func _refresh_status() -> void:
	if queued == 0:
		status_text = "Esperando madera"
	else:
		var pct := int(_progress * 10.0) * 10 # de 10 en 10 para no saturar la red
		status_text = "Fabricando %d%%  ·  en cola %d/%d" % [pct, queued, capacity]


func _process(delta: float) -> void:
	if working:
		_gear.rotate_z(delta * 4.0)
