extends Interactable
## Botón del tablón de mejoras. Cada uno compra el siguiente nivel de una mejora con el
## dinero común. El cartel muestra nivel, precio y efecto para todos los jugadores.

@export var upgrade_index := 0

const AFFORDABLE := Color(0.3, 0.85, 0.35)
const TOO_EXPENSIVE := Color(0.6, 0.6, 0.6)
const MAXED := Color(0.95, 0.75, 0.2)

@onready var _label: Label3D = $Label
@onready var _cap: MeshInstance3D = $Cap

var _state: WorkshopState


func _ready() -> void:
	super()
	used.connect(_on_used)
	_connect_state.call_deferred()


func _connect_state() -> void:
	var g := get_tree().get_first_node_in_group("game") as Game
	if g == null:
		return
	_state = g.state
	_state.changed.connect(_refresh)
	_refresh()


func get_interaction_text() -> String:
	if _state == null:
		return "Comprar"
	var cost := _state.next_price(upgrade_index)
	if cost < 0:
		return "Mejora al máximo"
	if _state.money < cost:
		return "Faltan %d monedas" % (cost - _state.money)
	return "Comprar por %d monedas" % cost


func _on_used(by: Player) -> void:
	_state.server_buy(upgrade_index, by.display_name)


func _refresh() -> void:
	var info: Dictionary = Upgrades.LIST[upgrade_index]
	var lvl := _state.level(upgrade_index)
	var max_lvl := Upgrades.max_level(upgrade_index)
	var cost := _state.next_price(upgrade_index)
	var price_line := "AL MÁXIMO" if cost < 0 else "%d monedas" % cost
	_label.text = "%s\nNivel %d/%d · %s\n%s" % [info["name"], lvl, max_lvl, price_line, info["effect"]]
	var mat := StandardMaterial3D.new()
	mat.emission_enabled = true
	var color := MAXED if cost < 0 else (AFFORDABLE if _state.money >= cost else TOO_EXPENSIVE)
	mat.albedo_color = color
	mat.emission = color * 0.4
	_cap.material_override = mat
