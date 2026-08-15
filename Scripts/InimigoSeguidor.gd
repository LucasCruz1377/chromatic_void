extends InimigoBase


@export var aceleracao: float = 280.0


func Mover(delta: float) -> void:
	if not is_instance_valid(player):
		velocity = velocity.move_toward(Vector2.ZERO, aceleracao * delta)
		return

	var direcao := global_position.direction_to(player.global_position)
	velocity = velocity.move_toward(direcao * Velocidade, aceleracao * delta)
