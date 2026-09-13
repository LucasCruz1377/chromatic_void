extends Node2D
class_name RastroExclusivo


const CORES_ARCO_IRIS := [
	Color("ff4f68"), Color("ffb83f"), Color("fff45a"),
	Color("58f58b"), Color("42dfff"), Color("7280ff"), Color("db59ff"),
]
const DISTANCIA_MAXIMA_ENTRE_AMOSTRAS := 110.0

var alvo: Node2D
var tipo: StringName = &""
var cor_base := Color.WHITE
var ativo := false
var pontos: Array[Dictionary] = []
var acumulador := 0.0
var duracao := 0.9
var linhas_spectrum: Array[Line2D] = []


func configurar(novo_alvo: Node2D, novo_tipo: StringName, nova_cor: Color) -> void:
	if tipo != novo_tipo:
		pontos.clear()
	alvo = novo_alvo
	tipo = novo_tipo
	cor_base = nova_cor
	duracao = 1.15 if tipo == &"fspeed" else 0.82
	set_as_top_level(true)
	global_position = Vector2.ZERO
	z_index = 2
	process_mode = Node.PROCESS_MODE_ALWAYS
	_preparar_linhas_spectrum()


func definir_estado(novo_ativo: bool, nova_cor: Color) -> void:
	var ativou_agora := novo_ativo and not ativo
	ativo = novo_ativo
	cor_base = nova_cor
	if novo_ativo:
		set_process(true)
	if ativou_agora:
		# Garante a primeira amostra imediatamente após acelerar.
		acumulador = maxf(acumulador, 0.035)


func _process(delta: float) -> void:
	if not is_instance_valid(alvo):
		queue_free()
		return
	if not ativo and pontos.is_empty():
		for linha in linhas_spectrum:
			linha.visible = false
		set_process(false)
		return
	for ponto in pontos:
		ponto["idade"] = float(ponto.get("idade", 0.0)) + delta
	while not pontos.is_empty() and float(pontos[0].get("idade", 0.0)) > duracao:
		pontos.pop_front()
	acumulador += delta
	if ativo and alvo.visible and acumulador >= 0.035:
		acumulador = 0.0
		var origem := alvo.global_position - Vector2(25.0, 0.0).rotated(alvo.global_rotation)
		if (
			not pontos.is_empty()
			and Vector2(pontos.back()["posicao"]).distance_to(origem)
			> DISTANCIA_MAXIMA_ENTRE_AMOSTRAS
		):
			# O wrap transporta a nave para o lado oposto da arena. A Line2D
			# não pode ligar as duas bordas, portanto inicia um trecho novo.
			_interromper_tracado()
		if pontos.is_empty() or Vector2(pontos.back()["posicao"]).distance_to(origem) >= 3.0:
			pontos.append({"posicao": origem, "idade": 0.0})
			if pontos.size() > 42:
				pontos.pop_front()
	_atualizar_linhas_spectrum()
	queue_redraw()


func _interromper_tracado() -> void:
	pontos.clear()
	acumulador = 0.0
	for linha in linhas_spectrum:
		linha.clear_points()
		linha.visible = false
	queue_redraw()


func _draw() -> void:
	if pontos.size() < 2:
		return
	# O Spectrum é desenhado por Line2D para manter o gradiente contínuo e
	# reduzir a opacidade suavemente até o final do rastro.
	if tipo == &"spectrum":
		return
	for indice in range(1, pontos.size()):
		var anterior := Vector2(pontos[indice - 1]["posicao"])
		var atual := Vector2(pontos[indice]["posicao"])
		if anterior.distance_to(atual) > 110.0:
			continue
		var idade := float(pontos[indice]["idade"])
		var alpha := clampf(1.0 - idade / duracao, 0.0, 1.0)
		var direcao := (atual - anterior).normalized()
		var normal := Vector2(-direcao.y, direcao.x)
		if indice % 3 == 0:
			continue
		var marca := cor_base.darkened(0.62)
		marca.a = alpha * 0.78
		for lado in [-1.0, 1.0]:
			draw_line(anterior + normal * 8.0 * lado, atual + normal * 8.0 * lado, marca, 4.2, true)


func _preparar_linhas_spectrum() -> void:
	if linhas_spectrum.is_empty():
		for indice in CORES_ARCO_IRIS.size():
			var linha := Line2D.new()
			linha.name = "FaixaSpectrum%d" % indice
			linha.width = 3.2
			linha.antialiased = true
			linha.begin_cap_mode = Line2D.LINE_CAP_ROUND
			linha.end_cap_mode = Line2D.LINE_CAP_ROUND
			add_child(linha)
			linhas_spectrum.append(linha)
	for indice in linhas_spectrum.size():
		var linha := linhas_spectrum[indice]
		var cor: Color = CORES_ARCO_IRIS[indice]
		var gradiente := Gradient.new()
		gradiente.set_color(0, Color(cor.r, cor.g, cor.b, 0.0))
		gradiente.set_color(1, Color(cor.r, cor.g, cor.b, 0.90))
		linha.gradient = gradiente
		linha.visible = tipo == &"spectrum"


func _atualizar_linhas_spectrum() -> void:
	if linhas_spectrum.is_empty():
		return
	var visivel := tipo == &"spectrum" and ativo and pontos.size() >= 2
	for linha in linhas_spectrum:
		linha.visible = visivel
	if not visivel:
		return
	for faixa in linhas_spectrum.size():
		var vertices := PackedVector2Array()
		for indice in pontos.size():
			var atual := Vector2(pontos[indice]["posicao"])
			var direcao := Vector2.RIGHT
			if indice > 0:
				direcao = Vector2(pontos[indice - 1]["posicao"]).direction_to(atual)
			elif pontos.size() > 1:
				direcao = atual.direction_to(Vector2(pontos[1]["posicao"]))
			var normal := Vector2(-direcao.y, direcao.x)
			var deslocamento := (float(faixa) - 3.0) * 2.25
			vertices.append(atual + normal * deslocamento)
		linhas_spectrum[faixa].points = vertices
