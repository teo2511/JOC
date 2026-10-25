extends Station
## Trineo de Santa (fijo, no se conduce). Aparece en el patio cuando el saco se llena y
## lleva sus regalos: con [E] te da uno en las manos para llevarlo a una chimenea.
## Se va cuando termina el reparto.


func _ready() -> void:
	super()
	cooldown = 0.3
	used.connect(_on_used)
	_set_present(false)


func get_interaction_text() -> String:
	return "Coger un regalo del trineo" if game() and game().state.sleigh_gifts > 0 else "El trineo está vacío"


func _on_used(by: Player) -> void:
	for item in get_tree().get_nodes_in_group("carryable"):
		if item.holder_peer == by.peer_id:
			return # con las manos ocupadas no se puede coger
	if not game().state.server_take_from_sleigh():
		return
	var gift: Carryable = game().spawn_item(preload("res://scenes/items/gift_box.tscn"), by.get_hold_transform().origin)
	gift.from_sleigh = true
	gift.server_try_pick(by.peer_id)


func on_state_changed(state: WorkshopState) -> void:
	_set_present(state.delivering)
	status_text = "Quedan %d regalos" % state.sleigh_gifts


func _set_present(on: bool) -> void:
	visible = on
	collision_layer = ((1 << 0) | (1 << 3)) if on else 0
