extends Node2D
class_name PerigoSetorial

enum Forma { LINHA, CIRCULO, PUXAO }
var forma := Forma.LINHA
var a := Vector2.ZERO
var b := Vector2.ZERO
var raio := 50.0
var largura := 14.0
var cor := Color.WHITE
var aviso := 0.7
var ativo := 0.2
var dano := 10.0
var forca := 0.0
var tempo := 0.0
var recarga := 0.0

static func criar(cena: Node, tipo: Forma, inicio: Vector2, fim: Vector2, cor_fx: Color, tempo_aviso: float, tempo_ativo: float, dano_fx: float, tamanho: float, forca_fx := 0.0) -> PerigoSetorial:
	if not is_instance_valid(cena) or cena.is_queued_for_deletion():
		return null
	var p := PerigoSetorial.new()
	p.forma = tipo; p.a = inicio; p.b = fim; p.cor = cor_fx
	p.aviso = tempo_aviso; p.ativo = tempo_ativo; p.dano = dano_fx
	p.raio = tamanho; p.largura = tamanho; p.forca = forca_fx; p.z_index = 2
	cena.add_child(p)
	return p

func _process(delta: float) -> void:
	tempo += delta; recarga = maxf(0.0, recarga - delta); queue_redraw()
	if tempo >= aviso and tempo < aviso + ativo: _aplicar(delta)
	elif tempo >= aviso + ativo + 0.18: queue_free()

func _aplicar(delta: float) -> void:
	var alvo := get_tree().get_first_node_in_group("player") as Node2D
	if not is_instance_valid(alvo): return
	var dentro := false
	if forma == Forma.LINHA: dentro = _distancia_segmento(alvo.global_position, a, b) <= largura * 0.5
	else: dentro = alvo.global_position.distance_to(a) <= raio
	if not dentro: return
	if forma == Forma.PUXAO:
		if forca > 0.0: alvo.global_position += alvo.global_position.direction_to(a) * forca * delta
		elif alvo.get("velocity") != null: alvo.set("velocity", Vector2(alvo.get("velocity")) * pow(0.78, delta * 10.0))
	if recarga <= 0.0 and alvo.has_method("tomar_dano"):
		alvo.call("tomar_dano", dano); recarga = 0.4 if forma == Forma.PUXAO else ativo + 0.1

func _draw() -> void:
	var ligado := tempo >= aviso
	var alpha := 0.95 if ligado else 0.3 + absf(sin(tempo * 15.0)) * 0.55
	alpha *= 1.0 - clampf((tempo - aviso - ativo) / 0.18, 0.0, 1.0)
	if forma == Forma.LINHA:
		if not ligado:
			var lateral := (b - a).normalized().orthogonal() * largura * 0.5
			draw_line(a, b, Color(cor, 0.12), largura, true)
			draw_line(a + lateral, b + lateral, Color(cor, 0.5), 1.0, true)
			draw_line(a - lateral, b - lateral, Color(cor, 0.5), 1.0, true)
			draw_circle(a.lerp(b, clampf(tempo / maxf(aviso, 0.01), 0.0, 1.0)), 4.0, Color.WHITE)
		draw_line(a, b, Color(cor, alpha), largura if ligado else 3.0, true)
		if not ligado: draw_line(a, b, Color(1,1,1,0.7), 1.0, true)
	else:
		if not ligado:
			draw_arc(a, raio + 5.0, -PI / 2.0, -PI / 2.0 + TAU * clampf(tempo / maxf(aviso, 0.01), 0.0, 1.0), 48, Color.WHITE, 2.0, true)
		draw_circle(a, raio, Color(cor, 0.28 if ligado else 0.08))
		draw_arc(a, raio, 0, TAU, 64, Color(cor, alpha), 5.0 if ligado else 2.0, true)

func _distancia_segmento(p: Vector2, inicio: Vector2, fim: Vector2) -> float:
	var segmento := fim - inicio
	if segmento.length_squared() < 0.01: return p.distance_to(inicio)
	var fator := clampf((p - inicio).dot(segmento) / segmento.length_squared(), 0.0, 1.0)
	return p.distance_to(inicio + segmento * fator)
