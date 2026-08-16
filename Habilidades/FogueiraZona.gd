extends Node2D
class_name FogueiraZona


var duracao := 8.0
var raio := 95.0
var dano_por_segundo := 3.5
var intervalo_dano := 0.45
var tempo_dano := 0.0
var pulso := 0.0
var cor := Color(1.0, 0.36, 0.08, 0.9)


func configurar(
	nova_posicao: Vector2,
	nova_duracao: float,
	novo_raio: float,
	novo_dano_por_segundo: float
) -> void:
	global_position = nova_posicao
	duracao = nova_duracao
	raio = novo_raio
	dano_por_segundo = novo_dano_por_segundo


func _ready() -> void:
	z_index = 2
	queue_redraw()


func _process(delta: float) -> void:
	duracao -= delta
	tempo_dano -= delta
	pulso += delta * 8.0
	queue_redraw()

	if tempo_dano <= 0.0:
		tempo_dano = intervalo_dano
		queimar_inimigos()

	if duracao <= 0.0:
		queue_free()


func queimar_inimigos() -> void:
	for inimigo in get_tree().get_nodes_in_group("inimigo"):
		if not is_instance_valid(inimigo) or not (inimigo is Node2D):
			continue
		if global_position.distance_to(inimigo.global_position) > raio:
			continue
		if inimigo.has_method("tomarDano"):
			inimigo.tomarDano(dano_por_segundo * intervalo_dano)


func _draw() -> void:
	var oscilacao := 1.0 + sin(pulso) * 0.06
	draw_circle(Vector2.ZERO, raio, Color(1.0, 0.20, 0.04, 0.055))
	draw_arc(Vector2.ZERO, raio, 0.0, TAU, 54, Color(1.0, 0.48, 0.10, 0.48), 2.0)

	var chama := PackedVector2Array([
		Vector2(-15.0, 16.0),
		Vector2(-11.0, -4.0) * oscilacao,
		Vector2(-3.0, 3.0),
		Vector2(2.0, -24.0) * oscilacao,
		Vector2(9.0, -5.0),
		Vector2(16.0, 16.0),
	])
	draw_colored_polygon(chama, cor)
	draw_circle(Vector2(2.0, 8.0), 7.0, Color(1.0, 0.86, 0.20, 0.95))
	draw_line(Vector2(-18.0, 19.0), Vector2(18.0, 25.0), Color(0.48, 0.18, 0.05), 5.0)
	draw_line(Vector2(18.0, 19.0), Vector2(-18.0, 25.0), Color(0.48, 0.18, 0.05), 5.0)
