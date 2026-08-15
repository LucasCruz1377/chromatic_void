extends Habilidade
class_name HabilidadeShockwave


@export_category("Onda de Choque")
@export var raio: float = 170.0
@export var dano: float = 5.0
@export var forca_empurrao: float = 550.0
@export var duracao_atordoamento: float = 0.75


func executar(player) -> void:
	criar_efeito_visual(player)

	var camera := player.get_tree().get_first_node_in_group("camera")
	if camera and camera.has_method("shake"):
		camera.shake(7.0)

	for inimigo in player.get_tree().get_nodes_in_group("inimigo"):
		if not is_instance_valid(inimigo):
			continue

		var distancia := player.global_position.distance_to(inimigo.global_position)
		if distancia > raio:
			continue

		var direcao := (inimigo.global_position - player.global_position).normalized()
		if direcao.is_zero_approx():
			direcao = Vector2.RIGHT.rotated(randf() * TAU)

		if inimigo.has_method("tomarDano"):
			inimigo.tomarDano(dano)

		if inimigo.has_method("aplicar_atordoamento"):
			inimigo.aplicar_atordoamento(duracao_atordoamento)

		var empurrao := direcao * forca_empurrao
		if inimigo.has_method("aplicar_empurrao"):
			inimigo.aplicar_empurrao(empurrao)
		elif inimigo is CharacterBody2D:
			inimigo.velocity += empurrao


func criar_efeito_visual(player) -> void:
	var onda := Line2D.new()
	var segmentos := 48
	var raio_inicial := 24.0

	onda.width = 5.0
	onda.default_color = Color(1.0, 0.85, 0.25, 0.9)
	onda.closed = true
	onda.antialiased = true
	onda.z_index = 5

	for indice in range(segmentos):
		var angulo := TAU * float(indice) / float(segmentos)
		onda.add_point(Vector2.from_angle(angulo) * raio_inicial)

	player.get_tree().current_scene.add_child(onda)
	onda.global_position = player.global_position

	var escala_final := raio / raio_inicial
	var tween := onda.create_tween()
	tween.tween_property(onda, "scale", Vector2.ONE * escala_final, 0.28)
	tween.parallel().tween_property(onda, "modulate:a", 0.0, 0.28)
	tween.tween_callback(onda.queue_free)
