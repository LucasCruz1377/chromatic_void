extends CanvasLayer


const IconesControle = preload("res://Scripts/IndicadoresControle.gd")

@onready var caixa_pause: VBoxContainer = $"caixa pause"
@onready var camera = $"../Camera"
@onready var display_skill = $DisplaySkill
@onready var indicador_habilidade: TextureRect = $DisplaySkill/IndicadorBotao
@export var quantidadeOpcoesUpgrade: int
@onready var player = get_tree().get_first_node_in_group("player")
@onready var tela_upgrades: Control = $TelaUpgrades
@onready var botao_despause: Button = $"caixa pause/despause"
@onready var botao_voltar_pause: Button = $"caixa pause/voltarmenu"
@onready var caixa_gameover: VBoxContainer = $"caixa gameover"
@onready var botao_tentar_novamente: Button = $"caixa gameover/Tentar de novo"
@onready var botao_voltar_gameover: Button = $"caixa gameover/Voltarmenu2"
@onready var barra_vida: TextureProgressBar = $Barra_vida
@onready var barra_xp: TextureProgressBar = $Barra_xp
@onready var texto_nivel: Label = $LvlText

var pausa_anterior := false
var gameover_anterior := false


func _ready() -> void:
	player.subiuDeNivel.connect(_on_player_subiu_de_nivel)
	pausa_anterior = get_tree().paused
	gameover_anterior = caixa_gameover.visible
	botao_tentar_novamente.focus_neighbor_bottom = (
		botao_tentar_novamente.get_path_to(botao_voltar_gameover)
	)
	botao_voltar_gameover.focus_neighbor_top = (
		botao_voltar_gameover.get_path_to(botao_tentar_novamente)
	)
	botao_tentar_novamente.focus_neighbor_top = (
		botao_tentar_novamente.get_path_to(botao_voltar_gameover)
	)
	botao_voltar_gameover.focus_neighbor_bottom = (
		botao_voltar_gameover.get_path_to(botao_tentar_novamente)
	)
	botao_voltar_pause.focus_neighbor_top = (
		botao_voltar_pause.get_path_to(botao_despause)
	)
	botao_voltar_pause.focus_neighbor_bottom = (
		botao_voltar_pause.get_path_to(botao_despause)
	)
	botao_despause.focus_neighbor_top = (
		botao_despause.get_path_to(botao_voltar_pause)
	)
	botao_despause.focus_neighbor_bottom = (
		botao_despause.get_path_to(botao_voltar_pause)
	)
	Global.dispositivo_alterado.connect(_on_dispositivo_alterado)
	Global.configuracoes_alteradas.connect(_atualizar_indicador_habilidade)
	Input.joy_connection_changed.connect(_on_controle_conectado)
	get_viewport().size_changed.connect(_ajustar_hud_responsivo)
	_atualizar_indicador_habilidade()
	call_deferred("_ajustar_hud_responsivo")


func _ajustar_hud_responsivo() -> void:
	_aplicar_layout_hud(get_viewport().get_visible_rect().size)


func _aplicar_layout_hud(tamanho: Vector2) -> void:
	if tamanho.x <= 0.0 or tamanho.y <= 0.0:
		return
	var margem := minf(18.0, tamanho.x * 0.05)
	var largura_barra := minf(630.0, tamanho.x - margem * 2.0)
	largura_barra = minf(largura_barra, tamanho.x * 0.70)
	var centro_x := tamanho.x * 0.5
	var inicio_x := centro_x - largura_barra * 0.5
	var y_vida := tamanho.y - 36.0
	for barra in [barra_vida, barra_xp]:
		if not is_instance_valid(barra):
			continue
		barra.nine_patch_stretch = true
		barra.custom_minimum_size = Vector2.ZERO
		barra.scale = Vector2.ONE
		barra.rotation = 0.0
		barra.set_anchors_preset(Control.PRESET_TOP_LEFT)
		barra.position = Vector2(inicio_x, y_vida if barra == barra_vida else y_vida - 15.0)
		barra.size = Vector2(largura_barra, 8.0 if barra == barra_vida else 6.0)
		barra.fill_mode = TextureProgressBar.FILL_BILINEAR_LEFT_AND_RIGHT
	if is_instance_valid(texto_nivel):
		texto_nivel.set_anchors_preset(Control.PRESET_TOP_LEFT)
		texto_nivel.position = Vector2(inicio_x, y_vida - 43.0)
	if is_instance_valid(display_skill):
		display_skill.set_anchors_preset(Control.PRESET_TOP_LEFT)
		display_skill.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		display_skill.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		display_skill.scale = Vector2.ONE
		display_skill.rotation = 0.0
		display_skill.position = Vector2(centro_x - 32.0, y_vida - 102.0)
		display_skill.size = Vector2(64.0, 64.0)


func _on_dispositivo_alterado(_tipo: StringName) -> void:
	_atualizar_indicador_habilidade()


func _on_controle_conectado(_dispositivo: int, _conectado: bool) -> void:
	_atualizar_indicador_habilidade()


func _atualizar_indicador_habilidade() -> void:
	var textura := IconesControle.textura_para_acao(&"Habilidade")
	indicador_habilidade.texture = textura
	indicador_habilidade.visible = (
		Global.ultimo_dispositivo == &"controle"
		and not Input.get_connected_joypads().is_empty()
		and textura != null
	)


func _on_player_subiu_de_nivel() -> void:
	camera.offset = Vector2.ZERO


func _process(_delta: float) -> void:
	var players := get_tree().get_nodes_in_group("player").size()
	var batalha := get_parent()
	var escolhendo_setor := (
		batalha != null
		and bool(batalha.get("escolha_setor_ativa"))
	)

	if Input.is_action_just_pressed("pausar") and players > 0 and not escolhendo_setor:
		if tela_upgrades.has_method("esta_aberta") and bool(
			tela_upgrades.call("esta_aberta")
		):
			tela_upgrades.call("fechar_menu")
		else:
			if (
				not get_tree().paused
				and is_instance_valid(batalha)
				and batalha.has_method("registrar_visual_boss_antes_pausa")
			):
				batalha.call("registrar_visual_boss_antes_pausa")
			get_tree().paused = not get_tree().paused
			if get_tree().paused:
				Global.definir_cursor_interface(true)
				botao_despause.call_deferred("grab_focus")
				if (
					is_instance_valid(batalha)
					and batalha.has_method("restaurar_visual_boss_durante_pausa")
				):
					batalha.call_deferred("restaurar_visual_boss_durante_pausa")
			else:
				Global.definir_cursor_interface(false)
				if (
					is_instance_valid(batalha)
					and batalha.has_method("limpar_estado_visual_boss_pausa")
				):
					batalha.call("limpar_estado_visual_boss_pausa")

	caixa_pause.visible = get_tree().paused and not escolhendo_setor
	if get_tree().paused != pausa_anterior:
		pausa_anterior = get_tree().paused

	if caixa_gameover.visible and not gameover_anterior:
		botao_tentar_novamente.call_deferred("grab_focus")
	gameover_anterior = caixa_gameover.visible

	if Input.is_action_just_pressed("reset") and not escolhendo_setor:
		preparar_troca_de_cena()
		Global.Pontos = 0
		Global.Combo = 0
		get_tree().reload_current_scene()


func preparar_troca_de_cena() -> void:
	if tela_upgrades.has_method("esta_aberta") and bool(
		tela_upgrades.call("esta_aberta")
	):
		tela_upgrades.call("fechar_menu")
	get_tree().paused = false
	Engine.time_scale = 1.0
	Global.definir_cursor_interface(true)


func _on_tentar_de_novo_pressed() -> void:
	preparar_troca_de_cena()
	Global.Pontos = 0
	Global.Combo = 0
	get_tree().reload_current_scene()


func _on_despause_pressed() -> void:
	get_tree().paused = false
	Global.definir_cursor_interface(false)
	var batalha = get_parent()
	if is_instance_valid(batalha) and batalha.has_method("limpar_estado_visual_boss_pausa"):
		batalha.call("limpar_estado_visual_boss_pausa")


func _on_voltarmenu_2_pressed() -> void:
	preparar_troca_de_cena()
	get_tree().change_scene_to_file("res://Rooms/TelaInicial.tscn")


func _on_voltarmenu_pressed() -> void:
	preparar_troca_de_cena()
	get_tree().change_scene_to_file("res://Rooms/TelaInicial.tscn")
