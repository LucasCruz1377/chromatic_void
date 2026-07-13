extends CharacterBody2D
class_name InimigoBase

@export var VidaMaxima := 100
@export var Dano := 2
@export var ValorXP := 1
@export var Velocidade := 100
@export var usa_wrap : bool = true
var Vida := VidaMaxima

@onready var player = get_tree().get_first_node_in_group("player")

# Called when the node enters the scene tree for the first time.
func _ready():
	Vida = VidaMaxima + (1 * int(player.nivel_atual / 5))

func _physics_process(delta):
	if usa_wrap:
		position.x = wrap(position.x,0,960)
		position.y = wrap(position.y,0,540)
	velocity.limit_length(Velocidade)
	Mover(delta)
	move_and_slide()

func Mover(Delta):
	pass
	
func tomarDano(valor):
	if Vida <= 0:
		morrer()
	Vida -= valor
	
func morrer():
	queue_free()
