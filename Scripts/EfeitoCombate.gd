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
	var raio := lerpf(4.0, 19.0, progresso) * intensidade
	draw_arc(Vector2.ZERO, raio, 0.0, TAU, 20, cor_atual, 2.2, true)
	for indice in 5:
		var angulo := float(indice) * TAU / 5.0 + float(semente % 17) * 0.07
		var inicio := Vector2.from_angle(angulo) * raio * 0.35
		var fim := Vector2.from_angle(angulo) * raio * 1.25
		draw_line(inicio, fim, cor_atual, 1.7, true)


func desenhar_morte(progresso: float, cor_atual: Color) -> void:
	var raio := lerpf(8.0, 46.0, progresso) * intensidade
	draw_arc(Vector2.ZERO, raio, 0.0, TAU, 28, cor_atual, 3.0, true)
	draw_arc(Vector2.ZERO, raio * 0.55, 0.0, TAU, 20, cor_atual, 1.5, true)
	for indice in 9:
		var angulo := float(indice) * TAU / 9.0 + float(semente % 11) * 0.09
		var inicio := Vector2.from_angle(angulo) * raio * 0.30
		var fim := Vector2.from_angle(angulo) * raio * 1.30
		draw_line(inicio, fim, cor_atual, 2.0, true)


func desenhar_dano_player(progresso: float, cor_atual: Color) -> void:
	var raio := lerpf(18.0, 54.0, progresso) * intensidade
	draw_arc(Vector2.ZERO, raio, -PI * 0.85, PI * 0.85, 30, cor_atual, 4.0, true)
	var cruz := 13.0 * intensidade * (1.0 - progresso * 0.35)
	draw_line(Vector2(-cruz, 0), Vector2(cruz, 0), cor_atual, 2.5, true)
	draw_line(Vector2(0, -cruz), Vector2(0, cruz), cor_atual, 2.5, true)


func desenhar_aviso(progresso: float, cor_atual: Color) -> void:
	var raio := lerpf(8.0, 32.0, progresso) * intensidade
	draw_arc(Vector2.ZERO, raio, 0.0, TAU, 24, cor_atual, 2.5, true)
	draw_line(Vector2.ZERO, direcao * raio * 1.45, cor_atual, 2.0, true)


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
