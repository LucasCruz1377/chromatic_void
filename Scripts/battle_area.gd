extends Node2D

@onready var target : Marker2D
@onready var contpontos: Label = $GUI/Pontos
@onready var player: CharacterBody2D = $CharacterBody2D
@onready var caixa_gameover: VBoxContainer = $"GUI/caixa gameover"
@onready var tocarmusica: AudioStreamPlayer2D = $tocarmusica


const ENEMY = preload("res://Entities/enemy.tscn")
const TIMER_MAX = 2 * 60

var players = []

var timer = TIMER_MAX
var pontos = 0

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	players = get_tree().get_nodes_in_group("player")
	tocarmusica.play()
func _process(_delta: float) -> void:
	tocarmusica.pitch_scale = Engine.time_scale
	
	var pontos_tg = Global.Pontos
	players = get_tree().get_nodes_in_group("player")
	if pontos < pontos_tg:
		pontos += 1 * Global.Combo
	
	contpontos.text = str(int(pontos)).pad_zeros(8)
	
	if timer >= 0:
		timer -= 1 
	else:
		spawnar_enemy()
		timer = randi_range(0,TIMER_MAX)
		
	if players.size() <= 0:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		caixa_gameover.visible = true
		
func spawnar_enemy():
	var spawners = get_tree().get_nodes_in_group("spawners")
	
	if spawners.size() == 0 or players.size() == 0:
		return

	var inimigo = ENEMY.instantiate()
	get_tree().current_scene.add_child(inimigo)
	
	var spawner = spawners.pick_random()
	inimigo.global_position = spawner.global_position
