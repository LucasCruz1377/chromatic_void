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
var rolagem_conquistas: ScrollContainer
var painel_nickname: PanelContainer
var campo_nickname: LineEdit
var camada_fluxo: CanvasLayer
var fundo_fluxo: ColorRect
var conteudo_fluxo: VBoxContainer
var campo_ip: LineEdit
var etapa_fluxo := &""
var fluxo_aberto := false
var mensagem_rede := ""
var mensagem_rede_erro := false


func _ready() -> void:
	Global.definir_cursor_interface(true)
	_criar_tela_carregamento()
	botao_sair.visible = not Global.dispositivo_mobile()
	texto_debug.visible = Global.modo_desenvolvedor
	if not botao_sair.visible:
		botoes_menu.erase(botao_sair)
	$Astro.apresentar()
	Global.aplicar_configuracoes()
	_criar_interface_nickname_e_multiplayer()
	_criar_menu_conquistas()
	if musica_menu.stream is AudioStreamOggVorbis:
		(musica_menu.stream as AudioStreamOggVorbis).loop = true
	if not musica_menu.playing:
		musica_menu.play()
	# No mobile o cursor continua invisível, mas a emulação de clique precisa
	# permanecer ativa para LineEdit receber toque e abrir o teclado virtual.
	Global.definir_cursor_interface(Global.dispositivo_mobile())
	Global.dispositivo_alterado.connect(_on_dispositivo_alterado)
	_configurar_navegacao_menu()
	botao_iniciar.call_deferred("grab_focus")

	if not botao_loja.pressed.is_connected(_on_shop_pressed):
		botao_loja.pressed.connect(_on_shop_pressed)
	if not Rede.lobby_alterado.is_connected(_on_lobby_alterado):
		Rede.lobby_alterado.connect(_on_lobby_alterado)
	if not Rede.status_alterado.is_connected(_on_status_rede_alterado):
		Rede.status_alterado.connect(_on_status_rede_alterado)


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
	if fluxo_aberto and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_voltar_fluxo()
		return
	if conquistas_abertas and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_fechar_menu_conquistas()


func _pode_executar_acao_menu() -> bool:
	return not carregando_cena and not conquistas_abertas and not fluxo_aberto


func _input(event: InputEvent) -> void:
	if not conquistas_abertas or not is_instance_valid(rolagem_conquistas):
		return
	if event is InputEventScreenDrag:
		var arrasto := event as InputEventScreenDrag
		if rolagem_conquistas.get_global_rect().has_point(arrasto.position):
			rolagem_conquistas.scroll_vertical -= roundi(arrasto.relative.y)
			get_viewport().set_input_as_handled()


func _on_start_pressed() -> void:
	if not _pode_executar_acao_menu():
		return
	click_som()
	_mostrar_escolha_modo()


func _on_solo_pressed() -> void:
	Rede.iniciar_solo()
	Global.primeira_vez_jogando = false
	click_som()
	await _carregar_cena(CENA_BATALHA)


func _on_multiplayer_pressed() -> void:
	click_som()
	_mostrar_escolha_multiplayer()


func _on_criar_lobby_pressed() -> void:
	click_som()
	var erro := Rede.criar_lobby(_salvar_nickname())
	if erro == OK:
		_mostrar_lobby()


func _on_entrar_lobby_pressed() -> void:
	click_som()
	_mostrar_entrada_ip()


func _on_conectar_ip_pressed() -> void:
	if not is_instance_valid(campo_ip):
		return
	click_som()
	var erro := Rede.entrar_lobby(campo_ip.text, _salvar_nickname())
	if erro == OK:
		_mostrar_lobby()


func _on_iniciar_lobby_pressed() -> void:
	click_som()
	Global.primeira_vez_jogando = false
	Rede.solicitar_inicio_partida()


func _criar_interface_nickname_e_multiplayer() -> void:
	painel_nickname = PanelContainer.new()
	painel_nickname.name = "PainelNickname"
	painel_nickname.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	painel_nickname.offset_left = -306.0
	painel_nickname.offset_top = 18.0
	painel_nickname.offset_right = -18.0
	painel_nickname.offset_bottom = 91.0
	painel_nickname.add_theme_stylebox_override(
		"panel", _estilo_conquistas(Color(0.012, 0.022, 0.065, 0.94), Color(0.28, 0.92, 0.78), 10, 2)
	)
	$CanvasLayer.add_child(painel_nickname)
	var margem_nick := MarginContainer.new()
	for lado in ["margin_left", "margin_right"]:
		margem_nick.add_theme_constant_override(lado, 12)
	margem_nick.add_theme_constant_override("margin_top", 7)
	margem_nick.add_theme_constant_override("margin_bottom", 7)
	painel_nickname.add_child(margem_nick)
	var coluna_nick := VBoxContainer.new()
	coluna_nick.add_theme_constant_override("separation", 3)
	margem_nick.add_child(coluna_nick)
	var rotulo_nick := Label.new()
	rotulo_nick.text = "NICKNAME DO PILOTO"
	rotulo_nick.add_theme_font_size_override("font_size", 11)
	rotulo_nick.add_theme_color_override("font_color", Color(0.45, 0.96, 0.82))
	coluna_nick.add_child(rotulo_nick)
	campo_nickname = LineEdit.new()
	campo_nickname.name = "Nickname"
	campo_nickname.text = Rede.nickname_local
	campo_nickname.placeholder_text = "PILOTO"
	campo_nickname.max_length = 16
	campo_nickname.select_all_on_focus = true
	_configurar_campo_texto_mobile(campo_nickname)
	campo_nickname.add_theme_font_size_override("font_size", 16)
	campo_nickname.focus_exited.connect(_salvar_nickname)
	campo_nickname.text_submitted.connect(_on_nickname_enviado)
	coluna_nick.add_child(campo_nickname)

	camada_fluxo = CanvasLayer.new()
	camada_fluxo.name = "CamadaMultiplayer"
	camada_fluxo.layer = 170
	camada_fluxo.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(camada_fluxo)
	fundo_fluxo = ColorRect.new()
	fundo_fluxo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fundo_fluxo.color = Color(0.002, 0.005, 0.022, 0.94)
	fundo_fluxo.mouse_filter = Control.MOUSE_FILTER_STOP
	camada_fluxo.add_child(fundo_fluxo)
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fundo_fluxo.add_child(centro)
	var painel := PanelContainer.new()
	painel.custom_minimum_size = Vector2(460.0, 360.0)
	painel.add_theme_stylebox_override(
		"panel", _estilo_conquistas(Color(0.015, 0.026, 0.078, 0.99), Color(0.30, 0.92, 1.0), 16, 2)
	)
	centro.add_child(painel)
	var margem := MarginContainer.new()
	for lado in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		margem.add_theme_constant_override(lado, 24)
	painel.add_child(margem)
	conteudo_fluxo = VBoxContainer.new()
	conteudo_fluxo.alignment = BoxContainer.ALIGNMENT_CENTER
	conteudo_fluxo.add_theme_constant_override("separation", 12)
	margem.add_child(conteudo_fluxo)
	camada_fluxo.hide()


func _on_nickname_enviado(_texto: String) -> void:
	_salvar_nickname()
	if is_instance_valid(botao_iniciar):
		botao_iniciar.grab_focus()


func _configurar_campo_texto_mobile(campo: LineEdit) -> void:
	campo.mouse_filter = Control.MOUSE_FILTER_STOP
	campo.focus_mode = Control.FOCUS_ALL
	campo.virtual_keyboard_enabled = true
	if Global.dispositivo_mobile():
		campo.gui_input.connect(_on_campo_texto_mobile_input.bind(campo))


func _on_campo_texto_mobile_input(event: InputEvent, campo: LineEdit) -> void:
	if event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
		campo.grab_focus()
		campo.caret_column = campo.text.length()
		campo.accept_event()


func _salvar_nickname() -> String:
	if not is_instance_valid(campo_nickname):
		return Rede.nickname_local
	var nickname := Rede.definir_nickname(campo_nickname.text)
	campo_nickname.text = nickname
	return nickname


func _limpar_fluxo() -> void:
	for filho in conteudo_fluxo.get_children():
		conteudo_fluxo.remove_child(filho)
		filho.queue_free()
	campo_ip = null


func _adicionar_titulo_fluxo(titulo: String, subtitulo: String = "") -> void:
	var rotulo := Label.new()
	rotulo.text = titulo
	rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rotulo.add_theme_font_size_override("font_size", 28)
	rotulo.add_theme_color_override("font_color", Color(0.52, 0.95, 1.0))
	conteudo_fluxo.add_child(rotulo)
	if not subtitulo.is_empty():
		var detalhe := Label.new()
		detalhe.text = subtitulo
		detalhe.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		detalhe.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		detalhe.add_theme_font_size_override("font_size", 12)
		detalhe.add_theme_color_override("font_color", Color(0.58, 0.68, 0.86))
		conteudo_fluxo.add_child(detalhe)


func _adicionar_botao_fluxo(texto: String, acao: Callable, destaque := false) -> Button:
	var botao := Button.new()
	botao.custom_minimum_size = Vector2(310.0, 48.0)
	botao.text = texto
	botao.add_theme_font_size_override("font_size", 18)
	var borda := Color(0.34, 1.0, 0.72) if destaque else Color(0.32, 0.68, 1.0)
	botao.add_theme_stylebox_override("normal", _estilo_conquistas(Color(0.03, 0.06, 0.14), borda, 9, 2))
	botao.add_theme_stylebox_override("hover", _estilo_conquistas(Color(0.07, 0.14, 0.24), borda.lightened(0.2), 9, 2))
	botao.add_theme_stylebox_override("focus", _estilo_conquistas(Color(0.07, 0.14, 0.24), Color.WHITE, 9, 2))
	botao.pressed.connect(acao)
	conteudo_fluxo.add_child(botao)
	return botao


func _adicionar_status_rede() -> void:
	if mensagem_rede.is_empty():
		return
	var status := Label.new()
	status.text = mensagem_rede
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.add_theme_font_size_override("font_size", 12)
	status.add_theme_color_override(
		"font_color", Color(1.0, 0.42, 0.48) if mensagem_rede_erro else Color(0.42, 1.0, 0.72)
	)
	conteudo_fluxo.add_child(status)


func _abrir_fluxo(etapa: StringName) -> void:
	fluxo_aberto = true
	etapa_fluxo = etapa
	camada_fluxo.show()
	for botao in botoes_menu:
		botao.disabled = true
	campo_nickname.editable = not Rede.em_lobby


func _mostrar_escolha_modo() -> void:
	_abrir_fluxo(&"modo")
	_limpar_fluxo()
	_adicionar_titulo_fluxo("INICIAR PARTIDA", "Escolha como deseja entrar no Vazio Cromático.")
	var solo := _adicionar_botao_fluxo("JOGAR SOLO", _on_solo_pressed, true)
	_adicionar_botao_fluxo("MULTIPLAYER", _on_multiplayer_pressed)
	_adicionar_botao_fluxo("VOLTAR", _voltar_fluxo)
	solo.call_deferred("grab_focus")


func _mostrar_escolha_multiplayer() -> void:
	_abrir_fluxo(&"multiplayer")
	_limpar_fluxo()
	_adicionar_titulo_fluxo("MULTIPLAYER", "Sala para 2 jogadores • conexão direta por IP")
	var criar := _adicionar_botao_fluxo("CRIAR LOBBY", _on_criar_lobby_pressed, true)
	_adicionar_botao_fluxo("ENTRAR POR IP", _on_entrar_lobby_pressed)
	_adicionar_botao_fluxo("VOLTAR", _mostrar_escolha_modo)
	criar.call_deferred("grab_focus")


func _mostrar_entrada_ip() -> void:
	_abrir_fluxo(&"ip")
	_limpar_fluxo()
	_adicionar_titulo_fluxo("ENTRAR NO LOBBY", "Digite o IPv4 informado pelo host. Porta UDP %d." % Rede.PORTA)
	campo_ip = LineEdit.new()
	campo_ip.name = "EnderecoIP"
	campo_ip.custom_minimum_size = Vector2(330.0, 46.0)
	campo_ip.placeholder_text = "Ex.: 192.168.0.10"
	campo_ip.text = "127.0.0.1"
	campo_ip.select_all_on_focus = true
	_configurar_campo_texto_mobile(campo_ip)
	campo_ip.add_theme_font_size_override("font_size", 18)
	campo_ip.text_submitted.connect(func(_texto: String) -> void: _on_conectar_ip_pressed())
	conteudo_fluxo.add_child(campo_ip)
	_adicionar_status_rede()
	_adicionar_botao_fluxo("CONECTAR", _on_conectar_ip_pressed, true)
	_adicionar_botao_fluxo("VOLTAR", _mostrar_escolha_multiplayer)
	campo_ip.call_deferred("grab_focus")


func _mostrar_lobby() -> void:
	_abrir_fluxo(&"lobby")
	_limpar_fluxo()
	_adicionar_titulo_fluxo("LOBBY", "HOST UDP %d • %d/%d JOGADORES" % [Rede.PORTA, Rede.jogadores.size(), Rede.MAX_JOGADORES])
	var ids: Array = Rede.jogadores.keys()
	ids.sort()
	for id in ids:
		var jogador := Label.new()
		jogador.text = "◆  %s%s" % [str(Rede.jogadores[id]), "  [HOST]" if int(id) == 1 else ""]
		jogador.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		jogador.add_theme_font_size_override("font_size", 18)
		jogador.add_theme_color_override("font_color", Color(0.56, 1.0, 0.78))
		conteudo_fluxo.add_child(jogador)
	if Rede.jogadores.size() < Rede.MAX_JOGADORES:
		var espera := Label.new()
		espera.text = "AGUARDANDO OUTRO PILOTO..."
		espera.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		espera.add_theme_color_override("font_color", Color(0.68, 0.72, 0.92))
		conteudo_fluxo.add_child(espera)
	_adicionar_status_rede()
	if Rede.hospedando:
		var iniciar := _adicionar_botao_fluxo("INICIAR PARTIDA", _on_iniciar_lobby_pressed, true)
		iniciar.disabled = not Rede.pode_iniciar_partida()
	_adicionar_botao_fluxo("SAIR DO LOBBY", _sair_do_lobby)


func _sair_do_lobby() -> void:
	Rede.encerrar_lobby()
	campo_nickname.editable = true
	_mostrar_escolha_multiplayer()


func _voltar_fluxo() -> void:
	match etapa_fluxo:
		&"lobby":
			_sair_do_lobby()
		&"ip":
			_mostrar_escolha_multiplayer()
		&"multiplayer":
			_mostrar_escolha_modo()
		_:
			fluxo_aberto = false
			etapa_fluxo = &""
			camada_fluxo.hide()
			campo_nickname.editable = true
			for botao in botoes_menu:
				botao.disabled = false
			botao_iniciar.call_deferred("grab_focus")


func _on_lobby_alterado(_jogadores: Dictionary) -> void:
	if fluxo_aberto and etapa_fluxo == &"lobby":
		_mostrar_lobby()


func _on_status_rede_alterado(mensagem: String, erro: bool) -> void:
	mensagem_rede = mensagem
	mensagem_rede_erro = erro
	if fluxo_aberto and etapa_fluxo == &"lobby":
		_mostrar_lobby()
	elif fluxo_aberto and etapa_fluxo == &"ip" and erro:
		_mostrar_entrada_ip()


func _on_shop_pressed() -> void:
	if not _pode_executar_acao_menu():
		return
	click_som()
	await _carregar_cena(CENA_LOJA)


func _on_achievements_pressed() -> void:
	if not _pode_executar_acao_menu():
		return
	click_som()
	conquistas_abertas = true
	_atualizar_lista_conquistas()
	camada_conquistas.show()
	for botao in botoes_menu:
		botao.disabled = true
	botao_fechar_conquistas.call_deferred("grab_focus")


func _on_options_pressed() -> void:
	if not _pode_executar_acao_menu():
		return
	click_som()
	await _carregar_cena(CENA_CONFIGURACOES)


func _on_exit_pressed() -> void:
	if not _pode_executar_acao_menu():
		return
	carregando_cena = true
	for botao in botoes_menu:
		botao.disabled = true
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
		_trocar_cena_direta_ou_recuperar(caminho)
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
				var erro_troca := get_tree().change_scene_to_packed(recurso as PackedScene)
				if erro_troca != OK:
					_recuperar_falha_carregamento(caminho, erro_troca)
				return
		if estado_carregamento_falhou(estado):
			push_warning("Falha no carregamento em segundo plano: %s" % caminho)
			_trocar_cena_direta_ou_recuperar(caminho)
			return
		# Nunca deixa um estado inesperado girar em loop sem devolver um frame.
		await get_tree().process_frame


static func estado_carregamento_falhou(estado: int) -> bool:
	return estado in [
		ResourceLoader.THREAD_LOAD_FAILED,
		ResourceLoader.THREAD_LOAD_INVALID_RESOURCE,
	]


func _trocar_cena_direta_ou_recuperar(caminho: String) -> void:
	var erro := get_tree().change_scene_to_file(caminho)
	if erro != OK:
		_recuperar_falha_carregamento(caminho, erro)


func _recuperar_falha_carregamento(caminho: String, erro: Error) -> void:
	push_error("Não foi possível abrir %s (erro %d)." % [caminho, erro])
	carregando_cena = false
	if is_instance_valid(tela_carregamento):
		tela_carregamento.hide()
	if is_instance_valid(transition) and transition.has_animation("fade_out"):
		transition.play("fade_out")
	for botao in botoes_menu:
		if is_instance_valid(botao):
			botao.disabled = false
	if is_instance_valid(botao_iniciar):
		botao_iniciar.call_deferred("grab_focus")


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

	rolagem_conquistas = ScrollContainer.new()
	rolagem_conquistas.name = "RolagemConquistas"
	rolagem_conquistas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rolagem_conquistas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rolagem_conquistas.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rolagem_conquistas.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	rolagem_conquistas.scroll_deadzone = 8
	coluna.add_child(rolagem_conquistas)

	lista_conquistas = VBoxContainer.new()
	lista_conquistas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lista_conquistas.add_theme_constant_override("separation", 8)
	rolagem_conquistas.add_child(lista_conquistas)

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
		var secreta := bool(dados.get("secreta", false))
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
		nome.text = (
			("✓  " + str(dados.get("nome", id)))
			if liberada
			else ("?  CONQUISTA SECRETA" if secreta else "◇  " + str(dados.get("nome", id)))
		)
		nome.add_theme_font_size_override("font_size", 15)
		nome.add_theme_color_override(
			"font_color", Color(0.56, 1.0, 0.76) if liberada else Color(0.72, 0.78, 0.92)
		)
		textos.add_child(nome)
		var descricao := Label.new()
		descricao.text = (
			str(dados.get("descricao", ""))
			if liberada or not secreta
			else "Continue explorando o ciclo cromático para revelar esta conquista."
		)
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
			else ("OCULTA" if secreta else "%d / %d" % [int(progresso["atual"]), int(progresso["meta"])])
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
