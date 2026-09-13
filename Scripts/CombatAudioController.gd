extends Node
class_name CombatAudioController

const SONS_TIRO: Array[AudioStream] = [
	preload("res://sounds/Enemies/SFX_tiro_var1.wav"),
	preload("res://sounds/Enemies/SFX_tiro_var2.wav"),
	preload("res://sounds/Enemies/SFX_tiro_var3.wav"),
	preload("res://sounds/Enemies/SFX_tiro_var4.wav"),
]
const SOM_GRAVIDADE := preload("res://sounds/Bosses/sfx_gravidade_eclipse.wav")
const SOM_AMETISTA := preload("res://sounds/Bosses/snd_attack1_ametista.wav")
const INTERVALO_MINIMO_TIRO_MS := 55

var ultimo_tiro_ms := -INTERVALO_MINIMO_TIRO_MS
var gravidade_ativa_anterior := false
var poderes_ametista_anterior := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().node_added.connect(_ao_adicionar_node)


func _process(_delta: float) -> void:
	if multiplayer.has_multiplayer_peer() and not multiplayer.is_server():
		return
	_processar_gravidade()
	_processar_ametista()


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
	var sizigia := get_tree().get_first_node_in_group("boss_sizigia")
	var ativa := (
		is_instance_valid(sizigia)
		and float(sizigia.get("gravidade_tempo")) > 0.05
	)
	if ativa and not gravidade_ativa_anterior:
		if multiplayer.has_multiplayer_peer():
			_tocar_gravidade_remoto.rpc()
		_tocar_gravidade_remoto()
	gravidade_ativa_anterior = ativa


func _processar_ametista() -> void:
	var boss_ametista: Node
	for candidato in get_tree().get_nodes_in_group("boss"):
		if candidato is BossNoAmetista:
			boss_ametista = candidato
			break
	if not is_instance_valid(boss_ametista):
		poderes_ametista_anterior = 0
		return
	var poderes := int(boss_ametista.get("poderes_executados"))
	if poderes <= poderes_ametista_anterior:
		return
	poderes_ametista_anterior = poderes
	var ataque := int(boss_ametista.get("ultimo_ataque"))
	if ataque not in [0, 1, 3]:
		return
	if multiplayer.has_multiplayer_peer():
		_tocar_ametista_remoto.rpc()
	_tocar_ametista_remoto()


@rpc("authority", "call_remote", "reliable")
func _tocar_gravidade_remoto() -> void:
	_criar_audio(
		SOM_GRAVIDADE,
		randf_range(0.90, 1.10),
		-5.0
	)


@rpc("authority", "call_remote", "reliable")
func _tocar_ametista_remoto() -> void:
	_criar_audio(
		SOM_AMETISTA,
		randf_range(0.88, 1.12),
		-6.0
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
