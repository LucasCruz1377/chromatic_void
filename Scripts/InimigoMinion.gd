extends InimigoBase


@export var aceleracao: float = 440.0
@export var oscilacao: float = 2.8

var fase_oscilacao: float = 0.0


func _ready() -> void:
	super._ready()
	fase_oscilacao = randf_range(0.0, TAU)


func Mover(delta: float) -> void:
	if not is_instance_valid(player):
		return

	fase_oscilacao += delta * oscilacao
	var ate_player := global_position.direction_to(player.global_position)
	var lateral := ate_player.orthogonal() * sin(fase_oscilacao) * 0.45
	var direcao := (ate_player + lateral).normalized()
	velocity = velocity.move_toward(direcao * Velocidade, aceleracao * delta)
