extends Node2D
class_name SizigiaFinalController

## O mesmo relógio e a mesma geometria alimentam o desenho e os acertos.
## O host publica a partitura atual, inclusive para quem chega durante um golpe.
enum Golpe { NENHUM, CRESCENTES, MARE, CRATERAS, SOMBRA, INVESTIDA, RAIO, MANCHAS, ROUBO, RETORNO, REFLEXOS, TOTALIDADE, ABSOLUTO }

const LUA := Color("#a5d8ff")
const SOL := Color("#ffb24c")
const SOMBRA := Color("#d299ff")
const SEGURO := Color("#80ffcc")
const ROTA_LUA := [Golpe.CRESCENTES, Golpe.MARE, Golpe.CRATERAS, Golpe.SOMBRA]
const ROTA_SOL := [Golpe.INVESTIDA, Golpe.MANCHAS, Golpe.RAIO, Golpe.INVESTIDA, Golpe.ROUBO]
const ROTA_ECLIPSE := [Golpe.TOTALIDADE, Golpe.RETORNO, Golpe.REFLEXOS, Golpe.CRATERAS]
const DURACOES := [0.0, 3.3, 5.6, 3.9, 3.5, 2.85, 3.65, 5.6, 4.8, 4.1, 4.3, 7.7, 7.6]
const NOMES := [
	"",
	"CRESCENTES LUNARES — ATRAVESSE AS ABERTURAS",
	"MARÉ LUNAR — SIGA AS BALIZAS VERDES",
	"CHUVA DE CRATERAS — SAIA DOS ALVOS MARCADOS",
	"SOMBRA DO PASSADO — DEIXE SEU RASTRO PARA TRÁS",
	"INVESTIDA SOLAR — SAIA DA LINHA VERMELHA",
	"RAIO SOLAR — A MIRA TRAVA ANTES DO DISPARO",
	"MANCHAS SOLARES — DESTRUA-AS ANTES DA EXPLOSÃO",
	"ROUBO DE LUZ — CESSE FOGO ENQUANTO O HALO CARREGA",
	"CRESCENTES INCENDIÁRIOS — ELES RETORNAM",
	"REFLEXOS ASTRAIS — ATAQUE VINDO DOS DOIS LADOS",
	"TOTALIDADE — ATRAIA O RAIO E CRUZE A PASSAGEM",
	"ECLIPSE ABSOLUTO — SIGA A SOMBRA ATÉ O ABRIGO",
]

const MEIA_ABERTURA := 0.38
const DISTANCIA_ONDA := 960.0

var tipo := Golpe.NENHUM
var tempo := 0.0
var origem := Vector2.ZERO
var direcao := Vector2.RIGHT
var alvo_id := 1
var marca := Vector2.ZERO
var pontos := PackedVector2Array()
var abrigos := PackedVector2Array()
var lacunas := PackedFloat32Array()
var historicos := {}
var amostra := 0.0
var energia := 0.0
var mascara_orbes := 0
var serie := 0
var investida_dupla := false
var som_emitido := false
var impactos := {}
var anterior := 0.0
var pilotos: Array[Node2D] = []
var orbes: Array[OrbeAstral] = []
@onready var boss = get_parent()


func _ready() -> void:
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
	amostra -= delta
	if amostra > 0:
		return
	amostra = 0.1
	var presentes := {}
	for p in pilotos_vivos():
		var id := p.get_instance_id()
		presentes[id] = true
		var rastro: PackedVector2Array = historicos.get(id, PackedVector2Array())
		if not rastro.is_empty() and rastro[-1].distance_to(p.global_position) > 90.0:
			rastro.clear()
		rastro.append(p.global_position)
		if rastro.size() > 30:
			rastro.remove_at(0)
		historicos[id] = rastro
	for id in historicos.keys():
		if not presentes.has(id):
			historicos.erase(id)


func escolher() -> void:
	var rota: Array = ROTA_LUA
	if boss.fase_atual == 2:
		rota = ROTA_SOL
	elif boss.fase_atual == 3:
		rota = ROTA_ECLIPSE
		if not boss.absoluto_usado and boss.Vida <= boss.VidaMaxima * 0.35:
			boss.absoluto_usado = true
			iniciar(Golpe.ABSOLUTO)
			return
	var escolha: int = rota[boss.passo_rotacao % rota.size()]
	boss.passo_rotacao += 1
	iniciar(escolha)


func iniciar(escolha: int) -> void:
	pilotos = pilotos_vivos()
	if pilotos.is_empty():
		return
	encerrar()
	serie += 1
	tipo = escolha as Golpe
	var alvo := pilotos[(serie - 1) % pilotos.size()]
	alvo_id = alvo.get_multiplayer_authority()
	origem = boss.global_position
	marca = alvo.global_position
	direcao = origem.direction_to(marca)
	if direcao.is_zero_approx():
		direcao = Vector2.RIGHT
	boss.direcao_investida = direcao
	investida_dupla = tipo == Golpe.INVESTIDA and boss.passo_rotacao >= 4
	var area := Global.obter_retangulo_area_visivel()
	for p in pilotos:
		var angulo := origem.angle_to_point(p.global_position)
		if tipo == Golpe.TOTALIDADE:
			lacunas.append(angulo - 0.43)
			lacunas.append(angulo + 0.43)
		else:
			lacunas.append(angulo)
		if tipo == Golpe.ABSOLUTO:
			var abrigo := p.global_position.move_toward(area.get_center(), 108.0)
			if not protegido(abrigo, 60.0):
				abrigos.append(abrigo)
	if tipo in [Golpe.SOMBRA, Golpe.ABSOLUTO]:
		pontos = historicos.get(alvo.get_instance_id(), PackedVector2Array([marca])).duplicate()
	if tipo == Golpe.REFLEXOS:
		pontos = PackedVector2Array([area.position + area.size * Vector2(0.20, 0.27), area.position + area.size * Vector2(0.80, 0.73)])
	if tipo == Golpe.CRATERAS:
		pontos.append(marca)
	if tipo == Golpe.MANCHAS:
		mascara_orbes = 7
		criar_orbes()
	boss.subtitulo_alterado.emit(tr(NOMES[tipo]))
	queue_redraw()


func snapshot() -> Array:
	return [serie, tipo, tempo, origem, direcao, alvo_id, marca, pontos, abrigos, lacunas, energia, mascara_orbes, investida_dupla]


func receber(s: Array) -> void:
	if s.size() != 13 or int(s[0]) < serie:
		return
	var nova := int(s[0]) != serie or int(s[1]) != tipo
	if nova:
		encerrar()
	serie = s[0]
	tipo = int(s[1]) as Golpe
	tempo = s[2]
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
	if nova and tipo != Golpe.NENHUM:
		boss.subtitulo_alterado.emit(tr(NOMES[tipo]))
		if tipo == Golpe.MANCHAS:
			criar_orbes()
	atualizar_orbes()
	set_process(tipo != Golpe.NENHUM)
	queue_redraw()


func _process(delta: float) -> void:
	# Interpola entre as amostras completas do servidor. Somente ele resolve dano.
	tempo = minf(tempo + delta, DURACOES[tipo])
	feedback_local(delta)
	atualizar_orbes()
	queue_redraw()


func avancar(delta: float) -> void:
	anterior = tempo
	tempo += delta
	pilotos = pilotos_vivos()
	feedback_local(delta)
	if tipo in [Golpe.RAIO, Golpe.TOTALIDADE] and tempo < trava_raio():
		for p in pilotos:
			if p.get_multiplayer_authority() == alvo_id:
				marca = p.global_position
				direcao = origem.direction_to(marca)
				break
	if tipo == Golpe.CRATERAS and pontos.size() < 3 and tempo >= pontos.size() * 0.52:
		for p in pilotos:
			if p.get_multiplayer_authority() == alvo_id:
				marca = p.global_position
		pontos.append(marca)
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
	if tempo >= DURACOES[tipo]:
		encerrar()
		boss.estado = boss.Estado.MOVENDO
		boss.subtitulo_alterado.emit(boss.obter_subtitulo_boss())
		boss.tempo_ataque = 0.60 if boss.fase_atual == 3 and boss.Vida < boss.VidaMaxima * 0.25 else 1.05
	queue_redraw()


func encerrar() -> void:
	tipo = Golpe.NENHUM
	tempo = 0.0
	anterior = 0.0
	som_emitido = false
	energia = 0.0
	pontos = PackedVector2Array()
	abrigos = PackedVector2Array()
	lacunas = PackedFloat32Array()
	impactos.clear()
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
	if gravidade_ativa():
		for p in pilotos_vivos():
			if p is Player and (not Rede.modo_multiplayer or p.is_multiplayer_authority()):
				p.velocity += p.global_position.direction_to(origem) * 65.0 * delta
	var instante := -1.0
	if tipo == Golpe.INVESTIDA:
		instante = 0.95
	elif tipo in [Golpe.RAIO, Golpe.TOTALIDADE]:
		instante = trava_raio()
	elif tipo == Golpe.ABSOLUTO:
		instante = 5.1
	if instante >= 0 and tempo >= instante and not som_emitido:
		som_emitido = true
		var som := &"explosoes" if tipo == Golpe.ABSOLUTO else &"investida"
		preload("res://Scripts/AudioCombate.gd").tocar(self, som, 0.0, 0.90, 0.90, -12.0)
		Global.vibrar_controle(0.25, 0.40, 0.10)


func absorvendo() -> bool:
	return tipo == Golpe.ROUBO and tempo < 2.15


func exposto() -> bool:
	match tipo:
		Golpe.TOTALIDADE: return tempo >= 5.5
		Golpe.ABSOLUTO: return tempo >= 5.4
		Golpe.INVESTIDA: return tempo >= 1.77
	return false


func protegido(pos: Vector2, raio: float) -> bool:
	for abrigo in abrigos:
		if pos.distance_to(abrigo) <= raio:
			return true
	return false


func ferir(p: Node2D, dano: float, fonte: Vector2) -> void:
	if p.has_method("tomar_dano"):
		p.tomar_dano(dano, fonte)


func acerto(p: Node2D, indice: int, fator: float, fonte: Vector2) -> void:
	var chave := Vector2i(indice, p.get_multiplayer_authority())
	if impactos.has(chave):
		return
	impactos[chave] = true
	ferir(p, boss.Dano * fator, fonte)
	if tipo in [Golpe.RETORNO, Golpe.RAIO] and p.has_method("aplicar_queimadura"):
		p.aplicar_queimadura(boss.Dano * 0.18, 2.4)


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
			leque(visual, origem, direcao, 4, 0.72, tipo == Golpe.RETORNO, 10)
		Golpe.MARE:
			onda(visual, 1.25, 0.0, 0)
			onda(visual, 2.70, 0.16, 1)
		Golpe.CRATERAS:
			for i in pontos.size():
				cratera(visual, i)
		Golpe.SOMBRA, Golpe.ABSOLUTO:
			memoria(visual)
			if tipo == Golpe.ABSOLUTO:
				clarao(visual)
		Golpe.INVESTIDA:
			if visual:
				investida()
			if investida_dupla and tempo >= 0.95 and tempo < 1.77:
				for lado in [-1, 1]:
					var rumo := direcao.rotated(lado * (0.45 + (tempo - 0.95) * 0.45))
					var pos := origem + rumo * (tempo - 0.95) * 465
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
					erupcao(visual, pos_orbe(i, tempo), 3.2, 8, 50 + i * 10)
		Golpe.ROUBO:
			if visual and tempo < 2.15:
				draw_arc(origem, 80, -PI / 2, 1.5 * PI, 64, Color(SOL, 0.45), 3, true)
				draw_arc(origem, 80, -PI / 2, -PI / 2 + TAU * energia / 40.0, 48, SOL, 7, true)
			erupcao(visual, origem, 2.45, 5 + floori(energia / 8.0), 100)
		Golpe.REFLEXOS:
			if pontos.size() == 2:
				for i in 2:
					leque(visual, pontos[i], pontos[i].direction_to(marca), 3, 0.9 + i * 0.70, false, 120 + i * 5)
		Golpe.TOTALIDADE:
			onda(visual, 2.8, 0.0, 2)
			raio(visual)
	if visual and exposto():
		var centro: Vector2 = boss.global_position
		for i in 4:
			var a := i * PI / 2 + tempo * 0.55
			draw_arc(centro, 76 + sin(tempo * 5) * 2, a, a + 0.68, 12, SEGURO, 3, true)


func livre(angulo: float, desvio: float) -> bool:
	for abertura in lacunas:
		if absf(angle_difference(angulo, abertura + desvio)) <= MEIA_ABERTURA:
			return true
	return false


func onda(visual: bool, partida: float, desvio: float, indice: int) -> void:
	var idade := tempo - partida
	if idade > 2.4 or (indice == 1 and idade < -1.1):
		return
	var raio_atual := lerpf(45, DISTANCIA_ONDA, clampf(idade / 2.4, 0, 1))
	if visual:
		var cor := SOMBRA if tipo == Golpe.TOTALIDADE else LUA
		var arco := PackedVector2Array()
		for i in 145:
			var a := TAU * i / 144.0
			if livre(a, desvio):
				if arco.size() > 1:
					draw_polyline(arco, cor, 3.5, true)
				arco.clear()
			else:
				arco.append(origem + Vector2.from_angle(a) * raio_atual)
		if arco.size() > 1:
			draw_polyline(arco, cor, 3.5, true)
		for abertura in lacunas:
			for lado in [-1, 1]:
				var eixo := Vector2.from_angle(abertura + desvio + MEIA_ABERTURA * lado)
				var ponta := origem + eixo * raio_atual
				draw_circle(ponta, 4, SEGURO)
				if idade < 0:
					draw_dashed_line(ponta, origem + eixo * 460.0, Color(SEGURO, 0.43), 1.5, 12, true)
	elif idade >= 0:
		for p in pilotos:
			var v := p.global_position - origem
			if absf(v.length() - raio_atual) <= 15 and not livre(v.angle(), desvio):
				acerto(p, indice, 0.46, origem)


func trava_raio() -> float:
	return 1.25 if tipo == Golpe.TOTALIDADE else 1.65


func raio(visual: bool) -> void:
	var disparo := 2.55
	var comprimento := Global.obter_retangulo_area_visivel().size.length() + 150
	var fim := origem + direcao * comprimento
	if visual and tempo <= disparo + 0.34:
		var normal := direcao.orthogonal() * 19.0
		if tempo < disparo:
			var cor := Color(SOL, 0.62) if tempo < trava_raio() else Color.WHITE
			draw_line(origem + normal, fim + normal, cor, 2, true)
			draw_line(origem - normal, fim - normal, cor, 2, true)
			draw_dashed_line(origem, fim, cor, 2, 14, true)
			draw_arc(marca, 17, 0, TAU, 24, cor, 2, true)
		else:
			var alpha := 1.0 - smoothstep(disparo, disparo + 0.34, tempo)
			draw_line(origem, fim, Color(SOL, alpha * 0.55), 45, true)
			draw_line(origem, fim, Color(Color.WHITE, alpha), 13, true)
	elif not visual and anterior < disparo and tempo >= disparo:
		for p in pilotos:
			if Geometry2D.get_closest_point_to_segment(p.global_position, origem, fim).distance_to(p.global_position) <= 19:
				acerto(p, 4, 0.84 if tipo == Golpe.TOTALIDADE else 0.76, origem)


func cratera(visual: bool, i: int) -> void:
	var idade := tempo - (1.55 + i * 0.52)
	var pos := pontos[i]
	if visual and idade < 0.42:
		if idade < 0:
			draw_circle(pos, 48, Color(LUA, 0.09))
			draw_arc(pos, 48, 0, TAU, 48, LUA, 2, true)
			draw_arc(pos, 48, -PI/2, -PI/2 + TAU * clampf(1 + idade / 1.55, 0, 1), 48, Color.WHITE, 4, true)
			draw_line(pos + Vector2(-26,-70) * -idade, pos + Vector2(-12,-32) * -idade, LUA, 4, true)
		else:
			draw_arc(pos, 48 + idade * 75, 0, TAU, 48, Color(LUA, 1 - idade / 0.42), 5, true)
	elif not visual and idade >= 0 and idade < 0.24:
		for p in pilotos:
			if p.global_position.distance_to(pos) <= 48:
				acerto(p, i, 0.48, pos)


func memoria(visual: bool) -> void:
	if pontos.is_empty() or tempo > 2.90:
		return
	var passo := clampf((tempo - 1.15) / 1.65, 0, 1) * (pontos.size() - 1)
	var i := floori(passo)
	var pos := pontos[i].lerp(pontos[mini(i + 1, pontos.size() - 1)], passo - i)
	if visual:
		if pontos.size() > 1:
			draw_polyline(pontos, Color(SOMBRA, 0.36), 4, true)
		draw_arc(pos, 22, tempo, TAU + tempo - 0.45, 24, SOMBRA, 3, true)
		draw_circle(pos, 12, Color(SOMBRA, 0.45))
	elif tempo >= 1.15:
		for p in pilotos:
			if p.global_position.distance_to(pos) < 24:
				acerto(p, 6, 0.30, pos)


func clarao(visual: bool) -> void:
	if visual and tempo <= 5.35:
		for abrigo in abrigos:
			draw_circle(abrigo, 82, Color(SEGURO, 0.12))
			draw_arc(abrigo, 82, 0, TAU, 64, SEGURO, 3, true)
			draw_arc(abrigo, 82 + 16 * (1.0 - clampf(tempo / 5.1, 0, 1)), 0, TAU, 60, Color(SEGURO, 0.60), 2, true)
			if not pontos.is_empty():
				draw_dashed_line(pontos[-1], abrigo, Color(SEGURO, 0.55), 2, 14, true)
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
			var fim := (origem + direcao * 460).clamp(area.position, area.end)
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
			draw_arc(centro, 32, eixo.angle()-0.64, eixo.angle()+0.64, 20, SOL if indice >= 125 else LUA, 4, true)
		return
	var distancia := idade * 260.0
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
			if retorna and absf(idade * 260.0 - 360) < 32:
				draw_arc(pos, 17, 0, TAU, 14, Color.WHITE, 2, true)
		else:
			for p in pilotos:
				if p.global_position.distance_to(pos) <= 15:
					acerto(p, indice + i, 0.34, pos)


func erupcao(visual: bool, centro: Vector2, partida: float, n: int, indice: int) -> void:
	var idade := tempo - partida
	for i in n:
		var rumo := Vector2.from_angle(i * TAU / n)
		var pos := centro + rumo * (20 + maxf(0, idade) * 210)
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
