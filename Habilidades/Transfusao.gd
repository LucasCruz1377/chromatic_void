extends Habilidade
class_name HabilidadeTransfusao


@export_category("Transfusão")
@export_range(0.05, 0.80, 0.05) var custo_vida_maxima: float = 0.25
@export var dano: float = 15.0
@export var raio: float = 260.0
@export var forca_empurrao: float = 420.0


func pode_ativar(player) -> bool:
	if not super(player):
		return false
	return player.vida > player.VIDA_MAXIMA * custo_vida_maxima + 1.0


func executar(player) -> void:
	var custo = player.VIDA_MAXIMA * custo_vida_maxima
	if not player.sacrificar_vida(custo):
		return

	criar_pulso(player)
	var camera = player.get_tree().get_first_node_in_group("camera")
	if camera and camera.has_method("shake"):
		camera.shake(10.0)

	for inimigo in player.get_tree().get_nodes_in_group("inimigo"):
		if not is_instance_valid(inimigo) or not (inimigo is Node2D):
			continue
		var distancia = player.global_position.distance_to(inimigo.global_position)
		if distancia > raio:
			continue
		if inimigo.has_method("tomarDano"):
			inimigo.tomarDano(dano)
		var direcao = player.global_position.direction_to(inimigo.global_position)
		if inimigo.has_method("aplicar_empurrao"):
			inimigo.aplicar_empurrao(direcao * forca_empurrao)


func criar_pulso(player) -> void:
	var pulso := Line2D.new()
	pulso.width = 7.0
	pulso.default_color = Color(1.0, 0.05, 0.18, 0.92)
	pulso.closed = true
	pulso.antialiased = true
	pulso.z_index = 7
	var raio_inicial := 24.0

	for indice in range(56):
		var angulo := TAU * float(indice) / 56.0
		pulso.add_point(Vector2.from_angle(angulo) * raio_inicial)

	player.get_tree().current_scene.add_child(pulso)
	pulso.global_position = player.global_position
	var escala_final := raio / raio_inicial
	var tween := pulso.create_tween().set_parallel(true)
	tween.tween_property(pulso, "scale", Vector2.ONE * escala_final, 0.34)
	tween.tween_property(pulso, "modulate:a", 0.0, 0.34)
	tween.chain().tween_callback(pulso.queue_free)


func obter_upgrades_especificos() -> Dictionary:
	var icone := "res://Habilidades/Icones/transfusao.svg"
	var cor := Color(1.0, 0.08, 0.24)
	return {
		&"transfusao_dano": criar_carta_upgrade("PULSO HEMÁTICO", "+4 de dano em área.", icone, cor, Nome, 3, [&"dano"]),
		&"transfusao_alcance": criar_carta_upgrade("CÍRCULO SOLIDÁRIO", "+40 de raio da onda.", icone, cor, Nome, 3, [&"alcance"]),
		&"transfusao_eficiencia": criar_carta_upgrade("DOAÇÃO EFICIENTE", "Reduz o custo em 3% da vida máxima.", icone, cor, Nome, 3, [&"vida"]),
	}


func aplicar_upgrade_especifico(id: StringName, _nivel: int) -> bool:
	match id:
		&"transfusao_dano": dano += 4.0
		&"transfusao_alcance": raio += 40.0
		&"transfusao_eficiencia": custo_vida_maxima = maxf(custo_vida_maxima - 0.03, 0.10)
		_: return false
	return true
