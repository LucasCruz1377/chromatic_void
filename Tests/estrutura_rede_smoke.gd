extends Node

var falhas: Array[String] = []


func verificar(condicao: bool, mensagem: String) -> void:
	if not condicao:
		falhas.append(mensagem)
		push_error(mensagem)


func _ready() -> void:
	await testar_quadros_dos_chefes()
	await testar_especies()
	testar_pacotes_mundo()
	print(
		(
			"TESTE %s: estrutura, fragmentacao e autoridade de entidades"
			% ("OK" if falhas.is_empty() else "FALHOU")
		)
	)
	get_tree().quit(0 if falhas.is_empty() else 1)


func testar_quadros_dos_chefes() -> void:
	for nome in [
		"BossPet0",
		"BossFlorEquinocio",
		"BossEclipseColheita",
		"BossConstelacaoAmparo",
		"BossNoAmetista"
	]:
		var boss := (
			(load("res://Entities/%s.tscn" % nome) as PackedScene).instantiate() as ChefeBase
		)
		verificar(boss != null, nome + " nao herda ChefeBase")
		if boss == null:
			continue
		add_child(boss)
		await get_tree().process_frame
		boss.set_physics_process(false)
		var visual := Node2D.new()
		visual.name = "VisualRegressao"
		boss.add_child(visual)
		visual.rotation = 0.73
		var linha := Line2D.new()
		linha.name = "LinhaGrandeRegressao"
		visual.add_child(linha)
		for i in 256:
			linha.add_point(Vector2(i, i % 7))
		if boss is BossMensal:
			boss.angulo_visual = 1.5
		var snapshot := boss._capturar_snapshot_visual_boss(41)
		verificar(not snapshot.visuais.is_empty(), nome + " descartou o quadro visual grande")
		var partes := boss.dividir_snapshot_visual(snapshot)
		verificar(partes.size() > 1, nome + " nao fragmentou o quadro grande")
		for parte in partes:
			verificar(var_to_bytes(parte).size() < 1200, nome + " excedeu o MTU")
		visual.rotation = -0.5
		linha.clear_points()
		# Um peer cliente permite testar a aplicacao sem confiar em autoridade local.
		var peer := ENetMultiplayerPeer.new()
		verificar(peer.create_client("127.0.0.1", 24569) == OK, "cliente de regressao nao abriu")
		multiplayer.multiplayer_peer = peer
		Rede.modo_multiplayer = true
		partes.reverse()
		boss.receber_parte_snapshot_visual(partes[0])
		verificar(is_equal_approx(visual.rotation, -0.5), "quadro parcial alterou o chefe")
		for parte in partes:
			boss.receber_parte_snapshot_visual(parte)
		verificar(
			is_equal_approx(visual.rotation, 0.73),
			nome + " perdeu a rotacao com partes fora de ordem"
		)
		verificar(linha.points.size() == 256, nome + " perdeu os pontos da linha")
		if boss is BossMensal:
			var defesas: Dictionary = boss._capturar_estado_defesas_rede()
			defesas["sequencia"] = 1
			defesas["angulo_visual"] = 0.5
			boss.receber_estado_defesas_rede(defesas)
			verificar(is_equal_approx(boss.angulo_visual, 1.5), nome + " voltou ao angulo antigo")
		var vida := boss.Vida
		boss.receber_eco_laco(10.0)
		boss.morrer()
		verificar(
			boss.Vida == vida and not boss.is_queued_for_deletion(),
			nome + " alterou vida/morte no cliente"
		)
		for parte in partes:
			boss.receber_parte_snapshot_visual(parte)
		verificar(boss.partes_snapshot.is_empty(), "duplicatas deixaram fragmentos pendentes")
		Rede.modo_multiplayer = false
		peer.close()
		multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
		boss.queue_free()
		await get_tree().process_frame


func testar_especies() -> void:
	var total := 0
	for arquivo in DirAccess.get_files_at("res://Scripts"):
		if not arquivo.begins_with("Inimigo") or not arquivo.ends_with(".gd"):
			continue
		var script := load("res://Scripts/" + arquivo) as GDScript
		if script == null or not script.can_instantiate():
			continue
		var fonte := FileAccess.get_file_as_string("res://Scripts/" + arquivo)
		if not fonte.contains('extends "res://Scripts/InimigoSetorialBase.gd"'):
			continue
		var inimigo := script.new() as InimigoSetorialBase
		verificar(inimigo != null, arquivo + " nao usa a base setorial")
		add_child(inimigo)
		verificar(
			not inimigo.morre_ao_colidir_player, arquivo + " perdeu o comportamento de contato"
		)
		verificar(
			inimigo.get_meta("tipo_setorial") == int(inimigo.estilo),
			arquivo + " perdeu a identidade"
		)
		inimigo.queue_free()
		total += 1
	await get_tree().process_frame
	verificar(total == 25, "a base setorial nao cobre as 25 especies")


func testar_pacotes_mundo() -> void:
	var arena := load("res://Scripts/battle_area.gd").new() as Node2D
	var snapshot := {"sequencia": 19, "players": {}, "cristais_coop": 5, "inimigos": []}
	for id in range(1, 5):
		snapshot.players[id] = {"posicao": Vector2.ONE, "rotacao": 0.5, "velocidade": Vector2.ONE}
	for id in 100:
		snapshot.inimigos.append({"caminho": NodePath("Inimigo_%d" % id), "posicao": Vector2.ONE, "rotacao": 0.5, "velocidade": Vector2.ONE})
	var partes: Array[Dictionary] = arena.call("_dividir_posicoes_mundo", snapshot)
	var total := 0
	for parte in partes:
		verificar(var_to_bytes(parte).size() < 1200, "snapshot de mundo excedeu MTU com quatro pilotos")
		total += parte.inimigos.size()
	verificar(total == 100, "fragmentacao do mundo perdeu inimigos")
	arena.free()
