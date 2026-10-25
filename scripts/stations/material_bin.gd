extends Station
## Caja de materiales: con [E] te da un bloque de madera directamente en las manos.
## Si ya llevas algo, el bloque aparece encima de la caja.

const WOOD_SCENE := preload("res://scenes/items/wood_block.tscn")
## Máximo de bloques sueltos en el taller, para que nadie llene el suelo de madera.
@export var max_loose_blocks := 12

@onready var _drop_point: Node3D = $DropPoint


func _ready() -> void:
	super()
	used.connect(_on_used)


func _on_used(by: Player) -> void:
	var loose := get_tree().get_nodes_in_group("carryable").filter(
		func(i): return i.kind == "material" and i.is_available())
	if loose.size() >= max_loose_blocks:
		status_text = "¡Demasiada madera suelta!"
		get_tree().create_timer(1.5).timeout.connect(func(): status_text = "")
		return
	var hands_free := true
	for item in get_tree().get_nodes_in_group("carryable"):
		if item.holder_peer == by.peer_id:
			hands_free = false
	var pos := by.get_hold_transform().origin if hands_free else _drop_point.global_position
	var wood: Carryable = game().spawn_item(WOOD_SCENE, pos)
	if hands_free:
		wood.server_try_pick(by.peer_id)
