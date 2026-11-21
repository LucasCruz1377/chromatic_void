# Comportamento e desenho especificos desta especie.
extends "res://Scripts/InimigoSetorialBase.gd"


func _mover_especie(ate: Vector2, distancia: float, delta: float) -> void:
	velocity = velocity.move_toward(
		ate.rotated(1.1 + sin(tempo * 2.0) * 0.25) * Velocidade, 230.0 * delta
	)


func _executar() -> void:
	EfeitoCombateCena.criar(
		get_tree().current_scene,
		global_position,
		EfeitoCombate.Tipo.ACERTO,
		cor_setor,
		0.55,
		direcao
	)
	velocity = direcao.rotated(0.52) * Velocidade * 2.4


func _draw() -> void:
	var c := cor_setor.lightened(0.1)
	draw_arc(Vector2.ZERO, 18, tempo, tempo + 5.2, 32, c, 6)
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
	estilo = Estilo.CIPO_ESPIRAL
