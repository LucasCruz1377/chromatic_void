# Comportamento e desenho especificos desta especie.
extends "res://Scripts/InimigoSetorialBase.gd"

const Perigo := preload("res://Scripts/PerigoSetorial.gd")


func _mover_especie(ate: Vector2, distancia: float, delta: float) -> void:
	velocity = velocity.move_toward(_distancia(ate, distancia, 320.0) * Velocidade, 150.0 * delta)


func _destino_e_aviso() -> void:
	var cena := get_tree().current_scene
	if not is_instance_valid(cena):
		return
	Perigo.criar(
		cena,
		Perigo.Forma.PUXAO,
		global_position,
		global_position,
		cor_setor,
		preparo,
		0.95,
		Dano * 0.2,
		150.0,
		58.0
	)


func _draw() -> void:
	var c := cor_setor.lightened(0.1)
	draw_circle(Vector2.ZERO, 8, Color(.02, .01, .08))
	draw_arc(Vector2.ZERO, 18, -tempo, TAU - tempo, 28, c, 5)
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
	estilo = Estilo.ECO_GRAVITACIONAL
