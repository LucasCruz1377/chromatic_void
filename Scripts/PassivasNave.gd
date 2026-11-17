extends Node2D
## Comportamentos das passivas de propulsao e das estrelas de cura.
## Somente a autoridade da nave altera cargas ou solicita dano ao host.

const JANELA_DUPLO_TOQUE := 0.3
const DURACAO_ARRANCADA := 0.18
const RECARGA_ARRANCADA := 1.1
const CARGA_MAXIMA_ESTRELA := 8.75
const RAIO_ORBITA := 70.0
const RAIO_ACERTO := 20.0
const COR_ESTRELAS := Color("54f2a6")
const COR_JANUS := Color("f6d374")

var jogador
var frente_anterior := false
var janela_toque := 0.0
var recarga := 0.0
var tempo_arrancada := 0.0
var fase_orbita := 0.0
var intervalo_acerto := 0.0


func _ready() -> void:
	jogador = get_parent()
	z_index = 4


func tem_autoridade() -> bool:
	return not Rede.modo_multiplayer or jogador.is_multiplayer_authority()


func atualizar_propulsao(frente: bool, re: bool, delta: float) -> void:
	janela_toque = maxf(janela_toque - delta, 0.0)
	recarga = maxf(recarga - delta, 0.0)
	tempo_arrancada = maxf(tempo_arrancada - delta, 0.0)
	jogador.direcao_propulsao = 0 if frente == re else (1 if frente else -1)
	if not jogador.vivo or jogador.ctrlblock:
		frente_anterior = false
		janela_toque = 0.0
		tempo_arrancada = 0.0
		jogador.direcao_propulsao = 0
		return
	if jogador.modulo_nave != &"n01_reflexos_rapidos":
		janela_toque = 0.0
		tempo_arrancada = 0.0
	elif frente and not re and not frente_anterior:
		if janela_toque > 0.0 and recarga <= 0.0 and not jogador.UsandoHabilidade:
			jogador.velocity += jogador.transform.x.normalized() * 180.0
			tempo_arrancada = DURACAO_ARRANCADA
			recarga = RECARGA_ARRANCADA
			janela_toque = 0.0
		else:
			janela_toque = JANELA_DUPLO_TOQUE
	frente_anterior = frente


func multiplicador_arrancada() -> float:
	return 1.4 if tempo_arrancada > 0.0 else 1.0


func multiplicador_protecao(origem: Vector2) -> float:
	if jogador.modulo_nave != &"n07_propulsor_janus" or jogador.direcao_propulsao == 0:
		return 1.0
	if jogador.ctrlblock or not origem.is_finite():
		return 1.0
	var ate_origem: Vector2 = origem - jogador.global_position
	if ate_origem.length_squared() < 0.001:
		return 1.0
	var frente: Vector2 = jogador.global_transform.x.normalized()
	var alinhamento := ate_origem.normalized().dot(frente) * float(jogador.direcao_propulsao)
	# Um setor de 120 graus protege o lado efetivamente acionado.
	return 0.78 if alinhamento >= 0.5 else 1.0


func armazenar_cura(excedente: float) -> void:
	if not tem_autoridade() or not is_finite(excedente) or excedente <= 0.0:
		return
	for indice in range(4):
		jogador.estrelas_solidarias[indice] = minf(
			float(jogador.estrelas_solidarias[indice]) + excedente / 4.0,
			CARGA_MAXIMA_ESTRELA
		)
	queue_redraw()


func posicao_estrela(indice: int) -> Vector2:
	# Compensa a rotacao da nave: as estrelas orbitam sem girar com a mira.
	var angulo: float = fase_orbita + TAU * float(indice) / 4.0 - jogador.global_rotation
	return Vector2.from_angle(angulo) * RAIO_ORBITA


func _process(delta: float) -> void:
	if not is_instance_valid(jogador):
		return
	visible = jogador.visible and jogador.vivo
	if not jogador.vivo or jogador.modulo_nave != &"n05_reserva_solidaria":
		if tem_autoridade():
			jogador.estrelas_solidarias = Vector4.ZERO
		queue_redraw()
		return
	fase_orbita = fmod(fase_orbita + delta * 1.5, TAU)
	intervalo_acerto -= delta
	if tem_autoridade() and intervalo_acerto <= 0.0:
		intervalo_acerto = 0.05
		atingir_inimigos()
	queue_redraw()


func atingir_inimigos() -> void:
	if not tem_autoridade() or not jogador.vivo or jogador.modulo_nave != &"n05_reserva_solidaria":
		return
	var inimigos := get_tree().get_nodes_in_group("inimigo")
	for indice in range(4):
		var carga: float = jogador.estrelas_solidarias[indice]
		if carga <= 0.0:
			continue
		var ponto := to_global(posicao_estrela(indice))
		for alvo in inimigos:
			if not is_instance_valid(alvo) or alvo.is_queued_for_deletion() or not alvo is Node2D:
				continue
			if bool(alvo.get("morto")) or not alvo.has_method("tomarDano"):
				continue
			if ponto.distance_squared_to(alvo.global_position) > RAIO_ACERTO * RAIO_ACERTO:
				continue
			# Cada carga causa exatamente um impacto e so reaparece com nova cura.
			jogador.estrelas_solidarias[indice] = 0.0
			alvo.tomarDano(carga)
			break


func _draw() -> void:
	if not is_instance_valid(jogador) or not jogador.vivo:
		return
	if jogador.modulo_nave == &"n05_reserva_solidaria":
		for indice in range(4):
			if jogador.estrelas_solidarias[indice] <= 0.0:
				continue
			var centro := posicao_estrela(indice)
			# O mesmo losango de quatro pontas usado no icone da passiva.
			var pontos := PackedVector2Array([
				centro + Vector2(0, -9), centro + Vector2(6, 0),
				centro + Vector2(0, 9), centro + Vector2(-6, 0)
			])
			draw_colored_polygon(pontos, COR_ESTRELAS)
			pontos.append(pontos[0])
			draw_polyline(pontos, COR_ESTRELAS.lightened(0.25), 1.0, true)
	elif jogador.modulo_nave == &"n07_propulsor_janus" and jogador.direcao_propulsao != 0:
		var centro_angulo := 0.0 if jogador.direcao_propulsao > 0 else PI
		draw_arc(Vector2.ZERO, 35.0, centro_angulo - PI / 3.0, centro_angulo + PI / 3.0, 20, Color(COR_JANUS, 0.7), 2.0, true)
