extends Node2D
class_name SizigiaFinalController

## O mesmo relógio e a mesma geometria alimentam o desenho e os acertos.
## O host publica a partitura atual, inclusive para quem chega durante um golpe.
enum Golpe { NENHUM, CRESCENTES, MARE, METEOROS, SOMBRA, INVESTIDA, RAIO, MANCHAS, ROUBO, RETORNO, REFLEXOS, TOTALIDADE, ABSOLUTO }

const LUA := Color("#a5d8ff")
const SOL := Color("#ffb24c")
const SOMBRA := Color("#d299ff")
const SEGURO := Color("#80ffcc")
const ROTA_LUA := [Golpe.CRESCENTES, Golpe.MARE, Golpe.METEOROS, Golpe.SOMBRA]
const ROTA_SOL := [Golpe.INVESTIDA, Golpe.MANCHAS, Golpe.RAIO, Golpe.INVESTIDA, Golpe.ROUBO]
const ROTA_ECLIPSE := [Golpe.TOTALIDADE, Golpe.RETORNO, Golpe.REFLEXOS, Golpe.METEOROS]
const DURACOES := [0.0, 3.3, 5.6, 5.05, 1.45, 2.85, 3.65, 5.6, 4.8, 4.1, 4.3, 7.7, 7.6]
const NOMES := [
	"",
	"CRESCENTES LUNARES — ATRAVESSE AS ABERTURAS",
	"MARÉ LUNAR — SIGA AS BALIZAS VERDES",
	"CHUVA DE METEOROS",
	"SOMBRA LUNAR — DESVIE DA CRUZ",
	"INVESTIDA SOLAR — SAIA DA LINHA VERMELHA",
	"RAIO SOLAR — A MIRA TRAVA ANTES DO DISPARO",
	"MANCHAS SOLARES — DESTRUA-AS ANTES DA EXPLOSÃO",
	"ROUBO DE LUZ — CESSE FOGO ENQUANTO O HALO CARREGA",
	"CRESCENTES INCENDIÁRIOS — ELES RETORNAM",
	"REFLEXOS ASTRAIS — ATAQUE VINDO DOS DOIS LADOS",
	"TOTALIDADE — ATRAIA O RAIO E CRUZE A PASSAGEM",
	"ECLIPSE ABSOLUTO — BUSQUE O ABRIGO",
]

const MEIA_ABERTURA := 0.38
const ANEIS_LUA := [2, 5, 10]
const ANEIS_ECLIPSE := [4, 7, 10]
const PRIMEIRO_ANEL := 3.2
const INTERVALO_ANEIS := 1.5
const PASSO_ANGULAR := PI / 8.0
const VELOCIDADE_ANEL := 510.0
const RAIO_NAVE_PADRAO := 13.5
const DISTANCIA_ONDA := 960.0

var tipo := Golpe.NENHUM
var tempo := 0.0
var origem := Vector2.ZERO
var direcao := Vector2.RIGHT
var alvo_id := 1
var vez_clone := 0
var marca := Vector2.ZERO
var pontos := PackedVector2Array()
var abrigos := PackedVector2Array()
var lacunas := PackedFloat32Array()
var historicos := {}
const INTERVALO_POSE := 1.0 / 30.0
const JANELA_MEMORIA := 2.9
const MATERIALIZACAO := 0.7
const VIDA_DARDO := 1.55
const VELOCIDADE_DARDO := 385.0
const INTERVALO_TIRO_CLONE := 1.0 / 3.0
const ALVO_METEORO := preload("res://FX/AlvoMeteoro.svg")
const INTERVALO_CHUVA := 0.87
const INTERVALO_IMPACTOS := 0.10
const ONDA_IMPACTO := 0.30
var linhas_chuva := PackedInt32Array()
var area_chuva := Rect2()
var vez_meteoro := 0
var historicos_tiros := {}
var proximo_tiro := {}
var gatilhos := {}
var ritmo_replica := 1.0
var forma_tiro := PackedVector2Array()
var cor_tiro := Color.WHITE
var relogio := 0.0
var amostra := 0.0
var especial := {}
var sombra: SombraDaLua
var sombra_invocada := false
var dano_sombra_por_peer := {}
var clone: CloneLunar
var energia := 0.0
var mascara_orbes := 0
var etapa := 1 # Fixa a dificuldade até terminar o golpe já anunciado.
var serie := 0
var investida_dupla := false
var som_emitido := false
var ultima_leva_sonora := -1
var ultimo_pulso_sonoro := -1
var impactos := {}
var anterior := 0.0
var pilotos: Array[Node2D] = []
var orbes: Array[OrbeAstral] = []
@onready var boss = get_parent()


func _ready() -> void:
	# Copia somente a geometria do projétil padrão. A colisão continua hostil e autoritativa.
	var referencia := preload("res://Entities/fireball.tscn").instantiate()
	var poligono := referencia.get_node("Polygon2D") as Polygon2D
	forma_tiro = poligono.transform * poligono.polygon
	cor_tiro = poligono.color.inverted()
	referencia.free()
	top_level = true
	global_transform = Transform2D.IDENTITY
	z_index = 4
	set_process(false)


func pilotos_vivos() -> Array[Node2D]:
	var vivos: Array[Node2D] = []
	for p in get_tree().get_nodes_in_group("player"):
		if p is Node2D and p.visible and p.get("vivo") != false and not p.is_queued_for_deletion():
			vivos.append(p)
	return vivos


func registrar_trajetorias(delta: float) -> void:
	relogio += delta
	amostra -= delta
	if amostra > 0:
		return
	amostra += INTERVALO_POSE
	var presentes := {}
	for p in pilotos_vivos():
		var id := p.get_instance_id()
		presentes[id] = true
		var poses: PackedVector4Array = historicos.get(id, PackedVector4Array())
		poses.append(Vector4(p.global_position.x, p.global_position.y, p.global_rotation, relogio))
		while poses.size() > 1 and poses[0].w < relogio - JANELA_MEMORIA:
			poses.remove_at(0)
		historicos[id] = poses
		var tiros: PackedFloat32Array = historicos_tiros.get(id, PackedFloat32Array())
		var proximo := float(proximo_tiro.get(id, relogio))
		var pressionado: bool = p is Player and p.gatilho_pressionado
		if pressionado:
			if not gatilhos.get(id, false):
				proximo = maxf(relogio, proximo)
			if relogio + 0.00001 >= proximo:
				tiros.append(proximo)
				proximo += INTERVALO_TIRO_CLONE
		gatilhos[id] = pressionado
		proximo_tiro[id] = proximo
		while not tiros.is_empty() and tiros[0] < poses[0].w:
			tiros.remove_at(0)
		historicos_tiros[id] = tiros
	for id in historicos.keys():
		if not presentes.has(id):
			historicos.erase(id)
			historicos_tiros.erase(id)
			proximo_tiro.erase(id)
			gatilhos.erase(id)


func preparar_memoria(alvo: Node2D) -> void:
	var id := alvo.get_instance_id()
	var poses: PackedVector4Array = historicos.get(id, PackedVector4Array()).duplicate()
	var atual := Vector4(alvo.global_position.x, alvo.global_position.y, alvo.global_rotation, relogio)
	if poses.is_empty() or relogio - poses[-1].w > 0.001:
		poses.append(atual)
	var inicio := poses[0].w
	for i in poses.size():
		poses[i].w -= inicio
	var tiros := PackedFloat32Array()
	for t in historicos_tiros.get(id, PackedFloat32Array()):
		if t >= inicio:
			tiros.append(t - inicio)
	especial = {"poses": poses, "tiros": tiros}
	if alvo is Player:
		especial["modelo"] = CloneLunar.capturar(alvo)
	materializar_clone()


func materializar_clone() -> void:
	if not especial.has("modelo"):
		return
	clone = CloneLunar.new()
	clone.name = "DuploLunar_%d" % serie
	add_child(clone)
	clone.configurar(especial.modelo)
	atualizar_clone()


func pose_em(instante: float) -> Vector4:
	var poses: PackedVector4Array = especial.poses
	for i in range(1, poses.size()):
		var a := poses[i - 1]
		var b := poses[i]
		if instante >= b.w:
			continue
		# Wrap ou teleporte: o casco reaparece do outro lado sem cruzar a arena.
		if Vector2(a.x, a.y).distance_squared_to(Vector2(b.x, b.y)) > 100.0 * 100.0:
			return a
		var peso := clampf((instante - a.w) / maxf(b.w - a.w, 0.001), 0, 1)
		return Vector4(lerpf(a.x, b.x, peso), lerpf(a.y, b.y, peso), lerp_angle(a.z, b.z, peso), instante)
	return poses[-1]


func atualizar_clone() -> void:
	if not is_instance_valid(clone):
		return
	var instante := tempo - MATERIALIZACAO
	var pose := pose_em(instante)
	clone.position = Vector2(pose.x, pose.y)
	clone.rotation = pose.z
	var fim: float = especial.poses[-1].w
	clone.self_modulate.a = smoothstep(0.0, 0.32, tempo) * (1.0 - smoothstep(fim, fim + 0.32, instante))
	clone.visible = clone.self_modulate.a > 0.001


func escolher() -> void:
	var rota: Array = ROTA_LUA
	if boss.fase_atual == 2:
		rota = ROTA_SOL
	elif boss.fase_atual == 3:
		rota = ROTA_ECLIPSE
		if not boss.absoluto_usado and boss.fase_da_barra() == 3:
			boss.absoluto_usado = true
			iniciar(Golpe.ABSOLUTO)
			return
	var escolha: int = rota[boss.passo_rotacao % rota.size()]
	boss.passo_rotacao += 1
	if escolha == Golpe.SOMBRA and sombra_invocada:
		escolha = rota[boss.passo_rotacao % rota.size()]
		boss.passo_rotacao += 1
	iniciar(escolha)


func iniciar(escolha: int) -> void:
	pilotos = pilotos_vivos()
	if pilotos.is_empty():
		return
	encerrar()
	serie += 1
	tipo = escolha as Golpe
	etapa = boss.fase_da_barra()
	var alvo := pilotos[(serie - 1) % pilotos.size()]
	if tipo in [Golpe.SOMBRA, Golpe.ABSOLUTO]:
		pilotos.sort_custom(func(a: Node2D, b: Node2D) -> bool:
			return a.get_multiplayer_authority() < b.get_multiplayer_authority())
		alvo = pilotos[vez_clone % pilotos.size()]
		vez_clone += 1
	alvo_id = alvo.get_multiplayer_authority()
	origem = boss.global_position
	marca = alvo.global_position
	direcao = origem.direction_to(marca)
	if direcao.is_zero_approx():
		direcao = Vector2.RIGHT
	boss.direcao_investida = direcao
	investida_dupla = tipo == Golpe.INVESTIDA and (etapa >= 2 or boss.passo_rotacao >= 4)
	var area := Global.obter_retangulo_area_visivel()
	if aneis_rotativos():
		# A onda nasce no astro e precisa alcançar até o canto mais distante.
		var distancia := (origem - area.get_center()).abs() + area.size * 0.5
		# Perto das bordas, gira a saída do alvo na direção do interior da sala.
		var sentido := 1.0 if serie % 2 == 0 else -1.0
		if not area.grow(-100.0).has_point(origem):
			var para_centro := origem.direction_to(area.get_center())
			sentido = 1.0 if direcao.cross(para_centro) >= 0.0 else -1.0
		especial = {"alcance": distancia.length() + 32.0, "raio_nave": 0.0, "sentido": sentido}
	var mare_intermediaria := mare_da_segunda_fase()
	if tipo == Golpe.TOTALIDADE or mare_intermediaria:
		var furos := 4 if tipo == Golpe.TOTALIDADE and Rede.modo_multiplayer else 2
		for i in furos:
			lacunas.append(fposmod(direcao.angle() + TAU * i / furos, TAU))
	for p in pilotos:
		if tipo == Golpe.MARE and not mare_intermediaria:
			lacunas.append(fposmod(origem.angle_to_point(p.global_position), TAU))
		if aneis_rotativos():
			especial.raio_nave = maxf(especial.raio_nave, raio_piloto(p))
		if tipo == Golpe.ABSOLUTO:
			var abrigo := p.global_position.move_toward(area.get_center(), 108.0)
			if not protegido(abrigo, 60.0):
				abrigos.append(abrigo)
	lacunas.sort()
	if tipo == Golpe.SOMBRA and alvo is Player and not sombra_invocada and boss.fase_atual == boss.Fase.LUA:
		var modelo := CloneLunar.capturar(alvo)
		var colisao := alvo.get_node("colisao") as CollisionShape2D
		modelo["raio"] = (colisao.shape as CircleShape2D).radius * absf(colisao.global_scale.x)
		var pos := posicao_invocacao_sombra(area)
		criar_sombra(modelo, boss.obter_vida_maxima_atual() * 0.20, pos)
	elif tipo == Golpe.ABSOLUTO:
		preparar_memoria(alvo)
	if tipo == Golpe.REFLEXOS:
		pontos = PackedVector2Array([area.position + area.size * Vector2(0.20, 0.27), area.position + area.size * Vector2(0.80, 0.73)])
	if tipo == Golpe.METEOROS:
		preparar_chuva(area)
	if tipo == Golpe.MANCHAS:
		mascara_orbes = 7
		criar_orbes()
	boss.subtitulo_alterado.emit(tr(NOMES[tipo]))
	queue_redraw()


func raio_piloto(p: Node2D) -> float:
	var forma := p.get_node_or_null("colisao") as CollisionShape2D
	if forma != null and forma.shape is CircleShape2D:
		return (forma.shape as CircleShape2D).radius * absf(forma.global_scale.x)
	return RAIO_NAVE_PADRAO


func preparar_chuva(area: Rect2) -> void:
	area_chuva = area
	var eclipse: bool = boss.fase_atual == 3
	var levas := 3 + etapa
	especial = {"raios": PackedFloat32Array(), "quedas": PackedVector2Array(),
		"avisos": PackedFloat32Array(), "antecedencia": (1.05 if eclipse else 1.10) - (etapa - 1) * 0.06, "levas": levas}
	# Em cada leva cai uma pedra em cada coluna. Todas as células recebem uma queda.
	linhas_chuva.resize(levas * 3)
	for coluna in 3:
		var linhas := range(levas)
		linhas.shuffle()
		for leva in levas:
			linhas_chuva[leva * 3 + coluna] = linhas[leva]
	marcar_leva()


func marcar_leva() -> void:
	var leva: int = especial.avisos.size()
	especial.avisos.append(tempo)
	var celula := area_chuva.size / Vector2(3, especial.levas)
	var alvo := area_chuva.get_center()
	if not pilotos.is_empty():
		var piloto := pilotos[vez_meteoro % pilotos.size()]
		vez_meteoro += 1
		alvo = piloto.global_position
		if piloto is CharacterBody2D:
			alvo += (piloto.velocity * 0.18).limit_length(36.0)
	# O alvo fica fixo desde o primeiro quadro do aviso. Mesmo um piloto na borda pode sair para dentro.
	pontos.append(alvo.clamp(area_chuva.position, area_chuva.end))
	for coluna in 3:
		var linha := linhas_chuva[leva * 3 + coluna]
		var deslocamento := Vector2(randf_range(0.3, 0.7), randf_range(0.3, 0.7))
		pontos.append(area_chuva.position + (Vector2(coluna, linha) + deslocamento) * celula)
	for i in 4:
		especial.quedas.append(Vector2(randf_range(-145, 145), -260))
		var raio := 49.0 if i == 0 else randf_range(47, 58)
		especial.raios.append(minf(raio, minf(celula.x, area_chuva.size.y / 4.0) * 0.43))


func instante_impacto(i: int) -> float:
	return especial.avisos[i >> 2] + especial.antecedencia + (i % 4) * INTERVALO_IMPACTOS


func aneis_rotativos() -> bool:
	return tipo == Golpe.TOTALIDADE or (tipo == Golpe.MARE and etapa >= 2)


func quantidade_aneis() -> int:
	return ANEIS_LUA[etapa - 1] if tipo == Golpe.MARE else ANEIS_ECLIPSE[etapa - 1]


func mare_da_segunda_fase() -> bool:
	return tipo == Golpe.MARE and etapa == 2


func antecedencia_anel() -> float:
	return 1.8 if mare_da_segunda_fase() else 1.2


func inicio_aneis() -> float:
	if mare_da_segunda_fase():
		return antecedencia_anel()
	return 1.4 if tipo == Golpe.MARE else PRIMEIRO_ANEL


func intervalo_aneis() -> float:
	if mare_da_segunda_fase():
		return 2.0
	return INTERVALO_ANEIS + (3 - etapa) * 0.15


func velocidade_anel() -> float:
	return VELOCIDADE_ANEL - (3 - etapa) * 45.0


func fim_dos_aneis() -> float:
	return inicio_aneis() + (quantidade_aneis() - 1) * intervalo_aneis() + float(especial.alcance) / velocidade_anel()


func duracao_golpe() -> float:
	if aneis_rotativos():
		return fim_dos_aneis() + 1.4
	if tipo == Golpe.METEOROS:
		# Se o host atrasar um quadro, nunca cortar o aviso ou a última explosão.
		return maxf(DURACOES[tipo], instante_impacto(pontos.size() - 1) + ONDA_IMPACTO)
	return DURACOES[tipo]


func snapshot() -> Array:
	return [serie, tipo, tempo, origem, direcao, alvo_id, marca, pontos, abrigos, lacunas, energia, mascara_orbes, investida_dupla, especial, etapa]


func receber(s: Array) -> void:
	if s.size() != 15 or int(s[0]) < serie:
		return
	var nova := int(s[0]) != serie or int(s[1]) != tipo
	if nova:
		encerrar()
	serie = s[0]
	tipo = int(s[1]) as Golpe
	var tempo_host := float(s[2])
	if nova or tipo == Golpe.NENHUM:
		tempo = tempo_host
		ritmo_replica = 1.0
	else:
		# Corrige a velocidade entre pacotes sem rebobinar a nave ou seus tiros.
		ritmo_replica = clampf(1.0 + (tempo_host - tempo) * 2.0, 0.85, 1.12)
		tempo = maxf(tempo, tempo_host)
	origem = s[3]
	direcao = s[4]
	alvo_id = s[5]
	marca = s[6]
	pontos = s[7]
	abrigos = s[8]
	lacunas = s[9]
	energia = s[10]
	mascara_orbes = s[11]
	investida_dupla = s[12]
	especial = s[13]
	etapa = s[14]
	if nova and tipo == Golpe.ABSOLUTO:
		materializar_clone()
	atualizar_clone()
	if nova and tipo != Golpe.NENHUM:
		boss.subtitulo_alterado.emit(tr(NOMES[tipo]))
		if tipo == Golpe.MANCHAS:
			criar_orbes()
	atualizar_orbes()
	set_process(tipo != Golpe.NENHUM)
	queue_redraw()


func _process(delta: float) -> void:
	# Interpola entre as amostras completas do servidor. Somente ele resolve dano.
	tempo = minf(tempo + delta * ritmo_replica, duracao_golpe())
	feedback_local(delta)
	atualizar_clone()
	atualizar_orbes()
	queue_redraw()


func avancar(delta: float) -> void:
	anterior = tempo
	tempo += delta
	pilotos = pilotos_vivos()
	if tipo == Golpe.METEOROS and especial.avisos.size() < especial.levas and tempo >= float(especial.avisos[-1]) + INTERVALO_CHUVA - (etapa - 1) * 0.07:
		marcar_leva()
	feedback_local(delta)
	atualizar_clone()
	if tipo in [Golpe.RAIO, Golpe.TOTALIDADE] and tempo < trava_raio():
		for p in pilotos:
			if p.get_multiplayer_authority() == alvo_id:
				marca = p.global_position
				direcao = origem.direction_to(marca)
				break
	if tipo == Golpe.INVESTIDA:
		if tempo < 0.95:
			boss.estado = boss.Estado.AVISANDO
		elif tempo < 1.77:
			boss.estado = boss.Estado.INVESTINDO
		else:
			boss.estado = boss.Estado.RECUPERANDO
	boss.multiplicador_dano_recebido = 1.45 if exposto() else 1.0
	atualizar_orbes()
	padrao(false)
	if tempo >= duracao_golpe() and (tipo != Golpe.METEOROS or especial.avisos.size() == especial.levas):
		encerrar()
		boss.estado = boss.Estado.MOVENDO
		boss.subtitulo_alterado.emit(boss.obter_subtitulo_boss())
		boss.tempo_ataque = 1.05
		if boss.fase_atual == 2:
			boss.tempo_ataque = 0.90
		elif boss.fase_atual == 3:
			boss.tempo_ataque = 0.78
		boss.tempo_ataque *= 1.0 - (boss.fase_da_barra() - 1) * 0.12
	queue_redraw()


func encerrar() -> void:
	tipo = Golpe.NENHUM
	tempo = 0.0
	anterior = 0.0
	som_emitido = false
	ultima_leva_sonora = -1
	ultimo_pulso_sonoro = -1
	energia = 0.0
	pontos = PackedVector2Array()
	abrigos = PackedVector2Array()
	lacunas = PackedFloat32Array()
	impactos.clear()
	especial = {}
	if is_instance_valid(clone):
		clone.hide()
		clone.queue_free()
		clone = null
	for orbe in orbes:
		if is_instance_valid(orbe):
			orbe.hide()
			orbe.queue_free()
	orbes.clear()
	mascara_orbes = 0
	if is_instance_valid(boss):
		boss.multiplicador_dano_recebido = 1.0
	set_process(false)
	queue_redraw()


func gravidade_ativa() -> bool:
	return (tipo == Golpe.MARE and tempo < 1.25) or (tipo == Golpe.TOTALIDADE and tempo < trava_raio())


func feedback_local(delta: float) -> void:
	if tipo == Golpe.ABSOLUTO and especial.has("tiros"):
		var instante_replay := tempo - MATERIALIZACAO
		var tiros: PackedFloat32Array = especial.tiros
		while ultimo_pulso_sonoro + 1 < tiros.size() and tiros[ultimo_pulso_sonoro + 1] <= instante_replay:
			ultimo_pulso_sonoro += 1
			var t := tiros[ultimo_pulso_sonoro]
			if instante_replay - t < 0.12:
				var pose := pose_em(t)
				preload("res://Scripts/AudioCombate.gd").tocar_posicional(self, Vector2(pose.x, pose.y), &"pulso_clone", 0.1, 0.70, 0.76, -16.0)
	if gravidade_ativa():
		for p in pilotos_vivos():
			if p is Player and (not Rede.modo_multiplayer or p.is_multiplayer_authority()):
				p.velocity += p.global_position.direction_to(origem) * 65.0 * delta
	var instante := -1.0
	if tipo == Golpe.SOMBRA:
		instante = 0.18
	elif tipo == Golpe.INVESTIDA:
		instante = 0.95
	elif tipo in [Golpe.RAIO, Golpe.TOTALIDADE]:
		instante = trava_raio()
	elif tipo == Golpe.METEOROS:
		for leva in range(0, pontos.size(), 4):
			var t := instante_impacto(leva)
			if leva > ultima_leva_sonora and tempo >= t and tempo < t + 0.45:
				ultima_leva_sonora = leva
				preload("res://Scripts/AudioCombate.gd").tocar_posicional(self, pontos[leva], &"explosoes", 0.15, 0.83, 1.04, -12.0)
				Global.vibrar_controle(0.14, 0.27, 0.09)
	elif tipo == Golpe.ABSOLUTO:
		instante = 5.1
	if instante >= 0 and tempo >= instante and not som_emitido:
		som_emitido = true
		var som := &"explosoes" if tipo == Golpe.ABSOLUTO else &"investida"
		if tipo == Golpe.SOMBRA:
			som = &"retrocesso"
		preload("res://Scripts/AudioCombate.gd").tocar(self, som, 0.0, 0.90, 0.90, -12.0)
		Global.vibrar_controle(0.25, 0.40, 0.10)


func absorvendo() -> bool:
	return tipo == Golpe.ROUBO and tempo < 2.15


func exposto() -> bool:
	match tipo:
		Golpe.TOTALIDADE: return tempo >= fim_dos_aneis()
		Golpe.ABSOLUTO: return tempo >= 5.4
		Golpe.INVESTIDA: return tempo >= 1.77
	return false


func protegido(pos: Vector2, raio: float) -> bool:
	for abrigo in abrigos:
		if pos.distance_to(abrigo) <= raio:
			return true
	return false


func fator_dano(fase: int) -> float:
	return 1.0 + (fase - 1) * 0.15


func ferir(p: Node2D, dano: float, fonte: Vector2) -> void:
	if p.has_method("tomar_dano"):
		p.tomar_dano(dano, fonte)


func acerto(p: Node2D, indice: int, fator: float, fonte: Vector2) -> void:
	var chave := Vector2i(indice, p.get_multiplayer_authority())
	if impactos.has(chave):
		return
	impactos[chave] = true
	ferir(p, boss.Dano * fator * fator_dano(etapa), fonte)
	if tipo in [Golpe.RETORNO, Golpe.RAIO] and p.has_method("aplicar_queimadura"):
		p.aplicar_queimadura(boss.Dano * 0.18 * fator_dano(etapa), 2.4)


func posicao_invocacao_sombra(area: Rect2) -> Vector2:
	var limite := area.grow(-42)
	var melhor := -INF
	var pos := origem
	for i in 8:
		var rumo := direcao.rotated((i + 2) * TAU / 8.0)
		var candidato := (origem + rumo * 112.0).clamp(limite.position, limite.end)
		var espaco := candidato.distance_to(origem) - 64.0
		for piloto in pilotos:
			espaco = minf(espaco, candidato.distance_to(piloto.global_position) - 96.0)
		if espaco > melhor + 0.01:
			melhor = espaco
			pos = candidato
	return pos


func criar_sombra(modelo: Dictionary, vida: float, pos: Vector2) -> void:
	sombra_invocada = true
	sombra = SombraDaLua.new()
	sombra.name = "SombraDaLua"
	add_child(sombra)
	sombra.configurar(modelo, vida, pos)


func snapshot_sombra() -> Array:
	if is_instance_valid(sombra) and not sombra.morto:
		return sombra.snapshot()
	return []


func receber_sombra(s: Array) -> void:
	if s.is_empty():
		if is_instance_valid(sombra):
			sombra.dissolver()
		return
	var nova := not is_instance_valid(sombra)
	if nova:
		criar_sombra(s[0], s[1], s[3])
	sombra.receber(s, nova)


# Habilidades de área e contato usam o controlador estável mesmo após a morte da sombra.
@rpc("any_peer", "call_remote", "reliable")
func solicitar_impacto_sombra(valor: float) -> void:
	if not multiplayer.is_server() or Rede.pausa_do_host or not is_instance_valid(sombra) or sombra.morto:
		return
	var peer := multiplayer.get_remote_sender_id()
	if not Rede.jogadores.has(peer) or not is_finite(valor) or valor <= 0 or valor > 1500.0:
		return
	for p in pilotos_vivos():
		if p.get_multiplayer_authority() != peer or p.global_position.distance_to(sombra.global_position) > 2400:
			continue
		var agora := Global.tempo_combate_ms()
		var janela: Vector2 = dano_sombra_por_peer.get(peer, Vector2(agora, 0))
		if agora - janela.x >= 1000:
			janela = Vector2(agora, 0)
		if janela.y + valor <= 5000.0:
			dano_sombra_por_peer[peer] = janela + Vector2(0, valor)
			sombra.tomarDano(valor)
		return


func criar_orbes() -> void:
	for i in 3:
		var orbe := OrbeAstral.new()
		orbe.name = "Mancha_%d_%d" % [serie, i]
		orbe.indice = i
		add_child(orbe)
		orbes.append(orbe)
	atualizar_orbes()


# Habilidades de contato e área não passam pelo registro de disparos da arena.
@rpc("any_peer", "call_remote", "reliable")
func solicitar_impacto_mancha(geracao: int, indice: int, valor: float) -> void:
	if not multiplayer.is_server() or Rede.pausa_do_host or geracao != serie or tipo != Golpe.MANCHAS:
		return
	if indice < 0 or indice >= orbes.size() or not is_finite(valor) or valor <= 0 or valor > 3:
		return
	var peer := multiplayer.get_remote_sender_id()
	for p in pilotos_vivos():
		if p.get_multiplayer_authority() == peer and p.global_position.distance_to(orbes[indice].global_position) <= 550:
			orbes[indice].tomarDano(valor)
			return


func pos_orbe(i: int, t: float) -> Vector2:
	return origem + Vector2.from_angle(i * TAU / 3.0 + minf(t, 2.5) * 0.48) * 115.0


func atualizar_orbes() -> void:
	for i in orbes.size():
		var ativo := tempo < 3.2 and (mascara_orbes & (1 << i)) != 0
		orbes[i].position = pos_orbe(i, tempo)
		orbes[i].morto = not ativo
		orbes[i].visible = ativo
		if ativo:
			orbes[i].queue_redraw()
		orbes[i].collision_layer = 4 if ativo else 0


func _draw() -> void:
	padrao(true)


func padrao(visual: bool) -> void:
	match tipo:
		Golpe.CRESCENTES, Golpe.RETORNO:
			leque(visual, origem, direcao, (5 if tipo == Golpe.RETORNO else 4) + (etapa - 1) * 2, 0.72, tipo == Golpe.RETORNO, 10)
		Golpe.MARE, Golpe.TOTALIDADE:
			if aneis_rotativos():
				for i in quantidade_aneis():
					onda(visual, inicio_aneis() + i * intervalo_aneis(), desvio_anel(i), 300 + i)
			else:
				onda(visual, 1.25, 0.0, 0)
				onda(visual, 2.70, 0.16, 1)
			if tipo == Golpe.TOTALIDADE:
				raio(visual)
		Golpe.METEOROS:
			for i in pontos.size():
				meteoro(visual, i)
		Golpe.ABSOLUTO:
			memoria(visual)
			clarao(visual)
		Golpe.INVESTIDA:
			if visual:
				investida()
			if investida_dupla and tempo >= 0.95 and tempo < 1.77:
				for lado in [-1, 1]:
					var rumo := direcao.rotated(lado * (0.45 + (tempo - 0.95) * 0.45))
					var pos := origem + rumo * (tempo - 0.95) * (465.0 + 45.0 * (etapa - 1))
					if visual:
						draw_line(pos - rumo * 18, pos, SOL, 4, true)
						draw_circle(pos, 4, Color.WHITE)
					else:
						for p in pilotos:
							if p.global_position.distance_to(pos) <= 12:
								acerto(p, 140 + lado, 0.30, pos)
		Golpe.RAIO:
			raio(visual)
		Golpe.MANCHAS:
			for i in 3:
				if mascara_orbes & (1 << i):
					erupcao(visual, pos_orbe(i, tempo), 3.2, 8 + 2 * (etapa - 1), 50 + i * 16)
		Golpe.ROUBO:
			if visual and tempo < 2.15:
				draw_arc(origem, 80, -PI / 2, 1.5 * PI, 64, Color(SOL, 0.45), 3, true)
				draw_arc(origem, 80, -PI / 2, -PI / 2 + TAU * energia / 40.0, 48, SOL, 7, true)
			erupcao(visual, origem, 2.45, 5 + etapa * 2 + floori(energia / 8.0), 100)
		Golpe.REFLEXOS:
			if pontos.size() == 2:
				for i in 2:
					leque(visual, pontos[i], pontos[i].direction_to(marca), 3 + (etapa - 1) * 2, 0.9 + i * 0.70, false, 120 + i * 12)
	if visual and exposto():
		var centro: Vector2 = boss.global_position
		for i in 4:
			var a := i * PI / 2 + tempo * 0.55
			draw_arc(centro, 76 + sin(tempo * 5) * 2, a, a + 0.68, 12, SEGURO, 3, true)


func desvio_anel(i: int) -> float:
	# Alterna o sentido após duas mudanças. O corredor inicial fica fora da mira.
	var passo := 3 - absi(2 - (i % 4))
	return passo * PASSO_ANGULAR * float(especial.sentido)


func livre(angulo: float, desvio: float, meia: float = MEIA_ABERTURA) -> bool:
	for abertura in lacunas:
		if absf(angle_difference(angulo, abertura + desvio)) <= meia:
			return true
	return false


func onda(visual: bool, partida: float, desvio: float, indice: int) -> void:
	var rotativo := aneis_rotativos()
	var centro: Vector2 = boss.global_position if rotativo else origem
	var alcance := float(especial.alcance) if rotativo else DISTANCIA_ONDA
	var inicial := 0.0 if rotativo else 45.0
	var velocidade := velocidade_anel() if rotativo else (alcance - inicial) / 2.4
	var idade := tempo - partida
	if idade < -antecedencia_anel() or (anterior - partida if not visual else idade) > (alcance - inicial) / velocidade:
		return
	var raio := clampf(inicial + maxf(0, idade) * velocidade, inicial, alcance)
	var larguras_de_nave := 3.2 if mare_da_segunda_fase() else 2.0 + (3 - etapa) * 0.6
	var meio_vao := larguras_de_nave * float(especial.raio_nave) if rotativo else 0.0
	var meia := asin(minf(meio_vao / maxf(raio, 1.0), 1.0)) if rotativo else MEIA_ABERTURA
	if visual:
		var cor := SOMBRA if tipo == Golpe.TOTALIDADE else LUA
		for i in lacunas.size():
			var eixo := lacunas[i] + desvio
			var proximo := lacunas[(i + 1) % lacunas.size()] + desvio
			if i == lacunas.size() - 1:
				proximo += TAU
			if raio > 1.0 and proximo - eixo > 2.0 * meia:
				var segmentos := maxi(3, ceili((proximo - eixo - 2.0 * meia) * raio / 9.0))
				draw_arc(centro, raio, eixo + meia, proximo - meia, segmentos, cor, 3.0, true)
			if idade < 0 and rotativo:
				var rumo := Vector2.from_angle(eixo)
				for lado in [-1.0, 1.0]:
					var borda: Vector2 = centro + rumo.orthogonal() * meio_vao * lado
					draw_dashed_line(borda, borda + rumo * alcance, Color(SEGURO, 0.48), 1.5, 12, true)
			else:
				for lado in [-1.0, 1.0]:
					var rumo := Vector2.from_angle(eixo + meia * lado)
					var ponta := centro + rumo * raio
					draw_circle(ponta, 2.5, SEGURO)
					if idade < 0:
						draw_dashed_line(ponta, centro + rumo * 460.0, Color(SEGURO, 0.43), 1.5, 12, true)
	elif idade >= 0:
		var raio_anterior := clampf(inicial + (anterior - partida) * velocidade, inicial, alcance)
		for p in pilotos:
			var v := p.global_position - centro
			var distancia := v.length()
			var margem := raio_piloto(p) + 1.5 if rotativo else 15.0
			if distancia < raio_anterior - margem or distancia > raio + margem:
				continue
			var passagem := MEIA_ABERTURA
			if rotativo:
				# Usa a largura real no ponto de travessia, descontando a borda da nave.
				passagem = asin(clampf((meio_vao - margem) / maxf(distancia, 1.0), 0.0, 1.0))
			if not livre(v.angle(), desvio, passagem):
				acerto(p, indice, 0.46, centro)


func trava_raio() -> float:
	return 1.25 if tipo == Golpe.TOTALIDADE else 1.65


func raio(visual: bool) -> void:
	var quantidade := etapa if tipo == Golpe.RAIO else 1
	for i in quantidade:
		var eixo := direcao.rotated((i - (quantidade - 1) * 0.5) * 0.23)
		desenhar_ou_aplicar_raio(visual, eixo)


func desenhar_ou_aplicar_raio(visual: bool, eixo: Vector2) -> void:
	var disparo := 2.55 - (etapa - 1) * 0.12
	var comprimento := Global.obter_retangulo_area_visivel().size.length() + 150
	var fim := origem + eixo * comprimento
	if visual and tempo <= disparo + 0.34:
		var normal := eixo.orthogonal() * 19.0
		if tempo < disparo:
			var cor := Color(SOL, 0.62) if tempo < trava_raio() else Color.WHITE
			draw_line(origem + normal, fim + normal, cor, 2, true)
			draw_line(origem - normal, fim - normal, cor, 2, true)
			draw_dashed_line(origem, fim, cor, 2, 14, true)
			draw_arc(origem + eixo * origem.distance_to(marca), 17, 0, TAU, 24, cor, 2, true)
		else:
			var alpha := 1.0 - smoothstep(disparo, disparo + 0.34, tempo)
			draw_line(origem, fim, Color(SOL, alpha * 0.55), 45, true)
			draw_line(origem, fim, Color(Color.WHITE, alpha), 13, true)
	elif not visual and anterior < disparo and tempo >= disparo:
		for p in pilotos:
			if Geometry2D.get_closest_point_to_segment(p.global_position, origem, fim).distance_to(p.global_position) <= 19:
				acerto(p, 4, 0.84 if tipo == Golpe.TOTALIDADE else 0.76, origem)


func meteoro(visual: bool, i: int) -> void:
	var queda := instante_impacto(i)
	var idade := tempo - queda
	if not visual:
		if anterior < queda and tempo >= queda:
			var raio: float = especial.raios[i]
			for p in pilotos:
				if p.global_position.distance_squared_to(pontos[i]) <= raio * raio:
					acerto(p, i, 0.48, pontos[i])
		return
	var aviso: float = especial.antecedencia
	if idade < -aviso or idade >= ONDA_IMPACTO:
		return
	var pos := pontos[i]
	var raio: float = especial.raios[i]
	var cor := LUA if boss.fase_atual == 1 else SOMBRA
	if idade < 0:
		var progresso := 1.0 + idade / aviso
		var pulso := 0.5 - 0.5 * cos(TAU * (progresso + progresso * progresso * 1.5))
		var metade := Vector2.ONE * (raio * 64.0 / 62.0)
		draw_texture_rect(ALVO_METEORO, Rect2(pos - metade, metade * 2), false, Color("#81d5ff").lerp(Color.WHITE, pulso))
		# O aviso aparece primeiro. A aproximação da sombra e a queda acelerada sinalizam o impacto.
		var inicio_queda := 0.36 + (etapa - 1) * 0.05
		var voo := smoothstep(inicio_queda, 1.0, progresso)
		draw_set_transform(pos, 0, Vector2(1, 0.5))
		draw_circle(Vector2.ZERO, raio * lerpf(0.18, 0.85, voo), Color(0.06, 0.045, 0.11, 0.15 + voo * 0.35))
		draw_set_transform_matrix(Transform2D.IDENTITY)
		if progresso < inicio_queda:
			return
		var vetor: Vector2 = especial.quedas[i]
		var pedra := pos + vetor * (1.0 - voo * voo)
		var tamanho := PerigoAstral.TEXTURA_METEORO.get_size() * lerpf(0.36, 0.72, voo) * (raio / 58.0)
		var lateral := vetor.normalized().orthogonal() * raio * 0.18
		var cauda := pedra + vetor * (0.09 + voo * 0.14)
		draw_colored_polygon(PackedVector2Array([pedra - lateral, cauda, pedra + lateral]), Color(cor, 0.15 + 0.20 * voo))
		draw_set_transform(pedra, progresso * 5.0 + i)
		draw_texture_rect(PerigoAstral.TEXTURA_METEORO, Rect2(-tamanho * 0.5, tamanho), false, Color(1.32, 1.32, 1.32))
		draw_set_transform_matrix(Transform2D.IDENTITY)
	else:
		var onda := idade / ONDA_IMPACTO
		draw_circle(pos, raio, Color(cor, 0.26 * (1.0 - onda)))
		draw_arc(pos, raio * lerpf(0.70, 1.0, onda), 0, TAU, 32, Color(cor, 1.0 - onda), 3.5, true)


func memoria(visual: bool) -> void:
	if not especial.has("poses"):
		return
	var instante := tempo - MATERIALIZACAO
	var pose := pose_em(instante)
	var pos := Vector2(pose.x, pose.y)
	var fim: float = especial.poses[-1].w
	if visual and is_instance_valid(clone) and clone.visible:
		var forca := 0.32 * CloneLunar.intensidade_aura() * clone.self_modulate.a
		var tamanho := 84.0 * clone.scale.x
		draw_texture_rect(CloneLunar.HALO, Rect2(pos - Vector2.ONE * tamanho * 0.5, Vector2.ONE * tamanho), false, Color(clone.cor_aura, forca))
	if visual and instante < 0:
		var carga := smoothstep(0.0, MATERIALIZACAO, tempo)
		var fase := tempo * 3.0
		var brilho := sin(PI * carga)
		for lado in [0.0, PI]:
			var arco: float = fase + lado
			draw_arc(origem, 64.0 + carga * 8.0, arco, arco + 0.9, 18, Color(LUA, brilho), 2, true)
			draw_arc(pos, lerpf(33, 16, carga), -arco, -arco + 1.7, 20, Color(SOMBRA, brilho), 2, true)
	elif not visual and instante >= 0 and instante <= fim:
		for p in pilotos:
			if p.global_position.distance_squared_to(pos) <= 18.0 * 18.0:
				acerto(p, 6, 0.30, pos)
	for i in especial.tiros.size():
		var disparo: float = especial.tiros[i]
		var idade := instante - disparo
		if idade < 0 or idade > VIDA_DARDO:
			continue
		var emissao := pose_em(disparo)
		var rumo := Vector2.from_angle(emissao.z)
		var boca: Vector2 = especial.get("modelo", {}).get("boca", Vector2(16, 0))
		var origem_tiro := Vector2(emissao.x, emissao.y) + boca.rotated(emissao.z)
		var velocidade := VELOCIDADE_DARDO + (etapa - 1) * 25.0
		for lado in etapa:
			var angulo: float = [0.0, 0.22, -0.22][lado]
			var rumo_tiro := rumo.rotated(angulo if i % 2 == 0 else -angulo)
			var ponta := origem_tiro + rumo_tiro * idade * velocidade
			if visual:
				draw_set_transform(ponta, rumo_tiro.angle())
				draw_texture_rect(CloneLunar.HALO, Rect2(-18,-8,36,16), false, Color(cor_tiro, 0.35 * CloneLunar.intensidade_aura()))
				draw_colored_polygon(forma_tiro, Color(cor_tiro.r * 1.4, cor_tiro.g * 1.4, cor_tiro.b * 1.4))
				draw_set_transform_matrix(Transform2D.IDENTITY)
				if idade < 0.075:
					draw_circle(origem_tiro, 5 * (1 - idade / 0.075), cor_tiro)
			else:
				var cauda := ponta - rumo_tiro * minf(idade, tempo - anterior) * velocidade
				for p in pilotos:
					var perto := Geometry2D.get_closest_point_to_segment(p.global_position, cauda, ponta) if cauda != ponta else ponta
					if perto.distance_squared_to(p.global_position) <= 11.0 * 11.0:
						acerto(p, 200 + i + lado * 64, 0.26, ponta)


func clarao(visual: bool) -> void:
	if visual and tempo <= 5.35:
		for abrigo in abrigos:
			draw_circle(abrigo, 82, Color(SEGURO, 0.12))
			draw_arc(abrigo, 82, 0, TAU, 64, SEGURO, 3, true)
			draw_arc(abrigo, 82 + 16 * (1.0 - clampf(tempo / 5.1, 0, 1)), 0, TAU, 60, Color(SEGURO, 0.60), 2, true)
		if tempo >= 5.10:
			var area := Global.obter_retangulo_area_visivel()
			draw_rect(area, Color(0.98, 0.80, 0.95, 0.48 * (1.0 - (tempo - 5.1) / 0.25)))
	elif not visual and anterior < 5.1 and tempo >= 5.1:
		for p in pilotos:
			if not protegido(p.global_position, 82):
				acerto(p, 7, 1.35, origem)


func investida() -> void:
	var pos: Vector2 = boss.global_position
	if tempo < 0.95:
		var normal := direcao.orthogonal() * 62.0
		for lado in [-1, 1]:
			var borda: Vector2 = origem + normal * lado
			var area := Global.obter_retangulo_area_visivel()
			var fim: Vector2 = (origem + direcao * boss.velocidade_investida() * 0.82).clamp(area.position, area.end)
			draw_dashed_line(borda, fim + normal * lado, Color("#ff794c"), 2, 12, true)
		for i in 5:
			var ponta := origem + direcao * (90 + i * 72 + fmod(tempo * 65, 32))
			draw_polyline(PackedVector2Array([ponta - direcao * 10 + normal * 0.13, ponta, ponta - direcao * 10 - normal * 0.13]), SOL, 2, true)
	elif tempo < 1.77:
		draw_colored_polygon(PackedVector2Array([pos + direcao.orthogonal()*22, pos-direcao*100, pos-direcao.orthogonal()*22]), Color(SOL, 0.40))


func leque(visual: bool, centro: Vector2, eixo: Vector2, n: int, partida: float, retorna: bool, indice: int) -> void:
	var idade := tempo - partida
	if idade < 0:
		if visual:
			if tipo == Golpe.REFLEXOS:
				var textura: Texture2D = boss.TEXTURA_SOL if indice >= 125 else boss.TEXTURA_LUA
				var tamanho := Vector2.ONE * 52
				draw_texture_rect(textura, Rect2(centro - tamanho * 0.5, tamanho), false, Color(1,1,1,0.68))
			var meia_mira := (n - 1) * 0.13 + 0.12
			draw_arc(centro, 32, eixo.angle() - meia_mira, eixo.angle() + meia_mira, 20, SOL if indice >= 125 else LUA, 4, true)
		return
	var velocidade := (300.0 if tipo in [Golpe.RETORNO, Golpe.REFLEXOS] else 260.0) + (etapa - 1) * 45.0
	var distancia := idade * velocidade
	if retorna:
		distancia = 360.0 - absf(360.0 - distancia)
	if distancia < 0:
		return
	for i in n:
		var rumo := eixo.rotated((float(i) - (n - 1) * 0.5) * 0.26)
		var pos := centro + rumo * distancia
		if visual:
			var cor := SOL if retorna else (SOMBRA if tipo == Golpe.REFLEXOS else LUA)
			draw_arc(pos, 11, rumo.angle()-1.35, rumo.angle()+1.35, 12, cor, 4, true)
			if retorna and absf(idade * velocidade - 360) < 32:
				draw_arc(pos, 17, 0, TAU, 14, Color.WHITE, 2, true)
		else:
			for p in pilotos:
				if p.global_position.distance_to(pos) <= 15:
					acerto(p, indice + i, 0.34, pos)


func erupcao(visual: bool, centro: Vector2, partida: float, n: int, indice: int) -> void:
	var idade := tempo - partida
	for i in n:
		var rumo := Vector2.from_angle(i * TAU / n)
		var pos := centro + rumo * (20 + maxf(0, idade) * (235.0 + (etapa - 1) * 40.0))
		if visual:
			if idade < 0:
				draw_line(pos, pos + rumo * 28, Color(SOL, 0.58), 2, true)
			else:
				draw_line(pos - rumo * 12, pos, SOL, 4, true)
				draw_circle(pos, 3, Color.WHITE)
		elif idade >= 0:
			for p in pilotos:
				if p.global_position.distance_to(pos) <= 14:
					acerto(p, indice + i, 0.30, pos)
