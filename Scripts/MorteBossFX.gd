extends Node2D
class_name MorteBossFX


var cor := Color.WHITE
var tempo := 0.0
var duracao := 1.15
var rotacao_fragmentos := 0.0


static func criar(pai: Node, posicao: Vector2, cor_efeito: Color) -> MorteBossFX:
	if not is_instance_valid(pai):
		return null
	var efeito := MorteBossFX.new()
	efeito.cor = cor_efeito
	efeito.global_position = posicao
	efeito.z_index = 90
	pai.add_child(efeito)
	return efeito


func _process(delta: float) -> void:
	tempo += delta
	rotacao_fragmentos += delta * 1.8
	queue_redraw()
	if tempo >= duracao:
		queue_free()


func _draw() -> void:
	var p := clampf(tempo / duracao, 0.0, 1.0)
	var alpha := pow(1.0 - p, 1.55)
	var atual := Color(cor.r, cor.g, cor.b, alpha)
	for anel in 3:
		var atraso := float(anel) * 0.13
		var pa := clampf((p - atraso) / maxf(1.0 - atraso, 0.01), 0.0, 1.0)
		if pa > 0.0:
			draw_arc(Vector2.ZERO, lerpf(12.0, 105.0 + anel * 20.0, pa), 0.0, TAU, 64, Color(cor.r, cor.g, cor.b, alpha * (1.0 - pa)), 4.0 - anel, true)
	for indice in 16:
		var angulo := TAU * float(indice) / 16.0 + rotacao_fragmentos * (1.0 if indice % 2 == 0 else -0.55)
		var vetor := Vector2.from_angle(angulo)
		var centro := vetor * lerpf(18.0, 145.0, p) * (0.72 + float(indice % 3) * 0.14)
		var tamanho := lerpf(8.0, 2.0, p)
		draw_colored_polygon(PackedVector2Array([centro + vetor * tamanho, centro + vetor.orthogonal() * tamanho * 0.55, centro - vetor * tamanho, centro - vetor.orthogonal() * tamanho * 0.55]), atual)
	if p < 0.28:
		draw_circle(Vector2.ZERO, lerpf(42.0, 8.0, p / 0.28), Color(1.0, 1.0, 1.0, 0.8 * (1.0 - p / 0.28)))
