extends Node


const AudioCombate = preload("res://Scripts/AudioCombate.gd")

const QUANTIDADES := {
	&"espinhos_flor": 1,
	&"morte_flor": 1,
	&"morte_sizigia": 1,
	&"explosoes": 4,
	&"player_hit": 3,
	&"menu": 2,
}


func _ready() -> void:
	validar_catalogo_audio()
	validar_reproducao_e_pitch()
	await validar_botoes_globais()
	validar_integracoes()
	await get_tree().process_frame
	print("TESTE OK: variações sonoras, pitch aleatório e eventos integrados")
	get_tree().quit()


func validar_catalogo_audio() -> void:
	for id in QUANTIDADES:
		assert(AudioCombate.SONS.has(id), "Grupo de áudio ausente: %s" % id)
		var streams: Array = AudioCombate.SONS[id]
		assert(
			streams.size() == int(QUANTIDADES[id]),
			"Quantidade incorreta de variações para %s" % id
		)
		for stream in streams:
			assert(stream is AudioStream, "Recurso de áudio inválido em %s" % id)


func validar_reproducao_e_pitch() -> void:
	var emissor := Node.new()
	add_child(emissor)
	var som := AudioCombate.tocar(
		emissor, &"player_hit", 0.0, 0.81, 1.19, -5.0
	)
	assert(is_instance_valid(som), "O som comum não foi criado")
	assert(som.pitch_scale >= 0.81 and som.pitch_scale <= 1.19)
	assert(som.stream in AudioCombate.SONS[&"player_hit"])

	var posicional := AudioCombate.tocar_posicional(
		self, Vector2(32.0, 48.0), &"explosoes", 0.0, 0.77, 1.23
	)
	assert(is_instance_valid(posicional), "O som posicional não foi criado")
	assert(posicional.position == Vector2(32.0, 48.0))
	assert(posicional.pitch_scale >= 0.77 and posicional.pitch_scale <= 1.23)
	assert(posicional.stream in AudioCombate.SONS[&"explosoes"])
	som.stop()
	posicional.stop()
	som.free()
	posicional.free()
	emissor.free()


func validar_botoes_globais() -> void:
	var botao := Button.new()
	add_child(botao)
	await get_tree().process_frame
	var antes := _contar_players_audio(AudioUI)
	botao.pressed.emit()
	var depois := _contar_players_audio(AudioUI)
	assert(depois == antes + 1, "O clique global não criou o som de menu")
	var som_menu: AudioStreamPlayer
	for filho in AudioUI.get_children():
		if filho is AudioStreamPlayer and filho.stream in AudioCombate.SONS[&"menu"]:
			som_menu = filho
	assert(is_instance_valid(som_menu), "A variação de menu não foi utilizada")
	assert(som_menu.pitch_scale >= 0.90 and som_menu.pitch_scale <= 1.13)
	som_menu.stop()
	som_menu.free()
	botao.free()


func validar_integracoes() -> void:
	var inimigo := FileAccess.get_file_as_string("res://Scripts/InimigoBase.gd")
	var player := FileAccess.get_file_as_string("res://Scripts/player.gd")
	var flor := FileAccess.get_file_as_string("res://Scripts/BossCaosPrimaveril.gd")
	var sizigia := FileAccess.get_file_as_string("res://Scripts/BossSizigiaEterna.gd")
	var projeto := FileAccess.get_file_as_string("res://project.godot")
	assert('&"explosoes"' in inimigo)
	assert('&"player_hit"' in player)
	assert('&"espinhos_flor"' in flor and '&"morte_flor"' in flor)
	assert('&"morte_sizigia"' in sizigia)
	assert('AudioUI="*res://Scripts/AudioUI.gd"' in projeto)


func _contar_players_audio(no: Node) -> int:
	var total := 0
	for filho in no.get_children():
		if filho is AudioStreamPlayer:
			total += 1
	return total
