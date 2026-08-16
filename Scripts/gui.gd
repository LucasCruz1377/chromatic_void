extends CanvasLayer


@onready var caixa_pause: VBoxContainer = $"caixa pause"
@onready var camera = $"../Camera"
@onready var display_skill = $DisplaySkill
@export var quantidadeOpcoesUpgrade: int
@onready var player = get_tree().get_first_node_in_group("player")
@onready var tela_upgrades: Control = $TelaUpgrades


func _ready() -> void:
	player.subiuDeNivel.connect(_on_player_subiu_de_nivel)


func _on_player_subiu_de_nivel() -> void:
	camera.offset = Vector2.ZERO


func _process(_delta: float) -> void:
	var players := get_tree().get_nodes_in_group("player").size()

	if Input.is_action_just_pressed("pausar") and players > 0:
		if tela_upgrades.has_method("esta_aberta") and bool(
			tela_upgrades.call("esta_aberta")
		):
			tela_upgrades.call("fechar_menu")
		else:
			get_tree().paused = not get_tree().paused

	caixa_pause.visible = get_tree().paused

	if Input.is_action_just_pressed("reset"):
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
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _on_tentar_de_novo_pressed() -> void:
	preparar_troca_de_cena()
	Global.Pontos = 0
	Global.Combo = 0
	get_tree().reload_current_scene()


func _on_despause_pressed() -> void:
	get_tree().paused = false


func _on_voltarmenu_2_pressed() -> void:
	preparar_troca_de_cena()
	get_tree().change_scene_to_file("res://Rooms/TelaInicial.tscn")


func _on_voltarmenu_pressed() -> void:
	preparar_troca_de_cena()
	get_tree().change_scene_to_file("res://Rooms/TelaInicial.tscn")
