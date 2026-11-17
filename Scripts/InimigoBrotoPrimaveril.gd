# Comportamento e desenho especificos desta especie.
extends "res://Scripts/InimigoSetorialBase.gd"

var destino := Vector2.ZERO

const Perigo := preload("res://Scripts/PerigoSetorial.gd")


func _mover_especie(ate: Vector2, distancia: float, delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, 350.0 * delta)


func _preparar() -> void:
	if not is_instance_valid(player):
		return
	preparando = true
	direcao = global_position.direction_to(player.global_position)
	var preparo_base := 0.72
	preparo = maxf(preparo_base * pow(0.90, indice_setor_dificuldade), 0.28)
	_destino_e_aviso()


func _destino_e_aviso() -> void:
	var cena := get_tree().current_scene
	if not is_instance_valid(cena):
		return
	destino = player.global_position + player.velocity * 0.35
	visible = false
	Perigo.criar(cena, Perigo.Forma.CIRCULO, destino, destino, cor_setor, preparo, 0.2, Dano, 42.0)


func _executar() -> void:
	EfeitoCombateCena.criar(
		get_tree().current_scene,
		global_position,
		EfeitoCombate.Tipo.ACERTO,
		cor_setor,
		0.55,
		direcao
	)
	global_position = destino
	visible = true


func _draw() -> void:
	var c := cor_setor.lightened(0.1)
	draw_circle(Vector2.ZERO, 10, c)
	draw_colored_polygon(
		PackedVector2Array([Vector2(0, -22), Vector2(9, -7), Vector2(-9, -7)]), Color(.45, 1, .55)
	)
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
	estilo = Estilo.BROTO_PRIMAVERIL
