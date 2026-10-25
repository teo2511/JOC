extends Interactable
## Palanca de broma: invierte la cinta transportadora unos segundos, así los juguetes van
## hacia atrás y caen al suelo delante de la fábrica (se pueden recoger, nada se pierde).
## Solo aparece cuando el equipo ha comprado la cinta.

@export var conveyor: Node3D
@export var reverse_seconds := 4.0


func _ready() -> void:
	super()
	cooldown = 12.0
	used.connect(func(_by): conveyor.server_reverse(reverse_seconds))
	_connect_state.call_deferred()


func _connect_state() -> void:
	var g := get_tree().get_first_node_in_group("game") as Game
	if g == null:
		return
	g.state.changed.connect(func(): _set_available(g.state.level(Upgrades.CONVEYOR) > 0))
	_set_available(g.state.level(Upgrades.CONVEYOR) > 0)


func get_interaction_text() -> String:
	return "Invertir la cinta (broma)" if can_use() else "La palanca se está recargando"


func _set_available(on: bool) -> void:
	visible = on
	collision_layer = ((1 << 0) | (1 << 3)) if on else 0
