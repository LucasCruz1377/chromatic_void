extends BossMensal
class_name BossNoAmetista

const FaixaEnergia := preload("res://Scripts/FaixaEnergiaBoss.gd")
const OndaAnelar := preload("res://Scripts/OndaAnelarBoss.gd")

var amarras: Array[float] = [38.0, 38.0, 38.0, 38.0]
var alvo_amarra := 0
var rompidas := 0
var giro := 1.0
var contracao := 0.0
var pulso_reacao := 0.0
var espiral_ativa := 0.0
var ultimo_ataque := -1
var poderes_executados := 0
var reacoes_executadas := 0


func _ready() -> void:
	super._ready()
	multiplicador_dano_recebido = 0.28
	tempo_ataque = 0.78


func Mover(delta: float) -> void:
	contracao = maxf(0.0, contracao - delta * 1.7)
	pulso_reacao = maxf(0.0, pulso_reacao - delta * 2.4)
	espiral_ativa = maxf(0.0, espiral_ativa - delta)
	super.Mover(delta)
	# Cada amarra desfeita solta o cristal e acelera sua movimentação lateral.
	if estado == Estado.MOVENDO and is_instance_valid(player) and rompidas > 0:
		var lateral := global_position.direction_to(player.global_position).orthogonal() * giro
		velocity += lateral * (16.0 + rompidas * 8.0)
	multiplicador_dano_recebido = 1.2 if _proxima(alvo_amarra) < 0 else 0.28 + rompidas * 0.12


func obter_velocidade_maxima() -> float:
	var velocidade_base := super.obter_velocidade_maxima()
	return velocidade_base * (1.32 if _sem_defesa() else 1.0)


func processar_recuperacao(delta: float) -> void:
	var estado_anterior := estado
	super.processar_recuperacao(delta)
	if estado_anterior == Estado.RECUPERANDO and estado == Estado.MOVENDO and _sem_defesa():
		tempo_ataque = minf(tempo_ataque, 0.62)


func escolher_ataque() -> int:
	var opcoes: Array[int] = [0, 1]
	if fase >= 2 or rompidas >= 1:
		opcoes.append(2)
	if fase >= 3 or rompidas >= 3:
		opcoes.append(3)
	if opcoes.size() > 1:
		opcoes.erase(ultimo_ataque)
	var escolhido := int(opcoes.pick_random())
	ultimo_ataque = escolhido
	return escolhido


func executar_ruptura(indice: int) -> void:
	poderes_executados += 1
	var proxima_amarra := _proxima(alvo_amarra + 1)
	if proxima_amarra >= 0:
		alvo_amarra = proxima_amarra
	match indice:
		0:
			_tecer_corredores()
		1:
			_lacos_perseguidores()
		2:
			_pulsos_de_libertacao()
		_:
			_espiral_viva()
	iniciar_recuperacao(0.22 if _sem_defesa() else 0.4)


func obter_posicao_satelite(_indice: int) -> Vector2:
	# Interface usada pelas faixas rastreadoras; neste boss todas nascem no cristal.
	return global_position


func _tecer_corredores() -> void:
	var cena := _obter_cena()
	if not is_instance_valid(cena):
		return
	var area := Global.obter_retangulo_area_visivel(28.0)
	var centro_arena := area.get_center()
	var inclinacao := PI * 0.5 + giro * (0.08 + rompidas * 0.018)
	var faixas := [-190.0, 0.0, 190.0]
	for indice in range(faixas.size()):
		FaixaEnergia.criar(cena, {
			"movimento": FaixaEnergia.Movimento.CORREDOR,
			"centro": centro_arena,
			"angulo": inclinacao,
			"comprimento": maxf(area.size.x, area.size.y) * 1.75,
			"largura": 19.0 + rompidas * 1.5,
			"cor": cor_principal if indice != 1 else cor_secundaria,
			"dano": Dano * 0.55,
			"atraso": indice * 0.12,
			"aviso": 0.92,
			"duracao": 2.35,
			"deslocamento": faixas[indice],
			"velocidade_deslocamento": (42.0 + indice * 7.0) * (-1.0 if indice == 1 else 1.0),
			"amplitude": absf(faixas[indice]) + 72.0,
		})


func _lacos_perseguidores() -> void:
	var cena := _obter_cena()
	if not is_instance_valid(cena) or not is_instance_valid(player):
		return
	var base := global_position.angle_to_point(player.global_position)
	var quantidade := 2 + mini(rompidas, 2) + (2 if _sem_defesa() else 0)
	for indice in range(quantidade):
		var abertura := (float(indice) - float(quantidade - 1) * 0.5) * 0.3
		FaixaEnergia.criar(cena, {
			"movimento": FaixaEnergia.Movimento.RASTREADORA,
			"centro": global_position,
			"angulo": base + abertura,
			"comprimento": 1260.0,
			"largura": 16.0 + rompidas * 1.8,
			"cor": cor_secundaria,
			"dano": Dano * (0.62 if _sem_defesa() else 0.52),
			"atraso": indice * 0.21,
			"aviso": 1.0,
			"antecedencia_trava": 0.3,
			"duracao": 0.42,
			"alvo": player,
			"dono": self,
			"indice_a": -1,
		})


func _pulsos_de_libertacao() -> void:
	contracao = 1.0
	var cena := _obter_cena()
	if not is_instance_valid(cena):
		return
	for indice in range(3):
		var contrair := indice % 2 == 1
		OndaAnelar.criar(cena, {
			"centro": global_position,
			"raio_inicial": 345.0 if contrair else 36.0,
			"raio_final": 38.0 if contrair else 345.0,
			"espessura": 19.0 + indice * 2.0,
			"cor": cor_secundaria if contrair else cor_principal,
			"dano": Dano * 0.47,
			"atraso": indice * 0.46,
			"aviso": 0.68,
			"duracao": 0.88,
		})


func _espiral_viva() -> void:
	giro *= -1.0
	espiral_ativa = 4.2
	var cena := _obter_cena()
	if not is_instance_valid(cena):
		return
	var area := Global.obter_retangulo_area_visivel(18.0)
	var centro_arena := area.get_center()
	var quantidade := 3 + mini(rompidas, 1)
	for indice in range(quantidade):
		FaixaEnergia.criar(cena, {
			"movimento": FaixaEnergia.Movimento.ESPIRAL,
			"centro": centro_arena,
			"angulo": angulo_visual + PI * float(indice) / float(quantidade),
			"comprimento": maxf(area.size.x, area.size.y) * 1.55,
			"largura": 15.0 + fase,
			"cor": cor_principal.lerp(cor_secundaria, float(indice) / float(quantidade)),
			"dano": Dano * 0.5,
			"atraso": indice * 0.1,
			"aviso": 1.05,
			"duracao": 3.05,
			"velocidade_angular": giro * (0.68 + indice * 0.06),
			"inverter": true,
		})
	OndaAnelar.criar(cena, {
		"centro": centro_arena,
		"raio_inicial": 54.0,
		"raio_final": 185.0,
		"espessura": 14.0,
		"cor": cor_secundaria,
		"dano": Dano * 0.3,
		"aviso": 0.92,
		"duracao": 0.72,
	})


func tomarDano(valor: float) -> void:
	if morto or valor <= 0.0:
		return
	var indice := _proxima(alvo_amarra)
	if indice >= 0:
		alvo_amarra = indice
		amarras[indice] = maxf(0.0, amarras[indice] - valor)
		var cena := _obter_cena()
		if is_instance_valid(cena):
			EfeitoCombateCena.criar(cena, _posicao_amarra(indice), EfeitoCombate.Tipo.ACERTO, cor_principal, 1.0)
		if amarras[indice] <= 0.0:
			rompidas += 1
			_reagir_amarra_rompida(indice)
			alvo_amarra = _proxima(indice + 1)
		queue_redraw()
		return
	super.tomarDano(valor)


func _reagir_amarra_rompida(indice: int) -> void:
	reacoes_executadas += 1
	pulso_reacao = 1.0
	contracao = 0.85
	tempo_ataque = minf(tempo_ataque, 0.18)
	giro *= -1.0
	if is_instance_valid(player):
		velocity = global_position.direction_to(player.global_position).orthogonal() * giro * 310.0
	var cena := _obter_cena()
	if not is_instance_valid(cena):
		return
	OndaAnelar.criar(cena, {
		"centro": _posicao_amarra(indice),
		"raio_inicial": 16.0,
		"raio_final": 190.0,
		"espessura": 16.0,
		"cor": cor_principal,
		"dano": Dano * 0.34,
		"aviso": 0.44,
		"duracao": 0.58,
	})
	if is_instance_valid(player):
		FaixaEnergia.criar(cena, {
			"movimento": FaixaEnergia.Movimento.RASTREADORA,
			"centro": global_position,
			"angulo": global_position.angle_to_point(player.global_position),
			"comprimento": 1180.0,
			"largura": 14.0,
			"cor": cor_secundaria,
			"dano": Dano * 0.38,
			"atraso": 0.2,
			"aviso": 0.78,
			"antecedencia_trava": 0.3,
			"duracao": 0.34,
			"alvo": player,
			"dono": self,
			"indice_a": -1,
		})


func _proxima(inicio: int) -> int:
	for passo in range(4):
		var indice := posmod(inicio + passo, 4)
		if amarras[indice] > 0.0:
			return indice
	return -1


func _sem_defesa() -> bool:
	return rompidas >= amarras.size() or _proxima(alvo_amarra) < 0


func _posicao_amarra(indice: int) -> Vector2:
	var angulo := angulo_visual * (1.0 if indice % 2 == 0 else -1.0) + indice * TAU / 4.0
	return global_position + Vector2.from_angle(angulo) * 68.0


func _obter_cena() -> Node:
	if not is_inside_tree():
		return null
	return get_tree().current_scene


func _draw() -> void:
	var brilho := 1.0 + pulso_reacao * 0.32
	var cristal := PackedVector2Array([
		Vector2(0.0, -27.0) * brilho,
		Vector2(19.0, 0.0) * brilho,
		Vector2(0.0, 31.0) * brilho,
		Vector2(-19.0, 0.0) * brilho,
	])
	draw_colored_polygon(cristal, cor_secundaria.lerp(Color.WHITE, contracao * 0.58))
	draw_polyline(PackedVector2Array([cristal[0], cristal[1], cristal[2], cristal[3], cristal[0]]), Color.WHITE, 2.0)

	for indice in range(4):
		var angulo := angulo_visual * (1.0 if indice % 2 == 0 else -1.0) + indice * TAU / 4.0
		var ponto := Vector2.from_angle(angulo) * 68.0
		if amarras[indice] <= 0.0:
			draw_arc(ponto, 12.0, angulo_visual, angulo_visual + PI * 1.25, 14, Color(cor_principal, 0.2), 3.0)
			continue
		var curva := PackedVector2Array([
			ponto,
			ponto.rotated(0.32 * giro) * 0.76,
			ponto.rotated(-0.29 * giro) * 0.5,
			Vector2.ZERO,
		])
		draw_polyline(curva, Color(cor_principal, 0.84), 9.0, true)
		draw_polyline(curva, Color(cor_secundaria, 0.78), 3.0, true)
		var raio := 14.0 if indice == alvo_amarra else 10.0
		draw_circle(ponto, raio, cor_principal)
		draw_circle(ponto, 4.0, Color.WHITE)

	var abertura := 4.65 + float(rompidas) * 0.23
	for raio in [36.0, 48.0]:
		draw_arc(Vector2.ZERO, raio, angulo_visual * giro, angulo_visual * giro + abertura, 48, Color(cor_principal, 0.68), 4.0)
	if espiral_ativa > 0.0:
		draw_arc(Vector2.ZERO, 58.0 + sin(angulo_visual * 5.0) * 5.0, 0.0, TAU, 56, Color(cor_secundaria, 0.82), 5.0)


func morrer() -> void:
	if Vida > 0.0:
		return
	var cena := _obter_cena()
	if is_instance_valid(cena):
		for indice in range(4):
			EfeitoCombateCena.criar(cena, _posicao_amarra(indice), EfeitoCombate.Tipo.MORTE, cor_principal, 1.3)
	super.morrer()
