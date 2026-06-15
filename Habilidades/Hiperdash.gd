extends Habilidade
class_name Hiperdash

@export var velocidade_dash : int = 200
@export var desaceleracao : float = 0.2
@export var desaceleracao_tempo : float
@export var intervalo : float

var ativo = false


func activate(player):
	if ativo :
		return

	ativo = true
	player.BloquearControle()
	Engine.time_scale = desaceleracao_tempo
	await player.get_tree().create_timer(intervalo).timeout
	player.BloquearGiro()
	Engine.time_scale = 1
	player.velocity += player.transform.x * player.SPEED * 5
	await player.get_tree().create_timer(0.25).timeout
	player.velocity *= desaceleracao
	await player.get_tree().create_timer(intervalo).timeout
	ativo = false
	player.DesbloquearControle()
	player.DesbloquearGiro()
	
func update(player,delta):
	if ativo:
		player.IniciarHabilidade()
	else:
		player.EncerrarHabilidade()
