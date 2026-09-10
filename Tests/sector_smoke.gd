extends Node


var falhas: Array[String] = []


func verificar(condicao: bool, mensagem: String) -> void:
	if not condicao:
		falhas.append(mensagem)
		push_error("TESTE: " + mensagem)


func _ready() -> void:
	var cena_batalha := load("res://Rooms/Battle_area.tscn") as PackedScene
	verificar(cena_batalha != null, "Battle_area.tscn não carregou")
	if cena_batalha == null:
		get_tree().quit(1)
		return

	var batalha := cena_batalha.instantiate()
	get_tree().root.add_child.call_deferred(batalha)
	await get_tree().process_frame
	get_tree().current_scene = batalha
	await get_tree().process_frame
	await get_tree().process_frame

	verificar(batalha.setor_atual == &"vazio_inicial", "a partida não começou no setor original")
	verificar(batalha.fundo_original.visible, "o fundo original não está visível no primeiro setor")
	verificar(not batalha.fundo_setor.visible, "um fundo temático apareceu no começo")
	verificar(not batalha.escolha_setor_ativa, "a escolha de setor apareceu no início")
	verificar(batalha.proximo_nivel_boss == 10, "o primeiro boss não está configurado para o nível 10")

	# O Modelo O usa apenas a estrela enviada; nave e rastro recebem a paleta.
	batalha.player.modelo_visual_nave = &"c07_modelo_o"
	batalha.player.cor_visual_nave = &"c11_ciano"
	batalha.player.rastro_visual_nave = &"c21_rastro_estelar_o"
	batalha.player.aplicar_personalizacao_nave()
	verificar(batalha.player.sprite_modelo_o.visible, "o Modelo O não apareceu")
	verificar(not batalha.player.corpo_visual.visible, "a nave poligonal ficou sobre o Modelo O")
	verificar(
		batalha.player.sprite_modelo_o.texture.resource_path.ends_with("UI/modelo_o.svg"),
		"o Modelo O não usa a estrela enviada"
	)
	var material_modelo_o := batalha.player.sprite_modelo_o.material as ShaderMaterial
	var cor_aplicada: Variant = material_modelo_o.get_shader_parameter("cor_estrela")
	verificar(
		cor_aplicada is Color and (cor_aplicada as Color).is_equal_approx(Color("39dcff")),
		"a paleta escolhida não chegou à estrela do Modelo O"
	)
	var material_estrelas := batalha.player.particulas_rastro_modelo_o.process_material as ParticleProcessMaterial
	verificar(
		is_instance_valid(material_estrelas) and material_estrelas.scale_max <= 0.076,
		"as estrelas do rastro do Modelo O não ficaram pequenas"
	)
	batalha.player.modelo_visual_nave = &"c01_modelo_padrao"
	batalha.player.cor_visual_nave = &"c10_verde_original"
	batalha.player.rastro_visual_nave = &"c20_rastro_padrao"
	batalha.player.aplicar_personalizacao_nave()
	verificar(not batalha.player.sprite_modelo_o.visible, "o Modelo O não saiu ao restaurar o padrão")
	verificar(batalha.player.corpo_visual.visible, "a nave padrão não voltou após o teste do Modelo O")

	batalha.tutorial_ativo = false
	batalha.player.nivel_atual = 10
	batalha.invocar_boss_do_setor()
	await get_tree().process_frame
	verificar(batalha.boss_atual_id == &"pet0", "o boss do nível 10 não é o PET-0")
	verificar(batalha.boss_ativo is BossPet0, "a cena criada no nível 10 não é BossPet0")

	if is_instance_valid(batalha.boss_ativo):
		batalha.boss_ativo.Vida = 0.0
		batalha.boss_ativo.morrer()
	await get_tree().create_timer(3.2, true).timeout
	verificar(&"vazio_inicial" in batalha.setores_concluidos, "o primeiro setor não foi marcado como concluído")
	verificar(not batalha.escolha_setor_ativa, "a transição linear permaneceu bloqueando a partida")
	verificar(batalha.setor_atual == &"constelacao_amparo", "o ciclo não avançou para a Constelação do Amparo")
	verificar(batalha.proximo_nivel_boss == 20, "o próximo boss não foi movido para o nível 20")

	var dados_setores = load("res://Scripts/SectorData.gd")
	verificar(
		dados_setores.ORDEM_CICLO == [
			&"vazio_inicial", &"constelacao_amparo", &"no_ametista",
			&"florescimento", &"lua_colheita"
		],
		"a ordem única dos cinco bosses foi alterada"
	)
	for caminho_inimigo in [
		"res://Entities/InimigoCentelhaGuia.tscn", "res://Entities/InimigoEloDourado.tscn",
		"res://Entities/InimigoPrismaAmparo.tscn", "res://Entities/InimigoSateliteBerco.tscn",
		"res://Entities/InimigoPulsoSolar.tscn", "res://Entities/InimigoFitaVioleta.tscn",
		"res://Entities/InimigoNoFlutuante.tscn", "res://Entities/InimigoEcoAmetista.tscn",
		"res://Entities/InimigoLaminaIris.tscn", "res://Entities/InimigoCasuloPrismatico.tscn",
		"res://Entities/InimigoBrotoPrimaveril.tscn", "res://Entities/InimigoSementeCanhao.tscn",
		"res://Entities/InimigoPolenErrante.tscn", "res://Entities/InimigoCipoEspiral.tscn",
		"res://Entities/InimigoFrutoExplosivo.tscn", "res://Entities/InimigoFragmentoLunar.tscn",
		"res://Entities/InimigoCentelhaSolar.tscn", "res://Entities/InimigoMeteoroJovem.tscn",
		"res://Entities/InimigoEcoGravitacional.tscn", "res://Entities/InimigoSateliteCoroa.tscn",
	]:
		var cena_setorial := load(caminho_inimigo) as PackedScene
		verificar(cena_setorial != null, "inimigo setorial ausente: " + caminho_inimigo)
		if cena_setorial != null:
			var inimigo_setorial := cena_setorial.instantiate() as InimigoSetorial
			batalha.add_child(inimigo_setorial)
			inimigo_setorial.global_position = Vector2(700, 260)
			await get_tree().physics_frame
			verificar(is_instance_valid(inimigo_setorial.visual), "inimigo setorial sem visual próprio")
			inimigo_setorial.queue_free()
	var opcoes: Array[StringName] = dados_setores.sortear_opcoes(
		batalha.setores_concluidos, batalha.setor_atual, 2
	)
	verificar(opcoes.size() == 2, "a rota não ofereceu duas opções")
	verificar(&"vazio_inicial" not in opcoes, "o setor inicial foi repetido nas rotas")

	batalha.aplicar_setor(&"florescimento")
	verificar(not batalha.fundo_original.visible, "o fundo original permaneceu no setor temático")
	verificar(batalha.fundo_setor.visible, "o fundo minimalista do setor temático não apareceu")
	batalha.player.nivel_atual = 20
	batalha.invocar_boss_do_setor()
	await get_tree().process_frame
	verificar(batalha.boss_atual_id == &"flor_equinocio", "o segundo setor não criou seu próprio boss")
	verificar(batalha.boss_ativo is BossCaosPrimaveril, "o setor floral não criou o Caos Primaveril")
	verificar(not (batalha.boss_ativo is BossPet0), "o PET-0 foi repetido no segundo setor")
	if ResourceLoader.exists(batalha.CAMINHO_LOTUS_DANCE):
		verificar(
			batalha.tocarmusica.stream.resource_path.ends_with("OST/LotusDance.mp3"),
			"LotusDance não começou na luta do Florecimento"
		)
	else:
		verificar(
			batalha.tocarmusica.stream == batalha.musica_partida_padrao,
			"a ausência opcional de LotusDance removeu a música padrão"
		)

	var cena_sizigia := load("res://Entities/BossEclipseColheita.tscn") as PackedScene
	verificar(cena_sizigia != null, "a cena da Sizígia Eterna não carregou")
	if cena_sizigia != null:
		var sizigia := cena_sizigia.instantiate()
		batalha.add_child(sizigia)
		await get_tree().process_frame
		verificar(sizigia is BossSizigiaEterna, "o Eclipse antigo não foi substituído pela Sizígia Eterna")
		verificar(sizigia.obter_vida_maxima_atual() >= 330.0, "a Lua começou sem a vida de boss principal")
		sizigia.queue_free()
		await get_tree().process_frame

	for caminho in [
		"res://Entities/BossConstelacaoAmparo.tscn",
		"res://Entities/BossNoAmetista.tscn",
	]:
		var cena_boss := load(caminho) as PackedScene
		verificar(cena_boss != null, "%s não carregou" % caminho)
		if cena_boss != null:
			var boss := cena_boss.instantiate()
			batalha.add_child(boss)
			await get_tree().process_frame
			verificar(boss is BossMensal, "%s não usa a base de boss esperada" % caminho)
			verificar(boss.has_method("obter_nome_boss"), "%s não expõe nome no HUD" % caminho)
			boss.queue_free()
			await get_tree().process_frame

	var cena_projetil_inimigo := load("res://Entities/ProjetilInimigo.tscn") as PackedScene
	var projetil_inimigo := cena_projetil_inimigo.instantiate()
	batalha.add_child(projetil_inimigo)
	projetil_inimigo.position = Vector2(100.0, 100.0)
	await get_tree().process_frame
	var visual_inimigo := projetil_inimigo.get_node("Visual") as Polygon2D
	verificar(visual_inimigo.self_modulate.r > 1.0, "o projétil inimigo não recebeu glow")
	verificar(projetil_inimigo.brilho_visual > 1.0, "o glow inimigo não está ajustável")
	projetil_inimigo.queue_free()

	var cena_projetil_player := load("res://Entities/fireball.tscn") as PackedScene
	var projetil_player := cena_projetil_player.instantiate()
	batalha.add_child(projetil_player)
	projetil_player.position = Vector2(100.0, 140.0)
	await get_tree().process_frame
	var visual_player := projetil_player.get_node("Polygon2D") as Polygon2D
	verificar(visual_player.self_modulate.r > 1.0, "o projétil do jogador não recebeu glow")
	verificar(projetil_player.brilho_visual > 1.0, "o glow do jogador não está ajustável")
	projetil_player.queue_free()

	var cena_inimigo_teste := load("res://Entities/InimigoMelee.tscn") as PackedScene
	var inimigo_teste := cena_inimigo_teste.instantiate() as InimigoBase
	inimigo_teste.VidaMaxima = 100.0
	inimigo_teste.process_mode = Node.PROCESS_MODE_DISABLED
	batalha.add_child(inimigo_teste)
	inimigo_teste.global_position = batalha.player.global_position + Vector2(180.0, 0.0)
	await get_tree().process_frame
	var transfusao := (
		load("res://Habilidades/habilidadeTransfusao.tres").duplicate(true)
		as HabilidadeTransfusao
	)
	var vida_inimigo_antes: float = inimigo_teste.Vida
	batalha.player.vida = 40.0
	transfusao.executar(batalha.player)
	verificar(inimigo_teste.Vida < vida_inimigo_antes, "Transfusão não drenou vida do inimigo")
	verificar(batalha.player.vida > 40.0, "Transfusão não curou o jogador com a vida drenada")
	inimigo_teste.queue_free()
	await get_tree().process_frame

	batalha.player.nivel_atual = 4
	batalha.player.xp_necessario = 1000
	batalha.player.xp_atual = 0.0
	batalha.player.niveis_upgrades[&"blindagem"] = 3
	batalha.player.vida = 20.0
	var cena_asteroide := load("res://Entities/AsteroideBonus.tscn") as PackedScene
	var asteroide := cena_asteroide.instantiate()
	batalha.add_child(asteroide)
	await get_tree().process_frame
	verificar(asteroide.calcular_cura() > asteroide.cura_base, "blindagem não aumenta a cura bônus")
	verificar(asteroide.calcular_xp() > asteroide.xp_base, "o nível do jogador não aumenta o XP bônus")
	var vida_antes: float = batalha.player.vida
	var xp_antes: float = batalha.player.xp_atual
	asteroide.conceder_recompensa()
	verificar(batalha.player.vida > vida_antes, "o asteroide não concedeu Vida")
	verificar(batalha.player.xp_atual > xp_antes, "o asteroide não concedeu XP")
	var sprites_asteroide := asteroide.find_children("*", "Sprite2D", true, false)
	verificar(sprites_asteroide.size() == 1, "o SVG do asteroide bônus não foi aplicado")
	asteroide.queue_free()
	await get_tree().process_frame

	batalha.caixa_gameover.visible = true
	await get_tree().process_frame
	await get_tree().process_frame
	var botao_gameover := batalha.get_node("GUI/caixa gameover/Tentar de novo") as Button
	verificar(
		get_viewport().gui_get_focus_owner() == botao_gameover,
		"o Game Over não focou o botão para o controle"
	)

	parar_audios(batalha)
	await get_tree().create_timer(0.08).timeout
	batalha.queue_free()
	await get_tree().process_frame

	var cena_loja := load("res://Rooms/Loja.tscn") as PackedScene
	verificar(cena_loja != null, "Loja.tscn não carregou")
	if cena_loja != null:
		var loja := cena_loja.instantiate()
		get_tree().root.add_child(loja)
		get_tree().current_scene = loja
		await get_tree().process_frame
		await get_tree().process_frame
		verificar(loja.rolagem_grade is ScrollContainer, "a grade da loja não possui scroll")
		verificar(loja.rolagem_detalhes is ScrollContainer, "os detalhes da loja não possuem scroll")
		verificar(loja.botoes_habilidades.size() == loja.habilidades.size(), "cartões da loja não estão navegáveis")
		loja.selecionar_categoria(4)
		await get_tree().process_frame
		verificar(loja.painel_filtros_personalizacao.visible, "os filtros de personalização não apareceram")
		verificar(loja.botoes_filtros_personalizacao.size() == 3, "a personalização não possui três aspectos")
		verificar(loja.obter_itens_categoria_atual().size() == 9, "o filtro Modelos não exibiu as nove naves")
		loja._selecionar_filtro_personalizacao(&"cor")
		verificar(loja.obter_itens_categoria_atual().size() == 6, "o filtro Cores não exibiu seis paletas")
		loja._selecionar_filtro_personalizacao(&"rastro")
		verificar(loja.obter_itens_categoria_atual().size() == 4, "o filtro Rastros não exibiu as quatro opções")
		var rastro_modelo_o := loja.obter_itens_categoria_atual()[1] as Dictionary
		verificar(
			StringName(rastro_modelo_o.get("requer_modelo", &"")) == &"c07_modelo_o",
			"o rastro de estrelas não está restrito ao Modelo O"
		)
		loja.selecionar_categoria(0)

		var aba := InputEventAction.new()
		aba.action = &"proxima_aba"
		aba.pressed = true
		loja._unhandled_input(aba)
		verificar(loja.categoria_atual == 1, "R1 não avançou a aba da loja")
		aba.action = &"aba_anterior"
		loja._unhandled_input(aba)
		verificar(loja.categoria_atual == 0, "L1 não voltou a aba da loja")
		await get_tree().process_frame
		await get_tree().process_frame
		if not loja.botoes_habilidades.is_empty():
			loja.botoes_habilidades[0].grab_focus()
			var aceitar := InputEventAction.new()
			aceitar.action = &"ui_accept"
			aceitar.pressed = true
			loja._input(aceitar)
			verificar(not loja.mensagem.text.is_empty(), "X não confirmou a habilidade focada")
		parar_audios(loja)
		await get_tree().create_timer(0.08).timeout
		loja.queue_free()
		await get_tree().process_frame
		await get_tree().process_frame

	if falhas.is_empty():
		print("TESTE OK: setores, Caos Primaveril, projéteis, asteroide, Game Over e loja")
		get_tree().quit(0)
	else:
		print("TESTE FALHOU: %d problema(s)" % falhas.size())
		get_tree().quit(1)


func parar_audios(raiz: Node) -> void:
	for no in raiz.get_children():
		if no is AudioStreamPlayer:
			(no as AudioStreamPlayer).stop()
			(no as AudioStreamPlayer).stream = null
		elif no is AudioStreamPlayer2D:
			(no as AudioStreamPlayer2D).stop()
			(no as AudioStreamPlayer2D).stream = null
		parar_audios(no)
