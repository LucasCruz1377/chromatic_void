extends Node2D

## Relógio compartilhado dos dois golpes em que o instrumento permanece vulnerável.
enum Golpe { LIVRE, ACORDE, FEIXE }
enum Regra { VERMELHO, LARANJA, AZUL, ROXO, VERDE }

const Visual = preload("res://Scripts/ContrafaseDueloVisual.gd")
const CARGA := 5.0
const TRAVA_MIRA := 4.0
const MEIO_LEQUE := PI / 4.5
const VELOCIDADE_ONDA := 950.0
const ESPESSURA_ONDA := 14.0
const PRELUDIO := 1.0
const PERIODO := 2.5
const TROCA_SUAVE := 0.22
const AVISO_COR := 0.55
const INTERVALO_DANO := 0.85
const PONTA := Vector2(0, -66)
const RAIO_NAVE := 13.5
const MEIA_LARGURA := 11.0

var golpe := Golpe.LIVRE
var tempo := 0.0
var fase_inicial := 1
var angulo_base := 0.0
var partida_feixe := Vector2.ZERO
var centro_feixe := Vector2.ZERO
var alcance_onda := 0.0
var atingidos := {}
var visual := Visual.new()
var chefe: CharacterBody2D


func _ready() -> void:
	chefe = get_parent()
	add_child(visual)
	visual.configurar(self)
	set_physics_process(false)


func autoridade() -> bool:
	return not Rede.modo_multiplayer or multiplayer.is_server()


func iniciar(tipo: Golpe, fase: int, alvo: Vector2) -> void:
	if not autoridade():
		return
	golpe = tipo
	fase_inicial = clampi(fase, 1, 3)
	tempo = 0.0
	atingidos.clear()
	angulo_base = chefe.global_position.angle_to_point(alvo) + PI / 2
	alcance_onda = Global.obter_retangulo_area_visivel().size.length() + 90.0
	if golpe == Golpe.FEIXE:
		partida_feixe = chefe.global_position
		centro_feixe = Global.obter_retangulo_area_visivel().get_center()
		angulo_base = centro_feixe.angle_to_point(alvo) + PI / 2
	chefe.rotation = angulo_base
	set_physics_process(true)
	visual.exibir()
	chefe._enviar_estado_defesas_rede()


func concluir() -> void:
	golpe = Golpe.LIVRE
	atingidos.clear()
	set_physics_process(false)
	visual.recolher()


func capturar() -> Dictionary:
	var estado := {
		"golpe": golpe,
		"relogio": tempo,
		"fase_golpe": fase_inicial,
		"mira": angulo_base,
		"alcance": alcance_onda,
	}
	if golpe == Golpe.FEIXE:
		estado["partida"] = partida_feixe
		estado["centro"] = centro_feixe
	return estado


func aplicar(dados: Dictionary) -> void:
	var recebido := int(dados["golpe"])
	if recebido == Golpe.LIVRE:
		if golpe != Golpe.LIVRE:
			concluir()
		return
	if golpe != recebido:
		visual.exibir()
	golpe = recebido
	if golpe == Golpe.FEIXE:
		partida_feixe = dados["partida"]
		centro_feixe = dados["centro"]
	tempo = float(dados["relogio"])
	fase_inicial = int(dados["fase_golpe"])
	angulo_base = float(dados["mira"])
	alcance_onda = float(dados["alcance"])
	set_physics_process(true)
	_atualizar_pose()


func _physics_process(delta: float) -> void:
	if golpe == Golpe.LIVRE or chefe.morto or Rede.pausa_do_host:
		return
	var anterior := tempo
	tempo += delta
	if golpe == Golpe.ACORDE and autoridade() and tempo < TRAVA_MIRA:
		var alvo: Node2D = chefe.player
		if is_instance_valid(alvo):
			var destino := chefe.global_position.angle_to_point(alvo.global_position) + PI / 2
			angulo_base = rotate_toward(angulo_base, destino, delta * 1.8)
	_atualizar_pose()
	if autoridade():
		if golpe == Golpe.ACORDE and tempo >= CARGA:
			_avancar_onda(anterior)
		elif golpe == Golpe.FEIXE and feixe_ativo():
			_avancar_feixes()
	visual.atualizar()
	if autoridade() and tempo >= duracao():
		concluir()
		chefe._enviar_estado_defesas_rede()


func _atualizar_pose() -> void:
	var giro := 0.0
	if golpe == Golpe.FEIXE:
		chefe.global_position = partida_feixe.lerp(centro_feixe, smoothstep(0.0, PRELUDIO, tempo))
		giro = maxf(tempo - PRELUDIO, 0.0) * velocidade_angular()
	chefe.rotation = angulo_base + giro


func velocidade_angular() -> float:
	return deg_to_rad(48.0 + (fase_inicial - 1) * 16.0)


func duracao() -> float:
	if golpe == Golpe.ACORDE:
		return CARGA + alcance_onda / VELOCIDADE_ONDA + 0.15
	return PRELUDIO + PERIODO * 5.0


func etapa_cor() -> int:
	return clampi(floori((tempo - PRELUDIO) / PERIODO), 0, 4)


func tempo_da_cor() -> float:
	return fposmod(maxf(tempo - PRELUDIO, 0.0), PERIODO)


func feixe_ativo() -> bool:
	return tempo >= PRELUDIO and tempo < duracao() and tempo_da_cor() >= TROCA_SUAVE


func antecipando_cor() -> bool:
	return tempo >= PRELUDIO and etapa_cor() < 4 and tempo_da_cor() >= PERIODO - AVISO_COR


func direcao_raio(indice: int) -> Vector2:
	return Vector2.UP.rotated(global_rotation + TAU * indice / fase_inicial)


func origem_raio(indice: int) -> Vector2:
	if indice == 0:
		return to_global(PONTA)
	return global_position


## Traça até a primeira borda adiante. O desenho e a colisão usam o mesmo segmento.
func fim_raio(indice: int) -> Vector2:
	var area := Global.obter_retangulo_area_visivel()
	var origem := origem_raio(indice)
	var rumo := direcao_raio(indice)
	var alcance := area.size.length() + 150.0
	if absf(rumo.x) > 0.0001:
		var borda := area.end.x if rumo.x > 0.0 else area.position.x
		alcance = minf(alcance, (borda - origem.x) / rumo.x)
	if absf(rumo.y) > 0.0001:
		var borda := area.end.y if rumo.y > 0.0 else area.position.y
		alcance = minf(alcance, (borda - origem.y) / rumo.y)
	return origem + rumo * maxf(0.0, alcance)


static func vulneravel(regra: int, velocidade: float, pronto: bool, y: float, boss_y: float) -> bool:
	match regra:
		Regra.VERMELHO:
			return true
		Regra.LARANJA:
			return velocidade <= 5.0
		Regra.AZUL:
			return velocidade > 24.0
		Regra.ROXO:
			return pronto
		Regra.VERDE:
			return y < boss_y
	return false


func _avancar_feixes() -> void:
	for i in fase_inicial:
		var inicio := origem_raio(i)
		var fim := fim_raio(i)
		if inicio.is_equal_approx(fim):
			continue
		var interceptados := _tracar_cascos(inicio, fim)
		for alvo in get_tree().get_nodes_in_group(&"player"):
			if not alvo is Player or not alvo.vivo:
				continue
			if tempo < float(atingidos.get(alvo.get_instance_id(), 0.0)):
				continue
			var pos: Vector2 = alvo.global_position
			var ponto := Geometry2D.get_closest_point_to_segment(pos, inicio, fim)
			if not interceptados.has(alvo.get_rid()) and pos.distance_squared_to(ponto) > pow(RAIO_NAVE + MEIA_LARGURA, 2):
				continue
			if vulneravel(etapa_cor(), alvo.velocity.length(), alvo.especial_pronto_rede, pos.y, global_position.y):
				atingidos[alvo.get_instance_id()] = tempo + INTERVALO_DANO
				alvo.tomar_dano(chefe.Dano * 0.65, inicio)


## A linha central atravessa os cascos. Um piloto à frente nunca protege
## o colega atrás dele. A faixa ao redor da linha cobre o brilho sólido.
func _tracar_cascos(inicio: Vector2, fim: Vector2) -> Array[RID]:
	var consulta := PhysicsRayQueryParameters2D.create(inicio, fim, 2)
	consulta.hit_from_inside = true
	var espaco := get_world_2d().direct_space_state
	var ignorados: Array[RID] = []
	var cascos: Array[RID] = []
	while true:
		consulta.exclude = ignorados
		var impacto := espaco.intersect_ray(consulta)
		if impacto.is_empty():
			break
		var rid: RID = impacto.rid
		ignorados.append(rid)
		if impacto.collider is Player:
			cascos.append(rid)
	return cascos


func raio_onda(instante: float) -> float:
	return maxf(instante - CARGA, 0.0) * VELOCIDADE_ONDA


func _avancar_onda(anterior: float) -> void:
	var origem := origem_raio(0)
	var rumo := direcao_raio(0)
	for nave in get_tree().get_nodes_in_group(&"player"):
		if not nave is Player or not nave.vivo or atingidos.has(nave.get_instance_id()):
			continue
		var vetor: Vector2 = nave.global_position - origem
		var distancia := vetor.length()
		if distancia < raio_onda(anterior) - RAIO_NAVE - ESPESSURA_ONDA:
			continue
		if distancia > raio_onda(tempo) + RAIO_NAVE + ESPESSURA_ONDA:
			continue
		if absf(rumo.angle_to(vetor)) > MEIO_LEQUE + atan2(RAIO_NAVE, distancia):
			continue
		atingidos[nave.get_instance_id()] = true
		nave.receber_power_chord(chefe.Dano * 1.5, origem)
