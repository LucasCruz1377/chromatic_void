extends Node2D
class_name RastroCarnaval


var raio := 30.0
var dano := 0.5
var cor := Color(1.0, 0.25, 0.82, 0.75)


func configurar(
	nova_posicao: Vector2,
	novo_dano: float,
	nova_cor: Color,
	novo_raio := 30.0
) -> void:
	global_position = nova_posicao
	dano = maxf(novo_dano, 0.0)
	cor = nova_cor
	raio = maxf(novo_raio, 8.0)


func _ready() -> void:
	z_index = 3
	aplicar_dano()
	queue_redraw()

	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ONE * 1.65, 0.48)
	tween.tween_property(self, "modulate:a", 0.0, 0.48)
	tween.chain().tween_callback(queue_free)


func aplicar_dano() -> void:
	for inimigo in get_tree().get_nodes_in_group("inimigo"):
		if not is_instance_valid(inimigo) or not (inimigo is Node2D):
			continue
		if global_position.distance_to(inimigo.global_position) > raio:
			continue
		if inimigo.has_method("tomarDano"):
			inimigo.tomarDano(dano)


func _draw() -> void:
	draw_circle(Vector2.ZERO, raio, Color(cor.r, cor.g, cor.b, 0.10))
	draw_arc(Vector2.ZERO, raio, 0.0, TAU, 28, cor, 2.5, true)
	for indice in range(6):
		var angulo := TAU * float(indice) / 6.0
		var ponto := Vector2.from_angle(angulo) * raio * 0.68
		draw_circle(ponto, 2.5, cor.lightened(0.22))
