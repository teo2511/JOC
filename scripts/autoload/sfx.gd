extends Node
## Efectos de sonido. Los archivos los genera tools/generate_sounds.py (assets/audio/sfx).
##
## - play(nombre, posición): suena solo en este PC. Con posición suena en 3D (más flojo
##   lejos); sin posición suena igual en todos lados (avisos, interfaz).
## - broadcast(nombre, posición): lo llama el anfitrión para que suene en todos los PCs
##   (las estaciones y las bromas solo corren en el anfitrión).

const DIR := "res://assets/audio/sfx/"
const NO_POSITION := Vector3.INF

var _streams := {}
## Sonidos que han sonado en este PC (para los tests).
var played: Array[String] = []


func _ready() -> void:
	for file in DirAccess.get_files_at(DIR):
		# En el juego exportado los .wav se ven como .wav.import.
		var name := file.trim_suffix(".import")
		if name.ends_with(".wav"):
			_streams[name.get_basename()] = load(DIR + name)


func has_sound(sound: String) -> bool:
	return _streams.has(sound)


func play(sound: String, at := NO_POSITION, volume_db := 0.0) -> void:
	var stream: AudioStream = _streams.get(sound)
	if stream == null:
		push_warning("Sonido desconocido: " + sound)
		return
	played.append(sound)
	if played.size() > 200:
		played.remove_at(0)
	var player: Node
	if at == NO_POSITION:
		var p := AudioStreamPlayer.new()
		p.stream = stream
		p.volume_db = volume_db
		player = p
	else:
		var p3 := AudioStreamPlayer3D.new()
		p3.stream = stream
		p3.volume_db = volume_db
		p3.unit_size = 6.0
		p3.max_distance = 45.0
		p3.position = at
		player = p3
	add_child(player)
	player.play()
	# Se borra al acabar. Con un temporizador y no con "finished", que sin tarjeta de sonido
	# (tests sin pantalla) puede no llegar nunca.
	get_tree().create_timer(stream.get_length() + 0.2).timeout.connect(player.queue_free)


## Solo en el anfitrión: hace sonar el efecto en todos los PCs.
func broadcast(sound: String, at := NO_POSITION) -> void:
	if multiplayer.is_server():
		_play_everywhere.rpc(sound, at)


@rpc("authority", "call_local", "unreliable")
func _play_everywhere(sound: String, at: Vector3) -> void:
	play(sound, at)
