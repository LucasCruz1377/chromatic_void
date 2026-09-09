extends Node2D
class_name JogadorRemoto


var peer_id := 0
var nickname := "PILOTO"
var posicao_alvo := Vector2.ZERO
var rotacao_alvo := 0.0
var velocidade_alvo := Vector2.ZERO
var vida := 100.0
var vida_maxima := 100.0
var vivo := true
var usando_habilidade := false
var cor_nave := Color("65d8ff")
var recebeu_primeiro_estado := false
var tempo_sem_pacote := 0.0


func configurar(id: int, nome: String, posicao_inicial: Vector2) -> void:
	peer_id = id
	nickname = nome
	global_position = posicao_inicial
	posicao_alvo = posicao_inicial
	z_index = 2
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("player_remoto")
	queue_redraw()


func aplicar_estado(dados: Dictionary) -> void:
	var nova_posicao: Variant = dados.get("posicao", posicao_alvo)
	if nova_posicao is Vector2:
		posicao_alvo = nova_posicao
	rotacao_alvo = float(dados.get("rotacao", rotacao_alvo))
	var nova_velocidade: Variant = dados.get("velocidade", velocidade_alvo)
	if nova_velocidade is Vector2:
		velocidade_alvo = nova_velocidade
	vida_maxima = maxf(float(dados.get("vida_maxima", vida_maxima)), 1.0)
	vida = clampf(float(dados.get("vida", vida)), 0.0, vida_maxima)
	vivo = bool(dados.get("vivo", vivo))
	usando_habilidade = bool(dados.get("habilidade", usando_habilidade))
	var nova_cor: Variant = dados.get("cor", cor_nave)
	if nova_cor is Color:
		cor_nave = nova_cor
	if not recebeu_primeiro_estado:
		global_position = posicao_alvo
		rotation = rotacao_alvo
		recebeu_primeiro_estado = true
	tempo_sem_pacote = 0.0
	queue_redraw()


func _process(delta: float) -> void:
	tempo_sem_pacote += delta
	var distancia := global_position.distance_to(posicao_alvo)
	var tamanho := get_viewport_rect().size
	if distancia > maxf(tamanho.x, tamanho.y) * 0.45:
		global_position = posicao_alvo
	else:
		global_position = global_position.lerp(posicao_alvo, 1.0 - exp(-16.0 * delta))
	rotation = lerp_angle(rotation, rotacao_alvo, 1.0 - exp(-18.0 * delta))
	queue_redraw()


func _draw() -> void:
	var alpha := 1.0 if vivo else 0.28
	var pulso := 1.0 + sin(Time.get_ticks_msec() * 0.012) * 0.08 if usando_habilidade else 1.0
	var brilho := Color(cor_nave, 0.16 * alpha)
	draw_circle(Vector2.ZERO, 31.0 * pulso, brilho)
	var casco := PackedVector2Array([
		Vector2(29, 0), Vector2(-14, -19), Vector2(-7, -6),
		Vector2(-23, 0), Vector2(-7, 6), Vector2(-14, 19),
	])
	draw_colored_polygon(casco, Color(cor_nave, 0.92 * alpha))
	draw_polyline(PackedVector2Array([
		Vector2(29, 0), Vector2(-14, -19), Vector2(-7, -6),
		Vector2(-23, 0), Vector2(-7, 6), Vector2(-14, 19), Vector2(29, 0),
	]), Color(cor_nave.lightened(0.42), alpha), 2.0)
	draw_circle(Vector2(2, 0), 5.0, Color(1.0, 1.0, 1.0, alpha))
	# Nome e vida permanecem orientados para a tela, mesmo com a nave girando.
	draw_set_transform(Vector2.ZERO, -rotation, Vector2.ONE)
	draw_string(ThemeDB.fallback_font, Vector2(-48, -38), nickname, HORIZONTAL_ALIGNMENT_CENTER, 96, 13, Color(0.76, 0.9, 1.0, alpha))
	draw_rect(Rect2(-35, -29, 70, 5), Color(0.02, 0.04, 0.10, 0.88), true)
	draw_rect(Rect2(-35, -29, 70.0 * vida / vida_maxima, 5), Color(0.34, 1.0, 0.58, alpha), true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
