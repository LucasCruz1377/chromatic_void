extends Node


var falhas: Array[String] = []


func verificar(condicao: bool, mensagem: String) -> void:
	if not condicao:
		falhas.append(mensagem)
		push_error("CONTEÚDO NOVO: " + mensagem)


func _ready() -> void:
	var cena_batalha := load("res://Rooms/Battle_area.tscn") as PackedScene
	var batalha := cena_batalha.instantiate()
	get_tree().root.add_child.call_deferred(batalha)
	await get_tree().process_frame
	get_tree().current_scene = batalha
	await get_tree().process_frame
	batalha.tutorial_ativo = false

	batalha.player.aplicar_poder_monthly(&"clone", Color("ff62ce"), 1.0)
	await get_tree().process_frame
	verificar(get_tree().get_nodes_in_group("ajudante_clone").size() == 1, "Clone Enganador não invocou seu eco temporário")
	batalha.player.aplicar_poder_monthly(&"protetor", Color("ffd65c"), 1.0)
	await get_tree().process_frame
	verificar(get_tree().get_nodes_in_group("ajudante_guardiao").size() == 1, "Espírito Protetor não invocou seu guardião")

	var cena_tiro := load("res://Entities/fireball.tscn") as PackedScene
	var projetil := cena_tiro.instantiate()
	batalha.add_child(projetil)
	projetil.global_position = Vector2(300, 300)
	projetil.rotation = 0.0
	projetil.configurar(1.0, 300.0, 1.0, 0, 4.0, 0, 0, batalha.player, cena_tiro)
	var alvo := Node2D.new()
	alvo.add_to_group("inimigo")
	batalha.add_child(alvo)
	alvo.global_position = Vector2(430, 300)
	projetil.definir_alvo_homing(alvo)
	verificar(projetil.alvo_homing == alvo, "o comportamento antigo do tiro teleguiado não foi restaurado")

	var setores = load("res://Scripts/SectorData.gd")
	var ids_antigos := [&"seguidor", &"melee", &"investida", &"tanque", &"atirador"]
	for setor_id in [&"constelacao_amparo", &"no_ametista", &"florescimento", &"lua_colheita"]:
		var dados: Dictionary = setores.obter(setor_id)
		verificar((dados.get("inimigos", []) as Array).size() == 5, "%s não tem cinco inimigos temáticos" % setor_id)
		for entrada in dados.get("inimigos", []):
			verificar(StringName(entrada[0]) not in ids_antigos, "%s ainda mistura inimigo antigo" % setor_id)

	for boss_path in ["res://Entities/BossConstelacaoAmparo.tscn", "res://Entities/BossNoAmetista.tscn"]:
		var cena_boss := load(boss_path) as PackedScene
		verificar(cena_boss != null, "boss novo não carregou: " + boss_path)

	for conquista in [&"combo_100", &"pontos_1000000", &"pontos_5000000", &"pontos_10000000", &"pontos_20000000", &"pontos_25000000"]:
		verificar(Global.CONQUISTAS.has(conquista), "conquista ausente: %s" % conquista)

	for no in get_tree().get_nodes_in_group("ajudante_clone") + get_tree().get_nodes_in_group("ajudante_guardiao"):
		if is_instance_valid(no):
			no.queue_free()
	projetil.queue_free()
	alvo.queue_free()
	for audio in batalha.find_children("*", "AudioStreamPlayer", true, false):
		(audio as AudioStreamPlayer).stop()
	for audio2d in batalha.find_children("*", "AudioStreamPlayer2D", true, false):
		(audio2d as AudioStreamPlayer2D).stop()
	batalha.queue_free()
	await get_tree().process_frame
	if falhas.is_empty():
		print("TESTE OK: ajudantes, tiro antigo, setores e conquistas")
		get_tree().quit(0)
	else:
		get_tree().quit(1)
