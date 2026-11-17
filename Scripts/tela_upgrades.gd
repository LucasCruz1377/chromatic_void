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
var painel_responsivo: Control
var container_cards: HBoxContainer
var indicador: Button
var texto_pontos: Label
var painel_descricao: Control
var nome_melhoria: Label
var descricao_melhoria: Label
var dica_confirmacao: Label
var linha_destaque: ColorRect
var upgrade_previsualizado: StringName = &""
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
	get_viewport().size_changed.connect(_on_tamanho_viewport_alterado)
	_atualizar_dica_menu()
	_aplicar_layout_responsivo()
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
	definir_player_local(get_tree().get_first_node_in_group("player") as Player)


func definir_player_local(novo_player: Player) -> void:
	if is_instance_valid(player):
		if player.pontos_upgrade_alterados.is_connected(_on_pontos_alterados):
			player.pontos_upgrade_alterados.disconnect(_on_pontos_alterados)
		if player.subiuDeNivel.is_connected(_on_player_subiu_de_nivel):
			player.subiuDeNivel.disconnect(_on_player_subiu_de_nivel)
	player = novo_player
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
	overlay.z_index = 10
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.015, 0.02, 0.065, 0.98)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	overlay.hide()
	add_child(overlay)

	painel_responsivo = Control.new()
	painel_responsivo.name = "PainelResponsivoMelhorias"
	painel_responsivo.size = Global.TAMANHO_BASE_JOGO
	painel_responsivo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(painel_responsivo)

	var titulo := Label.new()
	titulo.position = Vector2(180, 18)
	titulo.size = Vector2(600, 36)
	titulo.text = tr("MELHORIAS")
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 28)
	titulo.add_theme_color_override("font_color", Color(0.92, 0.95, 1.0))
	painel_responsivo.add_child(titulo)

	var contadores := HBoxContainer.new()
	contadores.position = Vector2(280, 56)
	contadores.size = Vector2(400, 28)
	contadores.alignment = BoxContainer.ALIGNMENT_CENTER
	contadores.add_theme_constant_override("separation", 14)
	painel_responsivo.add_child(contadores)

	texto_pontos = Label.new()
	texto_pontos.add_theme_font_size_override("font_size", 12)
	texto_pontos.add_theme_color_override("font_color", Color(0.68, 0.72, 0.83))
	contadores.add_child(texto_pontos)
	var separador := Label.new()
	separador.text = "•"
	separador.add_theme_font_size_override("font_size", 12)
	separador.add_theme_color_override("font_color", Color(0.38, 0.42, 0.6))
	contadores.add_child(separador)

	botao_rerrolar = Button.new()
	botao_rerrolar.name = "Rerolls"
	botao_rerrolar.flat = true
	botao_rerrolar.custom_minimum_size = Vector2(96, 28)
	botao_rerrolar.add_theme_font_size_override("font_size", 12)
	botao_rerrolar.add_theme_color_override("font_color", Color(0.68, 0.72, 0.83))
	botao_rerrolar.add_theme_color_override("font_hover_color", Color(0.45, 0.94, 1.0))
	botao_rerrolar.add_theme_color_override("font_focus_color", Color(0.45, 0.94, 1.0))
	for estado in ["normal", "hover", "pressed", "disabled"]:
		botao_rerrolar.add_theme_stylebox_override(estado, StyleBoxEmpty.new())
	botao_rerrolar.pressed.connect(_on_rerrolar_pressed)
	contadores.add_child(botao_rerrolar)

	botao_fechar = Button.new()
	botao_fechar.position = Vector2(856, 24)
	botao_fechar.size = Vector2(80, 32)
	botao_fechar.text = tr("FECHAR")
	botao_fechar.flat = true
	botao_fechar.add_theme_font_size_override("font_size", 10)
	botao_fechar.pressed.connect(fechar_menu)
	painel_responsivo.add_child(botao_fechar)

	container_cards = HBoxContainer.new()
	container_cards.name = "OpcoesHexagonais"
	container_cards.position = Vector2(40, 182)
	container_cards.size = Vector2(CardUpgrade.TAMANHO_CARD.x * 3, CardUpgrade.TAMANHO_CARD.y)
	container_cards.add_theme_constant_override("separation", 0)
	container_cards.alignment = BoxContainer.ALIGNMENT_CENTER
	container_cards.mouse_filter = Control.MOUSE_FILTER_IGNORE
	painel_responsivo.add_child(container_cards)

	painel_descricao = Control.new()
	painel_descricao.name = "DescricaoMelhoria"
	painel_descricao.position = Vector2(620, 198)
	painel_descricao.size = Vector2(300, 236)
	painel_descricao.mouse_filter = Control.MOUSE_FILTER_IGNORE
	painel_descricao.hide()
	painel_responsivo.add_child(painel_descricao)

	var coluna_descricao := VBoxContainer.new()
	coluna_descricao.size = painel_descricao.size
	coluna_descricao.add_theme_constant_override("separation", 0)
	coluna_descricao.mouse_filter = Control.MOUSE_FILTER_IGNORE
	painel_descricao.add_child(coluna_descricao)

	nome_melhoria = Label.new()
	nome_melhoria.custom_minimum_size = Vector2(300, 36)
	nome_melhoria.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nome_melhoria.add_theme_font_size_override("font_size", 22)
	nome_melhoria.add_theme_color_override("font_color", Color(0.95, 0.97, 1.0))
	coluna_descricao.add_child(nome_melhoria)

	var margem_linha := MarginContainer.new()
	margem_linha.add_theme_constant_override("margin_top", 12)
	margem_linha.add_theme_constant_override("margin_bottom", 18)
	coluna_descricao.add_child(margem_linha)
	linha_destaque = ColorRect.new()
	linha_destaque.custom_minimum_size = Vector2(90, 2)
	linha_destaque.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	margem_linha.add_child(linha_destaque)

	descricao_melhoria = Label.new()
	descricao_melhoria.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	descricao_melhoria.add_theme_font_size_override("font_size", 16)
	descricao_melhoria.add_theme_color_override("font_color", Color(0.87, 0.9, 0.96))
	coluna_descricao.add_child(descricao_melhoria)

	var margem_confirmacao := MarginContainer.new()
	margem_confirmacao.add_theme_constant_override("margin_top", 24)
	coluna_descricao.add_child(margem_confirmacao)
	dica_confirmacao = Label.new()
	dica_confirmacao.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dica_confirmacao.add_theme_font_size_override("font_size", 12)
	margem_confirmacao.add_child(dica_confirmacao)

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


func _on_tamanho_viewport_alterado() -> void:
	call_deferred("_aplicar_layout_responsivo")


func _aplicar_layout_responsivo(tamanho_teste := Vector2.ZERO) -> void:
	if not is_instance_valid(painel_responsivo):
		return
	var tamanho: Vector2 = tamanho_teste
	if tamanho == Vector2.ZERO:
		tamanho = get_viewport_rect().size
	var escala := minf(
		tamanho.x / Global.TAMANHO_BASE_JOGO.x,
		tamanho.y / Global.TAMANHO_BASE_JOGO.y
	)
	escala = clampf(escala, 0.35, 2.5)
	painel_responsivo.scale = Vector2.ONE * escala
	painel_responsivo.position = (
		tamanho - Global.TAMANHO_BASE_JOGO * escala
	) * 0.5


func criar_estilo_botao(cor: Color, borda: Color) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = cor
	estilo.border_color = borda
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(10)
	return estilo


func _atualizar_dica_menu() -> void:
	if not is_instance_valid(botao_fechar):
		return
	botao_fechar.tooltip_text = tr("Fechar") + " [%s]" % _texto_tecla_melhorias()
	if is_instance_valid(dica_confirmacao):
		dica_confirmacao.text = (
			tr("Toque novamente para escolher.") if Global.dispositivo_mobile()
			else tr("Confirme novamente para escolher.") if Global.ultimo_dispositivo == &"controle"
			else tr("Clique novamente para escolher.")
		)


func _texto_tecla_melhorias() -> String:
	for slot in range(Global.MAX_SLOTS_CONTROLE):
		var evento := Global.obter_evento_mapeado(&"abrir_melhorias", slot)
		if not evento is InputEventKey:
			continue
		var tecla := evento as InputEventKey
		var codigo := tecla.physical_keycode if tecla.physical_keycode != KEY_NONE else tecla.keycode
		var nome := OS.get_keycode_string(codigo)
		if nome.is_empty():
			continue
		var partes: Array[String] = []
		if tecla.ctrl_pressed:
			partes.append("CTRL")
		if tecla.alt_pressed:
			partes.append("ALT")
		if tecla.shift_pressed:
			partes.append("SHIFT")
		if tecla.meta_pressed:
			partes.append("META")
		partes.append(nome.to_upper())
		return "+".join(partes)
	return tr("SEM TECLA")


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

	var pontos: int = int(player.pontos_upgrade_pendentes)
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
		indicador.text = tr("◆  MELHORIAS: %d") % pontos
	else:
		indicador.text = (
			tr("◆  MELHORIAS: %d") % pontos
			if usando_controle
			else tr("◆  MELHORIAS: %d  [%s]") % [pontos, _texto_tecla_melhorias()]
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
	Global.definir_cursor_interface(true)
	time_scale_anterior = Engine.time_scale
	mouse_mode_anterior = Input.mouse_mode
	if not Rede.modo_multiplayer:
		Engine.time_scale = 0.0
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
	if not Rede.modo_multiplayer:
		Engine.time_scale = maxf(time_scale_anterior, 0.01)
	Global.definir_cursor_interface(false)
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
	texto_pontos.text = tr("Pontos: %d") % player.pontos_upgrade_pendentes
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
			""
		)
		card.escolhido.connect(_on_opcao_ativada)
		container_cards.add_child(card)

	configurar_navegacao_controle()

	if container_cards.get_child_count() > 0:
		var primeiro_card = container_cards.get_child(0)
		if primeiro_card.botao:
			call_deferred("_focar_controle_se_valido", primeiro_card.botao)


func _on_rerrolar_pressed() -> void:
	if not menu_aberto or not is_instance_valid(player) or player.compra_upgrade_pendente_rede:
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
	botao_rerrolar.text = tr("Rerolls: %d") % restantes
	botao_rerrolar.disabled = restantes <= 0 or player.compra_upgrade_pendente_rede
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


func _focar_controle_se_valido(controle: Variant) -> void:
	if (
		menu_aberto
		and is_instance_valid(controle)
		and controle.is_inside_tree()
		and controle.is_visible_in_tree()
	):
		controle.grab_focus()


func limpar_cards() -> void:
	upgrade_previsualizado = &""
	painel_descricao.hide()
	for filho in container_cards.get_children():
		container_cards.remove_child(filho)
		filho.queue_free()
	opcoes_atuais.clear()


func _on_opcao_ativada(id: StringName) -> void:
	if not menu_aberto or not is_instance_valid(player) or player.compra_upgrade_pendente_rede:
		return
	if id not in opcoes_atuais:
		return
	if upgrade_previsualizado == id:
		_on_upgrade_escolhido(id)
		return

	upgrade_previsualizado = id
	var dados := DadosUpgrades.obter(id, player.HabilidadeEquipada)
	var cor := Color(dados.get("cor", Color.WHITE))
	for card in container_cards.get_children():
		card.definir_selecionado(card.upgrade_id == id)
	nome_melhoria.text = tr(str(dados.get("nome", id)))
	descricao_melhoria.text = tr(str(dados.get("descricao", "")))
	linha_destaque.color = cor
	dica_confirmacao.add_theme_color_override("font_color", cor.lightened(0.18))
	painel_descricao.show()


func _on_upgrade_escolhido(id: StringName) -> void:
	if not player.comprar_upgrade(id):
		if not player.compra_upgrade_pendente_rede:
			mostrar_opcoes()
		return
	if player.compra_upgrade_pendente_rede:
		_atualizar_botao_rerrolar()
		return

	Global.vibrar_controle(0.18, 0.35, 0.12)

	if player.pontos_upgrade_pendentes > 0:
		atualizar_cabecalho()
		mostrar_opcoes()
	else:
		fechar_menu()


# O servidor decide a compra antes da interface sortear outra carta.
func ao_upgrade_confirmado_rede() -> void:
	if not menu_aberto or not is_instance_valid(player):
		return
	if player.pontos_upgrade_pendentes > 0:
		atualizar_cabecalho()
		mostrar_opcoes()
	else:
		fechar_menu()
