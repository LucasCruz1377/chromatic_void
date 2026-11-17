# Comportamento e desenho especificos desta especie.
extends "res://Scripts/InimigoSetorialBase.gd"

var fechado := false


func _mover_especie(ate: Vector2, distancia: float, delta: float) -> void:
	velocity = velocity.move_toward(_distancia(ate, distancia, 230.0) * Velocidade, 190.0 * delta)


func _executar() -> void:
	EfeitoCombateCena.criar(
		get_tree().current_scene,
		global_position,
		EfeitoCombate.Tipo.ACERTO,
		cor_setor,
		0.55,
		direcao
	)
	fechado = true
	multiplicador_dano_recebido = 0.22
	get_tree().create_timer(1.1).timeout.connect(_abrir_prisma)


func _abrir_prisma() -> void:
	if not is_inside_tree() or morto or is_queued_for_deletion():
		return
	fechado = false
	multiplicador_dano_recebido = 1.0
	_leque(3, 0.3, 260.0, Dano * 0.4)


func tomarDano(valor: float) -> void:
	# Os clientes detectam impacto, mas apenas o host pode executar
	# consequencias do ataque, alterar defesas ou criar drones.
	if Rede.modo_multiplayer and not multiplayer.is_server():
		super.tomarDano(valor)
		return
	if morto or valor <= 0.0:
		return
	if estilo == Estilo.PRISMA_AMPARO and is_instance_valid(player):
		multiplicador_dano_recebido = (
			0.22
			if global_position.direction_to(player.global_position).dot(direcao) > 0.25
			else 1.35
		)
	super.tomarDano(valor)


func _draw() -> void:
	var c := cor_setor.lightened(0.1)
	draw_colored_polygon(
		PackedVector2Array([Vector2(22, 0), Vector2(0, -17), Vector2(-15, 0), Vector2(0, 17)]), c
	)
	draw_line(Vector2(17, -18), Vector2(17, 18), Color.WHITE, 4)
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
	estilo = Estilo.PRISMA_AMPARO
