extends Node2D
class_name MonthlyAbilityEffect


const EfeitoCombateCena = preload("res://Scripts/EfeitoCombate.gd")
const ExplosaoMonthlyCena = preload("res://Scripts/MonthlyBurst.gd")
const AjudanteCena = preload("res://Scripts/AjudanteMonthly.gd")
const LacoCena = preload("res://Scripts/LacoUniaoAlvo.gd")

var player: Player
var modo: StringName
var cor := Color.WHITE
var potencia := 1.0
var config: Dictionary = {}
var tempo := 0.0
var duracao := 1.0
var acumulador := 0.0
var fase := 0.0
var resolvido := false
var resultado_ovo := 0
var infectados: Array[Node2D] = []
var posicoes_infectadas: Array[Vector2] = []
var posicoes_fantasma: Array[Vector2] = []
var folhas: Array[Dictionary] = []
var mascara_inimigos_ativa := true
var tempestade_gerando := true
var somente_visual_rede := false
var rng_visual := RandomNumberGenerator.new()


static func criar(
	parent: Node, player_ref: Player, modo_ref: StringName,
	cor_ref: Color, potencia_ref: float, config_ref: Dictionary = {}
) -> MonthlyAbilityEffect:
	var efeito := MonthlyAbilityEffect.new()
	parent.add_child(efeito)
	efeito.player = player_ref
	efeito.modo = modo_ref
	efeito.cor = cor_ref
	efeito.potencia = maxf(potencia_ref, 0.25)
	efeito.config = config_ref.duplicate(true)
	efeito.global_position = player_ref.global_position
	efeito.z_index = 4
	efeito._iniciar()
	return efeito


static func criar_visual_rede(
	parent: Node, player_ref: Player, modo_ref: StringName,
	cor_ref: Color, potencia_ref: float, config_ref: Dictionary = {}
) -> MonthlyAbilityEffect:
	var efeito := MonthlyAbilityEffect.new()
	efeito.somente_visual_rede = true
	parent.add_child(efeito)
	efeito.player = player_ref
	efeito.modo = modo_ref
	efeito.cor = cor_ref
	efeito.potencia = maxf(potencia_ref, 0.25)
	efeito.config = config_ref.duplicate(true)
	efeito.global_position = player_ref.global_position
	efeito.z_index = 4
	efeito._iniciar()
	return efeito


func _iniciar() -> void:
	rng_visual.seed = int(config.get("semente_visual", 1))
	match modo:
		&"clone":
			if somente_visual_rede:
				_criar_ajudante_visual(AjudanteMonthly.Tipo.CLONE, 6.5)
			queue_free()
			return
		&"protetor":
			if somente_visual_rede:
				_criar_ajudante_visual(AjudanteMonthly.Tipo.GUARDIAO, 7.5)
			queue_free()
			return
		&"ovo":
			duracao = 0.72
			resultado_ovo = rng_visual.randi_range(0, 2)
			cor = [Color("ffd45a"), Color("58ff91"), Color("ff6a50")][resultado_ovo]
		&"florescimento":
			duracao = float(config.get("duracao", 3.0))
			global_position = Vector2.ZERO
		&"fantasma":
			duracao = 3.5
			global_position = Vector2.ZERO
			if not somente_visual_rede:
				mascara_inimigos_ativa = player.get_collision_mask_value(3)
				player.set_collision_mask_value(3, false)
				player.invulneravel_por_habilidade = true
				player.modulate = Color(cor, 0.62)
			_deixar_orbe_fantasma()
		&"presente":
			duracao = 2.65
		&"laco":
			if not somente_visual_rede:
				_criar_laco()
			else:
				ExplosaoMonthlyCena.criar(get_tree().current_scene, player.global_position, cor, 1.35, &"presente", -1, false)
			queue_free()
		&"tempestade":
			duracao = maxf(float(config.get("duracao", 7.0)), 7.0)
			global_position = Vector2.ZERO
	queue_redraw()


func _criar_ajudante_visual(tipo: AjudanteMonthly.Tipo, duracao_ajudante: float) -> void:
	var ajudante := AjudanteCena.new() as AjudanteMonthly
	get_tree().current_scene.add_child(ajudante)
	ajudante.configurar_visual_rede(player, tipo, cor, duracao_ajudante)


func _process(delta: float) -> void:
	if not is_instance_valid(player):
		queue_free()
		return
	tempo += delta
	fase += delta
	match modo:
		&"ovo": _processar_ovo()
		&"orbe_cura": _processar_orbe_cura(delta)
		&"florescimento": _processar_florescimento(delta)
		&"fantasma": _processar_fantasma(delta)
		&"presente": _processar_presente(delta)
		&"tempestade": _processar_tempestade(delta)
	queue_redraw()
	if modo == &"tempestade" and tempo >= duracao:
		tempestade_gerando = false
		resolvido = true
		if folhas.is_empty():
			queue_free()
	elif tempo >= duracao and not resolvido:
		_finalizar()


func _processar_ovo() -> void:
	# O ovo permanece no ponto de ativação; a cor antecipa o resultado.
	pass


func _resolver_ovo() -> void:
	if somente_visual_rede:
		if resultado_ovo == 0:
			_criar_ajudante_visual(
				AjudanteMonthly.Tipo.DRONE_OVO,
				float(config.get("duracao_drone", 6.5))
			)
		elif resultado_ovo == 1:
			modo = &"orbe_cura"
			tempo = 0.0
			duracao = 2.8
			resolvido = false
			return
		else:
			ExplosaoMonthlyCena.criar(get_tree().current_scene, global_position, cor, 1.5, &"ovo", -1, false)
		resolvido = true
		queue_free()
		return
	if resultado_ovo == 0:
		var ajudante := AjudanteCena.new() as AjudanteMonthly
		get_tree().current_scene.add_child(ajudante)
		ajudante.add_to_group("ajudante_ovo")
		ajudante.configurar_drone_ovo(
			player, cor,
			float(config.get("dano_drone", 0.8)) * potencia,
			float(config.get("duracao_drone", 6.5))
		)
	elif resultado_ovo == 1:
		modo = &"orbe_cura"
		tempo = 0.0
		duracao = 2.8
		resolvido = false
		return
	else:
		_derrotar_area(global_position, 175.0 * potencia, 24.0 * potencia)
		ExplosaoMonthlyCena.criar(get_tree().current_scene, global_position, cor, 2.0, &"ovo", -1, false)
	resolvido = true
	queue_free()


func _processar_orbe_cura(delta: float) -> void:
	global_position = global_position.move_toward(player.global_position, 260.0 * delta)
	if global_position.distance_to(player.global_position) <= 18.0:
		if not somente_visual_rede:
			player.curar(float(config.get("cura", 22.0)) * potencia)
		EfeitoCombateCena.criar(get_tree().current_scene, player.global_position, EfeitoCombate.Tipo.MORTE, cor, 1.15, Vector2.RIGHT, -1, false)
		resolvido = true
		queue_free()


func _processar_florescimento(delta: float) -> void:
	for indice in range(infectados.size()):
		if is_instance_valid(infectados[indice]):
			posicoes_infectadas[indice] = infectados[indice].global_position
	if infectados.size() >= clampi(int(config.get("limite_raizes", 3)), 3, 5):
		return
	acumulador -= delta
	if acumulador <= 0.0:
		acumulador = float(config.get("intervalo", 0.52))
		var alvo := _proximo_nao_infectado(390.0)
		if is_instance_valid(alvo):
			infectados.append(alvo)
			posicoes_infectadas.append(alvo.global_position)
			if not somente_visual_rede and alvo.has_method("aplicar_atordoamento"):
				alvo.call("aplicar_atordoamento", duracao - tempo + 0.2)
			EfeitoCombateCena.criar(get_tree().current_scene, alvo.global_position, EfeitoCombate.Tipo.AVISO, cor, 0.85, player.global_position.direction_to(alvo.global_position), -1, false)


func _processar_fantasma(delta: float) -> void:
	acumulador -= delta
	if acumulador <= 0.0:
		acumulador = rng_visual.randf_range(0.5, 0.7)
		_deixar_orbe_fantasma()


func _deixar_orbe_fantasma() -> void:
	posicoes_fantasma.append(player.global_position)
	EfeitoCombateCena.criar(get_tree().current_scene, player.global_position, EfeitoCombate.Tipo.RASTRO, cor, 0.65, Vector2.RIGHT, -1, false)


func _processar_presente(delta: float) -> void:
	if somente_visual_rede:
		return
	for alvo in _inimigos_no_raio(global_position, 310.0):
		if alvo.is_in_group("boss"):
			continue
		if alvo.has_method("atrair_para_presente_misterioso"):
			alvo.call("atrair_para_presente_misterioso", self)
		var direcao := alvo.global_position.direction_to(global_position)
		if alvo is CharacterBody2D:
			var corpo := alvo as CharacterBody2D
			var velocidade_alvo := maxf(float(alvo.get("Velocidade")) * 1.8, 320.0)
			corpo.velocity = corpo.velocity.move_toward(
				direcao * velocidade_alvo, 1500.0 * delta
			)
		alvo.global_position = alvo.global_position.move_toward(global_position, 95.0 * delta)


func _processar_tempestade(delta: float) -> void:
	if tempestade_gerando:
		acumulador -= delta
		if acumulador <= 0.0:
			acumulador = 0.075
			_criar_folha()
			_criar_folha()
	var area := Global.obter_retangulo_area_visivel(8.0)
	for indice in range(folhas.size() - 1, -1, -1):
		var folha: Dictionary = folhas[indice]
		folha["pos"] = (folha["pos"] as Vector2) + (folha["vel"] as Vector2) * delta
		var posicao: Vector2 = folha["pos"]
		var remover := not area.grow(100.0).has_point(posicao)
		if not remover:
			var atingidos: Dictionary = folha["atingidos"]
			for alvo in _inimigos_no_raio(posicao, 17.0):
				var id := alvo.get_instance_id()
				if atingidos.has(id):
					continue
				atingidos[id] = true
				if not somente_visual_rede and alvo.has_method("tomarDano"):
					alvo.call("tomarDano", maxf(float(config.get("dano", 5.0)), 5.0) * potencia * player.multiplicador_dano_habilidade)
				folha["restantes"] = int(folha["restantes"]) - 1
				EfeitoCombateCena.criar(get_tree().current_scene, posicao, EfeitoCombate.Tipo.ACERTO, cor, 0.42, Vector2.RIGHT, -1, false)
				if int(folha["restantes"]) < 0:
					remover = true
					break
		folhas[indice] = folha
		if remover:
			folhas.remove_at(indice)
	if not tempestade_gerando and folhas.is_empty() and not is_queued_for_deletion():
		queue_free()


func _criar_folha() -> void:
	var area := Global.obter_retangulo_area_visivel(12.0)
	var inicio := Vector2(rng_visual.randf_range(area.position.x, area.end.x + 160.0), area.position.y - 35.0)
	# Movimento cai para baixo/esquerda. O desenho aponta para 315 graus.
	folhas.append({
		"pos": inicio,
		"vel": Vector2(-0.72, 1.0).normalized() * rng_visual.randf_range(420.0, 540.0),
		"restantes": int(config.get("perfuracao", 0)),
		"atingidos": {},
		"escala": rng_visual.randf_range(0.8, 1.25),
	})


func _finalizar() -> void:
	resolvido = true
	match modo:
		&"ovo":
			_resolver_ovo()
			return
		&"orbe_cura":
			if not somente_visual_rede:
				player.curar(float(config.get("cura", 22.0)) * potencia)
		&"florescimento":
			if somente_visual_rede:
				for posicao in posicoes_infectadas:
					ExplosaoMonthlyCena.criar(get_tree().current_scene, posicao, cor, 1.0, &"florescimento", -1, false)
			else:
				_explodir_infectados()
		&"fantasma":
			if not somente_visual_rede:
				player.set_collision_mask_value(3, mascara_inimigos_ativa)
				player.invulneravel_por_habilidade = false
				player.modulate = Color.WHITE
			for posicao in posicoes_fantasma:
				if not somente_visual_rede:
					_derrotar_area(posicao, 54.0, 7.0 * potencia)
				ExplosaoMonthlyCena.criar(get_tree().current_scene, posicao, cor, 0.8, &"fantasma", -1, false)
		&"presente":
			if not somente_visual_rede:
				_derrotar_area(global_position, 145.0, 30.0 * potencia)
			ExplosaoMonthlyCena.criar(get_tree().current_scene, global_position, cor, 2.1, &"presente", -1, false)
	queue_free()


func _explodir_infectados() -> void:
	for indice in range(posicoes_infectadas.size()):
		var alvo: Node2D = infectados[indice] if indice < infectados.size() else null
		var posicao := posicoes_infectadas[indice]
		if is_instance_valid(alvo):
			posicao = alvo.global_position
		if is_instance_valid(alvo) and alvo.has_method("tomarDano"):
			alvo.call("tomarDano", 8.0 * potencia * player.multiplicador_dano_habilidade)
		ExplosaoMonthlyCena.criar(get_tree().current_scene, posicao, cor, 1.0, &"florescimento", -1, false)
		if bool(config.get("projeteis_explosao", false)):
			for indice_petala in range(6):
				player.criar_projetil(TAU * float(indice_petala) / 6.0, 0.42 * potencia, true, null, 0.0, &"petal", cor, {"origem_global": posicao, "penetracao": 1})


func _criar_laco() -> void:
	var alvos: Array[Node2D] = []
	var area := Global.obter_retangulo_area_visivel(8.0)
	for node in get_tree().get_nodes_in_group("inimigo"):
		if node is Node2D and is_instance_valid(node) and area.has_point((node as Node2D).global_position):
			alvos.append(node as Node2D)
	if alvos.is_empty():
		return
	var laco := LacoCena.new()
	get_tree().current_scene.add_child(laco)
	laco.configurar(Global.obter_retangulo_area_visivel().get_center(), alvos, cor, potencia)


func _proximo_nao_infectado(raio: float) -> Node2D:
	var melhor: Node2D
	var menor := raio * raio
	for alvo in _inimigos_no_raio(player.global_position, raio):
		if alvo in infectados:
			continue
		var distancia := player.global_position.distance_squared_to(alvo.global_position)
		if distancia < menor:
			menor = distancia
			melhor = alvo
	return melhor


func _inimigos_no_raio(centro: Vector2, raio: float) -> Array[Node2D]:
	var alvos: Array[Node2D] = []
	for node in get_tree().get_nodes_in_group("inimigo"):
		if node is Node2D and is_instance_valid(node):
			var alvo := node as Node2D
			if centro.distance_squared_to(alvo.global_position) <= raio * raio:
				alvos.append(alvo)
	return alvos


func _derrotar_area(centro: Vector2, raio: float, dano_boss: float) -> void:
	for alvo in _inimigos_no_raio(centro, raio):
		if alvo.is_in_group("boss"):
			if alvo.has_method("tomarDano"):
				alvo.call("tomarDano", dano_boss * player.multiplicador_dano_habilidade)
		elif alvo.has_method("tomarDano"):
			var vida_atual: Variant = alvo.get("Vida")
			alvo.call("tomarDano", maxf(float(vida_atual) + 1.0, dano_boss))


func _draw() -> void:
	var brilho := cor.lightened(0.35)
	match modo:
		&"ovo":
			var pulso := 1.0 + sin(fase * 8.0) * 0.04
			draw_circle(Vector2.ZERO, 27.0 * pulso, Color(cor, 0.16))
			draw_colored_polygon(PackedVector2Array([Vector2(0, -25), Vector2(16, -11), Vector2(19, 12), Vector2(0, 27), Vector2(-19, 12), Vector2(-16, -11)]), Color(cor, 0.9))
			draw_polyline(PackedVector2Array([Vector2(0, -25), Vector2(16, -11), Vector2(19, 12), Vector2(0, 27), Vector2(-19, 12), Vector2(-16, -11), Vector2(0, -25)]), brilho, 3.0)
			for y in [-9.0, 3.0, 14.0]: draw_arc(Vector2(0, y), 11.0, 0.25, PI - 0.25, 12, Color.WHITE, 2.0)
		&"orbe_cura":
			draw_circle(Vector2.ZERO, 19.0 + sin(fase * 9.0) * 2.0, Color(cor, 0.2))
			draw_circle(Vector2.ZERO, 10.0, cor)
			draw_line(Vector2(-6, 0), Vector2(6, 0), Color.WHITE, 3.0)
			draw_line(Vector2(0, -6), Vector2(0, 6), Color.WHITE, 3.0)
		&"florescimento":
			for indice in range(posicoes_infectadas.size()):
				var ponta := posicoes_infectadas[indice]
				if indice < infectados.size() and is_instance_valid(infectados[indice]):
					ponta = infectados[indice].global_position
				var origem := player.global_position
				draw_line(origem, ponta, Color(cor, 0.22), 8.0)
				draw_line(origem, ponta, cor, 2.0)
				_desenhar_flor(ponta, 10.0 + sin(fase * 7.0) * 1.5)
		&"fantasma":
			for posicao in posicoes_fantasma:
				draw_circle(posicao, 17.0 + sin(fase * 6.0) * 2.0, Color(cor, 0.18))
				draw_circle(posicao, 8.0, Color(cor, 0.8))
				draw_arc(posicao, 12.0, 0.0, TAU, 20, brilho, 2.0)
		&"presente":
			draw_circle(Vector2.ZERO, 42.0 + sin(fase * 5.0) * 3.0, Color(cor, 0.12))
			draw_rect(Rect2(-25, -20, 50, 40), Color(cor, 0.88), true)
			draw_rect(Rect2(-28, -25, 56, 10), brilho, true)
			draw_rect(Rect2(-5, -25, 10, 45), Color.WHITE, true)
			draw_arc(Vector2(-8, -27), 10, PI, TAU, 12, brilho, 3.0)
			draw_arc(Vector2(8, -27), 10, PI, TAU, 12, brilho, 3.0)
		&"tempestade":
			for folha in folhas:
				_desenhar_folha(folha["pos"], float(folha["escala"]))


func _desenhar_flor(centro: Vector2, raio: float) -> void:
	for indice in range(6):
		var petala := centro + Vector2.from_angle(TAU * float(indice) / 6.0 + fase) * raio
		draw_circle(petala, raio * 0.46, Color(cor, 0.86))
	draw_circle(centro, raio * 0.5, Color("fff28a"))


func _desenhar_folha(posicao: Vector2, escala: float) -> void:
	var angulo := deg_to_rad(315.0)
	var frente := Vector2.from_angle(angulo) * 13.0 * escala
	var lado := frente.orthogonal().normalized() * 6.0 * escala
	draw_colored_polygon(PackedVector2Array([posicao + frente, posicao + lado, posicao - frente, posicao - lado]), Color(cor, 0.9))
	draw_line(posicao - frente, posicao + frente, cor.lightened(0.45), 1.5)
