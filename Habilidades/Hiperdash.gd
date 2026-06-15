extends Habilidade
class_name Hiperdash

@export var velocidade_dash : int = 200
@export var desaceleracao : float = 0.2
@export var desaceleracao_tempo : float
@export var intervalo : float

var ativo = false


func activate(player):
	if ativo:
		return
	
	ativo = true
	player.MAX_VELOCIDADE = 10000
	player.BloquearControle()
	Engine.time_scale = desaceleracao_tempo
	await player.get_tree().create_timer(intervalo)
	player.BloquearGiro()
	Engine.time_scale = 1
	player.velocity += velocidade_dash
	await player.get_tree().create_timer(intervalo)
	player.velocity *= desaceleracao
	player.DesbloquearControle()
	player.DesbloquearGiro()
	player.MAX_VELOCIDADE = 500
	ativo = false
func update(player,delta):
	pass
