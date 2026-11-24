extends CharacterBody2D
class_name SombraDaLua

const CICLO := 2.15
const FIM_PASSO := 0.76
const DISPARO := 1.38
const VIDA_TIRO := 1.75
const VELOCIDADE_TIRO := 285.0
const BRACOS := 4

var casco := CloneLunar.new()
var vida_maxima := 0.0
var vida := 0.0
var morto := false
var passo := 0
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
var posicao_replica := Vector2.ZERO
var rotacao_replica := 0.0
@onready var combate: SizigiaFinalController = get_parent()


func configurar(modelo: Dictionary, total: float, pos: Vector2) -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	vida_maxima = total
	vida = total
	global_position = pos
	destino = pos
	partida = pos
	posicao_replica = pos
	add_to_group("inimigo")
	add_to_group("visual_boss_local")
	collision_layer = 4
	collision_mask = 0
	var forma := CollisionShape2D.new()
	var circulo := CircleShape2D.new()
	circulo.radius = modelo.raio
	forma.shape = circulo
	add_child(forma)
	add_child(casco)
	casco.configurar(modelo)


func escolher_passo(pilotos: Array[Node2D]) -> void:
	var alvo := pilotos[passo % pilotos.size()]
	passo += 1
	partida = global_position
	var radial := alvo.global_position.direction_to(partida)
	if radial.is_zero_approx():
		radial = Vector2.RIGHT
	var area := Global.obter_retangulo_area_visivel().grow(-24)
	var lado := 1.0 if passo % 2 else -1.0
	# Passo curto ao redor da nave, seguido de uma parada para mirar.
	destino = (alvo.global_position + radial.rotated(lado * 0.85) * 160.0).clamp(area.position, area.end)
	destino = partida.move_toward(destino, 175.0)
	mira = destino.angle_to_point(alvo.global_position)


func _physics_process(delta: float) -> void:
	if morto or combate.boss.morto or combate.boss.destino_fase != 0 or Rede.pausa_do_host:
		return
	impacto = maxf(impacto - delta, 0.0)
	if Rede.modo_multiplayer and not multiplayer.is_server():
		global_position = global_position.lerp(posicao_replica, 1.0 - exp(-30.0 * delta))
		casco.rotation = lerp_angle(casco.rotation, rotacao_replica, 1.0 - exp(-30.0 * delta))
		tempo = minf(tempo + delta, CICLO)
		idade_tiro = minf(idade_tiro + delta, VIDA_TIRO)
		queue_redraw()
		return
	var pilotos := combate.pilotos_vivos()
	if pilotos.is_empty():
		return
	if passo == 0:
		escolher_passo(pilotos)
	var anterior := tempo
	tempo += delta
	if tempo >= CICLO:
		tempo = fmod(tempo, CICLO)
		anterior = 0.0
		escolher_passo(pilotos)
	global_position = partida.lerp(destino, smoothstep(0.0, FIM_PASSO, tempo))
	if anterior < FIM_PASSO:
		var alvo := pilotos[(passo - 1) % pilotos.size()]
		var previsao := alvo.global_position
		if alvo is CharacterBody2D:
			previsao += (alvo.velocity * 0.22).limit_length(55.0)
		mira = destino.angle_to_point(previsao)
	casco.rotation = rotate_toward(casco.rotation, mira, delta * 8.0)
	if anterior < DISPARO and tempo >= DISPARO:
		disparos += 1
		origem_tiro = global_position
		eixo_tiro = mira
		idade_tiro = 0.0
		atingidos.clear()
		som_salva()
	var idade_anterior := idade_tiro
	idade_tiro = minf(idade_tiro + delta, VIDA_TIRO)
	if disparos > 0 and idade_anterior < VIDA_TIRO:
		for i in BRACOS:
			var cauda := ponta(i, idade_anterior)
			var frente := ponta(i, idade_tiro)
			for p in pilotos:
				var chave := Vector2i(i, p.get_multiplayer_authority())
				if atingidos.has(chave):
					continue
				var perto := Geometry2D.get_closest_point_to_segment(p.global_position, cauda, frente)
				if perto.distance_squared_to(p.global_position) <= 121.0:
					atingidos[chave] = true
					combate.ferir(p, combate.boss.Dano * 0.26, frente)
	queue_redraw()


func ponta(indice: int, idade: float) -> Vector2:
	return origem_tiro + Vector2.from_angle(eixo_tiro + indice * TAU / BRACOS) * (15.0 + idade * VELOCIDADE_TIRO)


func som_salva() -> void:
	preload("res://Scripts/AudioCombate.gd").tocar_posicional(self, origem_tiro, &"pulso_clone", 0.1, 0.72, 0.78, -16.0)


func tomarDano(valor: float) -> void:
	if morto or not is_finite(valor) or valor <= 0 or Rede.pausa_do_host or combate.boss.destino_fase != 0:
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
	remove_from_group("inimigo")
	idade_tiro = VIDA_TIRO
	queue_redraw()
	var fim := create_tween().set_parallel(true)
	fim.tween_property(casco, "scale", casco.scale * 1.45, 0.20)
	fim.tween_property(self, "modulate:a", 0.0, 0.20)
	fim.chain().tween_callback(queue_free)


func snapshot() -> Array:
	return [casco.modelo, vida_maxima, vida, global_position, casco.rotation, tempo, mira, disparos, origem_tiro, eixo_tiro, idade_tiro]


func receber(s: Array, nova: bool) -> void:
	if not nova and vida > float(s[2]):
		impacto = 0.18
	vida = s[2]
	posicao_replica = s[3]
	rotacao_replica = s[4]
	tempo = s[5]
	mira = s[6]
	var emitiu := not nova and int(s[7]) > disparos
	disparos = s[7]
	origem_tiro = s[8]
	eixo_tiro = s[9]
	idade_tiro = s[10]
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
	var deslize := sin(PI * clampf(tempo / FIM_PASSO, 0.0, 1.0))
	var raio := 30.0 + deslize * 4.0
	draw_texture_rect(CloneLunar.HALO, Rect2(-Vector2.ONE * raio, Vector2.ONE * raio * 2.0),
		false, Color(cor, (0.32 + deslize * 0.12 + impacto) * brilho))
	if morto:
		draw_arc(Vector2.ZERO, 18, 0, TAU, 28, cor, 1.5, true)
		return
	draw_rect(Rect2(-13, -21, 26, 3), Color("#211d33"))
	draw_rect(Rect2(-13, -21, 26 * vida / vida_maxima, 3), cor.lerp(Color.WHITE, impacto * 4))
	if tempo >= FIM_PASSO and tempo < DISPARO:
		var carga := smoothstep(FIM_PASSO, DISPARO, tempo)
		for i in BRACOS:
			var rumo := Vector2.from_angle(mira + i * TAU / BRACOS)
			draw_line(rumo * 16, rumo * (24 + 12 * carga), Color(cor, 0.45 + carga * 0.55), 1.5, true)
	if idade_tiro < VIDA_TIRO:
		for i in BRACOS:
			draw_set_transform(to_local(ponta(i, idade_tiro)), eixo_tiro + i * TAU / BRACOS)
			draw_texture_rect(CloneLunar.HALO, Rect2(-18,-8,36,16), false, Color(combate.cor_tiro, 0.35 * brilho))
			draw_colored_polygon(combate.forma_tiro, combate.cor_tiro)
		draw_set_transform_matrix(Transform2D.IDENTITY)
