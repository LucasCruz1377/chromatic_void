# Comportamento e desenho especificos desta especie.
extends "res://Scripts/InimigoSetorialBase.gd"

const Crescente := preload("res://Scripts/CrescenteBumerangue.gd")


func _mover_especie(ate: Vector2, distancia: float, delta: float) -> void:
	velocity = velocity.move_toward(_distancia(ate, distancia, 330.0) * Velocidade, 210.0 * delta)


func _executar() -> void:
	EfeitoCombateCena.criar(
		get_tree().current_scene,
		global_position,
		EfeitoCombate.Tipo.ACERTO,
		cor_setor,
		0.55,
		direcao
	)
	Crescente.criar(get_tree().current_scene, self, direcao, Dano * 0.7, cor_setor)


func _draw() -> void:
	var c := cor_setor.lightened(0.1)
	draw_arc(Vector2.ZERO, 20, -1.3, 1.3, 24, c, 7)
	draw_circle(Vector2(7, 0), 15, Color(.01, .02, .08))
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
	estilo = Estilo.FRAGMENTO_LUNAR
