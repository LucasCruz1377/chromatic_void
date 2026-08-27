extends InimigoBase


@export var aceleracao: float = 280.0
@export var oscilacao_lateral: float = 0.18

var fase_movimento := 0.0


func _ready() -> void:
	super._ready()
	fase_movimento = randf_range(0.0, TAU)


func Mover(delta: float) -> void:
	if not is_instance_valid(player):
		velocity = velocity.move_toward(Vector2.ZERO, aceleracao * delta)
		return

	var direcao := global_position.direction_to(player.global_position)
	fase_movimento += delta * 2.2
	direcao = (
		direcao + direcao.orthogonal() * sin(fase_movimento) * oscilacao_lateral
	).normalized()
	velocity = velocity.move_toward(direcao * Velocidade, aceleracao * delta)
