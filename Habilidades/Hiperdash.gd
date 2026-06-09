extends Habilidade
class_name HiperDash

@export var ForcaDash := 3000.0
@export var TimerLentidao := 0.3
@export var DuracaoDash := 0.4
@export var EscalaLentidao := 0.3
@export var Particulas : ParticleProcessMaterial

func activate(player:Node2D):
	
	Engine.time_scale = EscalaLentidao
	await player.get_tree().create_timer(TimerLentidao).timeout
	Engine.time_scale = 1
	player.velocity += player.transform.x * ForcaDash
	await player.get_tree().create_timer(DuracaoDash).timeout
	player.velocity *= EscalaLentidao
