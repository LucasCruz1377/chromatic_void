extends Control


const DadosUpgrades = preload("res://Scripts/UpgradeData.gd")
const CardUpgrade = preload("res://Scripts/UpgradeCardNova.gd")

@export var cena_carta: PackedScene
@export var qtd_cartas: int = 3

@onready var container_antigo: Control = $ContainerCartas

var player: Player
var overlay: ColorRect
var container_cards: HBoxContainer
var indicador: Button
var texto_pontos: Label
var texto_habilidade: Label
var menu_aberto := false
var time_scale_anterior := 1.0
var mouse_mode_anterior := Input.MOUSE_MODE_HIDDEN
var tween_indicador: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	container_antigo.hide()
	construir_interface()
	call_deferred("conectar_player")


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
	faixa_topo.size = Vector2(960, 67)
	faixa_topo.color = Color(0.025, 0.045, 0.095, 0.96)
	faixa_topo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(faixa_topo)

	var titulo := Label.new()
	titulo.position = Vector2(32, 12)
	titulo.size = Vector2(400, 34)
	titulo.text = "MATRIZ DE MODIFICAÇÕES"
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

	texto_pontos = Label.new()
	texto_pontos.position = Vector2(590, 17)
	texto_pontos.size = Vector2(220, 34)
	texto_pontos.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	texto_pontos.add_theme_font_size_override("font_size", 17)
	texto_pontos.add_theme_color_override("font_color", Color(1.0, 0.8, 0.28))
	texto_pontos.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(texto_pontos)

	var fechar := Button.new()
	fechar.position = Vector2(830, 15)
	fechar.size = Vector2(98, 38)
	fechar.text = "FECHAR"
	fechar.pressed.connect(fechar_menu)
	fechar.add_theme_stylebox_override(
		"normal", criar_estilo_botao(Color(0.08, 0.1, 0.18), Color(0.34, 0.44, 0.65))
	)
	fechar.add_theme_stylebox_override(
		"hover", criar_estilo_botao(Color(0.13, 0.16, 0.27), Color(0.55, 0.8, 1.0))
	)
	overlay.add_child(fechar)

	container_cards = HBoxContainer.new()
	container_cards.position = Vector2(70, 82)
	container_cards.size = Vector2(820, 336)
	container_cards.add_theme_constant_override("separation", 20)
	container_cards.alignment = BoxContainer.ALIGNMENT_CENTER
	container_cards.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(container_cards)

	var rerrolar := Button.new()
	rerrolar.position = Vector2(382, 440)
	rerrolar.size = Vector2(196, 40)
	rerrolar.text = "RECALCULAR OPÇÕES"
	rerrolar.pressed.connect(mostrar_opcoes)
	rerrolar.add_theme_stylebox_override(
		"normal", criar_estilo_botao(Color(0.06, 0.15, 0.22), Color(0.2, 0.75, 1.0))
	)
	rerrolar.add_theme_stylebox_override(
		"hover", criar_estilo_botao(Color(0.09, 0.25, 0.34), Color(0.55, 0.94, 1.0))
	)
	overlay.add_child(rerrolar)

	var dica := Label.new()
	dica.position = Vector2(120, 492)
	dica.size = Vector2(720, 24)
	dica.text = "Escolha um mod ou feche o menu para guardar os pontos. TAB também abre e fecha."
	dica.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dica.add_theme_font_size_override("font_size", 12)
	dica.add_theme_color_override("font_color", Color(0.44, 0.54, 0.7))
	dica.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(dica)

	indicador = Button.new()
	indicador.name = "IndicadorMelhorias"
	indicador.position = Vector2(18, 16)
	indicador.size = Vector2(220, 44)
	indicador.pivot_offset = indicador.size * 0.5
	indicador.mouse_filter = Control.MOUSE_FILTER_STOP
	indicador.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	indicador.pressed.connect(abrir_menu)
	indicador.add_theme_font_size_override("font_size", 12)
	indicador.add_theme_stylebox_override(
		"normal", criar_estilo_botao(Color(0.08, 0.08, 0.18), Color(0.5, 0.72, 1.0))
	)
	indicador.add_theme_stylebox_override(
		"hover", criar_estilo_botao(Color(0.13, 0.16, 0.3), Color(0.85, 0.95, 1.0))
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


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return

	var tecla := event as InputEventKey
	if not tecla.pressed or tecla.echo:
		return
	if tecla.keycode != KEY_TAB and tecla.keycode != KEY_U:
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
	indicador.visible = pontos > 0 and not menu_aberto
	indicador.text = "◆  MELHORIAS: %d  [TAB]" % pontos


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
	if menu_aberto or not is_instance_valid(player):
		return
	if player.pontos_upgrade_pendentes <= 0 or get_tree().paused:
		return

	menu_aberto = true
	time_scale_anterior = Engine.time_scale
	mouse_mode_anterior = Input.mouse_mode
	Engine.time_scale = 0.0
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	overlay.show()
	indicador.hide()
	atualizar_cabecalho()
	mostrar_opcoes()


func fechar_menu() -> void:
	if not menu_aberto:
		return

	menu_aberto = false
	overlay.hide()
	Engine.time_scale = maxf(time_scale_anterior, 0.01)
	Input.set_mouse_mode(mouse_mode_anterior)
	limpar_cards()
	atualizar_indicador()


func esta_aberta() -> bool:
	return menu_aberto


func atualizar_cabecalho() -> void:
	texto_pontos.text = "PONTOS PENDENTES: %d" % player.pontos_upgrade_pendentes
	var nome_habilidade := "NENHUMA"
	if player.HabilidadeEquipada:
		nome_habilidade = player.HabilidadeEquipada.Nome
	texto_habilidade.text = "HABILIDADE EQUIPADA: " + nome_habilidade.to_upper()


func mostrar_opcoes() -> void:
	if not menu_aberto or not is_instance_valid(player):
		return

	limpar_cards()
	var opcoes := DadosUpgrades.sortear(player.niveis_upgrades, qtd_cartas)
	for id in opcoes:
		var dados := DadosUpgrades.obter(id)
		var card = CardUpgrade.new()
		container_cards.add_child(card)
		card.configurar(
			id,
			dados,
			DadosUpgrades.nivel(id, player.niveis_upgrades),
			DadosUpgrades.texto_requisitos(id, player.niveis_upgrades)
		)
		card.escolhido.connect(_on_upgrade_escolhido)


func limpar_cards() -> void:
	for filho in container_cards.get_children():
		container_cards.remove_child(filho)
		filho.queue_free()


func _on_upgrade_escolhido(id: StringName) -> void:
	if not player.comprar_upgrade(id):
		mostrar_opcoes()
		return

	if player.pontos_upgrade_pendentes > 0:
		atualizar_cabecalho()
		mostrar_opcoes()
	else:
		fechar_menu()
