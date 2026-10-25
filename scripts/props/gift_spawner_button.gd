extends Interactable
## Botón de la zona de pruebas: cada pulsación hace aparecer un objeto nuevo.
## Sirve para probar los objetos "usables" y la aparición de objetos en red.
## Solo el anfitrión crea el objeto; el ItemSpawner de la partida lo replica a todos.

@export var item_scene: PackedScene
@export var spawn_point: Node3D
## Nodo donde se añaden los objetos (debe ser el que vigila el ItemSpawner).
@export var items_parent: Node3D
## Límite de objetos creados por este botón, para no hundir el rendimiento.
@export var max_items := 20

var _spawned: Array[Node] = []


func _ready() -> void:
	super()
	used.connect(_on_used)


func _on_used(_by: Player) -> void:
	if item_scene == null or spawn_point == null or items_parent == null:
		return
	_spawned = _spawned.filter(func(n): return is_instance_valid(n))
	if _spawned.size() >= max_items:
		var oldest: Node = _spawned.pop_front()
		oldest.queue_free()
	var item := item_scene.instantiate() as Node3D
	# La posición se pone antes de añadirlo, para que los clientes lo reciban ya colocado.
	item.position = items_parent.to_local(spawn_point.global_position)
	items_parent.add_child(item, true)
	_spawned.append(item)
	_play_press.rpc()


@rpc("authority", "call_local", "unreliable")
func _play_press() -> void:
	var cap := get_node_or_null("Cap") as Node3D
	if cap == null:
		return
	var tween := create_tween()
	tween.tween_property(cap, "position:y", 1.01, 0.06)
	tween.tween_property(cap, "position:y", 1.06, 0.12)
