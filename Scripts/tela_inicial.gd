extends Node2D


const CENA_BATALHA := "res://Rooms/Battle_area.tscn"
const CENA_LOJA := "res://Rooms/Loja.tscn"
const CENA_CONFIGURACOES := "res://Rooms/configuracoes.tscn"

@onready var transition: AnimationPlayer = $transition
@onready var som: AudioStreamPlayer2D = $som
@onready var musica_menu: AudioStreamPlayer2D = $menumusica
@onready var botao_loja: Button = $CanvasLayer/CaixaMenu2/Shop
@onready var botao_iniciar: Button = $CanvasLayer/CaixaMenu2/Start
@onready var botao_sair: Button = $CanvasLayer/CaixaMenu2/Exit
@onready var texto_debug: Control = $Debug_text
@onready var botoes_menu: Array[Button] = [
	$CanvasLayer/CaixaMenu2/Start as Button,
	$CanvasLayer/CaixaMenu2/Shop as Button,
	$CanvasLayer/CaixaMenu2/Options as Button,
	$CanvasLayer/CaixaMenu2/Credits as Button,
	$CanvasLayer/CaixaMenu2/Exit as Button,
]
var tela_carregamento: Control
var texto_carregamento: Label
var carregando_cena := false


func _ready() -> void:
	Global.definir_emulacao_mouse_mobile(true)
	_criar_tela_carregamento()
	botao_sair.visible = not Global.dispositivo_mobile()
	texto_debug.visible = Global.modo_desenvolvedor
	if not botao_sair.visible:
		botoes_menu.erase(botao_sair)
	$Astro.apresentar()
	Global.aplicar_configuracoes()
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


func _on_start_pressed() -> void:
	Global.primeira_vez_jogando = false
	click_som()
	await _carregar_cena(CENA_BATALHA)


func _on_shop_pressed() -> void:
	click_som()
	await _carregar_cena(CENA_LOJA)


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


func _on_dispositivo_alterado(tipo: StringName) -> void:
	if tipo == &"controle":
		botao_iniciar.grab_focus()
