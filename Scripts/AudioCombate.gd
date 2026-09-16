extends RefCounted


const SONS := {
	&"retrocesso": [preload("res://sounds/SFX/Retrocesso.wav")],
	&"petalas": [preload("res://sounds/SFX/petalas_boomerang.wav")],
	&"investida": [preload("res://sounds/SFX/inimigo_investida.wav")],
	&"dash": [preload("res://sounds/SFX/Player_dash.wav")],
	&"cura": [preload("res://sounds/SFX/Curar.wav")],
	&"espinhos_flor": [preload("res://sounds/SFX/SFX_spikesshot_flor.wav")],
	&"morte_flor": [preload("res://sounds/SFX/SFX_death_flor.wav")],
	&"morte_sizigia": [preload("res://sounds/SFX/SFX_death_sizigia.wav")],
	&"explosoes": [
		preload("res://sounds/SFX/SFX_explosion1.wav"),
		preload("res://sounds/SFX/SFX_explosion2.wav"),
		preload("res://sounds/SFX/SFX_explosion3.wav"),
		preload("res://sounds/SFX/SFX_explosion4.wav"),
	],
	&"player_hit": [
		preload("res://sounds/SFX/hitHurt.wav"),
		preload("res://sounds/SFX/hitHurt2.wav"),
		preload("res://sounds/SFX/hitHurt3.wav"),
	],
	&"menu": [
		preload("res://sounds/SFX/SFX_menu1.wav"),
		preload("res://sounds/SFX/SFX_menu2.wav"),
	],
}


static func tocar(
	emissor: Node,
	id: StringName,
	intervalo: float = 0.12,
	pitch_minimo: float = 0.94,
	pitch_maximo: float = 1.06,
	volume_db: float = -9.0
) -> AudioStreamPlayer:
	if not _pode_tocar(emissor, id, intervalo):
		return null
	var stream := _sortear_stream(id)
	if not is_instance_valid(stream):
		return null
	var som := AudioStreamPlayer.new()
	som.stream = stream
	som.bus = &"Sound"
	som.volume_db = volume_db
	som.pitch_scale = randf_range(pitch_minimo, pitch_maximo)
	emissor.add_child(som)
	som.finished.connect(som.queue_free)
	som.play()
	return som


static func tocar_posicional(
	pai: Node,
	posicao: Vector2,
	id: StringName,
	intervalo: float = 0.0,
	pitch_minimo: float = 0.94,
	pitch_maximo: float = 1.06,
	volume_db: float = -6.0
) -> AudioStreamPlayer2D:
	if not _pode_tocar(pai, id, intervalo):
		return null
	var stream := _sortear_stream(id)
	if not is_instance_valid(stream):
		return null
	var som := AudioStreamPlayer2D.new()
	som.stream = stream
	som.bus = &"Sound"
	som.volume_db = volume_db
	som.pitch_scale = randf_range(pitch_minimo, pitch_maximo)
	pai.add_child(som)
	som.global_position = posicao
	som.finished.connect(som.queue_free)
	som.play()
	return som


static func _pode_tocar(emissor: Node, id: StringName, intervalo: float) -> bool:
	if not is_instance_valid(emissor) or not emissor.is_inside_tree():
		return false
	if not SONS.has(id):
		push_warning("Som de combate desconhecido: %s" % id)
		return false
	var chave := "som_%s" % id
	var agora := Time.get_ticks_msec()
	if agora < int(emissor.get_meta(chave, 0)):
		return false
	emissor.set_meta(chave, agora + int(maxf(intervalo, 0.0) * 1000.0))
	return true


static func _sortear_stream(id: StringName) -> AudioStream:
	var opcoes: Array = SONS.get(id, [])
	if opcoes.is_empty():
		return null
	return opcoes.pick_random() as AudioStream
