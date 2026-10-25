class_name WorkshopState
extends Node
## Estado compartido del taller: regalos en el saco, objetivo, dinero común, mejoras y la
## noche en curso. Solo el anfitrión lo cambia; el MultiplayerSynchronizer lo envía a todos.
## El dinero es del equipo: solo se gasta comprando mejoras, nadie puede quitárselo a otro.
##
## Una partida son NIGHTS noches. Cada noche pasa por estas fases:
##   LOBBY (solo al principio): se espera a que alguien pulse EMPEZAR.
##   PRODUCTION: PRODUCTION_TIME segundos para llenar el saco. Si se llena antes, el reparto
##     empieza ya y el tiempo que sobra da monedas.
##   DELIVERY: el trineo está en el patio; DELIVERY_TIME segundos para servir las casas.
##   RESULTS: resumen de la noche durante RESULTS_TIME segundos; después, la noche siguiente.
##   FINISHED: tras la última noche (Nochebuena). Se puede seguir (modo infinito) o empezar otra.

signal changed
signal goal_reached
## En todos los PCs, cuando alguien compra una mejora.
signal upgrade_bought(index: int, buyer_name: String)
## En todos los PCs: aviso grande para el equipo ("¡El trineo ha llegado!").
signal announced(text: String)
## En todos los PCs, al terminar el reparto de una noche (ver server_end_delivery).
signal results_ready(results: Dictionary)

enum Phase { LOBBY, PRODUCTION, DELIVERY, RESULTS, FINISHED }

const NIGHTS := 5
const PRODUCTION_TIME := 360.0
const DELIVERY_TIME := 120.0
const RESULTS_TIME := 15.0
## Regalos que pide cada noche para un elfo; luego +GOAL_PER_EXTRA_PLAYER por cada elfo más.
const BASE_GOALS := [6, 8, 10, 12, 14]
const GOAL_PER_EXTRA_PLAYER := 2
## Segundos de producción sobrantes que valen una moneda.
const SECONDS_PER_BONUS_COIN := 5
## Dónde guarda el anfitrión su récord (los tests usan otro archivo).
var record_path := "user://records.cfg"

## Monedas que da cada regalo que entra en el saco.
const GIFT_VALUE := 10
## Monedas extra por cada regalo que entra en una chimenea.
const DELIVERY_VALUE := 5

var gifts_in_sack := 0:
	set(value):
		var was_complete := is_complete()
		gifts_in_sack = value
		changed.emit()
		if not was_complete and is_complete():
			goal_reached.emit()
var goal := 10:
	set(value):
		goal = value
		changed.emit()
var money := 0:
	set(value):
		money = value
		changed.emit()
var total_earned := 0:
	set(value):
		total_earned = value
		changed.emit()
## Noche en curso (empieza en 1). Sube al terminar los resultados de cada noche.
var night := 1:
	set(value):
		night = value
		changed.emit()
var phase := Phase.LOBBY:
	set(value):
		phase = value
		changed.emit()
## Segundos que quedan de la fase actual (redondeado hacia arriba). Cambia una vez por segundo.
var seconds_left := 0:
	set(value):
		seconds_left = value
		changed.emit()
## true tras la última noche si el equipo decide seguir jugando.
var endless := false:
	set(value):
		endless = value
		changed.emit()
## true mientras el trineo está en el patio esperando a que se repartan los regalos.
var delivering := false:
	set(value):
		delivering = value
		changed.emit()
## Regalos que quedan en el trineo.
var sleigh_gifts := 0:
	set(value):
		sleigh_gifts = value
		changed.emit()
## Regalos entregados en chimeneas esta noche.
var delivered := 0:
	set(value):
		delivered = value
		changed.emit()
## Nivel de cada mejora, en el orden de Upgrades.LIST. Se reasigna entero al cambiar para
## que el MultiplayerSynchronizer detecte el cambio.
var upgrade_levels := PackedInt32Array([0, 0, 0, 0, 0]):
	set(value):
		upgrade_levels = value
		changed.emit()


# --- Solo en el anfitrión ---
var _time_left := 0.0
var _night_sacked := 0
var _earned_at_start := 0
var _run_delivered := 0


func _process(delta: float) -> void:
	if not multiplayer.is_server() or phase in [Phase.LOBBY, Phase.FINISHED]:
		return
	_time_left = maxf(_time_left - delta, 0.0)
	var secs := ceili(_time_left)
	if secs != seconds_left:
		seconds_left = secs
	if _time_left <= 0.0:
		_on_time_up()


func _on_time_up() -> void:
	match phase:
		Phase.PRODUCTION:
			server_start_delivery(true)
		Phase.DELIVERY:
			server_end_delivery()
		Phase.RESULTS:
			_after_results()


## Acaba la fase actual ya (para pruebas y para el botón de saltar en desarrollo).
func server_skip_phase() -> void:
	if multiplayer.is_server():
		_time_left = 0.0


func _set_timer(seconds: float) -> void:
	_time_left = seconds
	seconds_left = ceili(seconds)


func is_complete() -> bool:
	return gifts_in_sack >= goal


func level(index: int) -> int:
	return upgrade_levels[index] if index < upgrade_levels.size() else 0


func next_price(index: int) -> int:
	return Upgrades.price(index, level(index))


func server_add_gift() -> void:
	if not multiplayer.is_server():
		return
	gifts_in_sack += 1
	_night_sacked += 1
	money += GIFT_VALUE
	total_earned += GIFT_VALUE


## Compra el siguiente nivel de una mejora si hay dinero. Devuelve si se ha comprado.
func server_buy(index: int, buyer_name := "") -> bool:
	if not multiplayer.is_server() or index < 0 or index >= Upgrades.LIST.size():
		return false
	var cost := next_price(index)
	if cost < 0 or money < cost:
		return false
	money -= cost
	var levels := upgrade_levels.duplicate()
	levels[index] += 1
	upgrade_levels = levels
	_announce_purchase.rpc(index, buyer_name)
	return true


## Regalos que pide una noche según cuántos elfos hay.
static func goal_for(night_number: int, player_count: int) -> int:
	var base: int = BASE_GOALS[mini(night_number, BASE_GOALS.size()) - 1]
	if night_number > BASE_GOALS.size(): # modo infinito: +2 por cada noche extra
		base += 2 * (night_number - BASE_GOALS.size())
	return base + GOAL_PER_EXTRA_PLAYER * maxi(player_count - 1, 0)


## Empieza la noche actual (desde la espera, o tras los resultados). Devuelve si ha empezado.
func server_start_night() -> bool:
	if not multiplayer.is_server() or phase in [Phase.PRODUCTION, Phase.DELIVERY]:
		return false
	goal = goal_for(night, maxi(Network.players.size(), 1))
	delivered = 0
	_night_sacked = 0
	_earned_at_start = total_earned
	phase = Phase.PRODUCTION
	_set_timer(PRODUCTION_TIME)
	server_announce("¡Noche %d! Llenad el saco con %d regalos" % [night, goal])
	if is_complete(): # sobraban regalos de antes
		server_start_delivery()
	return true


## Saco lleno (o se acabó el tiempo): sus regalos pasan al trineo y empieza el reparto.
## Si el saco se llena antes de tiempo, cada SECONDS_PER_BONUS_COIN segundos sobrantes dan
## una moneda.
func server_start_delivery(time_up := false) -> bool:
	if not multiplayer.is_server() or phase != Phase.PRODUCTION or (not time_up and not is_complete()):
		return false
	var bonus := 0 if time_up else int(_time_left) / SECONDS_PER_BONUS_COIN
	money += bonus
	total_earned += bonus
	sleigh_gifts += mini(gifts_in_sack, goal)
	gifts_in_sack -= mini(gifts_in_sack, goal) # lo que pase del objetivo se queda para mañana
	delivered = 0
	delivering = true
	phase = Phase.DELIVERY
	_set_timer(DELIVERY_TIME)
	var text := "¡El trineo ha llegado al patio! Llevad los regalos a las chimeneas"
	if time_up:
		text = "¡Se acabó el tiempo! El trineo se lleva lo que hay: al patio"
	elif bonus > 0:
		text += " (+%d monedas por acabar antes)" % bonus
	server_announce(text)
	return true


## Saca un regalo del trineo. Devuelve si quedaba alguno.
func server_take_from_sleigh() -> bool:
	if not multiplayer.is_server() or phase != Phase.DELIVERY or sleigh_gifts <= 0:
		return false
	sleigh_gifts -= 1
	return true


## Un regalo ha entrado en una chimenea.
func server_deliver() -> void:
	if not multiplayer.is_server():
		return
	delivered += 1
	money += DELIVERY_VALUE
	total_earned += DELIVERY_VALUE


## Termina el reparto (todas las casas servidas o se acabó el tiempo) y enseña los
## resultados. Lo que sobre en el trineo vuelve al saco para la noche siguiente.
func server_end_delivery() -> void:
	if not multiplayer.is_server() or phase != Phase.DELIVERY:
		return
	var houses := get_tree().get_nodes_in_group("house")
	var happy := houses.filter(func(h): return h.is_satisfied()).size()
	_run_delivered += delivered
	var last := night >= NIGHTS and not endless
	var results := {
		"night": night,
		"goal": goal,
		"sacked": _night_sacked,
		"delivered": delivered,
		"happy": happy,
		"houses": houses.size(),
		"coins": total_earned - _earned_at_start,
		"final": last,
		"run_delivered": _run_delivered,
		"record": _update_record() if last else _load_record(),
	}
	for h in houses:
		h.server_reset()
	delivering = false
	gifts_in_sack += sleigh_gifts
	sleigh_gifts = 0
	phase = Phase.RESULTS
	_set_timer(RESULTS_TIME)
	_announce_results.rpc(results)


func _after_results() -> void:
	if night >= NIGHTS and not endless:
		phase = Phase.FINISHED
		seconds_left = 0
		server_announce("¡Feliz Nochebuena! Podéis seguir jugando o empezar otra partida")
		return
	night += 1
	server_start_night()


## Tras Nochebuena: seguir jugando noches cada vez más difíciles.
func server_continue_endless() -> bool:
	if not multiplayer.is_server() or phase != Phase.FINISHED:
		return false
	endless = true
	night += 1
	return server_start_night()


## Partida nueva: todo a cero (dinero, mejoras, noche) y vuelta a la espera.
func server_new_game() -> bool:
	if not multiplayer.is_server() or phase != Phase.FINISHED:
		return false
	night = 1
	endless = false
	money = 0
	total_earned = 0
	gifts_in_sack = 0
	sleigh_gifts = 0
	delivered = 0
	delivering = false
	_run_delivered = 0
	var levels := PackedInt32Array()
	levels.resize(Upgrades.LIST.size())
	upgrade_levels = levels
	phase = Phase.LOBBY
	seconds_left = 0
	server_announce("Partida nueva: pulsad EMPEZAR cuando estéis listos")
	return true


func _load_record() -> int:
	var cfg := ConfigFile.new()
	if cfg.load(record_path) != OK:
		return 0
	return cfg.get_value("records", "delivered", 0)


## Guarda el récord de regalos repartidos en una partida (en el PC del anfitrión).
func _update_record() -> int:
	var best := maxi(_load_record(), _run_delivered)
	var cfg := ConfigFile.new()
	cfg.set_value("records", "delivered", best)
	cfg.save(record_path)
	return best


func server_announce(text: String) -> void:
	_announce_text.rpc(text)


@rpc("authority", "call_local", "reliable")
func _announce_text(text: String) -> void:
	announced.emit(text)


@rpc("authority", "call_local", "reliable")
func _announce_results(results: Dictionary) -> void:
	results_ready.emit(results)


@rpc("authority", "call_local", "reliable")
func _announce_purchase(index: int, buyer_name: String) -> void:
	upgrade_bought.emit(index, buyer_name)
