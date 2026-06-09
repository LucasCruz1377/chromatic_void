extends Habilidade
class_name HiperDash

@export var ForcaDash := 300.0

func activate(player):
	player.velocity += player.tranform.x * ForcaDash
