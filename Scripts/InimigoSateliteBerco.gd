# Comportamento e desenho especificos desta especie.
extends "res://Scripts/InimigoSetorialBase.gd"

var drones_liberados := false


func _mover_especie(ate: Vector2, distancia: float, delta: float) -> void:
	velocity = velocity.move_toward(_distancia(ate, distancia, 310.0) * Velocidade, 160.0 * delta)


func _executar() -> void:
	EfeitoCombateCena.criar(
		get_tree().current_scene,
		global_position,
		EfeitoCombate.Tipo.ACERTO,
		cor_setor,
		0.55,
		direcao
	)
	pass


func tomarDano(valor: float) -> void:
	# Os clientes detectam impacto, mas apenas o host pode executar
	# consequencias do ataque, alterar defesas ou criar drones.
	if Rede.modo_multiplayer and not multiplayer.is_server():
		super.tomarDano(valor)
		return
	if morto or valor <= 0.0:
		return
	if estilo == Estilo.SATELITE_BERCO and not drones_liberados:
		drones_liberados = true
		_criar_drones.call_deferred(get_tree().current_scene, global_position)
	super.tomarDano(valor)


func _criar_drones(batalha: Node, origem: Vector2) -> void:
	if not is_instance_valid(batalha) or batalha.is_queued_for_deletion() or not is_inside_tree():
		return
	if batalha != get_tree().current_scene or (Rede.modo_multiplayer and not multiplayer.is_server()):
		return
	var cena := preload("res://Entities/InimigoCentelhaGuia.tscn")
	for lado in [-1.0, 1.0]:
		if batalha.has_method("contar_inimigos_regulares"):
			if int(batalha.call("contar_inimigos_regulares")) >= 10:
				break
		var drone := cena.instantiate() as InimigoBase
		if not is_instance_valid(drone):
			continue
		# Somente o host cria o drone na arena. O MultiplayerSpawner
		# replica a MESMA entidade, inclusive sua remocao.
		drone.position = origem + Vector2(30.0 * lado, 10.0)
		drone.VidaMaxima *= 0.5
		drone.ValorXP = 0.25
		batalha.add_child(drone, true)


func _draw() -> void:
	var c := cor_setor.lightened(0.1)
	draw_arc(Vector2.ZERO, 18, .35, TAU - .35, 28, c, 6)
	draw_circle(Vector2(-8, 0), 5, Color.WHITE)
	draw_circle(Vector2(8, 0), 5, Color.WHITE)
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
	estilo = Estilo.SATELITE_BERCO
