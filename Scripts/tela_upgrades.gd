extends Control


signal estado_alterado(aberto: bool)


const DadosUpgrades = preload("res://Scripts/UpgradeData.gd")
const CardUpgrade = preload("res://Scripts/UpgradeCardNova.gd")
const IconesControle = preload("res://Scripts/IndicadoresControle.gd")

@export var cena_carta: PackedScene
@export var qtd_cartas: int = 3

@onready var container_antigo: Control = $ContainerCartas

var player: Player
var overlay: ColorRect
var container_cards: HBoxContainer
var indicador: Button
var texto_pontos: Label
var texto_habilidade: Label
var texto_rotas: Label
var dica_menu: HBoxContainer
var botao_fechar: Button
var botao_rerrolar: Button
var opcoes_atuais: Array[StringName] = []
var menu_aberto := false
var time_scale_anterior := 1.0
var mouse_mode_anterior := Input.MOUSE_MODE_HIDDEN
var tween_indicador: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	container_antigo.hide()
	construir_interface()
	Global.dispositivo_alterado.connect(_on_dispositivo_alterado)
	Global.configuracoes_alteradas.connect(_on_configuracoes_alteradas)
	Input.joy_connection_changed.connect(_on_controle_conectado)
	_atualizar_dica_menu()
	call_deferred("conectar_player")


func _process(_delta: float) -> void:
	if menu_aberto:
		if not pode_manter_menu_aberto():
			fechar_menu()
		return

	if not is_instance_valid(indicador):
		return
	indicador.visible = pode_abrir_menu()


func _on_dispositivo_alterado(_tipo: StringName) -> void:
	_atualizar_dica_menu()
	atualizar_indicador()


func _on_controle_conectado(_dispositivo: int, _conectado: bool) -> void:
	_atualizar_dica_menu()
	atualizar_indicador()


func _on_configuracoes_alteradas() -> void:
	_atualizar_dica_menu()
	atualizar_indicador()


func conectar_player() -> void:
	player = get_tree().get_first_node_in_group("player") as Player
	if not is_instance_valid(player):
		push_warning("O menu de melhorias não encontrou o Player.")
		return

	if not player.pontos_upgrade_alterados.is_connected(_on_pontos_alterados):
		player.pontos_upgrade_alterados.connect(_on_pontos_alterados)
	if not player.subiuDeNivel.is_connected(_on_player_subiu_de_nivel):
		player.subiuDeNivel.connect(_on_player_subiu_de_nivel)
	atualizar_indicador()


func construir_interface() -> void:
	overlay = ColorRect.new()
	overlay.name = "OverlayMelhorias"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.005, 0.008, 0.025, 0.94)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	overlay.hide()
	add_child(overlay)

	var faixa_topo := ColorRect.new()
	faixa_topo.position = Vector2(0, 0)
	faixa_topo.size = Vector2(960, 82)
	faixa_topo.color = Color(0.025, 0.045, 0.095, 0.96)
	faixa_topo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(faixa_topo)

	var titulo := Label.new()
	titulo.position = Vector2(32, 12)
	titulo.size = Vector2(400, 34)
	titulo.text = "MATRIZ DE EVOLUÇÃO DA NAVE"
	titulo.add_theme_font_size_override("font_size", 25)
	titulo.add_theme_color_override("font_color", Color(0.58, 0.94, 1.0))
	titulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(titulo)

	texto_habilidade = Label.new()
	texto_habilidade.position = Vector2(32, 43)
	texto_habilidade.size = Vector2(520, 20)
	texto_habilidade.add_theme_font_size_override("font_size", 11)
	texto_habilidade.add_theme_color_override("font_color", Color(0.48, 0.58, 0.76))
	texto_habilidade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(texto_habilidade)

	texto_rotas = Label.new()
	texto_rotas.position = Vector2(32, 64)
	texto_rotas.size = Vector2(896, 16)
	texto_rotas.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	texto_rotas.add_theme_font_size_override("font_size", 10)
	texto_rotas.add_theme_color_override("font_color", Color(0.46, 0.75, 0.92))
	texto_rotas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(texto_rotas)

	texto_pontos = Label.new()
	texto_pontos.position = Vector2(590, 17)
	texto_pontos.size = Vector2(220, 34)
	texto_pontos.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	texto_pontos.add_theme_font_size_override("font_size", 17)
	texto_pontos.add_theme_color_override("font_color", Color(1.0, 0.8, 0.28))
	texto_pontos.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(texto_pontos)

	botao_fechar = Button.new()
	botao_fechar.position = Vector2(830, 15)
	botao_fechar.size = Vector2(98, 38)
	botao_fechar.text = "FECHAR"
	botao_fechar.pressed.connect(fechar_menu)
	botao_fechar.add_theme_stylebox_override(
		"normal", criar_estilo_botao(Color(0.08, 0.1, 0.18), Color(0.34, 0.44, 0.65))
	)
	botao_fechar.add_theme_stylebox_override(
		"hover", criar_estilo_botao(Color(0.13, 0.16, 0.27), Color(0.55, 0.8, 1.0))
	)
	botao_fechar.add_theme_stylebox_override(
		"focus", criar_estilo_botao(Color(0.11, 0.14, 0.24), Color(0.48, 0.76, 1.0))
	)
	overlay.add_child(botao_fechar)

	container_cards = HBoxContainer.new()
	container_cards.position = Vector2(70, 88)
	container_cards.size = Vector2(820, 336)
	container_cards.add_theme_constant_override("separation", 20)
	container_cards.alignment = BoxContainer.ALIGNMENT_CENTER
	container_cards.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(container_cards)

	botao_rerrolar = Button.new()
	botao_rerrolar.position = Vector2(382, 438)
	botao_rerrolar.size = Vector2(196, 40)
	botao_rerrolar.text = "RECALCULAR OPÇÕES"
	botao_rerrolar.pressed.connect(_on_rerrolar_pressed)
	botao_rerrolar.add_theme_stylebox_override(
		"normal", criar_estilo_botao(Color(0.06, 0.15, 0.22), Color(0.2, 0.75, 1.0))
	)
	botao_rerrolar.add_theme_stylebox_override(
		"hover", criar_estilo_botao(Color(0.09, 0.25, 0.34), Color(0.55, 0.94, 1.0))
	)
	botao_rerrolar.add_theme_stylebox_override(
		"focus", criar_estilo_botao(Color(0.08, 0.21, 0.30), Color(0.48, 0.9, 1.0))
	)
	overlay.add_child(botao_rerrolar)

	dica_menu = HBoxContainer.new()
	dica_menu.position = Vector2(120, 492)
	dica_menu.size = Vector2(720, 24)
	dica_menu.alignment = BoxContainer.ALIGNMENT_CENTER
	dica_menu.add_theme_constant_override("separation", 5)
	dica_menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(dica_menu)

	indicador = Button.new()
	indicador.name = "IndicadorMelhorias"
	indicador.position = Vector2(18, 16)
	indicador.size = Vector2(220, 44)
	indicador.pivot_offset = indicador.size * 0.5
	indicador.mouse_filter = Control.MOUSE_FILTER_STOP
	indicador.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	indicador.pressed.connect(abrir_menu)
	indicador.expand_icon = false
	indicador.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	indicador.add_theme_font_size_override("font_size", 12)
	indicador.add_theme_stylebox_override(
		"normal", criar_estilo_botao(Color(0.08, 0.08, 0.18), Color(0.5, 0.72, 1.0))
	)
	indicador.add_theme_stylebox_override(
		"hover", criar_estilo_botao(Color(0.13, 0.16, 0.3), Color(0.85, 0.95, 1.0))
	)
	indicador.add_theme_stylebox_override(
		"focus", criar_estilo_botao(Color(0.11, 0.14, 0.27), Color(0.72, 0.9, 1.0))
	)
	indicador.hide()
	add_child(indicador)


func criar_estilo_botao(cor: Color, borda: Color) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = cor
	estilo.border_color = borda
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(10)
	return estilo


func _atualizar_dica_menu() -> void:
	if not is_instance_valid(dica_menu):
		return
	for filho in dica_menu.get_children():
		dica_menu.remove_child(filho)
		filho.queue_free()

	var texto := Label.new()
	texto.text = "Escolha um mod ou feche o menu para guardar os pontos. Abre/fecha:"
	texto.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	texto.add_theme_font_size_override("font_size", 12)
	texto.add_theme_color_override("font_color", Color(0.44, 0.54, 0.7))
	texto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dica_menu.add_child(texto)

	var icone := IconesControle.textura_para_acao(&"abrir_melhorias")
	if (
		Global.ultimo_dispositivo == &"controle"
		and not Input.get_connected_joypads().is_empty()
		and icone != null
	):
		var imagem := TextureRect.new()
		imagem.custom_minimum_size = Vector2(24, 18)
		imagem.texture = icone
		imagem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		imagem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		imagem.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		imagem.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dica_menu.add_child(imagem)
	else:
		var tecla := Label.new()
		tecla.text = "[TAB]"
		tecla.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		tecla.add_theme_font_size_override("font_size", 12)
		tecla.add_theme_color_override("font_color", Color(0.62, 0.78, 1.0))
		tecla.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dica_menu.add_child(tecla)


func _unhandled_input(event: InputEvent) -> void:
	if menu_aberto and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		fechar_menu()
		return
	if not event.is_action_pressed("abrir_melhorias"):
		return

	get_viewport().set_input_as_handled()
	if menu_aberto:
		fechar_menu()
	else:
		abrir_menu()


func _on_player_subiu_de_nivel() -> void:
	# O menu não abre sozinho. Apenas chama atenção para o ponto pendente.
	atualizar_indicador()
	pulsar_indicador()


func _on_pontos_alterados(_novo_total: int) -> void:
	atualizar_indicador()
	if menu_aberto:
		atualizar_cabecalho()


func atualizar_indicador() -> void:
	if not is_instance_valid(player):
		indicador.hide()
		return

	var pontos := player.pontos_upgrade_pendentes
	indicador.visible = pode_abrir_menu()
	var icone := IconesControle.textura_para_acao(&"abrir_melhorias")
	var usando_controle: bool = (
		Global.ultimo_dispositivo == &"controle"
		and not Input.get_connected_joypads().is_empty()
		and icone != null
	)
	indicador.icon = icone if usando_controle else null
	if Global.dispositivo_mobile():
		indicador.icon = null
		indicador.text = "◆  MELHORIAS: %d" % pontos
	else:
		indicador.text = (
			"◆  MELHORIAS: %d" % pontos
			if usando_controle
			else "◆  MELHORIAS: %d  [TAB]" % pontos
		)


func pulsar_indicador() -> void:
	if not indicador.visible:
		return
	if tween_indicador and tween_indicador.is_valid():
		tween_indicador.kill()
	indicador.scale = Vector2.ONE
	tween_indicador = create_tween().set_loops(2)
	tween_indicador.tween_property(indicador, "scale", Vector2(1.07, 1.07), 0.14)
	tween_indicador.tween_property(indicador, "scale", Vector2.ONE, 0.18)


func abrir_menu() -> void:
	if menu_aberto or not pode_abrir_menu():
		return

	menu_aberto = true
	Global.definir_emulacao_mouse_mobile(true)
	time_scale_anterior = Engine.time_scale
	mouse_mode_anterior = Input.mouse_mode
	Engine.time_scale = 0.0
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	overlay.show()
	indicador.hide()
	estado_alterado.emit(true)
	atualizar_cabecalho()
	mostrar_opcoes()


func fechar_menu() -> void:
	if not menu_aberto:
		return

	menu_aberto = false
	get_viewport().gui_release_focus()
	overlay.hide()
	estado_alterado.emit(false)
	Engine.time_scale = maxf(time_scale_anterior, 0.01)
	Input.set_mouse_mode(mouse_mode_anterior)
	Global.definir_emulacao_mouse_mobile(false)
	limpar_cards()
	atualizar_indicador()


func esta_aberta() -> bool:
	return menu_aberto


func pode_abrir_menu() -> bool:
	return (
		is_instance_valid(player)
		and player.vivo
		and player.vida > 0.0
		and not player.UsandoHabilidade
		and not Input.is_action_pressed("Habilidade")
		and player.pontos_upgrade_pendentes > 0
		and not get_tree().paused
		and not menu_aberto
	)


func pode_manter_menu_aberto() -> bool:
	return (
		is_instance_valid(player)
		and player.vivo
		and player.vida > 0.0
		and not player.UsandoHabilidade
	)


func atualizar_cabecalho() -> void:
	texto_pontos.text = "PONTOS PENDENTES: %d" % player.pontos_upgrade_pendentes
	var nome_habilidade := "NENHUMA"
	if player.HabilidadeEquipada:
		nome_habilidade = player.HabilidadeEquipada.Nome
	texto_habilidade.text = (
		"HABILIDADE: %s   •   ESCOLHA UM ESTILO E APROFUNDE A CONSTRUÇÃO" %
		nome_habilidade.to_upper()
	)
	texto_rotas.text = "CONSTRUÇÃO ATUAL   •   " + DadosUpgrades.resumo_rotas(
		player.niveis_upgrades,
		player.HabilidadeEquipada,
		player.arma_monthly
	)
	_atualizar_botao_rerrolar()


func mostrar_opcoes(evitar: Array[StringName] = []) -> void:
	if not menu_aberto or not is_instance_valid(player):
		return

	limpar_cards()
	opcoes_atuais = DadosUpgrades.sortear(
		player.niveis_upgrades,
		qtd_cartas,
		player.HabilidadeEquipada,
		evitar,
		player.arma_monthly
	)
	for id in opcoes_atuais:
		var dados := DadosUpgrades.obter(id, player.HabilidadeEquipada)
		var card = CardUpgrade.new()
		card.configurar(
			id,
			dados,
			DadosUpgrades.nivel(id, player.niveis_upgrades),
			DadosUpgrades.texto_requisitos(
				id,
				player.niveis_upgrades,
				player.HabilidadeEquipada,
				player.arma_monthly
			)
		)
		card.escolhido.connect(_on_upgrade_escolhido)
		container_cards.add_child(card)

	configurar_navegacao_controle()

	if container_cards.get_child_count() > 0:
		var primeiro_card = container_cards.get_child(0)
		if primeiro_card.botao:
			call_deferred("_focar_controle_se_valido", primeiro_card.botao)


func _on_rerrolar_pressed() -> void:
	if not menu_aberto or not is_instance_valid(player):
		return
	if not player.gastar_reroll_upgrade():
		_atualizar_botao_rerrolar()
		return
	var anteriores: Array[StringName] = opcoes_atuais.duplicate()
	_atualizar_botao_rerrolar()
	mostrar_opcoes(anteriores)


func _atualizar_botao_rerrolar() -> void:
	if not is_instance_valid(botao_rerrolar) or not is_instance_valid(player):
		return
	var restantes: int = player.rerolls_upgrades_restantes
	botao_rerrolar.text = "RECALCULAR (%d)" % restantes
	botao_rerrolar.disabled = restantes <= 0
	botao_rerrolar.focus_mode = (
		Control.FOCUS_NONE if botao_rerrolar.disabled else Control.FOCUS_ALL
	)


func configurar_navegacao_controle() -> void:
	var botoes: Array[Button] = []
	for card in container_cards.get_children():
		if card.botao is Button:
			botoes.append(card.botao as Button)
	if botoes.is_empty():
		call_deferred("_focar_controle_se_valido", botao_fechar)
		return

	var destino_inferior: Button = (
		botao_rerrolar if not botao_rerrolar.disabled else botao_fechar
	)
	for indice in range(botoes.size()):
		var botao := botoes[indice]
		var anterior := botoes[(indice - 1 + botoes.size()) % botoes.size()]
		var proximo := botoes[(indice + 1) % botoes.size()]
		botao.focus_neighbor_left = botao.get_path_to(anterior)
		botao.focus_neighbor_right = botao.get_path_to(proximo)
		botao.focus_neighbor_top = botao.get_path_to(botao_fechar)
		botao.focus_neighbor_bottom = botao.get_path_to(destino_inferior)

	botao_fechar.focus_neighbor_bottom = botao_fechar.get_path_to(botoes[0])
	botao_fechar.focus_neighbor_top = botao_fechar.get_path_to(destino_inferior)
	if not botao_rerrolar.disabled:
		botao_rerrolar.focus_neighbor_top = botao_rerrolar.get_path_to(botoes[0])
		botao_rerrolar.focus_neighbor_bottom = botao_rerrolar.get_path_to(botao_fechar)


func _focar_controle_se_valido(controle: Control) -> void:
	if (
		menu_aberto
		and is_instance_valid(controle)
		and controle.is_inside_tree()
		and controle.is_visible_in_tree()
	):
		controle.grab_focus()


func limpar_cards() -> void:
	for filho in container_cards.get_children():
		container_cards.remove_child(filho)
		filho.queue_free()
	opcoes_atuais.clear()


func _on_upgrade_escolhido(id: StringName) -> void:
	if not player.comprar_upgrade(id):
		mostrar_opcoes()
		return

	Global.vibrar_controle(0.18, 0.35, 0.12)

	if player.pontos_upgrade_pendentes > 0:
		atualizar_cabecalho()
		mostrar_opcoes()
	else:
		fechar_menu()
