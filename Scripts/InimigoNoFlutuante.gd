# Comportamento e desenho especificos desta especie.
extends "res://Scripts/InimigoSetorialBase.gd"


func _mover_especie(ate: Vector2, distancia: float, delta: float) -> void:
	_mover_formacao(ate, distancia, delta)


func _atualizar_vinculos() -> void:
	_manter_vinculos()


func _mover_formacao(ate: Vector2, distancia: float, delta: float) -> void:
	if is_instance_valid(parceiro):
		var centro: Vector2 = (parceiro.global_position + Vector2(player.global_position)) * 0.5
		velocity = velocity.move_toward(
			global_position.direction_to(centro) * Velocidade, 180.0 * delta
		)
	else:
		velocity = velocity.move_toward(
			_distancia(ate, distancia, 250.0) * Velocidade, 180.0 * delta
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
	_ligar(false)


func morrer() -> void:
	if Rede.modo_multiplayer and not multiplayer.is_server():
		return
	if is_instance_valid(parceiro):
		parceiro.multiplicador_dano_recebido = 1.0
	parceiro = null
	super.morrer()


func _draw() -> void:
	var c := cor_setor.lightened(0.1)
	draw_arc(Vector2(-5, 0), 13, -1.2, 4.2, 24, c, 5)
	draw_arc(Vector2(5, 0), 13, 1.9, 7.3, 24, Color.WHITE, 4)
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
	if is_instance_valid(protegido):
		_desenhar_vinculo(protegido, "ESCUDO  •  -52% DANO", Color(1.0, 0.82, 0.24), true)
	if is_instance_valid(parceiro):
		if estilo == Estilo.ELO_DOURADO:
			_desenhar_vinculo(parceiro, "ELO  •  DANO COMPARTILHADO", Color(1.0, 0.72, 0.18), false)
		elif estilo == Estilo.NO_FLUTUANTE:
			_desenhar_vinculo(parceiro, "NÓ  •  RESISTÊNCIA", Color(0.82, 0.46, 1.0), true)
		elif estilo == Estilo.SATELITE_COROA:
			_desenhar_vinculo(parceiro, "FORMAÇÃO ORBITAL", Color(0.58, 0.72, 1.0), false)


func obter_descricao_vinculo() -> String:
	return "NÓ  •  RESISTÊNCIA"
	return ""


func _init() -> void:
	estilo = Estilo.NO_FLUTUANTE
