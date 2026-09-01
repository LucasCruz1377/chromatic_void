extends Node2D
class_name PerigoAstral


enum Tipo {
	METEORO,
	ONDA,
	UMBRA,
}


var tipo := Tipo.METEORO
var player: Node2D
var dano := 14.0
var cor := Color(0.68, 0.78, 1.0)
var tempo := 1.0
var duracao_total := 1.0
var raio := 72.0
var raio_inicial := 0.0
var raio_final := 700.0
var angulo_lacuna := 0.0
var largura_lacuna := 0.58
var angulo_corredor := 0.0
var largura_corredor := 0.68
var velocidade_corredor := 0.22
var atingiu := false
var intervalo_pulso := 0.85
var contador_pulso := 0.0
var preparo_umbra := 0.0


func _ready() -> void:
	z_index = 2
	add_to_group("projetil_inimigo")
	add_to_group("perigo_astral")
	player = get_tree().get_first_node_in_group("player") as Node2D
	contador_pulso = intervalo_pulso
	queue_redraw()


func configurar_meteoro(posicao: Vector2, novo_dano: float, nova_cor: Color, aviso: float = 0.95, novo_raio: float = 70.0) -> void:
	tipo = Tipo.METEORO
	global_position = posicao
	dano = novo_dano
	cor = nova_cor
	tempo = aviso
	duracao_total = aviso
	raio = novo_raio


func configurar_onda(
	posicao: Vector2,
	novo_dano: float,
	nova_cor: Color,
	inicio: float,
	fim: float,
	duracao: float,
	lacuna: float,
	largura: float = 0.58
) -> void:
	tipo = Tipo.ONDA
	global_position = posicao
	dano = novo_dano
	cor = nova_cor
	raio_inicial = inicio
	raio_final = fim
	tempo = duracao
	duracao_total = duracao
	angulo_lacuna = lacuna
	largura_lacuna = largura


func configurar_umbra(
	posicao: Vector2,
	novo_dano: float,
	duracao: float,
	angulo_inicial: float,
	velocidade: float = 0.22
) -> void:
	tipo = Tipo.UMBRA
	global_position = posicao
	dano = novo_dano
	cor = Color(0.4, 0.48, 1.0)
	tempo = duracao
	duracao_total = duracao
	angulo_corredor = angulo_inicial
	velocidade_corredor = velocidade
	preparo_umbra = 1.25
	contador_pulso = 1.35


func _process(delta: float) -> void:
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as Node2D
	tempo -= delta
	if tipo == Tipo.METEORO:
		processar_meteoro()
	elif tipo == Tipo.ONDA:
		processar_onda()
	else:
		processar_umbra(delta)
	queue_redraw()


func processar_meteoro() -> void:
	if tempo > 0.0:
		return
	if not atingiu:
		atingiu = true
		Global.vibrar_controle(0.35, 0.65, 0.12)
		if is_instance_valid(player) and player.global_position.distance_to(global_position) <= raio:
			aplicar_dano_player()
		tempo = -0.18
	elif tempo <= -0.15:
		queue_free()


func processar_onda() -> void:
	var progresso := clampf(1.0 - tempo / maxf(duracao_total, 0.01), 0.0, 1.0)
	raio = lerpf(raio_inicial, raio_final, progresso)
	if not atingiu and is_instance_valid(player):
		var distancia := player.global_position.distance_to(global_position)
		var angulo := (player.global_position - global_position).angle()
		var na_lacuna := absf(angle_difference(angulo, angulo_lacuna)) <= largura_lacuna * 0.5
		if absf(distancia - raio) <= 18.0 and not na_lacuna:
			atingiu = true
			aplicar_dano_player()
	if tempo <= 0.0:
		queue_free()


func processar_umbra(delta: float) -> void:
	angulo_corredor += velocidade_corredor * delta
	preparo_umbra = maxf(preparo_umbra - delta, 0.0)
	contador_pulso -= delta
	if contador_pulso <= 0.0:
		contador_pulso = intervalo_pulso
		if (
			preparo_umbra <= 0.0
			and is_instance_valid(player)
			and not esta_no_corredor(player.global_position)
		):
			aplicar_dano_player()
	if tempo <= 0.0:
		queue_free()


func esta_no_corredor(posicao: Vector2) -> bool:
	var angulo := (posicao - global_position).angle()
	return (
		absf(angle_difference(angulo, angulo_corredor)) <= largura_corredor * 0.5
		or absf(angle_difference(angulo, angulo_corredor + PI)) <= largura_corredor * 0.5
	)


func aplicar_dano_player() -> void:
	if is_instance_valid(player) and player.has_method("tomar_dano"):
		player.tomar_dano(dano)


func _draw() -> void:
	if tipo == Tipo.METEORO:
		var pulso := 1.0 + sin(Time.get_ticks_msec() * 0.016) * 0.08
		var progresso := clampf(tempo / maxf(duracao_total, 0.01), 0.0, 1.0)
		var aviso := cor
		aviso.a = 0.24 if tempo > 0.0 else 0.62
		draw_circle(Vector2.ZERO, raio * pulso, aviso)
		draw_arc(Vector2.ZERO, raio, 0.0, TAU, 48, Color(cor.r, cor.g, cor.b, 0.95), 4.5, true)
		draw_arc(Vector2.ZERO, maxf(raio * progresso, 4.0), 0.0, TAU, 40, Color.WHITE, 2.5, true)
		draw_line(Vector2(-raio, 0.0), Vector2(raio, 0.0), Color(cor.r, cor.g, cor.b, 0.82), 2.0, true)
		draw_line(Vector2(0.0, -raio), Vector2(0.0, raio), Color(cor.r, cor.g, cor.b, 0.82), 2.0, true)
	elif tipo == Tipo.ONDA:
		var halo := cor
		halo.a = 0.25
		var inicio_arco := angulo_lacuna + largura_lacuna * 0.5
		var fim_arco := angulo_lacuna + TAU - largura_lacuna * 0.5
		draw_arc(Vector2.ZERO, raio, inicio_arco, fim_arco, 96, halo, 22.0, true)
		draw_arc(Vector2.ZERO, raio, inicio_arco, fim_arco, 96, Color(cor.r, cor.g, cor.b, 0.96), 5.0, true)
		var borda_a := Vector2.from_angle(inicio_arco)
		var borda_b := Vector2.from_angle(fim_arco)
		var cor_segura := Color(0.36, 1.0, 0.72, 0.95)
		draw_line(borda_a * maxf(raio - 28.0, 0.0), borda_a * (raio + 28.0), cor_segura, 4.0, true)
		draw_line(borda_b * maxf(raio - 28.0, 0.0), borda_b * (raio + 28.0), cor_segura, 4.0, true)
	else:
		var sombra := Color(0.015, 0.02, 0.09, 0.54)
		draw_circle(Vector2.ZERO, 940.0, sombra)
		var pulso_seguro := 0.30 + absf(sin(Time.get_ticks_msec() * 0.008)) * 0.18
		var seguro := Color(0.32, 0.82, 1.0, pulso_seguro)
		draw_colored_polygon(PackedVector2Array([
			Vector2.ZERO,
			Vector2.from_angle(angulo_corredor - largura_corredor * 0.5) * 940.0,
			Vector2.from_angle(angulo_corredor + largura_corredor * 0.5) * 940.0,
		]), seguro)
		draw_colored_polygon(PackedVector2Array([
			Vector2.ZERO,
			Vector2.from_angle(angulo_corredor + PI - largura_corredor * 0.5) * 940.0,
			Vector2.from_angle(angulo_corredor + PI + largura_corredor * 0.5) * 940.0,
		]), seguro)
		var limite_a := Vector2.from_angle(angulo_corredor - largura_corredor * 0.5)
		var limite_b := Vector2.from_angle(angulo_corredor + largura_corredor * 0.5)
		draw_line(limite_a * -940.0, limite_a * 940.0, Color(0.55, 0.92, 1.0, 0.92), 3.5, true)
		draw_line(limite_b * -940.0, limite_b * 940.0, Color(0.55, 0.92, 1.0, 0.92), 3.5, true)
		if is_instance_valid(player):
			var alvo := to_local(player.global_position)
			var cor_alerta := Color(0.36, 1.0, 0.72) if esta_no_corredor(player.global_position) else Color(1.0, 0.24, 0.38)
			var raio_alerta := 25.0 + clampf(contador_pulso / intervalo_pulso, 0.0, 1.0) * 18.0
			draw_arc(alvo, raio_alerta, 0.0, TAU, 32, cor_alerta, 3.0, true)
