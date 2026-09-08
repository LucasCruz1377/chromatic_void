extends BossMensal
class_name BossConstelacaoAmparo

const FaixaEnergia := preload("res://Scripts/FaixaEnergiaBoss.gd")
const OndaAnelar := preload("res://Scripts/OndaAnelarBoss.gd")

enum Formacao { ORBITA, ESCUDO, RESGATE, ABRACO }

var satelites: Array[float] = [46.0, 46.0, 46.0]
var angulos: Array[float] = [0.0, TAU / 3.0, TAU * 2.0 / 3.0]
var alvo_satelite := 0
var exposto := false
var tempo_exposto := 0.0
var tempo_reacao_exposto := 0.0
var abraco := false
var tempo_abraco := 0.0
var duracao_abraco := 4.2
var raio_seguro := 360.0
var raio_orbita := 82.0
var raio_orbita_alvo := 82.0
var formacao := Formacao.ORBITA
var ultimo_ataque := -1
var poderes_executados := 0
var reacoes_executadas := 0
var pulso_reacao := 0.0


func _ready() -> void:
	super._ready()
	multiplicador_dano_recebido = 0.0
	tempo_ataque = 0.85


func Mover(delta: float) -> void:
	pulso_reacao = maxf(0.0, pulso_reacao - delta * 2.2)
	raio_orbita = move_toward(raio_orbita, raio_orbita_alvo, delta * 115.0)
	_atualizar_orbita(delta)

	if abraco:
		_comprimir(delta)
		var centro_arena := Global.obter_centro_area_visivel()
		velocity = velocity.move_toward(global_position.direction_to(centro_arena) * 150.0, 330.0 * delta)
		queue_redraw()
		return

	if exposto:
		tempo_exposto -= delta
		tempo_reacao_exposto -= delta
		if tempo_reacao_exposto <= 0.0:
			_reagir_nucleo_exposto()
		if tempo_exposto <= 0.0:
			_reformar()

	super.Mover(delta)
	multiplicador_dano_recebido = 1.32 if exposto else 0.0


func _atualizar_orbita(delta: float) -> void:
	var aceleracao := 1.0 + float(fase - 1) * 0.23
	for indice in range(3):
		var sentido := -1.0 if indice == 1 else 1.0
		var velocidade := (0.52 + float(indice) * 0.075) * aceleracao
		if formacao == Formacao.RESGATE:
			velocidade *= 2.0
		elif formacao == Formacao.ABRACO:
			velocidade *= 0.42
		angulos[indice] += delta * velocidade * sentido


func escolher_ataque() -> int:
	var opcoes: Array[int] = [0, 1]
	if fase >= 2:
		opcoes.append(2)
	if fase >= 3:
		opcoes.append(3)
	if opcoes.size() > 1:
		opcoes.erase(ultimo_ataque)
	var escolhido := int(opcoes.pick_random())
	ultimo_ataque = escolhido
	return escolhido


func executar_sentinela(indice: int) -> void:
	poderes_executados += 1
	match indice:
		0:
			_tridente_solar()
		1:
			_escudo_de_revezamento()
		2:
			_orbita_de_resgate()
		_:
			_iniciar_abraco()
	if not abraco:
		iniciar_recuperacao(0.42)


func obter_posicao_satelite(indice: int) -> Vector2:
	if indice < 0 or indice >= angulos.size():
		return global_position
	var variacao := 1.0
	if formacao == Formacao.ESCUDO and indice == alvo_satelite:
		variacao = 0.72
	return global_position + Vector2.from_angle(angulos[indice]) * raio_orbita * variacao


func _tridente_solar() -> void:
	formacao = Formacao.ORBITA
	raio_orbita_alvo = 92.0
	var cena := _obter_cena()
	if not is_instance_valid(cena) or not is_instance_valid(player):
		return
	for indice in range(3):
		if satelites[indice] <= 0.0:
			continue
		FaixaEnergia.criar(cena, {
			"movimento": FaixaEnergia.Movimento.RASTREADORA,
			"centro": global_position,
			"angulo": obter_posicao_satelite(indice).angle_to_point(player.global_position),
			"comprimento": 1280.0,
			"largura": 18.0 + fase * 2.0,
			"cor": cor_principal,
			"dano": Dano * 0.68,
			"atraso": indice * 0.24,
			"aviso": 0.88,
			"antecedencia_trava": 0.5,
			"duracao": 0.34,
			"alvo": player,
			"dono": self,
			"indice_a": indice,
		})


func _escudo_de_revezamento() -> void:
	formacao = Formacao.ESCUDO
	raio_orbita_alvo = 112.0
	alvo_satelite = _proximo(alvo_satelite + 1)
	var cena := _obter_cena()
	if not is_instance_valid(cena):
		return
	for indice in range(3):
		var seguinte := (indice + 1) % 3
		if satelites[indice] <= 0.0 or satelites[seguinte] <= 0.0:
			continue
		FaixaEnergia.criar(cena, {
			"movimento": FaixaEnergia.Movimento.LIGACAO,
			"dono": self,
			"indice_a": indice,
			"indice_b": seguinte,
			"largura": 15.0,
			"cor": cor_secundaria,
			"dano": Dano * 0.46,
			"aviso": 0.72,
			"duracao": 1.65,
		})
	OndaAnelar.criar(cena, {
		"centro": global_position,
		"raio_inicial": 42.0,
		"raio_final": 245.0,
		"espessura": 18.0,
		"cor": cor_secundaria,
		"dano": Dano * 0.42,
		"aviso": 0.62,
		"duracao": 0.8,
	})


func _orbita_de_resgate() -> void:
	formacao = Formacao.RESGATE
	raio_orbita_alvo = 168.0
	var cena := _obter_cena()
	if not is_instance_valid(cena):
		return
	for indice in range(3):
		var seguinte := (indice + 1) % 3
		if satelites[indice] <= 0.0 or satelites[seguinte] <= 0.0:
			continue
		FaixaEnergia.criar(cena, {
			"movimento": FaixaEnergia.Movimento.LIGACAO,
			"dono": self,
			"indice_a": indice,
			"indice_b": seguinte,
			"largura": 21.0,
			"cor": cor_principal,
			"dano": Dano * 0.54,
			"atraso": 0.15,
			"aviso": 0.82,
			"duracao": 2.15,
		})
	OndaAnelar.criar(cena, {
		"centro": global_position,
		"raio_inicial": 36.0,
		"raio_final": 330.0,
		"espessura": 24.0,
		"cor": cor_secundaria,
		"dano": Dano * 0.5,
		"aviso": 0.9,
		"duracao": 1.15,
		"impulso": 105.0,
	})


func _iniciar_abraco() -> void:
	abraco = true
	formacao = Formacao.ABRACO
	tempo_abraco = duracao_abraco
	raio_orbita_alvo = 205.0
	var tamanho := Global.obter_retangulo_area_visivel().size
	raio_seguro = minf(tamanho.x, tamanho.y) * 0.43
	estado = Estado.RECUPERANDO
	tempo_estado = duracao_abraco
	linha_aviso.visible = false


func _comprimir(delta: float) -> void:
	var tempo_anterior := tempo_abraco
	tempo_abraco -= delta
	var progresso := 1.0 - clampf(tempo_abraco / duracao_abraco, 0.0, 1.0)
	var tamanho := Global.obter_retangulo_area_visivel().size
	var inicial := minf(tamanho.x, tamanho.y) * 0.43
	raio_seguro = lerpf(inicial, 112.0, ease(progresso, 1.65))
	raio_orbita_alvo = maxf(126.0, raio_seguro + 24.0)
	var centro_arena := Global.obter_centro_area_visivel()
	if is_instance_valid(player):
		var pulso_atual := int(tempo_abraco * 4.0)
		var pulso_anterior := int(tempo_anterior * 4.0)
		if player.global_position.distance_to(centro_arena) > raio_seguro and pulso_atual != pulso_anterior:
			player.tomar_dano(Dano * 0.23)
	if tempo_abraco > 0.0:
		return
	abraco = false
	formacao = Formacao.ORBITA
	raio_orbita_alvo = 86.0
	estado = Estado.MOVENDO
	tempo_ataque = 0.38
	var cena := _obter_cena()
	if is_instance_valid(cena):
		OndaAnelar.criar(cena, {
			"centro": centro_arena,
			"raio_inicial": 108.0,
			"raio_final": 430.0,
			"espessura": 26.0,
			"cor": cor_principal,
			"dano": Dano * 0.62,
			"aviso": 0.34,
			"duracao": 0.8,
		})


func tomarDano(valor: float) -> void:
	if morto or valor <= 0.0:
		return
	if not exposto and _vivos() > 0:
		alvo_satelite = _proximo(alvo_satelite)
		var indice_atingido := alvo_satelite
		satelites[indice_atingido] = maxf(0.0, satelites[indice_atingido] - valor)
		var cena := _obter_cena()
		if is_instance_valid(cena):
			EfeitoCombateCena.criar(cena, obter_posicao_satelite(indice_atingido), EfeitoCombate.Tipo.ACERTO, cor_principal, 1.0)
		if satelites[indice_atingido] <= 0.0:
			_reagir_quebra_satelite(indice_atingido)
			alvo_satelite = _proximo(indice_atingido + 1)
		if _vivos() == 0:
			exposto = true
			tempo_exposto = 4.8
			tempo_reacao_exposto = 0.15
			multiplicador_dano_recebido = 1.32
			formacao = Formacao.RESGATE
			raio_orbita_alvo = 126.0
		queue_redraw()
		return
	super.tomarDano(valor)


func _reagir_quebra_satelite(indice: int) -> void:
	reacoes_executadas += 1
	pulso_reacao = 1.0
	tempo_ataque = minf(tempo_ataque, 0.22)
	if is_instance_valid(player):
		velocity = player.global_position.direction_to(global_position) * 260.0
	var cena := _obter_cena()
	if not is_instance_valid(cena):
		return
	OndaAnelar.criar(cena, {
		"centro": obter_posicao_satelite(indice),
		"raio_inicial": 18.0,
		"raio_final": 178.0,
		"espessura": 17.0,
		"cor": cor_principal,
		"dano": Dano * 0.36,
		"aviso": 0.42,
		"duracao": 0.56,
	})


func _reagir_nucleo_exposto() -> void:
	tempo_reacao_exposto = maxf(0.72, 1.16 - fase * 0.1)
	reacoes_executadas += 1
	pulso_reacao = 1.0
	var cena := _obter_cena()
	if not is_instance_valid(cena):
		return
	OndaAnelar.criar(cena, {
		"centro": global_position,
		"raio_inicial": 28.0,
		"raio_final": 205.0,
		"espessura": 14.0,
		"cor": cor_secundaria,
		"dano": Dano * 0.28,
		"aviso": 0.38,
		"duracao": 0.52,
	})


func _vivos() -> int:
	var quantidade := 0
	for vida_satelite in satelites:
		if vida_satelite > 0.0:
			quantidade += 1
	return quantidade


func _proximo(inicio: int) -> int:
	for passo in range(3):
		var indice := posmod(inicio + passo, 3)
		if satelites[indice] > 0.0:
			return indice
	return 0


func _reformar() -> void:
	exposto = false
	multiplicador_dano_recebido = 0.0
	formacao = Formacao.ORBITA
	raio_orbita_alvo = 84.0
	for indice in range(3):
		satelites[indice] = 28.0 + fase * 7.0
	alvo_satelite = _proximo(alvo_satelite)


func _obter_cena() -> Node:
	if not is_inside_tree():
		return null
	return get_tree().current_scene


func _draw() -> void:
	var brilho := 1.0 + sin(Time.get_ticks_msec() * 0.009) * 0.08
	var nucleo := PackedVector2Array()
	for indice in range(6):
		nucleo.append(Vector2.from_angle(angulo_visual + indice * TAU / 6.0) * 32.0 * brilho)
	draw_colored_polygon(nucleo, cor_principal if exposto else Color(0.16, 0.09, 0.015))
	draw_circle(Vector2.ZERO, 19.0 + pulso_reacao * 9.0, Color(cor_secundaria, 0.58))
	draw_circle(Vector2.ZERO, 10.0, Color.WHITE if exposto else cor_secundaria)

	for indice in range(3):
		var ponto := obter_posicao_satelite(indice) - global_position
		if satelites[indice] <= 0.0:
			draw_arc(ponto, 13.0, angulo_visual, angulo_visual + PI * 1.35, 14, Color(cor_principal, 0.24), 3.0)
			continue
		var seguinte := _proximo(indice + 1)
		if seguinte != indice:
			var ponto_seguinte := obter_posicao_satelite(seguinte) - global_position
			draw_line(ponto, ponto_seguinte, Color(cor_principal, 0.34), 2.0)
		var raio := 15.0 if indice == alvo_satelite else 11.0
		draw_circle(ponto, raio + sin(angulo_visual * 3.0 + indice) * 1.5, cor_principal)
		draw_arc(ponto, raio + 6.0, -PI * 0.65, PI * 0.65, 18, Color(cor_secundaria, 0.9), 3.0)
		draw_circle(ponto, 4.0, Color.WHITE)

	if abraco:
		var centro_local := Global.obter_centro_area_visivel() - global_position
		draw_circle(centro_local, raio_seguro, Color(cor_secundaria, 0.055))
		draw_arc(centro_local, raio_seguro, 0.0, TAU, 108, Color(cor_principal, 0.9), 7.0)
		for indice in range(3):
			var angulo := angulos[indice]
			draw_arc(centro_local, raio_seguro + 18.0, angulo - 0.62, angulo + 0.62, 24, Color(cor_secundaria, 0.74), 12.0)


func morrer() -> void:
	if Vida > 0.0:
		return
	var cena := _obter_cena()
	if is_instance_valid(cena):
		for indice in range(3):
			EfeitoCombateCena.criar(cena, obter_posicao_satelite(indice), EfeitoCombate.Tipo.MORTE, cor_principal, 1.4)
	super.morrer()
