# Comportamento e desenho especificos desta especie.
extends "res://Scripts/InimigoSetorialBase.gd"

var aliado_movimento: InimigoBase
var tempo_busca_aliado := 0.0


func _mover_especie(ate: Vector2, distancia: float, delta: float) -> void:
	_mover_para_aliado(ate, distancia, delta)


func _atualizar_vinculos() -> void:
	_manter_vinculos()


func _mover_para_aliado(ate: Vector2, distancia: float, delta: float) -> void:
	tempo_busca_aliado -= delta
	if not is_instance_valid(aliado_movimento) or tempo_busca_aliado <= 0.0:
		aliado_movimento = protegido if is_instance_valid(protegido) else _mais_proximo(false)
		tempo_busca_aliado = 0.28
	var aliado := aliado_movimento
	if is_instance_valid(aliado):
		var d := global_position.distance_to(aliado.global_position)
		velocity = velocity.move_toward(
			_distancia(global_position.direction_to(aliado.global_position), d, 105.0) * Velocidade,
			250.0 * delta
		)
	else:
		velocity = velocity.move_toward(
			_distancia(ate, distancia, 290.0) * Velocidade, 210.0 * delta
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
	_escudar()


func _escudar() -> void:
	protegido = _mais_proximo(false)
	if is_instance_valid(protegido):
		protegido.multiplicador_dano_recebido = 0.48
		protegido.set_meta("escudo_guia", self)


func morrer() -> void:
	if Rede.modo_multiplayer and not multiplayer.is_server():
		return
	_limpar_escudo()
	parceiro = null
	super.morrer()


func _draw() -> void:
	var c := cor_setor.lightened(0.1)
	draw_circle(Vector2.ZERO, 8, c)
	draw_arc(Vector2.ZERO, 17, 0, TAU, 24, c, 3)
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
	return "ESCUDO  •  -52% DANO"
	return ""


func _init() -> void:
	estilo = Estilo.CENTELHA_GUIA
