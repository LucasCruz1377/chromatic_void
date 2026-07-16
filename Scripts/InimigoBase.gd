extends CharacterBody2D
class_name InimigoBase

@export_group("Configuração")
@export var VidaMaxima := 100
@export var Dano := 2
@export var ValorXP := 1
@export var Velocidade := 30
@export var usa_wrap : bool = true
var Vida : int

@onready var player = get_tree().get_first_node_in_group("player")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func _physics_process(delta):
	pass

func Mover(Delta):
	pass
	
func tomarDano(valor):
	pass
	
func morrer():
	pass
