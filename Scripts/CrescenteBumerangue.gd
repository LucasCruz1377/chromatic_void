extends Node2D
class_name CrescenteBumerangue

var origem: Node2D
var direcao := Vector2.RIGHT
var velocidade := 330.0
var dano := 8.0
var cor := Color(0.7, 0.82, 1.0)
var tempo := 0.0
var atingiu := false

static func criar(cena: Node, dono: Node2D, dir: Vector2, dano_fx: float, cor_fx: Color) -> CrescenteBumerangue:
	var c := CrescenteBumerangue.new(); c.origem = dono; c.direcao = dir.normalized(); c.dano = dano_fx; c.cor = cor_fx
	c.global_position = dono.global_position; c.z_index = 2; cena.add_child(c); return c

func _process(delta: float) -> void:
	tempo += delta; rotation += delta * 8.0
	if tempo < 0.72: global_position += direcao * velocidade * delta
	elif is_instance_valid(origem):
		var volta := global_position.direction_to(origem.global_position)
		global_position += volta * velocidade * 1.2 * delta
		if global_position.distance_to(origem.global_position) < 22.0: queue_free(); return
	else: queue_free(); return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if not atingiu and is_instance_valid(player) and global_position.distance_to(player.global_position) < 22.0:
		atingiu = true
		if player.has_method("tomar_dano"): player.call("tomar_dano", dano)
	queue_redraw()

func _draw() -> void:
	draw_arc(Vector2.ZERO, 13.0, -1.25, 1.25, 20, cor, 6.0, true)
	draw_circle(Vector2(5, 0), 9.0, Color(0.01, 0.015, 0.05))
