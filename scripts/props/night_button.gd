extends Interactable
## Botón grande del taller para controlar la partida, que puede pulsar cualquier elfo:
## - mode "start": EMPEZAR la primera noche (en la espera) o SEGUIR jugando tras Nochebuena.
## - mode "restart": PARTIDA NUEVA tras Nochebuena (todo vuelve a cero).
## Solo se ve cuando sirve para algo.

@export_enum("start", "restart") var mode := "start"

@onready var _label: Label3D = $Label


func _ready() -> void:
	super()
	cooldown = 1.0
	used.connect(_on_used)
	_connect_state.call_deferred()


func _connect_state() -> void:
	var g := get_tree().get_first_node_in_group("game") as Game
	if g == null:
		return
	g.state.changed.connect(func(): _refresh(g.state))
	_refresh(g.state)


func _on_used(_by: Player) -> void:
	var state := (get_tree().get_first_node_in_group("game") as Game).state
	if mode == "restart":
		state.server_new_game()
	elif state.phase == WorkshopState.Phase.FINISHED:
		state.server_continue_endless()
	else:
		state.server_start_night()


func get_interaction_text() -> String:
	return "Pulsar: " + _label.text.to_lower().replace("\n", " ")


func _refresh(state: WorkshopState) -> void:
	var on := false
	if mode == "restart":
		on = state.phase == WorkshopState.Phase.FINISHED
		_label.text = "PARTIDA NUEVA"
	elif state.phase == WorkshopState.Phase.LOBBY:
		on = true
		_label.text = "EMPEZAR\nNOCHE %d" % state.night
	elif state.phase == WorkshopState.Phase.FINISHED:
		on = true
		_label.text = "SEGUIR JUGANDO\nNOCHE %d" % (state.night + 1)
	visible = on
	collision_layer = ((1 << 0) | (1 << 3)) if on else 0
