extends Habilidade
class_name HabilidadeShockwave


@export_category("Onda de Choque")
@export var raio: float = 170.0
@export var dano: float = 5.0
@export var forca_empurrao: float = 550.0
@export var duracao_atordoamento: float = 0.75


func executar(player) -> void:
	criar_efeito_visual(player)
	var camera = player.get_tree().get_first_node_in_group("camera")
	if camera and camera.has_method("shake"):
		camera.shake(7.0)
	for inimigo in player.get_tree().get_nodes_in_group("inimigo"):
		if not is_instance_valid(inimigo):
			continue
		var distancia = player.global_position.distance_to(inimigo.global_position)
		if distancia > raio:
			continue
		var direcao = (inimigo.global_position - player.global_position).normalized()
		if direcao.is_zero_approx():
			direcao = Vector2.RIGHT.rotated(randf() * TAU)
		if inimigo.has_method("tomarDano"):
			inimigo.tomarDano(dano)
		if inimigo.has_method("aplicar_atordoamento"):
			inimigo.aplicar_atordoamento(duracao_atordoamento)
		var empurrao = direcao * forca_empurrao
		if inimigo.has_method("aplicar_empurrao"):
			inimigo.aplicar_empurrao(empurrao)
		elif inimigo is CharacterBody2D:
			inimigo.velocity += empurrao


func criar_efeito_visual(player) -> void:
	var onda := Line2D.new()
	var segmentos := 48
	var raio_inicial := 24.0
	onda.width = 5.0
	onda.default_color = Color(0.35, 0.88, 1.0, 0.9)
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


func obter_upgrades_especificos() -> Dictionary:
	var icone := "res://Habilidades/Icones/onda_choque.svg"
	var cor := Color(0.22, 0.82, 1.0)
	return {
		&"onda_dano": criar_carta_upgrade("PULSO DE POTÊNCIA", "+2 de dano da onda.", icone, cor, Nome, 3, [&"dano"]),
		&"onda_alcance": criar_carta_upgrade("ANEL EXPANSIVO", "+30 de raio da onda.", icone, cor, Nome, 3, [&"alcance"]),
		&"onda_impacto": criar_carta_upgrade("RESSONÂNCIA", "+0,2 s de atordoamento e +100 de empurrão.", icone, cor, Nome, 3, [&"controle"]),
	}


func aplicar_upgrade_especifico(id: StringName, _nivel: int) -> bool:
	match id:
		&"onda_dano": dano += 2.0
		&"onda_alcance": raio += 30.0
		&"onda_impacto":
			duracao_atordoamento += 0.2
			forca_empurrao += 100.0
		_: return false
	return true
