extends Node


var maior_lista_recebida := 0
var papel := ""
var batalha: Node2D


func _ready() -> void:
	Rede.lobby_alterado.connect(_on_lobby_alterado)
	for argumento in OS.get_cmdline_user_args():
		if argumento.begins_with("--lobby-role="):
			papel = argumento.trim_prefix("--lobby-role=")
	if papel.is_empty():
		print("TESTE IGNORADO: execute host e client em processos separados")
		get_tree().quit(0)
		return
	Rede.configuracao_teste = _configuracao_teste_local()
	if papel == "host":
		if Rede.criar_lobby("HOST_TESTE") != OK:
			get_tree().quit(1)
			return
	else:
		await get_tree().create_timer(0.35).timeout
		if Rede.entrar_lobby("127.0.0.1", "CLIENTE_TESTE") != OK:
			get_tree().quit(1)
			return
	var limite := 6.0
	while limite > 0.0 and maior_lista_recebida < 2:
		await get_tree().create_timer(0.05).timeout
		limite -= 0.05
	if maior_lista_recebida != 2:
		_falhar("lista do lobby não chegou aos dois peers")
		return
	batalha = (load("res://Rooms/Battle_area.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(batalha)
	batalha.tutorial_ativo = false
	if not await _esperar_jogadores_reais():
		_falhar("MultiplayerSpawner não criou os dois Players reais")
		return
	var local: Player
	for candidato in get_tree().get_nodes_in_group("player"):
		if candidato is Player and candidato.peer_id_dono == Rede.peer_local():
			local = candidato
			break
	if not is_instance_valid(local):
		_falhar("não encontrou a nave controlada pelo peer local")
		return
	if not _personalizacoes_distintas_corretas():
		_falhar("modelo, cor, habilidade ou nickname colorido não preservou o loadout individual")
		return
	local.global_position = Vector2(240.0, 220.0) if papel == "host" else Vector2(720.0, 320.0)
	if papel == "host":
		batalha.spawnar_enemy()
		await get_tree().process_frame
		var inimigos_host := get_tree().get_nodes_in_group("inimigo")
		if not inimigos_host.is_empty():
			(inimigos_host[0] as Node2D).global_position = Vector2(480.0, 120.0)
	if not await _esperar_mundo_sincronizado():
		_falhar("posição dos Players ou inimigos não foi sincronizada")
		return
	var inimigo_teste := get_tree().get_nodes_in_group("inimigo")[0] as InimigoBase
	if papel == "host":
		inimigo_teste.Dano = 0.0
	var vida_esperada := inimigo_teste.VidaMaxima - 0.4
	if papel == "client":
		inimigo_teste.tomarDano(0.5)
	if not await _esperar_vida_inimigo(vida_esperada):
		_falhar("dano do cliente não chegou ao host ou a vida não voltou sincronizada")
		return
	local.criar_projetil(local.rotation, 1.0)
	if not await _esperar_visual_rede("TiroVisual_"):
		_falhar("tiro real do outro Player não apareceu visualmente")
		return
	if not await _esperar_estado_disparo_rede():
		_falhar("posição contínua do ataque não foi recebida do outro peer")
		return
	batalha.replicar_habilidade_player({
		"peer_id": Rede.peer_local(),
		"monthly": true,
		"efeito_id": &"tempestade",
		"cor": Color(0.3, 1.0, 0.48),
		"potencia": 1.0,
		"config": {"duracao": 7.0, "dano": 5.0, "semente_visual": 77331},
	})
	if not await _esperar_efeito_habilidade_rede():
		_falhar("habilidade do outro Player não apareceu visualmente")
		return
	batalha.replicar_habilidade_player({
		"peer_id": Rede.peer_local(),
		"monthly": true,
		"efeito_id": &"clone",
		"cor": Color(0.95, 0.35, 0.72),
		"potencia": 1.0,
		"config": {"semente_visual": 31415},
	})
	if not await _esperar_ajudante_visual_rede():
		_falhar("ajudante/partículas da habilidade não apareceram no outro peer")
		return
	EfeitoCombate.criar(
		batalha,
		Vector2(310.0, 160.0) if papel == "host" else Vector2(650.0, 380.0),
		EfeitoCombate.Tipo.MORTE,
		Color(0.4, 0.9, 1.0), 1.1
	)
	if not await _esperar_feedback_visual_rede():
		_falhar("feedback/partícula descartável não foi replicado")
		return
	local.niveis_upgrades[&"dano_calibrado" if papel == "host" else &"cadencia"] = 1
	local.call("_sincronizar_loadout_rede")
	if not await _esperar_upgrades_loadout_remoto():
		_falhar("upgrades individuais não foram publicados no loadout remoto")
		return
	if papel == "host":
		inimigo_teste.conceder_recompensa()
		inimigo_teste.conceder_recompensa()
	if not await _esperar_upgrade_compartilhado(local):
		_falhar("XP compartilhado não concedeu a mesma melhoria")
		return
	var menu := batalha.get_node("GUI/TelaUpgrades") as Control
	if bool(menu.call("esta_aberta")):
		_falhar("menu de melhorias abriu sem decisão do jogador")
		return
	menu.call("abrir_menu")
	if not bool(menu.call("esta_aberta")) or not is_equal_approx(Engine.time_scale, 1.0):
		_falhar("menu individual não abriu ou pausou a partida compartilhada")
		return
	await get_tree().process_frame
	menu.call("fechar_menu")
	if papel == "client":
		local.morrer()
	if not await _esperar_morte_individual(local):
		_falhar("morte individual encerrou a partida ou não abriu espera")
		return
	print("TESTE OK: %s sincronizou posições, partículas, loadouts, XP, menu e morte" % papel)
	await get_tree().create_timer(3.0).timeout
	Rede.encerrar_lobby()
	get_tree().quit(0)


func _esperar_jogadores_reais() -> bool:
	var limite := 6.0
	while limite > 0.0:
		var jogadores := get_tree().get_nodes_in_group("player")
		if jogadores.size() == 2:
			var validos := true
			for jogador in jogadores:
				validos = validos and jogador is Player
				validos = validos and jogador.get_node_or_null("MultiplayerSynchronizer") != null
				validos = validos and jogador.get_node_or_null("NicknameRede") != null
			if validos:
				return true
		await get_tree().create_timer(0.05).timeout
		limite -= 0.05
	return false


func _esperar_vida_inimigo(vida_maxima_esperada: float) -> bool:
	var limite := 4.0
	while limite > 0.0:
		for inimigo in get_tree().get_nodes_in_group("inimigo"):
			if inimigo is InimigoBase and inimigo.Vida <= vida_maxima_esperada:
				return true
		await get_tree().create_timer(0.05).timeout
		limite -= 0.05
	return false


func _esperar_mundo_sincronizado() -> bool:
	var limite := 6.0
	while limite > 0.0:
		var viu_host := false
		var viu_cliente := false
		for jogador in get_tree().get_nodes_in_group("player"):
			if jogador is Player:
				viu_host = viu_host or jogador.global_position.distance_to(Vector2(240.0, 220.0)) < 8.0
				viu_cliente = viu_cliente or jogador.global_position.distance_to(Vector2(720.0, 320.0)) < 8.0
		var viu_inimigo_sincronizado := false
		for inimigo in get_tree().get_nodes_in_group("inimigo"):
			if (
				inimigo is Node2D
				and (inimigo as Node2D).global_position.distance_to(Vector2(480.0, 120.0)) < 8.0
				and inimigo.get_node_or_null("MultiplayerSynchronizer") != null
			):
				viu_inimigo_sincronizado = true
				break
		if viu_host and viu_cliente and viu_inimigo_sincronizado:
			return true
		await get_tree().create_timer(0.05).timeout
		limite -= 0.05
	return false


func _esperar_visual_rede(prefixo: String) -> bool:
	var limite := 4.0
	while limite > 0.0:
		for filho in batalha.get_children():
			if filho.name.begins_with(prefixo):
				return true
		await get_tree().create_timer(0.05).timeout
		limite -= 0.05
	return false


func _esperar_estado_disparo_rede() -> bool:
	var limite := 4.0
	while limite > 0.0:
		for filho in batalha.get_children():
			if filho.name.begins_with("TiroVisual_") and filho.has_meta("estado_rede_recebido"):
				return true
		await get_tree().create_timer(0.05).timeout
		limite -= 0.05
	return false


func _esperar_efeito_habilidade_rede() -> bool:
	var limite := 4.0
	while limite > 0.0:
		for filho in batalha.get_children():
			if filho is MonthlyAbilityEffect and filho.somente_visual_rede:
				return true
		await get_tree().create_timer(0.05).timeout
		limite -= 0.05
	return false


func _esperar_ajudante_visual_rede() -> bool:
	var limite := 4.0
	while limite > 0.0:
		if not get_tree().get_nodes_in_group("ajudante_visual_rede").is_empty():
			return true
		await get_tree().create_timer(0.05).timeout
		limite -= 0.05
	return false


func _esperar_feedback_visual_rede() -> bool:
	var limite := 4.0
	while limite > 0.0:
		for filho in batalha.get_children():
			if filho.has_meta("efeito_visual_rede"):
				return true
		await get_tree().create_timer(0.05).timeout
		limite -= 0.05
	return false


func _esperar_upgrades_loadout_remoto() -> bool:
	var esperado: StringName = &"cadencia" if papel == "host" else &"dano_calibrado"
	var limite := 4.0
	while limite > 0.0:
		for jogador in get_tree().get_nodes_in_group("player"):
			if jogador is Player and jogador.peer_id_dono != Rede.peer_local():
				if int(jogador.niveis_upgrades_rede.get(esperado, 0)) == 1:
					return true
		await get_tree().create_timer(0.05).timeout
		limite -= 0.05
	return false


func _configuracao_teste_local() -> Dictionary:
	if papel == "host":
		return {
			"arma": "a04_canhao_esturjao", "modulo": "", "mutacao": "",
			"modelo": "c02_asa_delta", "cor": "c11_ciano",
			"rastro": "c20_rastro_padrao",
			"habilidade": "res://Habilidades/habilidadeHiperdash.tres",
			"upgrades": {},
		}
	return {
		"arma": "a10_rajada_morango", "modulo": "", "mutacao": "",
		"modelo": "c04_dardo", "cor": "c12_rosa",
		"rastro": "c20_rastro_padrao",
		"habilidade": "res://Habilidades/habilidadeFocoAbsoluto.tres",
		"upgrades": {},
	}


func _personalizacoes_distintas_corretas() -> bool:
	var viu_host := false
	var viu_cliente := false
	for jogador in get_tree().get_nodes_in_group("player"):
		if not jogador is Player:
			continue
		var esperado_modelo: StringName = &"c02_asa_delta" if jogador.peer_id_dono == 1 else &"c04_dardo"
		var esperada_cor: StringName = &"c11_ciano" if jogador.peer_id_dono == 1 else &"c12_rosa"
		var esperado_poder := "res://Habilidades/habilidadeHiperdash.tres" if jogador.peer_id_dono == 1 else "res://Habilidades/habilidadeFocoAbsoluto.tres"
		var label := jogador.get_node_or_null("NicknameRede")
		var texto := label.get_child(0) as Label if is_instance_valid(label) and label.get_child_count() > 0 else null
		if jogador.modelo_visual_nave != esperado_modelo or jogador.cor_visual_nave != esperada_cor:
			return false
		if jogador.habilidade_rede_path != esperado_poder or not is_instance_valid(texto):
			return false
		if not texto.get_theme_color("font_color").is_equal_approx(jogador.obter_cor_personalizacao()):
			return false
		viu_host = viu_host or jogador.peer_id_dono == 1
		viu_cliente = viu_cliente or jogador.peer_id_dono != 1
	return viu_host and viu_cliente


func _esperar_upgrade_compartilhado(local: Player) -> bool:
	var limite := 4.0
	while limite > 0.0:
		if local.nivel_atual == 2 and local.pontos_upgrade_pendentes == 1:
			return true
		await get_tree().create_timer(0.05).timeout
		limite -= 0.05
	return false


func _esperar_morte_individual(local: Player) -> bool:
	var limite := 4.0
	while limite > 0.0:
		if papel == "client":
			var painel := batalha.get_node("GUI/caixa gameover") as Control
			var reiniciar := batalha.get_node("GUI/caixa gameover/Tentar de novo") as Button
			if not local.vivo and painel.visible and not reiniciar.visible and not batalha.game_over:
				return true
		else:
			var cliente_morto := false
			for jogador in get_tree().get_nodes_in_group("player"):
				if jogador is Player and jogador.peer_id_dono != 1:
					cliente_morto = not jogador.vivo
			if cliente_morto and local.vivo and not batalha.game_over:
				return true
		await get_tree().create_timer(0.05).timeout
		limite -= 0.05
	var estados: Array[String] = []
	for jogador in get_tree().get_nodes_in_group("player"):
		if jogador is Player:
			estados.append("id=%d vivo=%s visible=%s vida=%.1f" % [jogador.peer_id_dono, jogador.vivo, jogador.visible, jogador.vida])
	print("DIAGNOSTICO MORTE %s game_over=%s players=[%s]" % [papel, batalha.game_over, "; ".join(estados)])
	return false


func _on_lobby_alterado(jogadores: Dictionary) -> void:
	maior_lista_recebida = maxi(maior_lista_recebida, jogadores.size())


func _falhar(mensagem: String) -> void:
	push_error("LOBBY %s: %s" % [papel, mensagem])
	Rede.encerrar_lobby()
	get_tree().quit(1)
