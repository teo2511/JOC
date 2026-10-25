extends Station
## Saco de Santa: cuenta los regalos que entran por la boca. Cada regalo se gasta al entrar,
## así que nunca cuenta dos veces. Lo que no es un regalo lo escupe hacia fuera, y también los
## regalos que ya han salido del trineo (esos van a las chimeneas).

@export var spit_speed := 4.0

@onready var _mouth: Area3D = $Mouth
@onready var _bag: Node3D = $Bag


func get_interaction_text() -> String:
	return "Echa aquí los regalos"


func server_scan() -> void:
	for item in items_in(_mouth):
		if item.kind == "gift" and not item.from_sleigh:
			if item.server_consume():
				game().state.server_add_gift()
				Sfx.broadcast("sack", global_position)
		else:
			var away := (item.global_position - global_position)
			away.y = 0
			item.linear_velocity = away.normalized() * spit_speed + Vector3.UP * spit_speed
			Sfx.broadcast("boing", global_position)


func on_state_changed(state: WorkshopState) -> void:
	status_text = "%d / %d regalos" % [state.gifts_in_sack, state.goal]
	var fill := clampf(float(state.gifts_in_sack) / maxf(state.goal, 1), 0.0, 1.0)
	_bag.scale = Vector3.ONE * (0.8 + 0.4 * fill)
