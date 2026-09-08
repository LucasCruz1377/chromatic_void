extends Node2D
class_name FaixaEnergiaBoss

## Faixa de energia procedural usada pelos bosses mensais. Ao contrário de um
## projétil, ela ocupa e transforma uma região da arena durante alguns segundos.

enum Movimento { FIXA, RASTREADORA, CORREDOR, ESPIRAL, LIGACAO }

var movimento: Movimento = Movimento.FIXA
var centro := Vector2.ZERO
var angulo := 0.0
var comprimento := 1250.0
var largura := 22.0
var cor := Color("#ffd85c")
var dano := 18
var atraso := 0.0
var tempo_aviso := 0.85
var antecedencia_trava := 0.0
var mira_travada := false
var tempo_ativo := 1.1
var velocidade_angular := 0.0
var velocidade_angular_atual := 0.0
var inverter_no_meio := false
var deslocamento := 0.0
var velocidade_deslocamento := 0.0
var amplitude_deslocamento := 80.0
var alvo: Node2D
var dono_formacao: Node
var indice_a := -1
var indice_b := -1
var acompanha_origem := false
var tempo := 0.0
var recarga_dano := 0.0
var ponto_a := Vector2.ZERO
var ponto_b := Vector2.ZERO
var _sentido_deslocamento := 1.0
var tempo_ate_redesenho := 0.0

static func criar(cena: Node, dados: Dictionary) -> FaixaEnergiaBoss:
	if not is_instance_valid(cena):
		return null
	var faixa := FaixaEnergiaBoss.new()
	faixa.movimento = int(dados.get("movimento", Movimento.FIXA)) as Movimento
	faixa.centro = dados.get("centro", Vector2.ZERO)
	faixa.angulo = float(dados.get("angulo", 0.0))
	faixa.comprimento = float(dados.get("comprimento", 1250.0))
	faixa.largura = float(dados.get("largura", 22.0))
	faixa.cor = dados.get("cor", Color("#ffd85c"))
	faixa.dano = int(dados.get("dano", 18))
	faixa.atraso = float(dados.get("atraso", 0.0))
	faixa.tempo_aviso = float(dados.get("aviso", 0.85))
	faixa.tempo_ativo = float(dados.get("duracao", 1.1))
	faixa.antecedencia_trava = clampf(float(dados.get("antecedencia_trava", 0.0)), 0.0, faixa.tempo_aviso)
	faixa.velocidade_angular = float(dados.get("velocidade_angular", 0.0))
	faixa.velocidade_angular_atual = faixa.velocidade_angular
	faixa.inverter_no_meio = bool(dados.get("inverter", false))
	faixa.deslocamento = float(dados.get("deslocamento", 0.0))
	faixa.velocidade_deslocamento = float(dados.get("velocidade_deslocamento", 0.0))
	faixa.amplitude_deslocamento = float(dados.get("amplitude", 80.0))
	faixa.alvo = dados.get("alvo") as Node2D
	faixa.dono_formacao = dados.get("dono") as Node
	faixa.indice_a = int(dados.get("indice_a", -1))
	faixa.indice_b = int(dados.get("indice_b", -1))
	faixa.acompanha_origem = bool(dados.get("acompanha_origem", false))
	faixa.z_index = 3
	faixa.add_to_group("perigo_boss_dinamico")
	cena.add_child(faixa)
	faixa._atualizar_geometria(0.0)
	return faixa

func _process(delta: float) -> void:
	tempo += delta
	recarga_dano = maxf(0.0, recarga_dano - delta)
	_atualizar_geometria(delta)
	var local := tempo - atraso
	if local >= tempo_aviso and local <= tempo_aviso + tempo_ativo:
		_aplicar_perigo()
	tempo_ate_redesenho -= delta
	if not Global.dispositivo_mobile() or tempo_ate_redesenho <= 0.0:
		queue_redraw()
		tempo_ate_redesenho = 1.0 / 30.0
	if local > tempo_aviso + tempo_ativo + 0.22:
		queue_free()

func _atualizar_geometria(delta: float) -> void:
	var local := tempo - atraso
	match movimento:
		Movimento.RASTREADORA:
			if mira_travada:
				return
			var origem := _posicao_formacao(indice_a, centro)
			var instante_trava := maxf(tempo_aviso - antecedencia_trava, 0.0)
			if local >= 0.0 and local < instante_trava and is_instance_valid(alvo):
				var desejado := origem.angle_to_point(alvo.global_position)
				angulo = lerp_angle(angulo, desejado, clampf(delta * 4.4, 0.0, 1.0))
			ponto_a = origem
			ponto_b = origem + Vector2.RIGHT.rotated(angulo) * comprimento
			if antecedencia_trava > 0.0 and local >= instante_trava:
				mira_travada = true
		Movimento.CORREDOR:
			if local >= 0.0:
				deslocamento += velocidade_deslocamento * _sentido_deslocamento * delta
				if absf(deslocamento) >= amplitude_deslocamento:
					deslocamento = clampf(deslocamento, -amplitude_deslocamento, amplitude_deslocamento)
					_sentido_deslocamento *= -1.0
			var direcao := Vector2.RIGHT.rotated(angulo)
			var normal := direcao.orthogonal()
			var meio := centro + normal * deslocamento
			ponto_a = meio - direcao * comprimento * 0.5
			ponto_b = meio + direcao * comprimento * 0.5
		Movimento.ESPIRAL:
			if local >= 0.0:
				var alvo_velocidade := velocidade_angular
				if inverter_no_meio and local > tempo_aviso + tempo_ativo * 0.5:
					alvo_velocidade = -velocidade_angular
				velocidade_angular_atual = move_toward(velocidade_angular_atual, alvo_velocidade, delta * 3.8)
				angulo += velocidade_angular_atual * delta
			var direcao := Vector2.RIGHT.rotated(angulo)
			ponto_a = centro - direcao * comprimento * 0.5
			ponto_b = centro + direcao * comprimento * 0.5
		Movimento.LIGACAO:
			ponto_a = _posicao_formacao(indice_a, centro)
			ponto_b = _posicao_formacao(indice_b, centro)
		_:
			var direcao := Vector2.RIGHT.rotated(angulo)
			ponto_a = centro - direcao * comprimento * 0.5
			ponto_b = centro + direcao * comprimento * 0.5

func _posicao_formacao(indice: int, alternativa: Vector2) -> Vector2:
	if is_instance_valid(dono_formacao) and dono_formacao.has_method("obter_posicao_satelite"):
		return dono_formacao.call("obter_posicao_satelite", indice)
	if acompanha_origem and is_instance_valid(dono_formacao) and dono_formacao is Node2D:
		return (dono_formacao as Node2D).global_position
	return alternativa

func _aplicar_perigo() -> void:
	if recarga_dano > 0.0:
		return
	var jogador := get_tree().get_first_node_in_group("player") as Node2D
	if not is_instance_valid(jogador):
		return
	if _distancia_segmento(jogador.global_position, ponto_a, ponto_b) <= largura * 0.58 + 13.0:
		if jogador.has_method("tomar_dano"):
			jogador.call("tomar_dano", dano)
		recarga_dano = 0.34

func _distancia_segmento(ponto: Vector2, inicio: Vector2, fim: Vector2) -> float:
	var segmento := fim - inicio
	var tamanho_quadrado := segmento.length_squared()
	if tamanho_quadrado <= 0.001:
		return ponto.distance_to(inicio)
	var proporcao := clampf((ponto - inicio).dot(segmento) / tamanho_quadrado, 0.0, 1.0)
	return ponto.distance_to(inicio + segmento * proporcao)

func _draw() -> void:
	var local := tempo - atraso
	if local < 0.0:
		var brilho_espera := 0.08 + sin(tempo * 8.0) * 0.025
		draw_line(ponto_a, ponto_b, Color(cor, brilho_espera), 2.0)
		return
	var ativo := local >= tempo_aviso
	if not ativo:
		var pulso := 0.85 if mira_travada else 0.44 + sin(local * 22.0) * 0.18
		draw_line(ponto_a, ponto_b, Color(cor, pulso * 0.28), largura + 12.0)
		draw_line(ponto_a, ponto_b, Color(cor, pulso), 3.0)
		var progresso := clampf(local / maxf(tempo_aviso, 0.01), 0.0, 1.0)
		var cursor := ponto_a.lerp(ponto_b, progresso)
		draw_circle(cursor, 6.0 + progresso * 5.0, Color.WHITE)
	else:
		var fade := clampf((tempo_aviso + tempo_ativo - local) / 0.2, 0.0, 1.0)
		var vibracao := sin(local * 34.0) * 2.0
		draw_line(ponto_a, ponto_b, Color(cor, 0.2 * fade), largura + 22.0 + vibracao)
		draw_line(ponto_a, ponto_b, Color(cor, 0.72 * fade), largura + vibracao)
		draw_line(ponto_a, ponto_b, Color.WHITE, maxf(2.0, largura * 0.19))
