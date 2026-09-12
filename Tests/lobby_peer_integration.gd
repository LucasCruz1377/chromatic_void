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
			var inimigo_posicao := inimigos_host[0] as CharacterBody2D
			inimigo_posicao.global_position = Vector2(480.0, 120.0)
			inimigo_posicao.velocity = Vector2.ZERO
			# Mantém o alvo estável enquanto as posições dos dois peers convergem.
			inimigo_posicao.set_physics_process(false)
	if not await _esperar_mundo_sincronizado():
		_falhar("posição dos Players ou inimigos não foi sincronizada")
		return
	var inimigo_teste := get_tree().get_nodes_in_group("inimigo")[0] as InimigoBase
	if papel == "host":
		inimigo_teste.set_physics_process(true)
		inimigo_teste.Dano = 0.0
	var vida_esperada := inimigo_teste.VidaMaxima - 0.4
	if papel == "client":
		inimigo_teste.tomarDano(0.5)
	if not await _esperar_vida_inimigo(vida_esperada):
		_falhar("dano do cliente não chegou ao host ou a vida não voltou sincronizada")
		return
	if papel == "client" and not await _esperar_hitflash_remoto(inimigo_teste):
		_falhar("flash visual de acerto não chegou ao client")
		return
	if papel == "host":
		Global.Combo = 5
	if not await _esperar_combo_rede(5):
		_falhar("combo autoritativo não foi sincronizado")
		return
	local.ao_ativar_habilidade()
	await get_tree().create_timer(0.3).timeout
	if Global.Combo != 5:
		_falhar("habilidade ativa zerou o combo no coop")
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
	batalha.replicar_feedback_visual({
		"classe": &"particula_cena",
		"cena": "res://FX/ParticulasMorteInimigo.tscn",
		"posicao": Vector2(480.0, 220.0),
		"rotacao": 0.0,
		"cor": Color(0.82, 0.24, 0.68),
	})
	if not await _esperar_particula_colorida():
		_falhar("partícula do outro peer perdeu sua cor e ficou branca")
		return
	# Estressa a corrida que acontece em aparelhos com latências diferentes:
	# o fim confiável pode chegar antes do último pacote de posição não confiável.
	for indice in range(16):
		local.criar_projetil(
			local.rotation + float(indice) * 0.025, 0.1, true, null, 0.0,
			&"beam", Color(0.3, 0.9, 1.0),
			{"tempo_vida": 0.08, "velocidade": 0.35}
		)
	await get_tree().create_timer(0.8).timeout
	local.niveis_upgrades[&"dano_calibrado" if papel == "host" else &"cadencia"] = 1
	local.call("_sincronizar_loadout_rede")
	if not await _esperar_upgrades_loadout_remoto():
		_falhar("upgrades individuais não foram publicados no loadout remoto")
		return
	var cristais_antes := Global.cristais
	if papel == "host":
		inimigo_teste.conceder_recompensa()
		inimigo_teste.conceder_recompensa()
	if not await _esperar_cristais_rede(cristais_antes):
		_falhar("cliente não recebeu os cristais concedidos pelo host")
		return
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
	local.vida = 20.0
	local.invencibilidade = true
	local.invencibilidade_cd = 12.0
	await get_tree().create_timer(0.5).timeout
	if papel == "host":
		var meteoro := (load("res://Entities/AsteroideBonus.tscn") as PackedScene).instantiate() as InimigoBase
		batalha.add_child(meteoro, true)
		meteoro.global_position = Vector2(480.0, 270.0)
		await get_tree().process_frame
		meteoro.conceder_recompensa()
		meteoro.queue_free()
	if not await _esperar_cura_meteoro(local):
		_falhar("meteoro bônus não curou os dois jogadores")
		return
	if papel == "host":
		batalha.limpar_inimigos_sem_recompensa()
		batalha._criar_boss(&"no_ametista", 2, true)
		await get_tree().process_frame
		if is_instance_valid(batalha.boss_ativo):
			batalha.boss_ativo.set_physics_process(false)
			batalha.boss_ativo.Vida = maxf(batalha.boss_ativo.VidaMaxima - 37.0, 1.0)
			batalha.boss_ativo.vida_alterada.emit(
				batalha.boss_ativo.Vida, batalha.boss_ativo.VidaMaxima
			)
	if not await _esperar_hud_boss_sincronizado():
		_falhar("barra de vida do boss não apareceu sincronizada no client")
		return
	local.invencibilidade = false
	local.invencibilidade_cd = 0.0
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


func _esperar_cristais_rede(valor_anterior: int) -> bool:
	var limite := 4.0
	while limite > 0.0:
		if Global.cristais > valor_anterior:
			return true
		await get_tree().create_timer(0.05).timeout
		limite -= 0.05
	return false


func _esperar_hitflash_remoto(inimigo: InimigoBase) -> bool:
	var limite := 4.0
	while limite > 0.0:
		if is_instance_valid(inimigo) and inimigo.has_meta("hitflash_rede_recebido"):
			return true
		await get_tree().create_timer(0.05).timeout
		limite -= 0.05
	return false


func _esperar_combo_rede(valor: int) -> bool:
	var limite := 4.0
	while limite > 0.0:
		if Global.Combo == valor:
			return true
		await get_tree().create_timer(0.05).timeout
		limite -= 0.05
	return false


func _esperar_cura_meteoro(jogador: Player) -> bool:
	var limite := 5.0
	while limite > 0.0:
		if is_instance_valid(jogador) and jogador.vida > 20.0:
			return true
		await get_tree().create_timer(0.05).timeout
		limite -= 0.05
	return false


func _esperar_hud_boss_sincronizado() -> bool:
	var limite := 6.0
	while limite > 0.0:
		var boss: InimigoBase
		for candidato in get_tree().get_nodes_in_group("boss"):
			if candidato is InimigoBase:
				boss = candidato as InimigoBase
				break
		if (
			is_instance_valid(boss)
			and is_instance_valid(batalha.boss_hud)
			and batalha.boss_hud.visible
			and is_instance_valid(batalha.boss_vida)
			and boss.Vida < boss.VidaMaxima
			and is_equal_approx(float(batalha.boss_vida.value), boss.Vida)
		):
			return true
		await get_tree().create_timer(0.05).timeout
		limite -= 0.05
	return false


func _esperar_particula_colorida() -> bool:
	var limite := 4.0
	while limite > 0.0:
		for filho in batalha.get_children():
			if filho.has_meta("efeito_visual_rede") and filho is GPUParticles2D:
				if (filho as CanvasItem).modulate != Color.WHITE:
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
			"modelo": "c08_modelo_spectrum", "cor": "c11_ciano",
			"rastro": "c22_rastro_spectrum",
			"habilidade": "res://Habilidades/habilidadeHiperdash.tres",
			"upgrades": {},
		}
	return {
		"arma": "a10_rajada_morango", "modulo": "", "mutacao": "",
		"modelo": "c09_modelo_fspeed", "cor": "c12_rosa",
		"rastro": "c23_rastro_fspeed",
		"habilidade": "res://Habilidades/habilidadeFocoAbsoluto.tres",
		"upgrades": {},
	}


func _personalizacoes_distintas_corretas() -> bool:
	var viu_host := false
	var viu_cliente := false
	for jogador in get_tree().get_nodes_in_group("player"):
		if not jogador is Player:
			continue
		var esperado_modelo: StringName = &"c08_modelo_spectrum" if jogador.peer_id_dono == 1 else &"c09_modelo_fspeed"
		var esperada_cor: StringName = &"c11_ciano" if jogador.peer_id_dono == 1 else &"c12_rosa"
		var esperado_poder := "res://Habilidades/habilidadeHiperdash.tres" if jogador.peer_id_dono == 1 else "res://Habilidades/habilidadeFocoAbsoluto.tres"
		var label := jogador.get_node_or_null("NicknameRede")
		var texto := label.get_child(0) as Label if is_instance_valid(label) and label.get_child_count() > 0 else null
		var barra := jogador.get_node_or_null("NicknameRede/BarraVidaRede") as ProgressBar
		if jogador.modelo_visual_nave != esperado_modelo or jogador.cor_visual_nave != esperada_cor:
			print("DIAGNOSTICO LOADOUT %s peer=%d modelo=%s esperado=%s cor=%s esperada=%s" % [papel, jogador.peer_id_dono, jogador.modelo_visual_nave, esperado_modelo, jogador.cor_visual_nave, esperada_cor])
			return false
		if jogador.habilidade_rede_path != esperado_poder or not is_instance_valid(texto) or not is_instance_valid(barra):
			print("DIAGNOSTICO LOADOUT %s peer=%d habilidade=%s esperada=%s texto=%s barra=%s" % [papel, jogador.peer_id_dono, jogador.habilidade_rede_path, esperado_poder, is_instance_valid(texto), is_instance_valid(barra)])
			return false
		# O Spectrum anima a matiz com o relógio; duas leituras consecutivas podem
		# diferir alguns milésimos mesmo representando a mesma identidade visual.
		var cor_nickname: Color = texto.get_theme_color("font_color")
		var cor_modelo: Color = jogador.obter_cor_personalizacao()
		var diferenca_cor := maxf(
			maxf(
				absf(cor_nickname.r - cor_modelo.r),
				absf(cor_nickname.g - cor_modelo.g)
			),
			absf(cor_nickname.b - cor_modelo.b)
		)
		if diferenca_cor > 0.01:
			print("DIAGNOSTICO LOADOUT %s peer=%d cor_nick=%s cor_nave=%s" % [papel, jogador.peer_id_dono, texto.get_theme_color("font_color"), jogador.obter_cor_personalizacao()])
			return false
		if jogador.particulas_rastro_modelo_o.emitting:
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
