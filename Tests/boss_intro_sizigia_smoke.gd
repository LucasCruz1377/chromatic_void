extends Node

var falhas: Array[String] = []


func checar(condicao: bool, mensagem: String) -> void:
	if condicao:
		return
	falhas.append(mensagem)
	push_error("INTROS E SIZÍGIA: " + mensagem)


func _ready() -> void:
	var sons := [
		"res://sounds/Bosses/snd_intro_pet.wav",
		"res://sounds/Bosses/snd_intro_boss2.wav",
		"res://sounds/Bosses/contrafase_corda.wav",
		"res://sounds/Bosses/snd_intro_flor.wav",
		"res://sounds/Bosses/snd_intro_sizigia.wav",
	]
	for caminho in sons:
		checar(ResourceLoader.exists(caminho), "som ausente: " + caminho)
		checar(load(caminho) is AudioStream, "som inválido: " + caminho)

	var nomes_esperados: Dictionary = {
		&"pet0": "PET-0",
		&"constelacao_amparo": "CONSTELAÇÃO DO AMPARO",
		&"contrafase": "CONTRAFASE",
		&"flor_equinocio": "CAOS PRIMAVERIL",
		&"eclipse_colheita": "SIZÍGIA ETERNA",
	}
	for id in nomes_esperados:
		checar(
			BossIntroPortrait.nome_do_boss(id) == nomes_esperados[id],
			"nome incorreto na intro de " + String(id)
		)
		var retrato := BossIntroPortrait.new()
		retrato.size = Vector2(300.0, 230.0)
		retrato.configurar(id, Color.WHITE)
		add_child(retrato)
		retrato.queue_redraw()
		await get_tree().process_frame
		retrato.queue_free()

	var fonte_intro := FileAccess.get_file_as_string("res://Scripts/battle_area.gd")
	checar(
		"visual_original.duplicate()" not in fonte_intro,
		"a intro ainda duplica o visual completo do boss"
	)
	checar(
		"cena.instantiate()" not in fonte_intro.substr(
			fonte_intro.find("func _mostrar_intro_boss"),
			fonte_intro.find("func limpar_inimigos_sem_recompensa") - fonte_intro.find("func _mostrar_intro_boss")
		),
		"a intro ainda instancia bosses fora da arena"
	)

	var batalha := (load("res://Rooms/Battle_area.tscn") as PackedScene).instantiate()
	get_tree().root.add_child.call_deferred(batalha)
	await get_tree().process_frame
	get_tree().current_scene = batalha
	checar(
		batalha.has_node("BossIntroThemeController"),
		"a arena não possui o controlador das intros temáticas"
	)

	var flor := (load("res://Entities/BossFlorEquinocio.tscn") as PackedScene).instantiate()
	batalha.add_child(flor)
	await get_tree().process_frame
	checar(flor.Dano >= 48.0, "o dano do Florecimento não foi aumentado")
	checar(
		flor.get_shape_owners().size() == 13,
		"a área vulnerável do Florecimento não cobre o corpo visível"
	)
	checar(
		flor.has_node("FlowerPhaseController"),
		"a Dança dos Caules não recebeu o controlador de duas execuções"
	)

	var sizigia := (load("res://Entities/BossEclipseColheita.tscn") as PackedScene).instantiate()
	batalha.add_child(sizigia)
	await get_tree().process_frame
	checar(sizigia.Dano >= 42.0, "o dano-base da Sizígia não foi aumentado")
	checar(
		is_equal_approx(sizigia.get_node("CollisionShape2D").shape.radius, 108.0 * sizigia.visual_fase.scale.x),
		"a área vulnerável da Sizígia não cobre o astro visível"
	)
	checar(
		sizigia.has_node("SizigiaFinalController"),
		"a Sizígia não recebeu o controlador das mecânicas finais"
	)
	var controlador := sizigia.get_node_or_null("SizigiaFinalController")
	if is_instance_valid(controlador):
		checar(controlador == sizigia.golpes, "Sizígia não possui um controlador único")

	flor.queue_free()
	sizigia.queue_free()
	for audio in batalha.find_children("*", "AudioStreamPlayer", true, false):
		(audio as AudioStreamPlayer).stop()
	for audio in batalha.find_children("*", "AudioStreamPlayer2D", true, false):
		(audio as AudioStreamPlayer2D).stop()
	batalha.queue_free()
	await get_tree().create_timer(0.25, true, false, true).timeout

	if falhas.is_empty():
		print("TESTE OK: intros temáticas, Florecimento e Sizígia final")
		get_tree().quit(0)
	else:
		get_tree().quit(1)
