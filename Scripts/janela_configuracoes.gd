extends Control


signal voltar_solicitado

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
@onready var restaurar: Button = $Painel/Margem/Coluna/Rodape/Restaurar
@onready var voltar: Button = $Painel/Margem/Coluna/Rodape/Voltar

var carregando := false
var fps_disponiveis := [0, 30, 60, 120, 144, 240]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_configurar_opcoes()
	_conectar_sinais()
	carregar_interface()
	_atualizar_titulos_abas()
	atualizar_controles_detectados()
	call_deferred("_focar_primeiro_controle")


func _unhandled_input(event: InputEvent) -> void:
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
	if carregando:
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
		return

	var nomes: Array[String] = []
	for dispositivo in controles:
		nomes.append(Input.get_joy_name(dispositivo))
	controle_detectado.text = "Detectado: " + ", ".join(nomes)


func _on_conexao_controle_alterada(_dispositivo: int, _conectado: bool) -> void:
	atualizar_controles_detectados()


func _on_restaurar_pressed() -> void:
	Global.restaurar_configuracoes_padrao()
	carregar_interface()


func _on_voltar_pressed() -> void:
	_salvar()
	voltar_solicitado.emit()


func _on_aba_alterada(_indice: int) -> void:
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
