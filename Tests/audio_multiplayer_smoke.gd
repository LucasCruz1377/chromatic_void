extends Node

var falhas: Array[String] = []


func checar(condicao: bool, mensagem: String) -> void:
	if condicao:
		return
	falhas.append(mensagem)
	push_error("ÁUDIO E REDE: " + mensagem)


func _ready() -> void:
	var sons := [
		"res://sounds/Enemies/SFX_tiro_var1.wav",
		"res://sounds/Enemies/SFX_tiro_var2.wav",
		"res://sounds/Enemies/SFX_tiro_var3.wav",
		"res://sounds/Enemies/SFX_tiro_var4.wav",
		"res://sounds/Bosses/sfx_gravidade_eclipse.wav",
		"res://sounds/Bosses/snd_attack1_ametista.wav",
	]
	for caminho in sons:
		checar(ResourceLoader.exists(caminho), "arquivo ausente: " + caminho)
		checar(load(caminho) is AudioStream, "áudio inválido: " + caminho)

	var controlador_script := load("res://Scripts/CombatAudioController.gd")
	checar(controlador_script != null, "controlador de áudio não carregou")
	if controlador_script != null:
		var controlador: Node = controlador_script.new()
		checar(controlador.SONS_TIRO.size() == 4, "não há quatro variações de tiro")
		checar(controlador.has_method("_tocar_gravidade_remoto"), "som gravitacional não configurado")
		checar(controlador.has_method("_tocar_ametista_remoto"), "som da Ametista não configurado")
		controlador.queue_free()

	var fonte_projetil := FileAccess.get_file_as_string("res://Scripts/ProjetilInimigo.gd")
	checar(
		"configuracao.property_set_sync(caminho, caminho in propriedades_movimento)" in fonte_projetil,
		"projéteis não recebem correções autoritativas de movimento"
	)
	checar(
		"if Rede.modo_multiplayer and not multiplayer.is_server():" in fonte_projetil and
		"tempo_vida -= delta" in fonte_projetil and
		"queue_free()" in fonte_projetil,
		"despawn dos projéteis não é controlado pelo host"
	)

	var fonte_setorial := FileAccess.get_file_as_string("res://Scripts/InimigoSementeCanhao.gd")
	var fonte_drone := FileAccess.get_file_as_string("res://Scripts/InimigoSateliteBerco.gd")
	checar(
		fonte_setorial.find("p.configurar(dir,dano_tiro,vel,0)") <
		fonte_setorial.find("cena.add_child(p, true)"),
		"tiro setorial ainda nasce antes de ser configurado"
	)
	checar(
		fonte_drone.find("drone.position = global_position") <
		fonte_drone.find("batalha.add_child(drone, true)"),
		"drones do Satélite Berço ainda nascem sem posição inicial"
	)

	var batalha := (load("res://Rooms/Battle_area.tscn") as PackedScene).instantiate()
	get_tree().root.add_child.call_deferred(batalha)
	await get_tree().process_frame
	get_tree().current_scene = batalha
	await get_tree().process_frame
	checar(
		batalha.has_node("CombatAudioController"),
		"a arena não ativou o controlador de áudio"
	)
	for audio in batalha.find_children("*", "AudioStreamPlayer", true, false):
		(audio as AudioStreamPlayer).stop()
	for audio in batalha.find_children("*", "AudioStreamPlayer2D", true, false):
		(audio as AudioStreamPlayer2D).stop()
	batalha.queue_free()
	await get_tree().process_frame

	if falhas.is_empty():
		print("TESTE OK: variações de áudio e projéteis multiplayer")
		get_tree().quit(0)
	else:
		get_tree().quit(1)
