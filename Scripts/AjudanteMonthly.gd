extends Node2D
class_name AjudanteMonthly


enum Tipo { CLONE, GUARDIAO, DRONE_OVO }

var tipo: Tipo = Tipo.CLONE
var dono: Node2D
var cor := Color.WHITE
var potencia := 1.0
var tempo_restante := 7.0
var tempo_disparo := 0.32
var fase := 0.0
var historico: Array[Dictionary] = []
var ultimo_angulo := 0.0
var dano_drone_ovo := 0.8


func configurar(dono_ref: Node2D, tipo_ref: Tipo, cor_ref: Color, potencia_ref: float) -> void:
	dono = dono_ref
	tipo = tipo_ref
	cor = cor_ref
	potencia = maxf(potencia_ref, 0.25)
	tempo_restante = 6.5 if tipo == Tipo.CLONE else 7.5
	global_position = dono.global_position
	ultimo_angulo = dono.global_rotation
	z_index = 2
	queue_redraw()


func configurar_drone_ovo(dono_ref: Node2D, cor_ref: Color, dano_ref: float, duracao_ref: float) -> void:
	configurar(dono_ref, Tipo.DRONE_OVO, cor_ref, 1.0)
	dano_drone_ovo = maxf(dano_ref, 0.1)
	tempo_restante = maxf(duracao_ref, 1.0)
	tempo_disparo = 0.15


func _process(delta: float) -> void:
	if not is_instance_valid(dono):
		queue_free()
		return
	tempo_restante -= delta
	if tempo_restante <= 0.0:
		queue_free()
		return
	fase += delta
	tempo_disparo -= delta
	if tipo == Tipo.CLONE:
		_processar_clone(delta)
	elif tipo == Tipo.GUARDIAO:
		_processar_guardiao(delta)
	else:
		_processar_drone_ovo(delta)
	modulate.a = clampf(tempo_restante * 2.0, 0.0, 1.0)
	queue_redraw()


func _processar_clone(_delta: float) -> void:
	historico.append({"posicao": dono.global_position, "angulo": dono.global_rotation})
	if historico.size() > 28:
		var amostra: Dictionary = historico.pop_front()
		global_position = amostra.get("posicao", dono.global_position)
		ultimo_angulo = float(amostra.get("angulo", dono.global_rotation))
		global_rotation = ultimo_angulo
	if tempo_disparo <= 0.0:
		tempo_disparo = 0.48
		if dono.has_method("criar_projetil"):
			dono.call("criar_projetil", ultimo_angulo, 0.72 * potencia, true, null, 0.0, &"clone", cor, {"velocidade": 0.92, "origem_global": global_position + Vector2.from_angle(ultimo_angulo) * 17.0})
		_pulso(0.62)


func _processar_guardiao(_delta: float) -> void:
	var angulo := fase * 2.45
	global_position = dono.global_position + Vector2.from_angle(angulo) * 54.0
	global_rotation = angulo + PI * 0.5
	var interceptou := false
	for node in get_tree().get_nodes_in_group("projetil_inimigo"):
		if node is Node2D and is_instance_valid(node):
			var projetil := node as Node2D
			if global_position.distance_squared_to(projetil.global_position) <= 34.0 * 34.0:
				projetil.queue_free()
				interceptou = true
				break
	if interceptou:
		_pulso(1.0)
		tempo_disparo = minf(tempo_disparo, 0.0)
	if tempo_disparo <= 0.0:
		var alvo := _inimigo_proximo()
		if is_instance_valid(alvo) and dono.has_method("criar_projetil"):
			var angulo_tiro := global_position.angle_to_point(alvo.global_position)
			dono.call("criar_projetil", angulo_tiro, 0.58 * potencia, true, null, 0.0, &"guardian", cor, {"velocidade": 1.05, "origem_global": global_position})
			tempo_disparo = 0.72


func _processar_drone_ovo(_delta: float) -> void:
	var angulo := fase * 1.9
	global_position = dono.global_position + Vector2.from_angle(angulo) * 66.0
	global_rotation = global_position.angle_to_point(_inimigo_proximo().global_position) if is_instance_valid(_inimigo_proximo()) else angulo
	if tempo_disparo <= 0.0:
		var alvo := _inimigo_proximo()
		if is_instance_valid(alvo) and dono.has_method("criar_projetil"):
			dono.call("criar_projetil", global_position.angle_to_point(alvo.global_position), dano_drone_ovo, true, alvo, 0.0, &"egg", cor, {"homing": 2.2, "origem_global": global_position})
			_pulso(0.72)
		tempo_disparo = 0.58


func _inimigo_proximo() -> Node2D:
	var melhor: Node2D
	var menor := 360.0 * 360.0
	for node in get_tree().get_nodes_in_group("inimigo"):
		if node is Node2D and is_instance_valid(node):
			var candidato := node as Node2D
			var distancia := global_position.distance_squared_to(candidato.global_position)
			if distancia < menor:
				menor = distancia
				melhor = candidato
	return melhor


func _pulso(escala: float) -> void:
	var efeito := preload("res://Scripts/EfeitoCombate.gd")
	efeito.criar(get_tree().current_scene, global_position, EfeitoCombate.Tipo.ACERTO, cor, escala)


func _draw() -> void:
	var brilho := cor * 1.45
	brilho.a = 1.0
	if tipo == Tipo.CLONE:
		var corpo := PackedVector2Array([
			Vector2(20, 0), Vector2(-13, -12), Vector2(-7, 0), Vector2(-13, 12)
		])
		draw_colored_polygon(corpo, Color(brilho, 0.72))
		draw_polyline(corpo + PackedVector2Array([corpo[0]]), brilho, 2.0)
		draw_circle(Vector2(-3, 0), 4.0, Color.WHITE)
	elif tipo == Tipo.GUARDIAO:
		var raio := 15.0 + sin(fase * 7.0) * 1.5
		draw_arc(Vector2.ZERO, raio, 0.0, TAU, 24, brilho, 3.0)
		draw_circle(Vector2.ZERO, 7.0, cor)
		for indice in range(3):
			var ponto := Vector2.from_angle(fase * 1.8 + TAU * float(indice) / 3.0) * 20.0
			draw_circle(ponto, 3.0, Color.WHITE)
	else:
		draw_circle(Vector2.ZERO, 18.0, Color(cor, 0.18))
		draw_colored_polygon(PackedVector2Array([Vector2(15, 0), Vector2(-9, -11), Vector2(-14, 0), Vector2(-9, 11)]), cor)
		draw_polyline(PackedVector2Array([Vector2(15, 0), Vector2(-9, -11), Vector2(-14, 0), Vector2(-9, 11), Vector2(15, 0)]), brilho, 2.0)
		draw_circle(Vector2(2, 0), 4.0, Color.WHITE)
