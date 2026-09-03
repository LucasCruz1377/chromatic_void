extends Node2D
class_name IndicadorGravitacional


var origem: Node2D
var player: Node2D
var duracao := 3.8
var duracao_total := 3.8
var sinal := 1.0
var cor := Color(0.36, 0.72, 1.0)


func _ready() -> void:
	z_index = 3
	add_to_group("projetil_inimigo")
	add_to_group("campo_gravitacional")
	player = get_tree().get_first_node_in_group("player") as Node2D
	queue_redraw()


func configurar(nova_origem: Node2D, novo_sinal: float, tempo: float) -> void:
	origem = nova_origem
	sinal = signf(novo_sinal)
	duracao = tempo
	duracao_total = tempo
	cor = Color(0.32, 0.76, 1.0) if sinal > 0.0 else Color(0.92, 0.38, 1.0)


func _process(delta: float) -> void:
	if not is_instance_valid(origem):
		queue_free()
		return
	global_position = origem.global_position
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as Node2D
	duracao -= delta
	if duracao <= 0.0:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var tempo := Time.get_ticks_msec() * 0.001
	var pulso := fposmod(tempo * 72.0 * sinal, 86.0)
	var halo := cor
	halo.a = 0.10
	draw_circle(Vector2.ZERO, 225.0, halo)

	for indice in 5:
		var raio := fposmod(48.0 + indice * 48.0 - pulso, 240.0)
		var alpha := clampf(1.0 - raio / 260.0, 0.16, 0.72)
		var cor_anel := cor
		cor_anel.a = alpha
		draw_arc(Vector2.ZERO, raio, 0.0, TAU, 64, cor_anel, 2.5, true)

	for indice in 12:
		var angulo := TAU * indice / 12.0 + tempo * 0.12 * sinal
		var externo := Vector2.from_angle(angulo) * 205.0
		var interno := Vector2.from_angle(angulo) * 155.0
		var inicio := externo if sinal > 0.0 else interno
		var fim := interno if sinal > 0.0 else externo
		draw_line(inicio, fim, Color(cor.r, cor.g, cor.b, 0.72), 2.0, true)
		draw_circle(fim, 3.5, cor)

	if is_instance_valid(player):
		var alvo := to_local(player.global_position)
		var aviso := cor
		aviso.a = 0.78
		draw_dashed_line(Vector2.ZERO, alvo, aviso, 2.0, 10.0, true)
		draw_arc(alvo, 31.0 + sin(tempo * 8.0) * 4.0, 0.0, TAU, 32, aviso, 3.0, true)
		var direcao := alvo.direction_to(Vector2.ZERO) * sinal
		draw_line(alvo, alvo + direcao * 45.0, cor, 5.0, true)
		draw_circle(alvo + direcao * 45.0, 5.0, cor)
