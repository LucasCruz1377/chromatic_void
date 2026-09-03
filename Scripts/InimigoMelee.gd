extends InimigoBase


enum Estado {
	CERCANDO,
	AVISANDO,
	GOLPEANDO,
	RECUPERANDO,
}

@export var aceleracao: float = 330.0
@export var distancia_golpe: float = 105.0
@export var tempo_aviso: float = 0.38
@export var duracao_golpe: float = 0.24
@export var tempo_recuperacao: float = 0.75
@export var velocidade_golpe: float = 430.0

var estado := Estado.CERCANDO
var tempo_estado: float = 0.0
var direcao_golpe := Vector2.RIGHT
var dano_aplicado: bool = false
var lado_orbita: float = 1.0

@onready var golpe: Area2D = $Golpe
@onready var visual: Node2D = $Visual


func _ready() -> void:
	super._ready()
	lado_orbita = [-1.0, 1.0].pick_random()
	golpe.monitoring = false


func Mover(delta: float) -> void:
	if not is_instance_valid(player):
		return

	match estado:
		Estado.CERCANDO:
			cercar(delta)
		Estado.AVISANDO:
			avisar(delta)
		Estado.GOLPEANDO:
			golpear(delta)
		Estado.RECUPERANDO:
			recuperar(delta)


func obter_velocidade_maxima() -> float:
	if estado == Estado.GOLPEANDO:
		return velocidade_golpe
	return Velocidade


func cercar(delta: float) -> void:
	var ate_player := global_position.direction_to(player.global_position)
	var distancia := global_position.distance_to(player.global_position)
	var direcao_lateral := ate_player.orthogonal() * lado_orbita
	var direcao := (ate_player + direcao_lateral * 0.42).normalized()
	velocity = velocity.move_toward(direcao * Velocidade, aceleracao * delta)

	if distancia <= distancia_golpe:
		estado = Estado.AVISANDO
		tempo_estado = tempo_aviso
		direcao_golpe = ate_player
		visual.modulate = Color(1.0, 0.35, 0.25, 1.0)
		var tween := create_tween().set_loops(2)
		tween.tween_property(visual, "scale", Vector2(1.14, 0.86), tempo_aviso / 4.0)
		tween.tween_property(visual, "scale", Vector2.ONE, tempo_aviso / 4.0)
		EfeitoCombateCena.criar(
			get_tree().current_scene,
			global_position,
			EfeitoCombate.Tipo.AVISO,
			Color(1.0, 0.28, 0.24),
			0.75,
			direcao_golpe
		)


func avisar(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, aceleracao * 2.0 * delta)
	tempo_estado -= delta
	rotation = direcao_golpe.angle()
	if tempo_estado <= 0.0:
		estado = Estado.GOLPEANDO
		tempo_estado = duracao_golpe
		dano_aplicado = false
		golpe.monitoring = true
		velocity = direcao_golpe * velocidade_golpe
		visual.scale = Vector2(1.22, 0.78)
		EfeitoCombateCena.criar(
			get_tree().current_scene,
			global_position,
			EfeitoCombate.Tipo.RASTRO,
			Color(1.0, 0.22, 0.32),
			0.9,
			direcao_golpe
		)


func golpear(delta: float) -> void:
	tempo_estado -= delta
	velocity = velocity.move_toward(
		direcao_golpe * velocidade_golpe,
		aceleracao * delta
	)

	if not dano_aplicado:
		for corpo in golpe.get_overlapping_bodies():
			if corpo.is_in_group("player") and corpo.has_method("tomar_dano"):
				corpo.tomar_dano(Dano)
				dano_aplicado = true
				break

	if tempo_estado <= 0.0:
		golpe.monitoring = false
		estado = Estado.RECUPERANDO
		tempo_estado = tempo_recuperacao
		visual.modulate = Color(0.65, 0.65, 0.65, 1.0)
		visual.scale = Vector2(0.9, 1.1)


func recuperar(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, aceleracao * 1.5 * delta)
	tempo_estado -= delta
	if tempo_estado <= 0.0:
		estado = Estado.CERCANDO
		visual.modulate = Color.WHITE
		visual.scale = Vector2.ONE
		lado_orbita *= -1.0


func ao_colidir_com_player(_alvo: Node) -> void:
	# O dano deste inimigo vem da área do golpe, não do corpo.
	pass
