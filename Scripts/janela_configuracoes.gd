extends Control


signal voltar_solicitado

const IconesControle = preload("res://Scripts/IndicadoresControle.gd")
const VELOCIDADE_ROLAGEM_CONTROLE := 480.0

@onready var abas: TabContainer = $Painel/Margem/Coluna/Abas

@onready var idiomas: OptionButton = $Painel/Margem/Coluna/Abas/JOGO/Conteudo/Idioma/Idiomas
@onready var mira_mouse: CheckButton = $Painel/Margem/Coluna/Abas/JOGO/Conteudo/MiraMouse
@onready var vibracao: CheckButton = $Painel/Margem/Coluna/Abas/JOGO/Conteudo/Vibracao
@onready var zona_morta: HSlider = $Painel/Margem/Coluna/Abas/JOGO/Conteudo/ZonaMorta/Controle
@onready var valor_zona_morta: Label = $Painel/Margem/Coluna/Abas/JOGO/Conteudo/ZonaMorta/Valor

@onready var tela_cheia: CheckButton = $Painel/Margem/Coluna/Abas/VIDEO/Conteudo/TelaCheia
@onready var vsync: CheckButton = $Painel/Margem/Coluna/Abas/VIDEO/Conteudo/VSync
@onready var limite_fps: OptionButton = $Painel/Margem/Coluna/Abas/VIDEO/Conteudo/LimiteFPS/Opcoes

@onready var neon: HSlider = $Painel/Margem/Coluna/Abas/GRAFICOS/Conteudo/Neon/Controle
@onready var valor_neon: Label = $Painel/Margem/Coluna/Abas/GRAFICOS/Conteudo/Neon/Valor
@onready var bloom: HSlider = $Painel/Margem/Coluna/Abas/GRAFICOS/Conteudo/Bloom/Controle
@onready var valor_bloom: Label = $Painel/Margem/Coluna/Abas/GRAFICOS/Conteudo/Bloom/Valor
@onready var tremor: HSlider = $Painel/Margem/Coluna/Abas/GRAFICOS/Conteudo/Tremor/Controle
@onready var valor_tremor: Label = $Painel/Margem/Coluna/Abas/GRAFICOS/Conteudo/Tremor/Valor

@onready var volume_master: HSlider = $Painel/Margem/Coluna/Abas/AUDIO/Conteudo/Master/Controle
@onready var valor_master: Label = $Painel/Margem/Coluna/Abas/AUDIO/Conteudo/Master/Valor
@onready var volume_musica: HSlider = $Painel/Margem/Coluna/Abas/AUDIO/Conteudo/Musica/Controle
@onready var valor_musica: Label = $Painel/Margem/Coluna/Abas/AUDIO/Conteudo/Musica/Valor
@onready var volume_som: HSlider = $Painel/Margem/Coluna/Abas/AUDIO/Conteudo/Efeitos/Controle
@onready var valor_som: Label = $Painel/Margem/Coluna/Abas/AUDIO/Conteudo/Efeitos/Valor

@onready var controle_detectado: Label = $Painel/Margem/Coluna/Abas/CONTROLES/Conteudo/ControleDetectado
@onready var controle_avancado: CheckButton = $Painel/Margem/Coluna/Abas/CONTROLES/Conteudo/ControleAvancado
@onready var instrucao_mapeamento: Label = $Painel/Margem/Coluna/Abas/CONTROLES/Conteudo/BarraControles/Instrucao
@onready var restaurar_controles: Button = $Painel/Margem/Coluna/Abas/CONTROLES/Conteudo/BarraControles/RestaurarControles
@onready var rolagem_mapeamentos: ScrollContainer = $Painel/Margem/Coluna/Abas/CONTROLES/Conteudo/Rolagem
@onready var lista_mapeamentos: VBoxContainer = $Painel/Margem/Coluna/Abas/CONTROLES/Conteudo/Rolagem/ListaMapeamentos
@onready var rodape: HBoxContainer = $Painel/Margem/Coluna/Rodape
@onready var restaurar: Button = $Painel/Margem/Coluna/Rodape/Restaurar
@onready var voltar: Button = $Painel/Margem/Coluna/Rodape/Voltar

var carregando := false
var fps_disponiveis := [0, 30, 60, 120, 144, 240]
var botoes_mapeamento: Dictionary = {}
var capturando_entrada := false
var captura_pronta := false
var acao_capturada: StringName
var slot_capturado := -1
var botao_capturado: Button
var save_apagado: bool = false
var apagar_save: Button
var confirmar_apagar_save: ConfirmationDialog


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_input(true)
	set_process_unhandled_input(true)
	_configurar_opcoes()
	_criar_controles_save()
	_conectar_sinais()
	_criar_lista_mapeamentos()
	carregar_interface()
	_atualizar_titulos_abas()
	atualizar_controles_detectados()
	call_deferred("_focar_primeiro_controle")


func _process(delta: float) -> void:
	if capturando_entrada or abas.get_current_tab_control().name != &"CONTROLES":
		return
	var controles := Input.get_connected_joypads()
	if controles.is_empty():
		return
	var dispositivo: int = controles[0]
	if controles.has(Global.ultimo_controle_id):
		dispositivo = Global.ultimo_controle_id
	var eixo := Input.get_joy_axis(dispositivo, JOY_AXIS_RIGHT_Y)
	if absf(eixo) <= Global.zona_morta_controle:
		return
	rolagem_mapeamentos.scroll_vertical += roundi(
		eixo * VELOCIDADE_ROLAGEM_CONTROLE * delta
	)


func _input(event: InputEvent) -> void:
	if not capturando_entrada or not captura_pronta:
		return
	# MouseMotion (gerado ao tirar o cursor do slot), gestos e outros eventos
	# não representam comandos remapeáveis. Antes, qualquer um deles encerrava a
	# espera imediatamente e fazia o botão voltar ao vínculo anterior.
	if not (
		event is InputEventKey
		or event is InputEventMouseButton
		or event is InputEventJoypadButton
		or event is InputEventJoypadMotion
	):
		return
	if event is InputEventKey and (not event.pressed or event.echo):
		return
	if event is InputEventMouseButton and not event.pressed:
		return
	if event is InputEventJoypadButton and not event.pressed:
		return
	if event is InputEventJoypadMotion:
		var minimo := maxf(Global.zona_morta_controle + 0.2, 0.65)
		if absf(event.axis_value) < minimo:
			return

	if event is InputEventKey and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		_cancelar_captura()
		return

	# Modificar o InputMap enquanto o próprio evento está sendo distribuído pode
	# fazer alguns controles perderem a entrada. A cópia é aplicada no próximo
	# ciclo, depois que o Godot conclui a propagação do botão atual.
	get_viewport().set_input_as_handled()
	var evento_capturado := event.duplicate(true) as InputEvent
	var acao_confirmada := acao_capturada
	var slot_confirmado := slot_capturado
	capturando_entrada = false
	captura_pronta = false
	if is_instance_valid(botao_capturado):
		botao_capturado.text = "[ OK ]"
	call_deferred(
		"_confirmar_mapeamento",
		acao_confirmada,
		slot_confirmado,
		evento_capturado
	)


func _unhandled_input(event: InputEvent) -> void:
	if capturando_entrada:
		return
	if _solicitou_limpar_slot(event):
		get_viewport().set_input_as_handled()
		_limpar_slot_focado()
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_voltar_pressed()
	elif event.is_action_pressed("aba_anterior"):
		get_viewport().set_input_as_handled()
		abas.current_tab = wrapi(abas.current_tab - 1, 0, abas.get_tab_count())
	elif event.is_action_pressed("proxima_aba"):
		get_viewport().set_input_as_handled()
		abas.current_tab = wrapi(abas.current_tab + 1, 0, abas.get_tab_count())


func _configurar_opcoes() -> void:
	idiomas.clear()
	var locais := TranslationServer.get_loaded_locales()
	if locais.is_empty():
		locais = PackedStringArray(["pt_BR", "es_EN"])
	for local in locais:
		idiomas.add_item(str(local))
		idiomas.set_item_metadata(idiomas.item_count - 1, str(local))

	limite_fps.clear()
	for fps in fps_disponiveis:
		limite_fps.add_item("SEM LIMITE" if fps == 0 else "%d FPS" % fps)
		limite_fps.set_item_metadata(limite_fps.item_count - 1, fps)


func _conectar_sinais() -> void:
	idiomas.item_selected.connect(_on_idioma_selecionado)
	mira_mouse.toggled.connect(_on_mira_mouse_toggled)
	vibracao.toggled.connect(_on_vibracao_toggled)
	zona_morta.value_changed.connect(_on_zona_morta_alterada)
	zona_morta.drag_ended.connect(_on_slider_finalizado)

	tela_cheia.toggled.connect(_on_tela_cheia_toggled)
	vsync.toggled.connect(_on_vsync_toggled)
	limite_fps.item_selected.connect(_on_fps_selecionado)

	neon.value_changed.connect(_on_neon_alterado)
	bloom.value_changed.connect(_on_bloom_alterado)
	tremor.value_changed.connect(_on_tremor_alterado)
	neon.drag_ended.connect(_on_slider_finalizado)
	bloom.drag_ended.connect(_on_slider_finalizado)
	tremor.drag_ended.connect(_on_slider_finalizado)

	volume_master.value_changed.connect(_on_master_alterado)
	volume_musica.value_changed.connect(_on_musica_alterada)
	volume_som.value_changed.connect(_on_som_alterado)
	volume_master.drag_ended.connect(_on_slider_finalizado)
	volume_musica.drag_ended.connect(_on_slider_finalizado)
	volume_som.drag_ended.connect(_on_slider_finalizado)

	controle_avancado.toggled.connect(_on_controle_avancado_toggled)
	restaurar_controles.pressed.connect(_on_restaurar_controles_pressed)
	restaurar.pressed.connect(_on_restaurar_pressed)
	voltar.pressed.connect(_on_voltar_pressed)
	abas.tab_changed.connect(_on_aba_alterada)
	Input.joy_connection_changed.connect(_on_conexao_controle_alterada)


func carregar_interface() -> void:
	carregando = true
	_selecionar_idioma(Global.idioma)
	mira_mouse.button_pressed = Global.mira_mouse
	vibracao.button_pressed = Global.vibracao
	zona_morta.value = Global.zona_morta_controle
	tela_cheia.button_pressed = Global.tela_cheia
	vsync.button_pressed = Global.vsync
	_selecionar_fps(Global.limite_fps)
	neon.value = Global.neon
	bloom.value = Global.bloom
	tremor.value = Global.tremor_tela
	volume_master.value = Global.volume_master
	volume_musica.value = Global.volume_musica
	volume_som.value = Global.volume_som
	controle_avancado.button_pressed = Global.controle_avancado
	_atualizar_valores()
	carregando = false


func _selecionar_idioma(local: String) -> void:
	for indice in idiomas.item_count:
		if str(idiomas.get_item_metadata(indice)) == local:
			idiomas.select(indice)
			return
	if idiomas.item_count > 0:
		idiomas.select(0)


func _selecionar_fps(fps: int) -> void:
	for indice in limite_fps.item_count:
		if int(limite_fps.get_item_metadata(indice)) == fps:
			limite_fps.select(indice)
			return
	limite_fps.select(0)


func _salvar() -> void:
	if carregando or save_apagado:
		return
	Global.salvar_configuracoes()


func _aplicar_previa() -> void:
	if carregando:
		return
	Global.aplicar_configuracoes()
	Global.configuracoes_alteradas.emit()


func _on_idioma_selecionado(index: int) -> void:
	Global.idioma = str(idiomas.get_item_metadata(index))
	_salvar()
	_atualizar_titulos_abas()


func _on_mira_mouse_toggled(valor: bool) -> void:
	Global.mira_mouse = valor
	_salvar()


func _on_vibracao_toggled(valor: bool) -> void:
	Global.vibracao = valor
	_salvar()
	if valor:
		Global.vibrar_controle()


func _on_controle_avancado_toggled(valor: bool) -> void:
	Global.controle_avancado = valor
	_salvar()


func _on_zona_morta_alterada(valor: float) -> void:
	Global.zona_morta_controle = valor
	_atualizar_valores()


func _on_tela_cheia_toggled(valor: bool) -> void:
	Global.tela_cheia = valor
	_salvar()


func _on_vsync_toggled(valor: bool) -> void:
	Global.vsync = valor
	_salvar()


func _on_fps_selecionado(index: int) -> void:
	Global.limite_fps = int(limite_fps.get_item_metadata(index))
	_salvar()


func _on_neon_alterado(valor: float) -> void:
	Global.neon = valor
	_atualizar_valores()
	_aplicar_previa()


func _on_bloom_alterado(valor: float) -> void:
	Global.bloom = valor
	_atualizar_valores()
	_aplicar_previa()


func _on_tremor_alterado(valor: float) -> void:
	Global.tremor_tela = valor
	_atualizar_valores()


func _on_master_alterado(valor: float) -> void:
	Global.volume_master = valor
	_atualizar_valores()
	_aplicar_previa()


func _on_musica_alterada(valor: float) -> void:
	Global.volume_musica = valor
	_atualizar_valores()
	_aplicar_previa()


func _on_som_alterado(valor: float) -> void:
	Global.volume_som = valor
	_atualizar_valores()
	_aplicar_previa()


func _on_slider_finalizado(valor_alterado: bool) -> void:
	if valor_alterado:
		_salvar()


func _atualizar_valores() -> void:
	valor_zona_morta.text = "%d%%" % roundi(zona_morta.value * 100.0)
	valor_neon.text = "%d%%" % roundi(neon.value * 100.0)
	valor_bloom.text = "%d%%" % roundi(bloom.value * 200.0)
	valor_tremor.text = "%d%%" % roundi(tremor.value * 100.0)
	valor_master.text = _texto_volume(volume_master.value)
	valor_musica.text = _texto_volume(volume_musica.value)
	valor_som.text = _texto_volume(volume_som.value)


func _texto_volume(valor: float) -> String:
	return "MUDO" if valor <= -79.5 else "%+.0f dB" % valor


func atualizar_controles_detectados() -> void:
	var controles := Input.get_connected_joypads()
	if controles.is_empty():
		controle_detectado.text = "Nenhum controle conectado. Conecte-o antes ou durante o jogo."
		_atualizar_textos_mapeamentos()
		return

	var nomes: Array[String] = []
	for dispositivo in controles:
		nomes.append(Input.get_joy_name(dispositivo))
	controle_detectado.text = "Detectado: " + ", ".join(nomes)
	_atualizar_textos_mapeamentos()


func _on_conexao_controle_alterada(_dispositivo: int, _conectado: bool) -> void:
	atualizar_controles_detectados()


func _on_restaurar_pressed() -> void:
	_cancelar_captura()
	Global.restaurar_configuracoes_padrao()
	carregar_interface()
	_atualizar_textos_mapeamentos()


func _on_restaurar_controles_pressed() -> void:
	_cancelar_captura()
	Global.restaurar_mapeamentos_padrao()
	_atualizar_textos_mapeamentos()


func _on_voltar_pressed() -> void:
	_cancelar_captura()
	if not save_apagado:
		_salvar()
	voltar_solicitado.emit()


func _on_aba_alterada(_indice: int) -> void:
	_cancelar_captura()
	call_deferred("_focar_primeiro_controle")


func _focar_primeiro_controle() -> void:
	var aba := abas.get_current_tab_control()
	if not aba:
		return
	var controles := aba.find_children("*", "Control", true, false)
	for controle in controles:
		if controle is BaseButton or controle is Range:
			controle.grab_focus()
			return


func _atualizar_titulos_abas() -> void:
	var chaves := [
		"T_TAB_GAME",
		"T_TAB_VIDEO",
		"T_TAB_GRAPHICS",
		"T_TAB_AUDIO",
		"T_TAB_CONTROLS"
	]
	for indice in mini(abas.get_tab_count(), chaves.size()):
		abas.set_tab_title(indice, tr(chaves[indice]))
	_atualizar_textos_save()
	_atualizar_rotulos_acoes()


func _criar_controles_save() -> void:
	apagar_save = Button.new()
	apagar_save.name = "ApagarSave"
	apagar_save.custom_minimum_size = Vector2(190.0, 38.0)
	apagar_save.focus_mode = Control.FOCUS_ALL
	apagar_save.add_theme_color_override("font_color", Color(1.0, 0.72, 0.72, 1.0))
	apagar_save.add_theme_color_override("font_hover_color", Color.WHITE)
	apagar_save.add_theme_color_override("font_focus_color", Color.WHITE)
	apagar_save.add_theme_stylebox_override(
		"normal",
		_estilo_slot(Color(0.15, 0.035, 0.055, 0.96), Color(0.72, 0.18, 0.28, 0.9))
	)
	apagar_save.add_theme_stylebox_override(
		"hover",
		_estilo_slot(Color(0.25, 0.045, 0.075, 1.0), Color(1.0, 0.32, 0.42, 1.0))
	)
	apagar_save.add_theme_stylebox_override(
		"focus",
		_estilo_slot(Color(0.3, 0.055, 0.085, 1.0), Color(1.0, 0.55, 0.62, 1.0))
	)
	apagar_save.add_theme_stylebox_override(
		"pressed",
		_estilo_slot(Color(0.36, 0.045, 0.075, 1.0), Color(1.0, 0.72, 0.76, 1.0))
	)
	rodape.add_child(apagar_save)
	rodape.move_child(apagar_save, 1)
	apagar_save.pressed.connect(_on_apagar_save_pressed)

	confirmar_apagar_save = ConfirmationDialog.new()
	confirmar_apagar_save.name = "ConfirmarApagarSave"
	confirmar_apagar_save.min_size = Vector2i(560, 220)
	confirmar_apagar_save.unresizable = true
	confirmar_apagar_save.exclusive = true
	add_child(confirmar_apagar_save)
	confirmar_apagar_save.confirmed.connect(_on_apagar_save_confirmado)
	confirmar_apagar_save.canceled.connect(_on_apagar_save_cancelado)
	_atualizar_textos_save()


func _atualizar_textos_save() -> void:
	if is_instance_valid(apagar_save) and not save_apagado:
		apagar_save.text = tr("B_DELETE_SAVE")
		apagar_save.tooltip_text = tr("T_DELETE_SAVE_HINT")
	if is_instance_valid(confirmar_apagar_save):
		confirmar_apagar_save.title = tr("T_DELETE_SAVE_TITLE")
		confirmar_apagar_save.dialog_text = tr("T_DELETE_SAVE_CONFIRM")
		confirmar_apagar_save.ok_button_text = tr("B_DELETE_EVERYTHING")
		confirmar_apagar_save.cancel_button_text = tr("B_CANCEL")


func _on_apagar_save_pressed() -> void:
	_cancelar_captura()
	confirmar_apagar_save.popup_centered()
	confirmar_apagar_save.get_cancel_button().call_deferred("grab_focus")


func _on_apagar_save_cancelado() -> void:
	if is_instance_valid(apagar_save) and not apagar_save.disabled:
		apagar_save.call_deferred("grab_focus")


func _on_apagar_save_confirmado() -> void:
	Global.apagar_save_completo()
	save_apagado = true
	carregar_interface()
	_atualizar_textos_mapeamentos()
	apagar_save.text = tr("T_SAVE_DELETED")
	apagar_save.tooltip_text = ""
	apagar_save.disabled = true
	voltar.call_deferred("grab_focus")


func _criar_lista_mapeamentos() -> void:
	for child in lista_mapeamentos.get_children():
		child.queue_free()
	botoes_mapeamento.clear()

	_criar_cabecalho_mapeamentos()
	for acao in Global.obter_acoes_remapeaveis():
		var linha := HBoxContainer.new()
		linha.name = "Acao_" + str(acao)
		linha.add_theme_constant_override("separation", 8)
		lista_mapeamentos.add_child(linha)

		var rotulo := Label.new()
		rotulo.name = "Rotulo"
		rotulo.custom_minimum_size = Vector2(160.0, 42.0)
		rotulo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		rotulo.add_theme_font_size_override("font_size", 12)
		rotulo.set_meta("chave_traducao", Global.obter_acoes_remapeaveis()[acao])
		linha.add_child(rotulo)

		for slot in Global.MAX_SLOTS_CONTROLE:
			var botao := _criar_botao_mapeamento()
			botao.set_meta("acao", acao)
			botao.set_meta("slot", slot)
			botao.pressed.connect(_on_slot_mapeamento_pressed.bind(acao, slot, botao))
			botao.focus_entered.connect(_on_slot_focado.bind(botao))
			linha.add_child(botao)
			botoes_mapeamento[_chave_slot(acao, slot)] = botao

	_atualizar_rotulos_acoes()
	_atualizar_textos_mapeamentos()


func _criar_cabecalho_mapeamentos() -> void:
	var cabecalho := HBoxContainer.new()
	cabecalho.name = "Cabecalho"
	cabecalho.add_theme_constant_override("separation", 8)
	lista_mapeamentos.add_child(cabecalho)
	for texto in ["AÇÃO", "SLOT 1", "SLOT 2", "SLOT 3"]:
		var rotulo := Label.new()
		rotulo.custom_minimum_size = Vector2(160.0, 24.0) if texto == "AÇÃO" else Vector2(142.0, 24.0)
		rotulo.text = texto
		rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rotulo.add_theme_color_override("font_color", Color(0.38, 0.78, 0.94, 1.0))
		rotulo.add_theme_font_size_override("font_size", 10)
		cabecalho.add_child(rotulo)


func _criar_botao_mapeamento() -> Button:
	var botao := Button.new()
	botao.custom_minimum_size = Vector2(142.0, 42.0)
	botao.focus_mode = Control.FOCUS_ALL
	botao.clip_text = true
	botao.expand_icon = false
	botao.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	botao.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	botao.add_theme_font_size_override("font_size", 10)
	botao.add_theme_color_override("font_color", Color(0.72, 0.94, 1.0, 1.0))
	botao.add_theme_color_override("font_focus_color", Color.WHITE)
	botao.add_theme_stylebox_override("normal", _estilo_slot(Color(0.035, 0.075, 0.12, 0.96), Color(0.16, 0.56, 0.72, 0.8)))
	botao.add_theme_stylebox_override("hover", _estilo_slot(Color(0.05, 0.12, 0.18, 1.0), Color(0.28, 0.86, 1.0, 1.0)))
	botao.add_theme_stylebox_override("focus", _estilo_slot(Color(0.06, 0.16, 0.22, 1.0), Color(0.48, 1.0, 0.82, 1.0)))
	botao.add_theme_stylebox_override("pressed", _estilo_slot(Color(0.08, 0.2, 0.25, 1.0), Color(0.65, 1.0, 0.88, 1.0)))
	return botao


func _on_slot_focado(botao: Button) -> void:
	call_deferred("_garantir_slot_visivel", botao)


func _garantir_slot_visivel(botao: Button) -> void:
	if is_instance_valid(botao) and rolagem_mapeamentos.is_ancestor_of(botao):
		rolagem_mapeamentos.ensure_control_visible(botao)


func _estilo_slot(fundo: Color, borda: Color) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = fundo
	estilo.border_color = borda
	estilo.set_border_width_all(1)
	estilo.set_corner_radius_all(5)
	estilo.content_margin_left = 7.0
	estilo.content_margin_right = 7.0
	return estilo


func _on_slot_mapeamento_pressed(acao: StringName, slot: int, botao: Button) -> void:
	if capturando_entrada:
		_cancelar_captura()
	capturando_entrada = true
	captura_pronta = false
	acao_capturada = acao
	slot_capturado = slot
	botao_capturado = botao
	botao.icon = null
	botao.text = "[ ... ]"
	instrucao_mapeamento.text = tr("T_BIND_WAITING")
	# O clique/acionamento que selecionou este botão ainda está sendo propagado.
	# A captura começa no próximo ciclo para ele nunca virar o novo vínculo.
	call_deferred("_armar_captura", acao, slot)


func _armar_captura(acao: StringName, slot: int) -> void:
	# A verificação evita que um deferred antigo arme outro slot caso o jogador
	# mude de seleção ou cancele muito rapidamente.
	if capturando_entrada and acao_capturada == acao and slot_capturado == slot:
		captura_pronta = true


func _finalizar_captura() -> void:
	capturando_entrada = false
	captura_pronta = false
	acao_capturada = &""
	slot_capturado = -1
	botao_capturado = null
	instrucao_mapeamento.text = tr("T_BIND_INSTRUCTION")
	_atualizar_textos_mapeamentos()


func _confirmar_mapeamento(
	acao: StringName,
	slot: int,
	evento: InputEvent
) -> void:
	Global.definir_mapeamento(acao, slot, evento)
	_finalizar_captura()


func _cancelar_captura() -> void:
	if not capturando_entrada:
		return
	_finalizar_captura()


func _solicitou_limpar_slot(event: InputEvent) -> bool:
	if event is InputEventKey and event.pressed and not event.echo:
		return event.keycode in [KEY_DELETE, KEY_BACKSPACE]
	if event is InputEventJoypadButton and event.pressed:
		return event.button_index == JOY_BUTTON_X
	return false


func _limpar_slot_focado() -> void:
	var foco := get_viewport().gui_get_focus_owner()
	if not foco or not foco.has_meta("acao") or not foco.has_meta("slot"):
		return
	Global.limpar_mapeamento(
		StringName(str(foco.get_meta("acao"))),
		int(foco.get_meta("slot"))
	)
	_atualizar_textos_mapeamentos()


func _atualizar_rotulos_acoes() -> void:
	if not is_instance_valid(lista_mapeamentos):
		return
	for rotulo in lista_mapeamentos.find_children("Rotulo", "Label", true, false):
		rotulo.text = tr(str(rotulo.get_meta("chave_traducao", "")))
	restaurar_controles.text = tr("B_RESTORE_CONTROLS")
	if not capturando_entrada:
		instrucao_mapeamento.text = tr("T_BIND_INSTRUCTION")


func _atualizar_textos_mapeamentos() -> void:
	for acao in Global.obter_acoes_remapeaveis():
		for slot in Global.MAX_SLOTS_CONTROLE:
			var botao = botoes_mapeamento.get(_chave_slot(acao, slot)) as Button
			if not is_instance_valid(botao):
				continue
			if capturando_entrada and botao == botao_capturado:
				continue
			var evento: InputEvent = Global.obter_evento_mapeado(acao, slot)
			var nome_evento := _nome_evento(evento)
			var icone := IconesControle.textura_para_evento(evento)
			botao.icon = icone
			botao.text = "" if icone != null else nome_evento
			botao.tooltip_text = nome_evento


func _nome_evento(evento: InputEvent) -> String:
	if evento == null:
		return tr("T_BIND_EMPTY")
	if evento is InputEventKey:
		var tecla := evento as InputEventKey
		var codigo := tecla.physical_keycode if tecla.physical_keycode != 0 else tecla.keycode
		var partes: Array[String] = []
		if tecla.ctrl_pressed:
			partes.append("CTRL")
		if tecla.alt_pressed:
			partes.append("ALT")
		if tecla.shift_pressed:
			partes.append("SHIFT")
		if tecla.meta_pressed:
			partes.append("META")
		partes.append(OS.get_keycode_string(codigo).to_upper())
		return "+".join(partes)
	if evento is InputEventMouseButton:
		var nomes_mouse := {
			MOUSE_BUTTON_LEFT: "MOUSE 1",
			MOUSE_BUTTON_RIGHT: "MOUSE 2",
			MOUSE_BUTTON_MIDDLE: "MOUSE 3",
			MOUSE_BUTTON_WHEEL_UP: "RODA ↑",
			MOUSE_BUTTON_WHEEL_DOWN: "RODA ↓",
		}
		return nomes_mouse.get(evento.button_index, "MOUSE %d" % evento.button_index)
	if evento is InputEventJoypadButton:
		return _nome_botao_controle(evento.button_index)
	if evento is InputEventJoypadMotion:
		return _nome_eixo_controle(evento.axis, evento.axis_value)
	return evento.as_text()


func _nome_botao_controle(indice: int) -> String:
	var playstation := _controle_conectado_e_playstation()
	var nomes_xbox := ["A", "B", "X", "Y", "VIEW", "HOME", "MENU", "L3", "R3", "LB", "RB", "D-PAD ↑", "D-PAD ↓", "D-PAD ←", "D-PAD →"]
	var nomes_ps := ["X", "CÍRCULO", "QUADRADO", "TRIÂNGULO", "SHARE", "PS", "OPTIONS", "L3", "R3", "L1", "R1", "D-PAD ↑", "D-PAD ↓", "D-PAD ←", "D-PAD →"]
	var nomes := nomes_ps if playstation else nomes_xbox
	return nomes[indice] if indice >= 0 and indice < nomes.size() else "BOTÃO %d" % (indice + 1)


func _nome_eixo_controle(eixo: int, valor: float) -> String:
	var direcao := "+" if valor > 0.0 else "−"
	var nomes := ["LS X", "LS Y", "RS X", "RS Y", "LT / L2", "RT / R2"]
	if eixo == JOY_AXIS_TRIGGER_LEFT:
		return "LT / L2"
	if eixo == JOY_AXIS_TRIGGER_RIGHT:
		return "RT / R2"
	return (nomes[eixo] if eixo >= 0 and eixo < nomes.size() else "EIXO %d" % eixo) + " " + direcao


func _controle_conectado_e_playstation() -> bool:
	var controles := Input.get_connected_joypads()
	if controles.is_empty():
		return false
	var nome := Input.get_joy_name(controles[0]).to_lower()
	return "playstation" in nome or "dualshock" in nome or "dualsense" in nome or "sony" in nome


func _chave_slot(acao: StringName, slot: int) -> String:
	return "%s:%d" % [acao, slot]
