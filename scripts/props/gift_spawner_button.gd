extends Interactable
## Botón de la zona de pruebas: cada pulsación hace aparecer un objeto nuevo.
## Sirve para probar los objetos "usables" y la aparición de objetos.

@export var item_scene: PackedScene
@export var spawn_point: Node3D
## Límite de objetos creados por este botón, para no hundir el rendimiento.
@export var max_items := 20

var _spawned: Array[Node] = []


func _ready() -> void:
	super()
	used.connect(_on_used)


func _on_used(_by: Node3D) -> void:
	if item_scene == null or spawn_point == null:
		return
	_spawned = _spawned.filter(func(n): return is_instance_valid(n))
	if _spawned.size() >= max_items:
		var oldest: Node = _spawned.pop_front()
		oldest.queue_free()
	var item := item_scene.instantiate() as Node3D
	get_parent().add_child(item)
	item.global_position = spawn_point.global_position
	_spawned.append(item)
	_press_animation()


func _press_animation() -> void:
	var cap := get_node_or_null("Cap") as Node3D
	if cap == null:
		return
	var tween := create_tween()
	tween.tween_property(cap, "position:y", cap.position.y - 0.05, 0.06)
	tween.tween_property(cap, "position:y", cap.position.y, 0.12)
