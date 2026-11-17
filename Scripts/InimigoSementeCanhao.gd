# Comportamento e desenho especificos desta especie.
extends "res://Scripts/InimigoSetorialBase.gd"


func _mover_especie(ate: Vector2, distancia: float, delta: float) -> void:
	velocity = velocity.move_toward(_distancia(ate, distancia, 355.0) * Velocidade, 200.0 * delta)


func _executar() -> void:
	EfeitoCombateCena.criar(
		get_tree().current_scene,
		global_position,
		EfeitoCombate.Tipo.ACERTO,
		cor_setor,
		0.55,
		direcao
	)
	_leque(3, 0.28, 315.0, Dano * 0.58)


func _draw() -> void:
	var c := cor_setor.lightened(0.1)
	draw_circle(Vector2.ZERO, 14, c)
	draw_line(Vector2.ZERO, direcao * 26, Color.WHITE, 8)
	for lado in [-1.0, 1.0]:
		var folha := PackedVector2Array(
			[Vector2(-5, 0), Vector2(-19, lado * 13), Vector2(-20, lado * 3)]
		)
		draw_colored_polygon(folha, cor_setor.darkened(0.3))
		draw_line(Vector2(-6, 0), Vector2(-18, lado * 8), cor_setor.lightened(0.4), 1.5, true)
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
	estilo = Estilo.SEMENTE_CANHAO
