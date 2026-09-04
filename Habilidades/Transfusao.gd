extends Habilidade
class_name HabilidadeTransfusao


@export_category("Transfusão")
@export var dano_dreno: float = 28.0
@export var alcance: float = 420.0
@export_range(0.10, 1.0, 0.05) var fator_roubo: float = 0.65


func pode_ativar(player) -> bool:
	return super(player) and is_instance_valid(obter_alvo(player))


func executar(player) -> void:
	var alvo := obter_alvo(player)
	if not is_instance_valid(alvo):
		return

	var origem := (alvo as Node2D).global_position
	var destino := (player as Node2D).global_position
	var vida_antes := ler_vida(alvo)
	criar_fluxo_vital(player, origem, destino)
	alvo.call("tomarDano", dano_dreno)

	var vida_depois := ler_vida(alvo)
	var dano_real := dano_dreno
	if vida_antes >= 0.0:
		if vida_depois >= 0.0 and vida_depois <= vida_antes:
			dano_real = vida_antes - vida_depois
		else:
			dano_real = minf(dano_dreno, vida_antes)
	player.curar(maxf(dano_real, 0.0) * fator_roubo)

	var camera := player.get_tree().get_first_node_in_group("camera") as Camera2D
	if is_instance_valid(camera) and camera.has_method("shake"):
		camera.shake(5.5)
	Global.vibrar_controle(0.22, 0.48, 0.16)


func obter_alvo(player) -> Node2D:
	if not is_instance_valid(player) or not (player is Node2D):
		return null
	var jogador := player as Node2D
	var melhor_alvo: Node2D
	var menor_distancia_quadrada := alcance * alcance
	for candidato in jogador.get_tree().get_nodes_in_group("inimigo"):
		if (
			not is_instance_valid(candidato)
			or not (candidato is Node2D)
			or not candidato.has_method("tomarDano")
		):
			continue
		var alvo := candidato as Node2D
		var distancia_quadrada := jogador.global_position.distance_squared_to(
			alvo.global_position
		)
		if distancia_quadrada <= menor_distancia_quadrada:
			menor_distancia_quadrada = distancia_quadrada
			melhor_alvo = alvo
	return melhor_alvo


func ler_vida(alvo: Object) -> float:
	if not is_instance_valid(alvo):
		return -1.0
	var valor: Variant = alvo.get("Vida")
	return float(valor) if valor != null else -1.0


func criar_fluxo_vital(player, origem: Vector2, destino: Vector2) -> void:
	var jogador := player as Node
	var cena := jogador.get_tree().current_scene
	if not is_instance_valid(cena):
		return

	var efeito := Node2D.new()
	efeito.name = "FluxoTransfusao"
	efeito.z_index = 12
	cena.add_child(efeito)

	var direcao := origem.direction_to(destino)
	var perpendicular := direcao.orthogonal()
	for indice in range(3):
		var deslocamento := float(indice - 1) * 13.0
		var linha := Line2D.new()
		linha.width = 5.0 - absf(deslocamento) * 0.10
		linha.default_color = Color(1.0, 0.04, 0.22, 0.90)
		linha.antialiased = true
		linha.add_point(origem + perpendicular * deslocamento)
		linha.add_point(origem.lerp(destino, 0.45) - perpendicular * deslocamento * 0.65)
		linha.add_point(origem.lerp(destino, 0.78) + perpendicular * deslocamento * 0.35)
		linha.add_point(destino)
		efeito.add_child(linha)

	var nucleo := Polygon2D.new()
	nucleo.polygon = criar_circulo(11.0, 18)
	nucleo.color = Color(1.0, 0.12, 0.30, 1.0)
	nucleo.global_position = origem
	efeito.add_child(nucleo)

	var tween_movimento := efeito.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween_movimento.tween_property(nucleo, "global_position", destino, 0.32)
	var tween_sumico := efeito.create_tween().set_parallel(true)
	tween_sumico.tween_property(efeito, "modulate:a", 0.0, 0.42)
	tween_sumico.chain().tween_callback(efeito.queue_free)


func criar_circulo(raio: float, lados: int) -> PackedVector2Array:
	var pontos := PackedVector2Array()
	for indice in range(lados):
		pontos.append(Vector2.from_angle(TAU * float(indice) / float(lados)) * raio)
	return pontos


func obter_upgrades_especificos() -> Dictionary:
	var icone := "res://Habilidades/Icones/transfusao.svg"
	var cor := Color(1.0, 0.08, 0.24)
	return {
		&"transfusao_dano": criar_carta_upgrade("DRENAGEM PROFUNDA", "+6 de dano roubado do alvo.", icone, cor, Nome, 3, [&"dano"]),
		&"transfusao_alcance": criar_carta_upgrade("VEIA CROMÁTICA", "+55 de alcance para escolher o inimigo.", icone, cor, Nome, 3, [&"alcance"]),
		&"transfusao_eficiencia": criar_carta_upgrade("CICLO VITAL", "+12% do dano convertido em cura.", icone, cor, Nome, 3, [&"vida"]),
	}


func aplicar_upgrade_especifico(id: StringName, _nivel: int) -> bool:
	match id:
		&"transfusao_dano": dano_dreno += 6.0
		&"transfusao_alcance": alcance += 55.0
		&"transfusao_eficiencia": fator_roubo = minf(fator_roubo + 0.12, 1.0)
		_: return false
	return true
