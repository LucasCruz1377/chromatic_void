# Comportamento e desenho especificos desta especie.
extends "res://Scripts/InimigoSetorialBase.gd"

var fechado := false


func _mover_especie(ate: Vector2, distancia: float, delta: float) -> void:
	velocity = velocity.move_toward(_distancia(ate, distancia, 265.0) * Velocidade, 150.0 * delta)


func _executar() -> void:
	EfeitoCombateCena.criar(
		get_tree().current_scene,
		global_position,
		EfeitoCombate.Tipo.ACERTO,
		cor_setor,
		0.55,
		direcao
	)
	fechado = not fechado
	multiplicador_dano_recebido = 0.08 if fechado else 1.0
	if not fechado:
		_radial(8, 235.0, Dano * 0.4)


func _draw() -> void:
	var c := cor_setor.lightened(0.1)
	draw_colored_polygon(
		PackedVector2Array([Vector2(0, -22), Vector2(15, 0), Vector2(0, 22), Vector2(-15, 0)]), c
	)
	draw_arc(Vector2.ZERO, 20, 0, TAU, 28, Color.WHITE, 3)
	draw_line(Vector2(0, -12), Vector2(8, 0), cor_setor.darkened(0.5), 2.0, true)
	draw_line(Vector2(8, 0), Vector2(0, 12), cor_setor.darkened(0.5), 2.0, true)
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
	estilo = Estilo.CASULO_PRISMATICO
