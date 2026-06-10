extends Habilidade
class_name HiperDash

@export var ForcaDash := 3000.0
@export var TimerLentidao := 0.3
@export var DuracaoDash := 0.4
@export var EscalaLentidao := 0.3
@export var Particulas : ParticleProcessMaterial
@export var LentidaoPosDash := 0.2

func activate(player:Node2D):
	player.IniciarHabilidade()
	player.BloquearControle()
	Engine.time_scale = EscalaLentidao
	await player.get_tree().create_timer(TimerLentidao).timeout
	player.BloquearGiro()
	Engine.time_scale = 1
	player.velocity += player.transform.x * ForcaDash
	await player.get_tree().create_timer(DuracaoDash).timeout
	player.velocity *= LentidaoPosDash
	player.DesbloquearControle()
	player.DesbloquearGiro()
	player.EncerrarHabilidade()
