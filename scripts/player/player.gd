class_name Player
extends CharacterBody3D
## Elfo en primera persona: movimiento, salto y cámara con ratón.
## La interacción con objetos está en player_interaction.gd.
##
## En red cada jugador controla su propio elfo (es su autoridad) y envía posición y
## orientación con el MultiplayerSynchronizer. Los demás PCs mueven ese elfo suavemente
## hacia lo recibido, sin simular nada.

@export var move_speed := 5.5
@export var ground_acceleration := 45.0
@export var air_acceleration := 12.0
@export var jump_velocity := 4.8
@export var respawn_below_y := -10.0

const MAX_PITCH := deg_to_rad(85.0)
const REMOTE_SMOOTHING := 15.0

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var input_enabled := true
## Lo ajusta la partida según la mejora "Botas de elfo".
var speed_multiplier := 1.0
var peer_id := 1
var display_name := "Elfo"
var elf_color := Color(0.13, 0.55, 0.25)

## Estado que se envía a los demás jugadores.
var sync_position := Vector3.ZERO
var sync_yaw := 0.0
var sync_pitch := 0.0

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var interaction: PlayerInteraction = $Interaction
@onready var hold_point: Node3D = %HoldPoint
@onready var name_tag: Label3D = $NameTag

var _spawn_transform: Transform3D


## Busca el elfo de un jugador por su peer id.
static func find(tree: SceneTree, id: int) -> Player:
	for p in tree.get_nodes_in_group("player"):
		if p.peer_id == id:
			return p
	return null


func is_local() -> bool:
	return is_multiplayer_authority()


func _ready() -> void:
	add_to_group("player")
	_spawn_transform = global_transform
	_apply_look()
	if is_local():
		add_to_group("local_player")
		camera.current = true
		name_tag.visible = false
		set_mouse_captured(true)
		_write_sync()
	else:
		camera.current = false
		input_enabled = false
		# El cuerpo de los demás se ve (capa 1); el propio va en la capa 2, que tu cámara no dibuja.
		$Body.layers = 1
		$Body/Hat.layers = 1
		name_tag.text = display_name
		if sync_position != Vector3.ZERO:
			global_position = sync_position


func _apply_look() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = elf_color
	$Body.material_override = mat


## Última posición conocida: la real si es el elfo propio, la recibida por red si es de otro.
## El anfitrión la usa para validar distancias sin depender del suavizado.
func latest_position() -> Vector3:
	return global_position if is_local() else sync_position


func get_hold_transform() -> Transform3D:
	return hold_point.global_transform


func set_mouse_captured(captured: bool) -> void:
	if not is_local():
		return
	input_enabled = captured
	if DisplayServer.get_name() == "headless":
		return
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if captured else Input.MOUSE_MODE_VISIBLE


func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled or not is_local():
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		look(event.relative)


## Gira la cámara según el movimiento del ratón (en píxeles).
func look(relative: Vector2) -> void:
	var sens := deg_to_rad(Settings.mouse_sensitivity)
	var y_sign := 1.0 if Settings.invert_y else -1.0
	rotate_y(-relative.x * sens)
	head.rotation.x = clampf(head.rotation.x + relative.y * sens * y_sign, -MAX_PITCH, MAX_PITCH)


func _physics_process(delta: float) -> void:
	if not is_local():
		_follow_remote(delta)
		return

	if not is_on_floor():
		velocity.y -= gravity * delta

	var input_dir := Vector2.ZERO
	if input_enabled:
		input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = jump_velocity

	var wish := (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized() * move_speed * speed_multiplier
	var accel := ground_acceleration if is_on_floor() else air_acceleration
	var horizontal := Vector3(velocity.x, 0.0, velocity.z).move_toward(wish, accel * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z

	move_and_slide()

	if global_position.y < respawn_below_y:
		respawn()
	_write_sync()


func _write_sync() -> void:
	sync_position = global_position
	sync_yaw = rotation.y
	sync_pitch = head.rotation.x


func _follow_remote(delta: float) -> void:
	var t := 1.0 - exp(-REMOTE_SMOOTHING * delta)
	# Si está muy lejos (reaparición), se teletransporta en vez de deslizarse.
	if global_position.distance_to(sync_position) > 5.0:
		global_position = sync_position
	else:
		global_position = global_position.lerp(sync_position, t)
	rotation.y = lerp_angle(rotation.y, sync_yaw, t)
	head.rotation.x = lerpf(head.rotation.x, sync_pitch, t)


func respawn() -> void:
	interaction.drop_held()
	global_transform = _spawn_transform
	velocity = Vector3.ZERO
