extends CharacterBody2D
class_name LacoUniaoAlvo


const EfeitoCombateCena = preload("res://Scripts/EfeitoCombate.gd")
const ExplosaoMonthlyCena = preload("res://Scripts/MonthlyBurst.gd")

var alvos: Array[Node2D] = []
var cor := Color("ff5b8d")
var vida := 14.0
var tempo_restante := 9.0
var fase := 0.0


func configurar(posicao: Vector2, alvos_ref: Array[Node2D], cor_ref: Color, potencia: float) -> void:
	global_position = posicao
	alvos.clear()
	alvos.append_array(alvos_ref)
	cor = cor_ref
	vida = 14.0 + 6.0 * potencia
	collision_layer = 4
	collision_mask = 9
	z_index = 3
	var forma := CollisionShape2D.new()
	var circulo := CircleShape2D.new()
	circulo.radius = 22.0
	forma.shape = circulo
	add_child(forma)
	queue_redraw()


func _process(delta: float) -> void:
	fase += delta
	tempo_restante -= delta
	# Array.filter() perde a tipagem em runtime. Reconstruir a lista tipada evita
	# o erro "Array" -> "Array[Node2D]" quando um inimigo deixa a árvore.
	var alvos_validos: Array[Node2D] = []
	for alvo in alvos:
		if is_instance_valid(alvo) and not alvo.is_queued_for_deletion():
			alvos_validos.append(alvo)
	alvos = alvos_validos
	queue_redraw()
	if tempo_restante <= 0.0 or alvos.is_empty():
		queue_free()


func tomarDano(valor: float) -> void:
	vida -= maxf(valor, 0.0)
	EfeitoCombateCena.criar(get_tree().current_scene, global_position, EfeitoCombate.Tipo.ACERTO, cor, 0.65)
	if vida <= 0.0:
		_romper()


func _romper() -> void:
	for alvo in alvos:
		if not is_instance_valid(alvo) or not alvo.has_method("tomarDano"):
			continue
		if alvo.is_in_group("boss"):
			alvo.call("tomarDano", 45.0)
		else:
			var vida_alvo: Variant = alvo.get("Vida")
			alvo.call("tomarDano", float(vida_alvo) + 1.0)
		ExplosaoMonthlyCena.criar(get_tree().current_scene, alvo.global_position, cor, 0.85, &"laco")
	ExplosaoMonthlyCena.criar(get_tree().current_scene, global_position, cor, 2.2, &"laco")
	queue_free()


func _draw() -> void:
	for alvo in alvos:
		if is_instance_valid(alvo):
			var ponto := to_local(alvo.global_position)
			draw_line(Vector2.ZERO, ponto, Color(cor, 0.18), 8.0)
			draw_line(Vector2.ZERO, ponto, cor, 2.0)
	var pulso := 1.0 + sin(fase * 7.0) * 0.08
	draw_circle(Vector2.ZERO, 27.0 * pulso, Color(cor, 0.18))
	draw_arc(Vector2.ZERO, 23.0 * pulso, 0.0, TAU, 24, cor.lightened(0.35), 3.0)
	# Laço central bem definido: duas alças, nó luminoso e duas fitas inferiores.
	draw_arc(Vector2(-10, -2), 13.0 * pulso, -2.55, 0.72, 18, cor.lightened(0.28), 5.0)
	draw_arc(Vector2(10, -2), 13.0 * pulso, 2.42, 5.70, 18, cor.lightened(0.28), 5.0)
	var fita_esquerda := PackedVector2Array([
		Vector2(-4, 4), Vector2(-20, 25), Vector2(-8, 21), Vector2(0, 6)
	])
	var fita_direita := PackedVector2Array([
		Vector2(4, 4), Vector2(20, 25), Vector2(8, 21), Vector2(0, 6)
	])
	draw_colored_polygon(fita_esquerda, Color(cor, 0.92))
	draw_colored_polygon(fita_direita, Color(cor, 0.92))
	draw_circle(Vector2.ZERO, 10.0 * pulso, Color(cor, 0.28))
	draw_circle(Vector2.ZERO, 6.5 * pulso, Color.WHITE)
