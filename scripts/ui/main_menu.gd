extends Control
## Menú principal: nombre del elfo, crear partida, unirse por IP y jugar solo.

signal host_requested
signal join_requested(address: String, port: int)
signal solo_requested

@onready var name_edit: LineEdit = %NameEdit
@onready var address_edit: LineEdit = %AddressEdit
@onready var status: Label = %Status
@onready var buttons: Array[Button] = [%HostButton, %JoinButton, %SoloButton]


func _ready() -> void:
	name_edit.text = Settings.player_name
	address_edit.text = Settings.last_address
	%HostButton.pressed.connect(_on_host)
	%JoinButton.pressed.connect(_on_join)
	%SoloButton.pressed.connect(_on_solo)
	%QuitButton.pressed.connect(func(): get_tree().quit())
	address_edit.text_submitted.connect(func(_t): _on_join())


func show_message(text: String) -> void:
	status.text = text
	set_busy(false)


func set_busy(busy: bool) -> void:
	for b in buttons:
		b.disabled = busy


func _save_fields() -> void:
	Settings.player_name = name_edit.text.strip_edges()
	Settings.last_address = address_edit.text.strip_edges()
	Settings.save_settings()


func _on_host() -> void:
	_save_fields()
	host_requested.emit()


func _on_solo() -> void:
	_save_fields()
	solo_requested.emit()


func _on_join() -> void:
	_save_fields()
	var text := address_edit.text.strip_edges()
	if text == "":
		show_message("Escribe la IP del anfitrión.")
		return
	# Admite "IP" o "IP:puerto".
	var address := text
	var port := Network.DEFAULT_PORT
	var colon := text.rfind(":")
	if colon > 0 and text.count(":") == 1:
		address = text.left(colon)
		port = text.substr(colon + 1).to_int()
	status.text = "Conectando con %s..." % text
	set_busy(true)
	join_requested.emit(address, port)
