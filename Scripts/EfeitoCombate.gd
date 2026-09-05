extends Node2D
class_name EfeitoCombate


enum Tipo {
	ACERTO,
	MORTE,
	DANO_PLAYER,
	AVISO,
	RASTRO,
}

var tipo := Tipo.ACERTO
var cor := Color.WHITE
var intensidade := 1.0
var duracao := 0.22
var tempo := 0.0
var direcao := Vector2.RIGHT
var semente := 0


static func criar(
	pai: Node,
	posicao_global: Vector2,
	tipo_efeito: Tipo,
	cor_efeito: Color,
	intensidade_efeito := 1.0,
	direcao_efeito := Vector2.RIGHT
) -> EfeitoCombate:
	if not is_instance_valid(pai):
		return null
	var efeito := EfeitoCombate.new()
	efeito.tipo = tipo_efeito
	efeito.cor = cor_efeito
	efeito.intensidade = maxf(intensidade_efeito, 0.2)
	efeito.direcao = direcao_efeito.normalized()
	efeito.semente = randi()
	match tipo_efeito:
		Tipo.MORTE:
			efeito.duracao = 0.42
		Tipo.DANO_PLAYER:
			efeito.duracao = 0.38
		Tipo.AVISO:
			efeito.duracao = 0.46
		Tipo.RASTRO:
			efeito.duracao = 0.20
		_:
			efeito.duracao = 0.20
	pai.add_child(efeito)
	efeito.global_position = posicao_global
	efeito.z_index = 20
	return efeito


func _process(delta: float) -> void:
	tempo += delta
	queue_redraw()
	if tempo >= duracao:
		queue_free()


func _draw() -> void:
	var progresso := clampf(tempo / maxf(duracao, 0.01), 0.0, 1.0)
	var alpha := 1.0 - progresso
	var cor_atual := Color(cor.r, cor.g, cor.b, cor.a * alpha)
	match tipo:
		Tipo.ACERTO:
			desenhar_acerto(progresso, cor_atual)
		Tipo.MORTE:
			desenhar_morte(progresso, cor_atual)
		Tipo.DANO_PLAYER:
			desenhar_dano_player(progresso, cor_atual)
		Tipo.AVISO:
			desenhar_aviso(progresso, cor_atual)
		Tipo.RASTRO:
			desenhar_rastro(progresso, cor_atual)


func desenhar_acerto(progresso: float, cor_atual: Color) -> void:
	var abertura := lerpf(2.0, 22.0, progresso) * intensidade
	var base := float(semente % 31) * 0.11
	for indice in 4:
		var angulo := base + float(indice) * TAU / 4.0 + sin(float(indice) * 7.3) * 0.24
		var vetor := Vector2.from_angle(angulo)
		var inicio := vetor * abertura * 0.28
		var fim := vetor * abertura
		draw_line(inicio, fim, cor_atual, lerpf(2.8, 1.1, progresso), true)
		var lasca := fim - vetor * 4.0 * intensidade
		draw_line(lasca, lasca + vetor.orthogonal() * 3.0 * intensidade, cor_atual, 1.2, true)
	if progresso < 0.45:
		var brilho := (1.0 - progresso / 0.45) * 5.0 * intensidade
		draw_colored_polygon(PackedVector2Array([
			Vector2(brilho, 0.0), Vector2(0.0, brilho * 0.55),
			Vector2(-brilho, 0.0), Vector2(0.0, -brilho * 0.55),
		]), cor_atual)


func desenhar_morte(progresso: float, cor_atual: Color) -> void:
	var raio := lerpf(7.0, 42.0, progresso) * intensidade
	var pontos := PackedVector2Array()
	var pontas := 14
	for indice in pontas:
		var angulo := float(indice) * TAU / float(pontas) + float(semente % 13) * 0.04
		var alternancia := 1.0 if indice % 2 == 0 else 0.48
		pontos.append(Vector2.from_angle(angulo) * raio * alternancia)
	draw_colored_polygon(pontos, Color(cor_atual.r, cor_atual.g, cor_atual.b, cor_atual.a * 0.22))
	for indice in 8:
		var angulo := float(indice) * TAU / 8.0 + float(semente % 19) * 0.07
		var vetor := Vector2.from_angle(angulo)
		var centro := vetor * raio * lerpf(0.45, 1.12, progresso)
		var tamanho := (4.5 - progresso * 2.8) * intensidade
		draw_colored_polygon(PackedVector2Array([
			centro + vetor * tamanho,
			centro + vetor.orthogonal() * tamanho * 0.55,
			centro - vetor * tamanho * 0.65,
			centro - vetor.orthogonal() * tamanho * 0.55,
		]), cor_atual)


func desenhar_dano_player(progresso: float, cor_atual: Color) -> void:
	var distancia := lerpf(12.0, 48.0, progresso) * intensidade
	for indice in 6:
		var angulo := float(indice) * TAU / 6.0 + 0.28
		var vetor := Vector2.from_angle(angulo)
		var centro := vetor * distancia
		draw_line(centro - vetor * 10.0, centro + vetor * 5.0, cor_atual, 3.2, true)


func desenhar_aviso(progresso: float, cor_atual: Color) -> void:
	var alcance := lerpf(8.0, 35.0, progresso) * intensidade
	var lateral := direcao.orthogonal()
	for lado in [-1.0, 1.0]:
		var lado_float := float(lado)
		var centro: Vector2 = direcao * alcance * 0.35 + lateral * lado_float * alcance * 0.38
		draw_line(centro - direcao * 7.0, centro + direcao * 5.0 - lateral * lado_float * 5.0, cor_atual, 2.2, true)
		draw_line(centro - direcao * 7.0, centro + direcao * 5.0 + lateral * lado_float * 5.0, cor_atual, 2.2, true)


func desenhar_rastro(progresso: float, cor_atual: Color) -> void:
	var comprimento := 44.0 * intensidade * (1.0 - progresso * 0.35)
	var largura := 8.0 * intensidade * (1.0 - progresso)
	var traseira := -direcao * comprimento
	var lateral := direcao.orthogonal() * largura
	var pontos := PackedVector2Array([
		lateral,
		traseira,
		-lateral,
	])
	draw_colored_polygon(pontos, Color(cor_atual.r, cor_atual.g, cor_atual.b, cor_atual.a * 0.42))
	draw_line(lateral, traseira, cor_atual, 1.4, true)
	draw_line(-lateral, traseira, cor_atual, 1.4, true)
