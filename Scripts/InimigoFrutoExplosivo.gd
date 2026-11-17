# Comportamento e desenho especificos desta especie.
extends "res://Scripts/InimigoSetorialBase.gd"

const Perigo := preload("res://Scripts/PerigoSetorial.gd")


func _mover_especie(ate: Vector2, distancia: float, delta: float) -> void:
	velocity = velocity.move_toward(ate * Velocidade, 120.0 * delta)


func _preparar() -> void:
	if not is_instance_valid(player):
		return
	preparando = true
	direcao = global_position.direction_to(player.global_position)
	var preparo_base := 1.05
	preparo = maxf(preparo_base * pow(0.90, indice_setor_dificuldade), 0.28)
	_destino_e_aviso()


func _destino_e_aviso() -> void:
	var cena := get_tree().current_scene
	if not is_instance_valid(cena):
		return
	Perigo.criar(
		cena,
		Perigo.Forma.CIRCULO,
		global_position,
		global_position,
		cor_setor,
		preparo,
		0.22,
		Dano,
		96.0
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
	_radial(8, 230.0, Dano * 0.36)
	Vida = 0
	morrer()


func _draw() -> void:
	var c := cor_setor.lightened(0.1)
	draw_circle(Vector2.ZERO, 16 + sin(tempo * 7) * 2, c)
	draw_arc(Vector2.ZERO, 22, 0, TAU, 28, Color.WHITE, 2)
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
	estilo = Estilo.FRUTO_EXPLOSIVO
