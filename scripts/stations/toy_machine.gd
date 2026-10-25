extends Station
## Fábrica de juguetes: se echa madera por la tolva de arriba y, tras craft_time segundos,
## sale un coche de juguete por la rampa de delante. Admite varios bloques en cola.

const TOY_SCENE := preload("res://scenes/items/toy_car.tscn")

## Valores sin mejoras. Las mejoras "Fábrica rápida" y "Fábrica grande" los cambian.
@export var base_craft_time := 3.0
@export var base_capacity := 3
@export var eject_speed := 2.5
## Velocidad de salida cuando hay cinta: el juguete cae justo encima de ella.
@export var eject_speed_with_conveyor := 0.9

const SPEED_PER_LEVEL := 0.75
const CAPACITY_PER_LEVEL := 2
const BASE_COLOR := Color(0.15, 0.5, 0.55)
const UPGRADED_COLOR := Color(0.95, 0.7, 0.15)

var craft_time := 3.0
var capacity := 3
var _has_conveyor := false
var _speed_level := 0

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
		var speed := eject_speed_with_conveyor if _has_conveyor else eject_speed
		game().spawn_item(TOY_SCENE, _output.global_position, out_dir * speed + Vector3.UP)
		working = queued > 0
	_refresh_status()


func _refresh_status() -> void:
	if queued == 0:
		status_text = "Esperando madera"
	else:
		var pct := int(_progress * 10.0) * 10 # de 10 en 10 para no saturar la red
		status_text = "Fabricando %d%%  ·  en cola %d/%d" % [pct, queued, capacity]


func on_state_changed(state: WorkshopState) -> void:
	_speed_level = state.level(Upgrades.FAST_MACHINE)
	craft_time = base_craft_time * pow(SPEED_PER_LEVEL, _speed_level)
	capacity = base_capacity + CAPACITY_PER_LEVEL * state.level(Upgrades.BIG_MACHINE)
	_has_conveyor = state.level(Upgrades.CONVEYOR) > 0
	# Cada nivel de velocidad la vuelve más dorada, para que se note la mejora.
	var t := float(_speed_level) / Upgrades.max_level(Upgrades.FAST_MACHINE)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = BASE_COLOR.lerp(UPGRADED_COLOR, t)
	mat.metallic = 0.2 + 0.5 * t
	mat.roughness = 0.5
	$Body.material_override = mat


func _process(delta: float) -> void:
	if working:
		_gear.rotate_z(delta * 4.0 / pow(SPEED_PER_LEVEL, _speed_level))
