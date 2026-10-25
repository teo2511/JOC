class_name Player
extends CharacterBody3D
## Elfo en primera persona: movimiento, salto y cámara con ratón.
## La interacción con objetos está en player_interaction.gd.

@export var move_speed := 5.5
@export var ground_acceleration := 45.0
@export var air_acceleration := 12.0
@export var jump_velocity := 4.8
@export var respawn_below_y := -10.0

const MAX_PITCH := deg_to_rad(85.0)

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var input_enabled := true

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var interaction: PlayerInteraction = $Interaction

var _spawn_transform: Transform3D


func _ready() -> void:
	add_to_group("player")
	_spawn_transform = global_transform
	camera.current = true
	set_mouse_captured(true)


func set_mouse_captured(captured: bool) -> void:
	if DisplayServer.get_name() == "headless":
		return
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if captured else Input.MOUSE_MODE_VISIBLE
	input_enabled = captured


func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled:
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
	if not is_on_floor():
		velocity.y -= gravity * delta

	var input_dir := Vector2.ZERO
	if input_enabled:
		input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = jump_velocity

	var wish := (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized() * move_speed
	var accel := ground_acceleration if is_on_floor() else air_acceleration
	var horizontal := Vector3(velocity.x, 0.0, velocity.z).move_toward(wish, accel * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z

	move_and_slide()

	if global_position.y < respawn_below_y:
		respawn()


func respawn() -> void:
	interaction.drop_held()
	global_transform = _spawn_transform
	velocity = Vector3.ZERO
