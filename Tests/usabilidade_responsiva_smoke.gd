extends Node


var falhas: Array[String] = []
var objetos_teste: Array[Node] = []


func verificar(condicao: bool, mensagem: String) -> void:
	if not condicao:
		falhas.append(mensagem)
		push_error("USABILIDADE/RESPONSIVIDADE: " + mensagem)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	testar_limites_area_batalha()
	await testar_tela_inicial()
	await testar_menu_upgrades_e_boss()
	await testar_loja_mobile()
	await finalizar()


func testar_limites_area_batalha() -> void:
	var ultrawide := Global.calcular_retangulo_area_visivel(Vector2(1280, 540))
	verificar(
		ultrawide.position.is_equal_approx(Vector2(-160, 0))
		and ultrawide.size.is_equal_approx(Vector2(1280, 540)),
		"a arena ultrawide ainda ficou limitada a 960x540"
	)
	var vertical := Global.calcular_retangulo_area_visivel(Vector2(720, 1280))
	verificar(
		is_equal_approx(vertical.size.x, 960.0) and vertical.size.y > 540.0,
		"a arena vertical não expandiu a altura lógica"
	)


func testar_tela_inicial() -> void:
	var cena := load("res://Rooms/TelaInicial.tscn") as PackedScene
	var tela := cena.instantiate() as Node2D
	var atualizacao := tela.get_node("JanelaAtualizacao")
	atualizacao.verificar_automaticamente = false
	get_tree().root.add_child.call_deferred(tela)
	objetos_teste.append(tela)
	await get_tree().process_frame
	await get_tree().process_frame

	var botao := tela.get_node_or_null("CanvasLayer/CaixaMenu2/Achievements") as Button
	verificar(is_instance_valid(botao), "o botão de conquistas não existe na tela inicial")
	var cursor_layer := tela.get_node_or_null("CursorLayer") as CanvasLayer
	verificar(
		is_instance_valid(cursor_layer) and cursor_layer.layer > 180,
		"o cursor personalizado não está acima dos botões e janelas"
	)
	tela._on_achievements_pressed()
	await get_tree().process_frame
	verificar(tela.conquistas_abertas, "a janela de conquistas não abriu")
	verificar(
		tela.lista_conquistas.get_child_count() == Global.CONQUISTAS.size(),
		"a janela não exibiu todas as conquistas cadastradas"
	)
	tela._fechar_menu_conquistas()
	verificar(not tela.conquistas_abertas, "a janela de conquistas não fechou")
	parar_audios(tela)
	tela.queue_free()
	await get_tree().process_frame


func testar_menu_upgrades_e_boss() -> void:
	var cena := load("res://Rooms/Battle_area.tscn") as PackedScene
	var batalha := cena.instantiate() as Node2D
	get_tree().root.add_child.call_deferred(batalha)
	objetos_teste.append(batalha)
	await get_tree().process_frame
	await get_tree().process_frame
	batalha.tutorial_ativo = false
	batalha.get_node("GUI")._ajustar_hud_responsivo()
	var centro_hud := Global.obter_retangulo_area_visivel(18.0).get_center().x
	var barra_vida := batalha.get_node("GUI/Barra_vida") as TextureProgressBar
	var barra_xp := batalha.get_node("GUI/Barra_xp") as TextureProgressBar
	verificar(
		is_equal_approx(barra_vida.position.x + barra_vida.size.x * 0.5, centro_hud)
		and is_equal_approx(barra_xp.position.x + barra_xp.size.x * 0.5, centro_hud),
		"as barras de vida e XP não compartilham o centro seguro"
	)
	verificar(
		is_equal_approx(barra_vida.size.x, barra_xp.size.x),
		"a vida e o XP não usam a mesma largura responsiva"
	)
	verificar(
		barra_vida.fill_mode == TextureProgressBar.FILL_BILINEAR_LEFT_AND_RIGHT
		and barra_xp.fill_mode == TextureProgressBar.FILL_BILINEAR_LEFT_AND_RIGHT,
		"as barras não crescem e diminuem a partir do centro"
	)

	var upgrades := batalha.get_node("GUI/TelaUpgrades") as Control
	upgrades._aplicar_layout_responsivo(Vector2(1280, 540))
	verificar(
		is_equal_approx(upgrades.painel_responsivo.position.x, 160.0),
		"os três upgrades continuam amontoados no lado esquerdo em ultrawide"
	)
	upgrades._aplicar_layout_responsivo(Vector2(640, 360))
	var fim_painel: Vector2 = (
		upgrades.painel_responsivo.position
		+ Global.TAMANHO_BASE_JOGO * upgrades.painel_responsivo.scale
	)
	verificar(
		upgrades.painel_responsivo.position.x >= 0.0
		and upgrades.painel_responsivo.position.y >= 0.0
		and fim_painel.x <= 640.1 and fim_painel.y <= 360.1,
		"o menu de upgrades saiu da tela numa resolução pequena"
	)

	batalha._criar_boss(&"flor_equinocio", 1, true)
	verificar(
		is_equal_approx(batalha.boss_hud.anchor_left, 0.5)
		and is_equal_approx(batalha.boss_hud.anchor_right, 0.5)
		and is_equal_approx(batalha.boss_hud.offset_left, -220.0)
		and is_equal_approx(batalha.boss_hud.offset_right, 220.0),
		"a barra do boss não está ancorada no centro do viewport"
	)
	var boss := batalha.boss_ativo as InimigoBase
	verificar(is_instance_valid(boss), "o Florecimento não pôde ser criado no teste")
	if is_instance_valid(boss):
		var visual := boss.get_node("Visual") as CanvasItem
		batalha.registrar_visual_boss_antes_pausa()
		boss.hide()
		visual.hide()
		boss.modulate.a = 0.0
		batalha.restaurar_visual_boss_durante_pausa()
		verificar(
			boss.visible and visual.visible and boss.modulate.a > 0.99,
			"o estado visual do Florecimento não foi preservado ao pausar"
		)
	parar_audios(batalha)
	batalha.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame


func testar_loja_mobile() -> void:
	var cena := load("res://Rooms/Loja.tscn") as PackedScene
	var loja := cena.instantiate() as Control
	get_tree().root.add_child.call_deferred(loja)
	objetos_teste.append(loja)
	await get_tree().process_frame
	await get_tree().process_frame
	loja._aplicar_layout_responsivo(Vector2(960, 540), true)
	verificar(not loja.conteudo_principal.vertical, "a descrição da loja mobile não permaneceu à direita")
	verificar(
		loja.rolagem_grade.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO,
		"a grade mobile não permite rolagem"
	)
	verificar(
		loja.rolagem_grade.get_v_scroll_bar().custom_minimum_size.x >= 22.0,
		"o slider da grade mobile continua pequeno"
	)
	verificar(
		loja.rolagem_detalhes.get_v_scroll_bar().custom_minimum_size.x <= 10.0,
		"a barra da descrição ainda ocupa espaço demais do texto"
	)
	verificar(
		loja.painel_detalhes.custom_minimum_size.x > 0.0,
		"o painel de descrição mobile deixou de ocupar a direita"
	)
	parar_audios(loja)
	loja.queue_free()
	await get_tree().process_frame


func parar_audios(raiz: Node) -> void:
	for no in raiz.get_children():
		if no is AudioStreamPlayer:
			(no as AudioStreamPlayer).stop()
			(no as AudioStreamPlayer).stream = null
		elif no is AudioStreamPlayer2D:
			(no as AudioStreamPlayer2D).stop()
			(no as AudioStreamPlayer2D).stream = null
		parar_audios(no)


func finalizar() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	for objeto in objetos_teste:
		if is_instance_valid(objeto):
			objeto.queue_free()
	await get_tree().process_frame
	if falhas.is_empty():
		print("TESTE OK: conquistas, cursor, pausa e layouts responsivos")
		get_tree().quit(0)
	else:
		print("TESTE FALHOU: %d problema(s) de usabilidade/responsividade" % falhas.size())
		get_tree().quit(1)
