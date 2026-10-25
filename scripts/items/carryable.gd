class_name Carryable
extends RigidBody3D
## Objeto que un elfo puede coger, soltar y lanzar (regalos, juguetes, materiales).
##
## En red, el anfitrión es el único que decide y el único que simula su física:
## - Los jugadores piden coger o soltar con request_pick / request_release.
## - El anfitrión valida la petición y cambia holder_peer (quién lo lleva, 0 = nadie).
## - holder_peer, sync_position y sync_rotation se envían a todos con el MultiplayerSynchronizer.
## - En los clientes el objeto está congelado y solo se mueve hacia la posición recibida.
## Mientras alguien lo lleva, cada PC lo coloca en las manos de ese elfo, así que quien lo
## lleva lo ve pegado a sus manos sin retraso.

signal holder_changed(old_peer: int, new_peer: int)

## Nombre que aparece en el aviso de interacción ("[E] Coger Regalo").
@export var display_name := "Objeto"
## Qué es en la cadena de producción: "material", "toy" (juguete sin envolver) o "gift".
@export_enum("material", "toy", "gift", "other") var kind := "other"
## Altura por debajo de la cual el objeto vuelve a su punto de aparición.
@export var respawn_below_y := -10.0

const FOLLOW_SPEED := 25.0
const CLIENT_SMOOTHING := 18.0
## Distancia máxima a la que el anfitrión acepta que alguien coja el objeto.
const MAX_PICK_DISTANCE := 4.0
## Velocidad máxima al soltar o lanzar, para que nadie mande velocidades absurdas.
const MAX_RELEASE_SPEED := 20.0

static var _highlight_material: StandardMaterial3D

## Quién lo lleva (peer id) o 0. Lo cambia solo el anfitrión.
var holder_peer := 0:
	set = _set_holder_peer
## Posición y rotación que el anfitrión envía a los demás.
var sync_position := Vector3.ZERO
var sync_rotation := Quaternion.IDENTITY

## true en cuanto una estación lo ha usado: ya no cuenta para nada más.
var consumed := false

var _spawn_transform: Transform3D
var _mesh: MeshInstance3D
var _exception_body: PhysicsBody3D


func _ready() -> void:
	add_to_group("carryable")
	collision_layer = 1 << 2 # capa "objetos"
	collision_mask = 0b0111 # mundo, jugadores y objetos
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	continuous_cd = true
	_spawn_transform = global_transform
	_mesh = _find_mesh(self)
	if multiplayer.is_server():
		_write_sync()
	else:
		freeze = true # en los clientes nunca se simula
		if sync_position != Vector3.ZERO:
			global_position = sync_position
			quaternion = sync_rotation
	if holder_peer != 0:
		_apply_holder(0, holder_peer)


func get_interaction_text() -> String:
	return "Coger " + display_name


func is_held() -> bool:
	return holder_peer != 0


# --- Peticiones de los jugadores (se ejecutan en el anfitrión) ---

@rpc("any_peer", "call_local", "reliable")
func request_pick() -> void:
	if not multiplayer.is_server():
		return
	var sender := _sender_id()
	var player := Player.find(get_tree(), sender)
	if player == null or player.latest_position().distance_to(global_position) > MAX_PICK_DISTANCE:
		return
	if _peer_is_holding_something(sender):
		return
	server_try_pick(sender)


@rpc("any_peer", "call_local", "reliable")
func request_release(velocity: Vector3) -> void:
	if not multiplayer.is_server():
		return
	server_release(_sender_id(), velocity)


# --- Reglas del anfitrión (también se usan en los tests) ---

## Da el objeto a peer_id si nadie lo lleva. Devuelve false si ya estaba cogido.
func server_try_pick(peer_id: int) -> bool:
	if holder_peer != 0:
		return false
	holder_peer = peer_id
	return true


## Suelta el objeto si lo lleva peer_id, con la velocidad indicada (limitada).
func server_release(peer_id: int, velocity: Vector3) -> bool:
	if holder_peer == 0 or holder_peer != peer_id:
		return false
	holder_peer = 0
	linear_velocity = velocity.limit_length(MAX_RELEASE_SPEED)
	angular_velocity = Vector3(randf_range(-2, 2), randf_range(-2, 2), randf_range(-2, 2))
	return true


## Lo suelta sin velocidad (por ejemplo, si quien lo llevaba se desconecta).
func server_force_release() -> void:
	if holder_peer != 0:
		server_release(holder_peer, Vector3.ZERO)


## Lo gasta una estación (máquina, mesa, saco). Devuelve false si ya estaba gastado o
## alguien lo lleva en las manos, así un mismo objeto nunca cuenta dos veces.
func server_consume() -> bool:
	if consumed or holder_peer != 0:
		return false
	consumed = true
	queue_free()
	return true


## Si está libre y quieto dentro de una estación, puede usarse.
func is_available() -> bool:
	return not consumed and holder_peer == 0 and not is_queued_for_deletion()


func server_respawn() -> void:
	server_force_release()
	global_transform = _spawn_transform
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO


# --- Estado y movimiento ---

func _set_holder_peer(value: int) -> void:
	var old := holder_peer
	if value == old:
		return
	holder_peer = value
	if is_inside_tree():
		_apply_holder(old, value)


func _apply_holder(old: int, new: int) -> void:
	if multiplayer.is_server():
		freeze = new != 0
	# El objeto no debe chocar con quien lo lleva.
	if new != 0:
		var body := Player.find(get_tree(), new)
		if body:
			_set_exception(body)
		set_highlighted(false)
	else:
		# Se recupera la colisión un instante después, cuando ya se ha alejado de sus manos.
		get_tree().create_timer(0.3).timeout.connect(func():
			if holder_peer == 0:
				_set_exception(null)
		)
	holder_changed.emit(old, new)
	get_tree().call_group("local_interaction", "on_item_holder_changed", self, old, new)


func _set_exception(body: PhysicsBody3D) -> void:
	if is_instance_valid(_exception_body):
		remove_collision_exception_with(_exception_body)
	_exception_body = body
	if body:
		add_collision_exception_with(body)


func _physics_process(delta: float) -> void:
	if holder_peer != 0:
		var player := Player.find(get_tree(), holder_peer)
		if player:
			var target := player.get_hold_transform()
			var t := minf(1.0, FOLLOW_SPEED * delta)
			global_position = global_position.lerp(target.origin, t)
			global_basis = global_basis.slerp(target.basis.orthonormalized(), t).orthonormalized()
		elif multiplayer.is_server():
			server_force_release()

	if multiplayer.is_server():
		if holder_peer == 0 and global_position.y < respawn_below_y:
			server_respawn()
		_write_sync()
	elif holder_peer == 0:
		var t := 1.0 - exp(-CLIENT_SMOOTHING * delta)
		global_position = global_position.lerp(sync_position, t)
		quaternion = quaternion.slerp(sync_rotation, t)


func _write_sync() -> void:
	sync_position = global_position
	sync_rotation = quaternion


func _sender_id() -> int:
	var id := multiplayer.get_remote_sender_id()
	return id if id != 0 else multiplayer.get_unique_id()


func _peer_is_holding_something(peer_id: int) -> bool:
	for item in get_tree().get_nodes_in_group("carryable"):
		if item.holder_peer == peer_id:
			return true
	return false


func set_highlighted(on: bool) -> void:
	if _mesh == null:
		return
	if _highlight_material == null:
		_highlight_material = StandardMaterial3D.new()
		_highlight_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_highlight_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_highlight_material.albedo_color = Color(1.0, 0.95, 0.6, 0.35)
	_mesh.material_overlay = _highlight_material if on else null


func _find_mesh(node: Node) -> MeshInstance3D:
	for child in node.get_children():
		if child is MeshInstance3D:
			return child
		var found := _find_mesh(child)
		if found:
			return found
	return null
