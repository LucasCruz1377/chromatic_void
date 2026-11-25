extends CharacterBody2D
class_name SombraDaLua

const INVOCACAO := 0.95
const FIM_PASSO := 0.43
const TRAVA_MIRA := 0.57
const DISPARO := 0.88
const CICLO_CURTO := 1.32
const CICLO_LONGO := 1.88
const VIDA_TIRO := 1.28
const VELOCIDADE_TIRO := 820.0
const FATOR_DANO := 0.36
const BRACOS := 4

var casco := CloneLunar.new()
var vida_maxima := 0.0
var vida := 0.0
var morto := false
var etapa_passo := 1
var etapa_salva := 1
var passo := 0
var alvo: Node2D
var rumo_passo := Vector2.RIGHT
var invocacao := 0.0
var tempo := 0.0
var partida := Vector2.ZERO
var destino := Vector2.ZERO
var mira := 0.0
var disparos := 0
var idade_tiro := VIDA_TIRO
var origem_tiro := Vector2.ZERO
var eixo_tiro := 0.0
var atingidos := {}
var impacto := 0.0
var rotacao_replica := 0.0
@onready var combate: SizigiaFinalController = get_parent()


func configurar(modelo: Dictionary, total: float, pos: Vector2) -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	vida_maxima = total
	vida = total
	global_position = pos
	destino = pos
	partida = pos
	casco.modulate.a = 0.0
	add_to_group("visual_boss_local")
	collision_layer = 0
	collision_mask = 0
	var forma := CollisionShape2D.new()
	var circulo := CircleShape2D.new()
	circulo.radius = modelo.raio
	forma.shape = circulo
	add_child(forma)
	add_child(casco)
	casco.configurar(modelo)


func duracao_ciclo() -> float:
	return (CICLO_LONGO if passo % 2 == 0 else CICLO_CURTO) - 0.12 * (etapa_passo - 1)


func atualizar_invocacao(instante: float) -> void:
	invocacao = clampf(instante, 0.0, INVOCACAO)
	var abertura := smoothstep(0.20, INVOCACAO * 0.84, invocacao)
	casco.modulate.a = abertura
	casco.scale = Vector2(casco.modelo.escala) * lerpf(0.35, 1.0, abertura)
	if invocacao >= INVOCACAO and not is_in_group("inimigo"):
		add_to_group("inimigo")
		collision_layer = 4


func escolher_passo(pilotos: Array[Node2D]) -> void:
	if combate.boss.fase_atual == BossSizigiaEterna.Fase.LUA:
		etapa_passo = combate.boss.fase_da_barra()
	# Um duelo de duas salvas por piloto. A segunda tem uma recuperação maior.
	if passo % 2 == 0 or not pilotos.has(alvo):
		alvo = pilotos[(passo >> 1) % pilotos.size()]
	passo += 1
	partida = global_position
	var radial := alvo.global_position.direction_to(partida)
	if radial.is_zero_approx():
		radial = Vector2.RIGHT
	var area := Global.obter_retangulo_area_visivel().grow(-25)
	var lado := -1.0 if passo % 3 == 0 else 1.0
	var melhor := -INF
	var alcance := 205.0 if passo % 2 else 252.0
	for sentido: float in [lado, -lado]:
		var ideal := alvo.global_position + radial.rotated(sentido * 1.02) * alcance
		var candidato := partida.move_toward(ideal.clamp(area.position, area.end), 215.0)
		# Penaliza encurralar-se na borda, cair em cima de outro piloto ou no casco do boss.
		var folga := candidato.distance_to(combate.boss.global_position) - 68.0
		for piloto in pilotos:
			folga = minf(folga, candidato.distance_to(piloto.global_position) - 78.0)
		var nota := minf(folga, 60.0) + partida.distance_to(candidato) * 0.25 - candidato.distance_to(ideal) * 0.16
		if nota > melhor:
			melhor = nota
			destino = candidato
	rumo_passo = partida.direction_to(destino)


func apontar() -> void:
	var pos := alvo.global_position
	if alvo is CharacterBody2D:
		# Inclui o tempo do aviso travado e o voo até a posição de interceptação.
		var v := (alvo as CharacterBody2D).velocity
		var relativo := pos + v * (DISPARO - TRAVA_MIRA) - destino
		var velocidade := velocidade_salva(etapa_passo)
		var a := velocidade * velocidade - v.length_squared()
		var b := relativo.dot(v)
		var voo := relativo.length() / velocidade
		if a > 1.0:
			voo = (b + sqrt(b * b + a * relativo.length_squared())) / a
		pos += (v * (DISPARO - TRAVA_MIRA + voo)).limit_length(155.0)
	mira = destino.angle_to_point(pos)


func _physics_process(delta: float) -> void:
	if morto or combate.boss.morto or combate.boss.destino_fase != 0 or Rede.pausa_do_host:
		return
	queue_redraw()
	if invocacao < INVOCACAO:
		atualizar_invocacao(invocacao + delta)
		return
	impacto = maxf(impacto - delta, 0.0)
	if Rede.modo_multiplayer and not multiplayer.is_server():
		casco.rotation = lerp_angle(casco.rotation, rotacao_replica, 1.0 - exp(-36.0 * delta))
		tempo = minf(tempo + delta, duracao_ciclo())
		global_position = partida.lerp(destino, smoothstep(0.0, FIM_PASSO, tempo))
		idade_tiro = minf(idade_tiro + delta, VIDA_TIRO)
		return
	var pilotos := combate.pilotos_vivos()
	if pilotos.is_empty():
		return
	if passo == 0:
		escolher_passo(pilotos)
	var anterior := tempo
	tempo += delta
	if tempo >= duracao_ciclo():
		tempo -= duracao_ciclo()
		anterior = 0.0
		escolher_passo(pilotos)
	global_position = partida.lerp(destino, smoothstep(0.0, FIM_PASSO, tempo))
	if anterior < TRAVA_MIRA:
		if not pilotos.has(alvo):
			alvo = pilotos[0]
		apontar()
	casco.rotation = rotate_toward(casco.rotation, mira, delta * 14.0)
	if anterior < DISPARO and tempo >= DISPARO:
		etapa_salva = etapa_passo
		disparos += 1
		origem_tiro = global_position
		eixo_tiro = mira
		idade_tiro = 0.0
		atingidos.clear()
		som_salva()
		delta = tempo - DISPARO
	avancar_dardos(delta, pilotos)


func avancar_dardos(delta: float, pilotos: Array[Node2D]) -> void:
	var anterior := idade_tiro
	idade_tiro = minf(idade_tiro + delta, VIDA_TIRO)
	if disparos == 0 or idade_tiro <= anterior:
		return
	for i in bracos_salva(etapa_salva):
		var cauda := ponta(i, anterior)
		var frente := ponta(i, idade_tiro)
		for p in pilotos:
			var chave := Vector2i(i, p.get_multiplayer_authority())
			if atingidos.has(chave):
				continue
			var perto := Geometry2D.get_closest_point_to_segment(p.global_position, cauda, frente)
			if perto.distance_squared_to(p.global_position) <= 121.0:
				atingidos[chave] = true
				combate.ferir(p, combate.boss.Dano * FATOR_DANO * combate.fator_dano(etapa_salva), frente)


func bracos_salva(fase: int) -> int:
	return BRACOS * 2 if fase == 3 else BRACOS


func velocidade_salva(fase: int) -> float:
	return VELOCIDADE_TIRO + 60.0 * (fase - 1)


func ponta(indice: int, idade: float) -> Vector2:
	return origem_tiro + Vector2.from_angle(eixo_tiro + indice * TAU / bracos_salva(etapa_salva)) * (15.0 + idade * velocidade_salva(etapa_salva))


func som_salva() -> void:
	preload("res://Scripts/AudioCombate.gd").tocar_posicional(self, origem_tiro, &"pulso_clone", 0.1, 0.72, 0.78, -16.0)


func tomarDano(valor: float) -> void:
	if morto or invocacao < INVOCACAO or not is_finite(valor) or valor <= 0 or Rede.pausa_do_host or combate.boss.destino_fase != 0:
		return
	if Rede.modo_multiplayer and not multiplayer.is_server():
		combate.solicitar_impacto_sombra.rpc_id(1, minf(valor, vida))
		return
	vida = maxf(0.0, vida - valor)
	impacto = 0.18
	if vida <= 0.0:
		dissolver()
	queue_redraw()


func dissolver() -> void:
	if morto:
		return
	morto = true
	set_physics_process(false)
	set_deferred("collision_layer", 0)
	if is_in_group("inimigo"):
		remove_from_group("inimigo")
	idade_tiro = VIDA_TIRO
	queue_redraw()
	var fim := create_tween().set_parallel(true)
	fim.tween_property(casco, "scale", casco.scale * 1.45, 0.20)
	fim.tween_property(self, "modulate:a", 0.0, 0.20)
	fim.chain().tween_callback(queue_free)


func snapshot() -> Array:
	return [casco.modelo, vida_maxima, vida, global_position, casco.rotation, tempo, mira, disparos, origem_tiro, eixo_tiro, idade_tiro, invocacao, passo, partida, destino, etapa_passo, etapa_salva]


func receber(s: Array, nova: bool) -> void:
	if not nova and vida > float(s[2]):
		impacto = 0.18
	vida = s[2]
	rotacao_replica = s[4]
	tempo = float(s[5]) if nova or passo != int(s[12]) else maxf(tempo, s[5])
	mira = s[6]
	var emitiu := not nova and int(s[7]) > disparos
	idade_tiro = float(s[10]) if nova or emitiu else maxf(idade_tiro, s[10])
	disparos = s[7]
	origem_tiro = s[8]
	eixo_tiro = s[9]
	if invocacao < INVOCACAO:
		atualizar_invocacao(maxf(invocacao, s[11]))
	etapa_passo = s[15]
	etapa_salva = s[16]
	passo = s[12]
	partida = s[13]
	destino = s[14]
	rumo_passo = partida.direction_to(destino)
	global_position = partida.lerp(destino, smoothstep(0.0, FIM_PASSO, tempo))
	if nova:
		casco.rotation = rotacao_replica
	elif emitiu and idade_tiro < 0.32:
		som_salva()
	queue_redraw()


func _draw() -> void:
	if not is_instance_valid(combate) or casco.modelo.is_empty():
		return
	var cor := casco.cor_aura
	var brilho := CloneLunar.intensidade_aura()
	if invocacao < INVOCACAO and not morto:
		desenhar_invocacao(cor, brilho)
		return
	var deslize := sin(PI * clampf(tempo / FIM_PASSO, 0.0, 1.0))
	var raio := 30.0 + deslize * 4.0
	draw_texture_rect(CloneLunar.HALO, Rect2(-Vector2.ONE * raio, Vector2.ONE * raio * 2.0),
		false, Color(cor, (0.32 + deslize * 0.12 + impacto) * brilho))
	if morto:
		draw_arc(Vector2.ZERO, 18, 0, TAU, 28, cor, 1.5, true)
		return
	if deslize > 0.05 and not rumo_passo.is_zero_approx():
		# Dois ecos curtos se apagam ao fim da arrancada.
		for i in range(1, 3):
			var eco := -rumo_passo * (7.0 * i * deslize)
			var tam := Vector2(24, 24) / sqrt(float(i))
			draw_texture_rect(CloneLunar.HALO, Rect2(eco - tam * 0.5, tam), false, Color(cor, deslize * 0.52 * brilho))
	draw_rect(Rect2(-13, -21, 26, 3), Color("#211d33"))
	draw_rect(Rect2(-13, -21, 26 * vida / vida_maxima, 3), cor.lerp(Color.WHITE, impacto * 4))
	if tempo >= FIM_PASSO and tempo < DISPARO:
		var carga := smoothstep(FIM_PASSO, DISPARO, tempo)
		for i in bracos_salva(etapa_passo):
			var rumo := Vector2.from_angle(mira + i * TAU / bracos_salva(etapa_passo))
			draw_line(rumo * 16, rumo * (24 + 12 * carga), Color(cor, 0.45 + carga * 0.55), 1.5, true)
			if i == 0 and tempo >= TRAVA_MIRA:
				draw_line(rumo * 38, rumo * (51 + 8 * carga), Color.WHITE, 1.5, true)
	if idade_tiro < VIDA_TIRO:
		for i in bracos_salva(etapa_salva):
			draw_set_transform(to_local(ponta(i, idade_tiro)), eixo_tiro + i * TAU / bracos_salva(etapa_salva))
			draw_texture_rect(CloneLunar.HALO, Rect2(-18,-8,36,16), false, Color(combate.cor_tiro, 0.35 * brilho))
			draw_colored_polygon(combate.forma_tiro, combate.cor_tiro)
			draw_line(Vector2(-13, 0), Vector2(4, 0), Color(combate.cor_tiro.lerp(Color.WHITE, 0.7), 0.86), 1.4, true)
		draw_set_transform_matrix(Transform2D.IDENTITY)


func desenhar_invocacao(cor: Color, brilho: float) -> void:
	var t := invocacao / INVOCACAO
	var fechar := smoothstep(0.03, 0.77, t)
	var revelar := smoothstep(0.64, 1.0, t)
	var centro := cor.lerp(Color.WHITE, 0.78)
	var raio := lerpf(40.0, 6.0, fechar)
	for i in BRACOS:
		var angulo := i * TAU / BRACOS + fechar * 1.15
		draw_arc(Vector2.ZERO, raio, angulo, angulo + 0.50, 10,
			Color(cor, (0.22 + fechar * 0.65) * (1.0 - revelar)), 1.5, true)
	var tam := Vector2.ONE * (18.0 + 48.0 * fechar)
	draw_texture_rect(CloneLunar.HALO, Rect2(-tam / 2, tam), false, Color(centro, (0.55 + 0.3 * fechar) * brilho))
	var pulso := sin(PI * t)
	draw_circle(Vector2.ZERO, 1.0 + 3.0 * pulso, Color(centro, pulso))
	if revelar > 0:
		draw_arc(Vector2.ZERO, lerpf(7, 35, revelar), 0, TAU, 36, Color(centro, 1.0 - revelar), 1.5, true)
