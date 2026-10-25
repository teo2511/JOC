extends Station
## Dispensador: con [E] te da un objeto directamente en las manos (madera, bolas de nieve...).
## Si ya llevas algo, el objeto aparece encima.

@export var item_scene: PackedScene = preload("res://scenes/items/wood_block.tscn")
## Tipo de objeto que da (para contar cuántos hay sueltos).
@export var item_kind := "material"
## Máximo de objetos de este tipo sueltos, para que nadie llene el suelo.
@export var max_loose_blocks := 12
@export var too_many_text := "¡Demasiada madera suelta!"

@onready var _drop_point: Node3D = $DropPoint


func _ready() -> void:
	super()
	used.connect(_on_used)


func _on_used(by: Player) -> void:
	var loose := get_tree().get_nodes_in_group("carryable").filter(
		func(i): return i.kind == item_kind and i.is_available())
	if loose.size() >= max_loose_blocks:
		status_text = too_many_text
		get_tree().create_timer(1.5).timeout.connect(func(): status_text = "")
		return
	var hands_free := true
	for item in get_tree().get_nodes_in_group("carryable"):
		if item.holder_peer == by.peer_id:
			hands_free = false
	var pos := by.get_hold_transform().origin if hands_free else _drop_point.global_position
	var wood: Carryable = game().spawn_item(item_scene, pos)
	if hands_free:
		wood.server_try_pick(by.peer_id)
