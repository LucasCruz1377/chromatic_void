# Comportamento e desenho especificos desta especie.
extends "res://Scripts/InimigoSetorialBase.gd"

const Perigo := preload("res://Scripts/PerigoSetorial.gd")


func _ready() -> void:
	super._ready()
	Velocidade *= 1.35


func _mover_especie(ate: Vector2, distancia: float, delta: float) -> void:
	velocity = velocity.move_toward(
		ate.rotated(sin(tempo * 2.5) * 0.92) * Velocidade, 270.0 * delta
	)
	if tempo_trilha <= 0.0 and global_position.distance_to(trilha) > 24.0:
		Perigo.criar(
			get_tree().current_scene,
			Perigo.Forma.LINHA,
			trilha,
			global_position,
			cor_setor,
			0.06,
			1.1,
			Dano * 0.35,
			11.0
		)
		trilha = global_position
		tempo_trilha = 0.11


func _executar() -> void:
	EfeitoCombateCena.criar(
		get_tree().current_scene,
		global_position,
		EfeitoCombate.Tipo.ACERTO,
		cor_setor,
		0.55,
		direcao
	)
	velocity = direcao.rotated(0.68) * Velocidade * 2.7


func _draw() -> void:
	var c := cor_setor.lightened(0.1)
	draw_polyline(
		PackedVector2Array(
			[Vector2(-24, 0), Vector2(-12, -9), Vector2(0, 8), Vector2(12, -8), Vector2(24, 0)]
		),
		c,
		7,
		true
	)
	# Núcleo e partículas de carga preservam a silhueta de cada espécie.
	draw_circle(Vector2.ZERO, 4.0, Color(0.03, 0.04, 0.10))
	draw_circle(direcao * 2.0, 1.8, Color.WHITE)
	if preparando:
		for i in 5:
			var ponto := (
				Vector2.from_angle(float(i) * TAU / 5.0 + tempo)
				* (12.0 + maxf(preparo, 0.0) * 22.0)
			)
			draw_circle(ponto, 2.0, cor_setor.lightened(0.4))


func _init() -> void:
	estilo = Estilo.FITA_VIOLETA
