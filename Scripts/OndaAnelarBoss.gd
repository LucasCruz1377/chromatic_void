extends Node2D
class_name OndaAnelarBoss

## Onda vazada: só o anel causa dano. Isso cria uma janela clara para atravessar
## o golpe e evita o comportamento de "círculo que acerta tudo".

var centro := Vector2.ZERO
var raio_inicial := 35.0
var raio_final := 360.0
var espessura := 24.0
var cor := Color("#c978ff")
var dano := 20
var atraso := 0.0
var tempo_aviso := 0.65
var tempo_ativo := 0.9
var intensidade_impulso := 0.0
var tempo := 0.0
var recarga := 0.0
var raio_atual := 0.0
var tempo_ate_redesenho := 0.0

static func criar(cena: Node, dados: Dictionary) -> OndaAnelarBoss:
	if not is_instance_valid(cena):
		return null
	var onda := OndaAnelarBoss.new()
	onda.centro = dados.get("centro", Vector2.ZERO)
	onda.raio_inicial = float(dados.get("raio_inicial", 35.0))
	onda.raio_final = float(dados.get("raio_final", 360.0))
	onda.espessura = float(dados.get("espessura", 24.0))
	onda.cor = dados.get("cor", Color("#c978ff"))
	onda.dano = int(dados.get("dano", 20))
	onda.atraso = float(dados.get("atraso", 0.0))
	onda.tempo_aviso = float(dados.get("aviso", 0.65))
	onda.tempo_ativo = float(dados.get("duracao", 0.9))
	onda.intensidade_impulso = float(dados.get("impulso", 0.0))
	onda.raio_atual = onda.raio_inicial
	onda.z_index = 4
	onda.add_to_group("perigo_boss_dinamico")
	cena.add_child(onda)
	return onda

func _process(delta: float) -> void:
	tempo += delta
	recarga = maxf(0.0, recarga - delta)
	var local := tempo - atraso
	if local >= tempo_aviso:
		var progresso := clampf((local - tempo_aviso) / maxf(tempo_ativo, 0.01), 0.0, 1.0)
		raio_atual = lerpf(raio_inicial, raio_final, ease(progresso, -1.4))
		_aplicar_perigo()
	tempo_ate_redesenho -= delta
	if not Global.dispositivo_mobile() or tempo_ate_redesenho <= 0.0:
		queue_redraw()
		tempo_ate_redesenho = 1.0 / 30.0
	if local > tempo_aviso + tempo_ativo + 0.2:
		queue_free()

func _aplicar_perigo() -> void:
	if recarga > 0.0:
		return
	var jogador := get_tree().get_first_node_in_group("player") as Node2D
	if not is_instance_valid(jogador):
		return
	var distancia := jogador.global_position.distance_to(centro)
	if absf(distancia - raio_atual) <= espessura * 0.6 + 13.0:
		if jogador.has_method("tomar_dano"):
			jogador.call("tomar_dano", dano)
		if intensidade_impulso != 0.0 and jogador is CharacterBody2D:
			var direcao := centro.direction_to(jogador.global_position)
			(jogador as CharacterBody2D).velocity += direcao * intensidade_impulso
		recarga = 0.42

func _draw() -> void:
	var local := tempo - atraso
	if local < 0.0:
		return
	if local < tempo_aviso:
		var progresso := clampf(local / maxf(tempo_aviso, 0.01), 0.0, 1.0)
		var alvo := lerpf(raio_inicial, raio_final, 0.2)
		draw_arc(centro, alvo, 0.0, TAU, 96, Color(cor, 0.22 + sin(local * 20.0) * 0.1), 3.0)
		draw_arc(centro, raio_inicial + progresso * 12.0, 0.0, TAU, 64, Color.WHITE, 2.0)
		return
	var fade := clampf((tempo_aviso + tempo_ativo - local) / 0.18, 0.0, 1.0)
	draw_arc(centro, raio_atual, 0.0, TAU, 112, Color(cor, 0.18 * fade), espessura + 20.0)
	draw_arc(centro, raio_atual, 0.0, TAU, 112, Color(cor, 0.76 * fade), espessura)
	draw_arc(centro, raio_atual, 0.0, TAU, 112, Color.WHITE, 3.0)
