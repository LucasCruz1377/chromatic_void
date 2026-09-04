extends Node2D
class_name MonthlyBurst


var cor := Color.WHITE
var intensidade := 1.0
var tempo := 0.0
var duracao := 0.52
var posicoes: Array[Vector2] = []
var velocidades: Array[Vector2] = []
var tamanhos: Array[float] = []


static func criar(pai: Node, posicao: Vector2, cor_efeito: Color, forca := 1.0) -> MonthlyBurst:
	if not is_instance_valid(pai):
		return null
	var explosao := MonthlyBurst.new()
	explosao.cor = cor_efeito
	explosao.intensidade = maxf(forca, 0.25)
	pai.add_child(explosao)
	explosao.global_position = posicao
	explosao.z_index = 24
	var quantidade := 10 if Global.dispositivo_mobile() else 18
	for indice in range(quantidade):
		var angulo := TAU * float(indice) / float(quantidade) + randf_range(-0.16, 0.16)
		explosao.posicoes.append(Vector2.ZERO)
		explosao.velocidades.append(Vector2.from_angle(angulo) * randf_range(58.0, 155.0) * explosao.intensidade)
		explosao.tamanhos.append(randf_range(1.8, 4.8) * sqrt(explosao.intensidade))
	return explosao


func _process(delta: float) -> void:
	tempo += delta
	for indice in range(posicoes.size()):
		posicoes[indice] += velocidades[indice] * delta
		velocidades[indice] = velocidades[indice].lerp(Vector2.ZERO, delta * 2.2)
	queue_redraw()
	if tempo >= duracao:
		queue_free()


func _draw() -> void:
	var progresso := clampf(tempo / duracao, 0.0, 1.0)
	var alpha := pow(1.0 - progresso, 1.5)
	for indice in range(posicoes.size()):
		var brilho := Color(cor.r, cor.g, cor.b, alpha)
		draw_circle(posicoes[indice], tamanhos[indice] * (1.0 - progresso * 0.55), brilho)
