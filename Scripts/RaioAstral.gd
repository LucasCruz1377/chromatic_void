extends Node2D
class_name RaioAstral


var origem: Node2D
var player: Node2D
var direcao := Vector2.LEFT
var dano := 22.0
var cor := Color(1.0, 0.72, 0.18)
var tempo_aviso := 1.15
var tempo_aviso_total := 1.15
var tempo_ativo := 0.32
var largura := 32.0
var comprimento := 1150.0
var rastrear_antes_de_disparar := true
var velocidade_varredura := 0.0
var queimadura_total := 0.0
var duracao_queimadura := 0.0
var ativo := false
var atingiu := false
var desaparecendo := false
var alpha_raio := 1.0
var tempo_trava_direcao := 0.34
var tween_saida: Tween


func _ready() -> void:
	z_index = 4
	add_to_group("projetil_inimigo")
	add_to_group("raio_astral")
	player = get_tree().get_first_node_in_group("player") as Node2D
	queue_redraw()


func configurar(
	nova_origem: Node2D,
	nova_direcao: Vector2,
	novo_dano: float,
	nova_cor: Color,
	aviso: float = 1.15,
	ativo_por: float = 0.32,
	nova_largura: float = 32.0,
	rastrear: bool = true,
	varredura: float = 0.0,
	dano_queimadura: float = 0.0,
	tempo_queimadura: float = 0.0
) -> void:
	origem = nova_origem
	direcao = nova_direcao.normalized()
	dano = novo_dano
	cor = nova_cor
	tempo_aviso = aviso
	tempo_aviso_total = aviso
	tempo_ativo = ativo_por
	largura = nova_largura
	rastrear_antes_de_disparar = rastrear
	velocidade_varredura = varredura
	queimadura_total = dano_queimadura
	duracao_queimadura = tempo_queimadura


func _process(delta: float) -> void:
	if not is_instance_valid(origem):
		queue_free()
		return
	global_position = origem.global_position
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as Node2D

	if desaparecendo:
		queue_redraw()
		return

	if not ativo:
		# A mira acompanha o jogador durante a maior parte da carga, mas trava
		# antes do disparo para que exista uma janela real de esquiva.
		if (
			rastrear_antes_de_disparar
			and tempo_aviso > tempo_trava_direcao
			and is_instance_valid(player)
		):
			direcao = global_position.direction_to(player.global_position)
		tempo_aviso -= delta
		if tempo_aviso <= 0.0:
			iniciar_disparo()
	else:
		tempo_ativo -= delta
		if tempo_ativo <= 0.0:
			iniciar_desaparecimento()
	queue_redraw()


func iniciar_disparo() -> void:
	ativo = true
	# O dano é resolvido uma única vez no instante do disparo. O restante da
	# duração existe apenas para leitura visual e para o desaparecimento suave.
	verificar_acerto()
	Global.vibrar_controle(0.82, 1.0, 0.22)
	var camera := get_tree().get_first_node_in_group("camera") as Camera2D
	if is_instance_valid(camera) and camera.has_method("shake"):
		camera.shake(16.0 if largura >= 36.0 else 13.0)


func iniciar_desaparecimento() -> void:
	if desaparecendo:
		return
	desaparecendo = true
	tween_saida = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween_saida.tween_property(self, "alpha_raio", 0.0, 0.38)
	tween_saida.tween_callback(queue_free)


func verificar_acerto() -> void:
	if atingiu or not is_instance_valid(player):
		return
	var relativo := player.global_position - global_position
	var ao_longo := direcao.dot(relativo)
	var perpendicular := absf(direcao.cross(relativo))
	if ao_longo >= 0.0 and ao_longo <= comprimento and perpendicular <= largura * 0.5:
		atingiu = true
		if player.has_method("tomar_dano"):
			player.tomar_dano(dano)
		if queimadura_total > 0.0 and player.has_method("aplicar_queimadura"):
			player.aplicar_queimadura(queimadura_total, duracao_queimadura)


func _draw() -> void:
	var fim := direcao * comprimento
	if ativo:
		var halo := Color(cor.r, cor.g, cor.b, 0.22 * alpha_raio)
		draw_line(Vector2.ZERO, fim, halo, largura * 1.8, true)
		draw_line(Vector2.ZERO, fim, Color(cor.r, cor.g, cor.b, alpha_raio), largura, true)
		draw_line(Vector2.ZERO, fim, Color(1.0, 0.98, 0.82, alpha_raio), largura * 0.24, true)
	else:
		var aviso := cor
		var carga := clampf(1.0 - tempo_aviso / maxf(tempo_aviso_total, 0.01), 0.0, 1.0)
		aviso.a = 0.62 + carga * 0.34
		var normal := direcao.rotated(PI * 0.5) * largura * 0.5
		draw_line(normal, fim + normal, Color(cor.r, cor.g, cor.b, 0.42), 2.0, true)
		draw_line(-normal, fim - normal, Color(cor.r, cor.g, cor.b, 0.42), 2.0, true)
		draw_dashed_line(Vector2.ZERO, fim, aviso, 3.0 + carga * 2.0, 13.0, true)
		draw_circle(Vector2.ZERO, 14.0 + carga * 20.0 + sin(Time.get_ticks_msec() * 0.018) * 3.0, Color(cor.r, cor.g, cor.b, 0.20 + carga * 0.48))
		draw_arc(Vector2.ZERO, 24.0 + carga * 16.0, 0.0, TAU, 32, aviso, 3.0 + carga * 2.0, true)
		if is_instance_valid(player):
			var alvo := to_local(player.global_position)
			draw_arc(alvo, 28.0 - carga * 10.0, 0.0, TAU, 28, Color(1.0, 0.28, 0.16, 0.95), 3.0, true)
			draw_line(alvo - Vector2(10.0, 0.0), alvo + Vector2(10.0, 0.0), Color.WHITE, 2.0, true)
			draw_line(alvo - Vector2(0.0, 10.0), alvo + Vector2(0.0, 10.0), Color.WHITE, 2.0, true)
