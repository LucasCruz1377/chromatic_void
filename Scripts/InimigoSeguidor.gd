extends InimigoBase

var direcao = Vector2.ZERO

func _physics_process(delta):
	Mover(delta)
	
	move_and_slide()
func Mover(Delta):
	if player:
		direcao = (player.global_position - global_position).normalized()
		velocity += direcao * Velocidade * Delta
