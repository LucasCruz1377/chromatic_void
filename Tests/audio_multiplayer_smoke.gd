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

	Rede.modo_multiplayer = true
	var projetil := (load("res://Entities/ProjetilInimigo.tscn") as PackedScene).instantiate() as ProjetilInimigo
	add_child(projetil)
	var sincronizador := projetil.get_node("MultiplayerSynchronizer") as MultiplayerSynchronizer
	for propriedade in ["position", "rotation", "direcao", "rebotes"]:
		var caminho := NodePath(".:" + propriedade)
		checar(sincronizador.replication_config.property_get_sync(caminho), "projetil nao sincroniza " + propriedade)
	Rede.modo_multiplayer = false
	projetil.queue_free()
	var canhao := (load("res://Entities/InimigoSementeCanhao.tscn") as PackedScene).instantiate() as InimigoSetorialBase
	add_child(canhao)
	var configuracao_spawn: Dictionary = {}
	child_entered_tree.connect(func(filho: Node) -> void:
		if filho is ProjetilInimigo:
			configuracao_spawn["direcao"] = filho.direcao
			configuracao_spawn["velocidade"] = filho.velocidade
			configuracao_spawn["dano"] = filho.dano
	)
	canhao._disparar(Vector2.DOWN, 271.0, 13.0)
	checar(configuracao_spawn.get("direcao") == Vector2.DOWN and configuracao_spawn.get("velocidade") == 271.0 and configuracao_spawn.get("dano") == 13.0, "tiro setorial nasceu antes de ser configurado")
	canhao.queue_free()
	var fonte_drone := FileAccess.get_file_as_string("res://Scripts/InimigoSateliteBerco.gd")
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
