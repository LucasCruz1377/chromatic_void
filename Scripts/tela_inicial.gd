extends Node2D


const CENA_BATALHA := "res://Rooms/Battle_area.tscn"
const CENA_LOJA := "res://Rooms/Loja.tscn"
const CENA_CONFIGURACOES := "res://Rooms/configuracoes.tscn"

@onready var transition: AnimationPlayer = $transition
@onready var som: AudioStreamPlayer2D = $som
@onready var musica_menu: AudioStreamPlayer2D = $menumusica
@onready var botao_loja: Button = $CanvasLayer/CaixaMenu2/Shop
@onready var botao_conquistas: Button = $CanvasLayer/CaixaMenu2/Achievements
@onready var botao_iniciar: Button = $CanvasLayer/CaixaMenu2/Start
@onready var botao_sair: Button = $CanvasLayer/CaixaMenu2/Exit
@onready var texto_debug: Control = $Debug_text
@onready var botoes_menu: Array[Button] = [
	$CanvasLayer/CaixaMenu2/Start as Button,
	$CanvasLayer/CaixaMenu2/Shop as Button,
	$CanvasLayer/CaixaMenu2/Achievements as Button,
	$CanvasLayer/CaixaMenu2/Options as Button,
	$CanvasLayer/CaixaMenu2/Credits as Button,
	$CanvasLayer/CaixaMenu2/Exit as Button,
]
var tela_carregamento: Control
var texto_carregamento: Label
var carregando_cena := false
var conquistas_abertas := false
var camada_conquistas: CanvasLayer
var painel_conquistas: PanelContainer
var lista_conquistas: VBoxContainer
var resumo_conquistas: Label
var botao_fechar_conquistas: Button


func _ready() -> void:
	Global.definir_emulacao_mouse_mobile(true)
	_criar_tela_carregamento()
	botao_sair.visible = not Global.dispositivo_mobile()
	texto_debug.visible = Global.modo_desenvolvedor
	if not botao_sair.visible:
		botoes_menu.erase(botao_sair)
	$Astro.apresentar()
	Global.aplicar_configuracoes()
	_criar_menu_conquistas()
	if musica_menu.stream is AudioStreamOggVorbis:
		(musica_menu.stream as AudioStreamOggVorbis).loop = true
	if not musica_menu.playing:
		musica_menu.play()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	Global.dispositivo_alterado.connect(_on_dispositivo_alterado)
	_configurar_navegacao_menu()
	botao_iniciar.call_deferred("grab_focus")

	if not botao_loja.pressed.is_connected(_on_shop_pressed):
		botao_loja.pressed.connect(_on_shop_pressed)


func _configurar_navegacao_menu() -> void:
	for indice in botoes_menu.size():
		var botao := botoes_menu[indice]
		var anterior := botoes_menu[wrapi(indice - 1, 0, botoes_menu.size())]
		var proximo := botoes_menu[(indice + 1) % botoes_menu.size()]
		botao.focus_neighbor_top = botao.get_path_to(anterior)
		botao.focus_neighbor_bottom = botao.get_path_to(proximo)


func _process(_delta: float) -> void:
	if get_tree().paused:
		get_tree().paused = false
	if carregando_cena and is_instance_valid(texto_carregamento):
		var quantidade_pontos := int(Time.get_ticks_msec() / 320) % 4
		texto_carregamento.text = "CARREGANDO" + ".".repeat(quantidade_pontos)


func _unhandled_input(event: InputEvent) -> void:
	if conquistas_abertas and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_fechar_menu_conquistas()


func _on_start_pressed() -> void:
	Global.primeira_vez_jogando = false
	click_som()
	await _carregar_cena(CENA_BATALHA)


func _on_shop_pressed() -> void:
	click_som()
	await _carregar_cena(CENA_LOJA)


func _on_achievements_pressed() -> void:
	click_som()
	conquistas_abertas = true
	_atualizar_lista_conquistas()
	camada_conquistas.show()
	for botao in botoes_menu:
		botao.disabled = true
	botao_fechar_conquistas.call_deferred("grab_focus")


func _on_options_pressed() -> void:
	click_som()
	await _carregar_cena(CENA_CONFIGURACOES)


func _on_exit_pressed() -> void:
	click_som()
	await get_tree().create_timer(0.5).timeout
	get_tree().quit()


func click_som() -> void:
	som.play()


func _carregar_cena(caminho: String) -> void:
	if carregando_cena:
		return
	carregando_cena = true
	for botao in botoes_menu:
		botao.disabled = true

	var erro: Error = ResourceLoader.load_threaded_request(caminho)
	transition.play("fade_in")
	await transition.animation_finished
	tela_carregamento.show()
	await get_tree().process_frame

	if erro != OK:
		push_warning("Não foi possível iniciar o carregamento em segundo plano: %s" % caminho)
		get_tree().change_scene_to_file(caminho)
		return

	var progresso: Array = []
	while true:
		var estado: int = int(ResourceLoader.load_threaded_get_status(caminho, progresso))
		if estado == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			await get_tree().process_frame
			continue
		if estado == ResourceLoader.THREAD_LOAD_LOADED:
			var recurso: Resource = ResourceLoader.load_threaded_get(caminho)
			if recurso is PackedScene:
				get_tree().change_scene_to_packed(recurso as PackedScene)
				return
		push_warning("Falha no carregamento em segundo plano: %s" % caminho)
		get_tree().change_scene_to_file(caminho)
		return


func _criar_tela_carregamento() -> void:
	var camada := CanvasLayer.new()
	camada.name = "CamadaCarregamento"
	camada.layer = 120
	add_child(camada)

	tela_carregamento = ColorRect.new()
	tela_carregamento.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tela_carregamento.color = Color(0.002, 0.004, 0.016, 1.0)
	tela_carregamento.mouse_filter = Control.MOUSE_FILTER_STOP
	camada.add_child(tela_carregamento)

	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tela_carregamento.add_child(centro)

	var coluna := VBoxContainer.new()
	coluna.alignment = BoxContainer.ALIGNMENT_CENTER
	coluna.add_theme_constant_override("separation", 14)
	centro.add_child(coluna)

	var simbolo := Label.new()
	simbolo.text = "◇"
	simbolo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	simbolo.add_theme_font_size_override("font_size", 42)
	simbolo.add_theme_color_override("font_color", Color(0.45, 0.9, 1.0))
	coluna.add_child(simbolo)

	texto_carregamento = Label.new()
	texto_carregamento.text = "CARREGANDO"
	texto_carregamento.custom_minimum_size = Vector2(230.0, 28.0)
	texto_carregamento.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	texto_carregamento.add_theme_font_size_override("font_size", 18)
	texto_carregamento.add_theme_color_override("font_color", Color(0.72, 0.82, 1.0))
	coluna.add_child(texto_carregamento)
	tela_carregamento.hide()


func _criar_menu_conquistas() -> void:
	camada_conquistas = CanvasLayer.new()
	camada_conquistas.name = "CamadaConquistas"
	camada_conquistas.layer = 180
	camada_conquistas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(camada_conquistas)

	var fundo := ColorRect.new()
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fundo.color = Color(0.002, 0.004, 0.018, 0.92)
	fundo.mouse_filter = Control.MOUSE_FILTER_STOP
	camada_conquistas.add_child(fundo)

	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fundo.add_child(centro)

	painel_conquistas = PanelContainer.new()
	painel_conquistas.add_theme_stylebox_override(
		"panel", _estilo_conquistas(
			Color(0.018, 0.026, 0.072, 0.99), Color(0.64, 0.34, 1.0), 16, 2
		)
	)
	centro.add_child(painel_conquistas)

	var margem := MarginContainer.new()
	for lado in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		margem.add_theme_constant_override(lado, 18)
	painel_conquistas.add_child(margem)

	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 10)
	margem.add_child(coluna)

	var cabecalho := HBoxContainer.new()
	cabecalho.add_theme_constant_override("separation", 12)
	coluna.add_child(cabecalho)

	var titulo := Label.new()
	titulo.text = "✦  CONQUISTAS"
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titulo.add_theme_font_size_override("font_size", 26)
	titulo.add_theme_color_override("font_color", Color(0.84, 0.68, 1.0))
	cabecalho.add_child(titulo)

	botao_fechar_conquistas = Button.new()
	botao_fechar_conquistas.custom_minimum_size = Vector2(108, 38)
	botao_fechar_conquistas.text = "FECHAR"
	botao_fechar_conquistas.pressed.connect(_fechar_menu_conquistas)
	botao_fechar_conquistas.add_theme_stylebox_override(
		"normal", _estilo_conquistas(Color(0.05, 0.07, 0.15), Color(0.36, 0.5, 0.78), 9, 1)
	)
	botao_fechar_conquistas.add_theme_stylebox_override(
		"hover", _estilo_conquistas(Color(0.09, 0.12, 0.24), Color(0.72, 0.48, 1.0), 9, 2)
	)
	cabecalho.add_child(botao_fechar_conquistas)

	resumo_conquistas = Label.new()
	resumo_conquistas.add_theme_font_size_override("font_size", 13)
	resumo_conquistas.add_theme_color_override("font_color", Color(0.48, 0.84, 1.0))
	coluna.add_child(resumo_conquistas)

	var rolagem := ScrollContainer.new()
	rolagem.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rolagem.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rolagem.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rolagem.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	rolagem.scroll_deadzone = 8
	coluna.add_child(rolagem)

	lista_conquistas = VBoxContainer.new()
	lista_conquistas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lista_conquistas.add_theme_constant_override("separation", 8)
	rolagem.add_child(lista_conquistas)

	get_viewport().size_changed.connect(_atualizar_tamanho_menu_conquistas)
	_atualizar_tamanho_menu_conquistas()
	camada_conquistas.hide()


func _atualizar_lista_conquistas() -> void:
	for filho in lista_conquistas.get_children():
		lista_conquistas.remove_child(filho)
		filho.queue_free()

	var liberadas := Global.conquistas_desbloqueadas.size()
	resumo_conquistas.text = "%d DE %d DESBLOQUEADAS" % [liberadas, Global.CONQUISTAS.size()]
	for id in Global.CONQUISTAS:
		var dados: Dictionary = Global.CONQUISTAS[id]
		var progresso := Global.progresso_conquista(id)
		var liberada := Global.conquista_liberada(id)
		var painel := PanelContainer.new()
		painel.custom_minimum_size = Vector2(0, 76)
		painel.add_theme_stylebox_override(
			"panel", _estilo_conquistas(
				Color(0.035, 0.055, 0.105) if liberada else Color(0.018, 0.026, 0.058),
				Color(0.42, 1.0, 0.68) if liberada else Color(0.20, 0.28, 0.46),
				10, 2 if liberada else 1
			)
		)
		lista_conquistas.add_child(painel)
		var margem := MarginContainer.new()
		margem.add_theme_constant_override("margin_left", 12)
		margem.add_theme_constant_override("margin_top", 8)
		margem.add_theme_constant_override("margin_right", 12)
		margem.add_theme_constant_override("margin_bottom", 8)
		painel.add_child(margem)
		var linha := HBoxContainer.new()
		linha.add_theme_constant_override("separation", 12)
		margem.add_child(linha)
		var textos := VBoxContainer.new()
		textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		linha.add_child(textos)
		var nome := Label.new()
		nome.text = ("✓  " if liberada else "◇  ") + str(dados.get("nome", id))
		nome.add_theme_font_size_override("font_size", 15)
		nome.add_theme_color_override(
			"font_color", Color(0.56, 1.0, 0.76) if liberada else Color(0.72, 0.78, 0.92)
		)
		textos.add_child(nome)
		var descricao := Label.new()
		descricao.text = str(dados.get("descricao", ""))
		descricao.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		descricao.add_theme_font_size_override("font_size", 11)
		descricao.add_theme_color_override("font_color", Color(0.48, 0.56, 0.72))
		textos.add_child(descricao)
		var status := Label.new()
		status.custom_minimum_size = Vector2(92, 0)
		status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		status.text = (
			"LIBERADA"
			if liberada
			else "%d / %d" % [int(progresso["atual"]), int(progresso["meta"])]
		)
		status.add_theme_font_size_override("font_size", 12)
		status.add_theme_color_override(
			"font_color", Color(0.42, 1.0, 0.68) if liberada else Color(0.66, 0.5, 1.0)
		)
		linha.add_child(status)


func _fechar_menu_conquistas() -> void:
	if not conquistas_abertas:
		return
	conquistas_abertas = false
	camada_conquistas.hide()
	for botao in botoes_menu:
		botao.disabled = false
	botao_conquistas.call_deferred("grab_focus")


func _atualizar_tamanho_menu_conquistas() -> void:
	if not is_instance_valid(painel_conquistas):
		return
	var tamanho := get_viewport_rect().size
	painel_conquistas.custom_minimum_size = Vector2(
		minf(720.0, maxf(tamanho.x - 28.0, 280.0)),
		minf(480.0, maxf(tamanho.y - 28.0, 250.0))
	)


func _estilo_conquistas(
	fundo: Color, borda: Color, raio: int, espessura: int
) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = fundo
	estilo.border_color = borda
	estilo.set_border_width_all(espessura)
	estilo.set_corner_radius_all(raio)
	return estilo


func _on_dispositivo_alterado(tipo: StringName) -> void:
	if tipo == &"controle":
		botao_iniciar.grab_focus()
