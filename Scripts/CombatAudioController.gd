extends Node
class_name CombatAudioController

const SONS_TIRO: Array[AudioStream] = [
	preload("res://sounds/Enemies/SFX_tiro_var1.wav"),
	preload("res://sounds/Enemies/SFX_tiro_var2.wav"),
	preload("res://sounds/Enemies/SFX_tiro_var3.wav"),
	preload("res://sounds/Enemies/SFX_tiro_var4.wav"),
]
const SOM_GRAVIDADE := preload("res://sounds/Bosses/sfx_gravidade_eclipse.wav")
const INTERVALO_MINIMO_TIRO_MS := 55

var ultimo_tiro_ms := -INTERVALO_MINIMO_TIRO_MS
var gravidade_ativa_anterior := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	get_tree().node_added.connect(_ao_adicionar_node)


func _process(_delta: float) -> void:
	if multiplayer.has_multiplayer_peer() and not multiplayer.is_server():
		return
	_processar_gravidade()


func _ao_adicionar_node(node: Node) -> void:
	if node is ProjetilInimigo:
		call_deferred("_tocar_tiro_do_inimigo", node)


func _tocar_tiro_do_inimigo(projetil: Node2D) -> void:
	if not is_instance_valid(projetil):
		return
	var agora := Time.get_ticks_msec()
	if agora - ultimo_tiro_ms < INTERVALO_MINIMO_TIRO_MS:
		return
	ultimo_tiro_ms = agora
	_criar_audio_2d(
		SONS_TIRO.pick_random(),
		projetil.global_position,
		randf_range(0.88, 1.14),
		-9.0
	)


func _processar_gravidade() -> void:
	var sizigia := get_tree().get_first_node_in_group("boss_sizigia") as BossSizigiaEterna
	var ativa := (
		is_instance_valid(sizigia)
		and sizigia.golpes.gravidade_ativa()
	)
	if ativa and not gravidade_ativa_anterior:
		if multiplayer.has_multiplayer_peer():
			_tocar_gravidade_remoto.rpc()
		_tocar_gravidade_remoto()
	gravidade_ativa_anterior = ativa


@rpc("authority", "call_remote", "reliable")
func _tocar_gravidade_remoto() -> void:
	_criar_audio(
		SOM_GRAVIDADE,
		randf_range(0.90, 1.10),
		-5.0
	)


func _criar_audio(stream: AudioStream, pitch: float, volume: float) -> void:
	var audio := AudioStreamPlayer.new()
	audio.stream = stream
	audio.pitch_scale = pitch
	audio.volume_db = volume
	add_child(audio)
	audio.finished.connect(audio.queue_free)
	audio.play()


func _criar_audio_2d(
	stream: AudioStream, posicao: Vector2, pitch: float, volume: float
) -> void:
	var audio := AudioStreamPlayer2D.new()
	audio.stream = stream
	audio.global_position = posicao
	audio.pitch_scale = pitch
	audio.volume_db = volume
	audio.max_distance = 1050.0
	audio.attenuation = 0.72
	add_child(audio)
	audio.finished.connect(audio.queue_free)
	audio.play()
