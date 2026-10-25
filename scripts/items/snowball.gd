extends Carryable
## Bola de nieve: se coge del montón de nieve y se lanza. Si al volar choca con otro elfo,
## a este se le cae lo que lleva, sale un poco despedido y ve escarcha en la pantalla.
## Se deshace con el primer golpe después de lanzarla. Todo lo decide el anfitrión.

## Velocidad mínima al soltarla para que cuente como lanzamiento (soltarla no golpea).
const MIN_THROW_SPEED := 5.0
const HIT_FORCE := 3.5

var _armed := false
var _thrower := 0


func _ready() -> void:
	super()
	contact_monitor = true
	max_contacts_reported = 4
	body_entered.connect(_on_body_entered)


func server_release(peer_id: int, velocity: Vector3) -> bool:
	var ok := super(peer_id, velocity)
	if ok and velocity.length() >= MIN_THROW_SPEED:
		_armed = true
		_thrower = peer_id
	return ok


func _on_body_entered(body: Node) -> void:
	if not multiplayer.is_server() or not _armed or consumed:
		return
	if body is Player:
		if body.peer_id == _thrower:
			return
		var dir := linear_velocity
		dir.y = 0
		var game := get_tree().get_first_node_in_group("game") as Game
		game.pranks.server_hit(body.peer_id, dir.normalized() * HIT_FORCE + Vector3.UP * 1.5, "snow")
	else:
		Sfx.broadcast("snow", global_position)
	_armed = false
	server_consume()
