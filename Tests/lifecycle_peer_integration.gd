extends Node

var papel := ""
var arena: Node2D
var prontos: Dictionary = {}
var assinaturas_sizigia := {}
var sizigia_confirmada: Dictionary = {}
var pausas_confirmadas: Dictionary = {}
var iniciar_saida := false
var concluido := false
var saida_liberada := false
var confirmacoes_fim: Dictionary = {}
var confirmacoes_preservacao: Dictionary = {}


func _ready() -> void:
	for argumento in OS.get_cmdline_user_args():
		if argumento.begins_with("--lifecycle-role="):
			papel = argumento.trim_prefix("--lifecycle-role=")
	if papel.is_empty():
		get_tree().quit(0)
		return
	await get_tree().process_frame
	# O controlador do teste acompanha a troca real de cena feita pelo lobby.
	get_tree().current_scene = null
	GerenciadorDeSave.salvar({"tutorialconcluido": true})
	var erro := Rede.criar_lobby(papel) if papel == "host" else Rede.entrar_lobby("127.0.0.1", papel)
	if erro != OK:
		falhar("nao abriu conexao")
		return
	if not await esperar(func() -> bool: return Rede.jogadores.size() == 4):
		falhar("lobby nao chegou a quatro pilotos")
		return
	if papel in ["client_a", "client_b"]:
		Rede.configuracao_teste = {"mutacao": "u13_dupla_experiencia"}
	if papel == "host" and not Rede.solicitar_inicio_partida():
		falhar("host nao iniciou pelo lobby")
		return
	if not await esperar(func() -> bool:
		var cena := get_tree().current_scene
		return cena != null and cena.scene_file_path == "res://Rooms/Battle_area.tscn"
	):
		falhar("transicao do lobby para a arena nao terminou")
		return
	arena = get_tree().current_scene as Node2D
	arena.set("preservar_conexao_ao_sair", true)
	arena.set("spawns_pausados_desenvolvedor", true)
	if not await esperar(func() -> bool:
		return get_tree().get_nodes_in_group("player").size() == 4 and (papel == "host" or bool(arena.get("entrada_estado_confirmada")))
	):
		falhar("quatro naves nao foram replicadas")
		return
	for piloto in get_tree().get_nodes_in_group("player"):
		piloto.invencibilidade = true
		piloto.invencibilidade_cd = 60.0
	# Cada processo move somente a nave que controla. Os quatro precisam
	# observar a posição final dos três colegas antes de iniciar o combate.
	var local := arena.call("_obter_jogador_rede", Rede.peer_local()) as Player
	if not await verificar_sizigia_rede():
		falhar("golpes ou transições da Sizígia divergiram entre quatro pilotos")
		return
	local.velocity = Vector2.ZERO # A prova de movimento começa após a atração da maré.
	var destino_local := destino_teste(Rede.peer_local())
	for quadro in 36:
		local.global_position = local.global_position.move_toward(destino_local, 6.0)
		await get_tree().physics_frame
	if not await esperar(todos_chegaram):
		falhar("movimento dos quatro pilotos nao convergiu")
		return
	if papel == "host":
		prontos[1] = true
	else:
		await get_tree().process_frame
		Input.action_press("pausar")
		await get_tree().process_frame
		await get_tree().process_frame
		Input.action_release("pausar")
		if get_tree().paused or arena.get_node("GUI/caixa pause").visible:
			falhar("cliente abriu a pausa")
			return
		_marcar_pronto.rpc_id(1)
	if papel == "host":
		if not await esperar(func() -> bool: return prontos.size() == 4):
			falhar("peers nao confirmaram entrada")
			return
		if arena.conceder_xp_equipe(5.25) != 10.5:
			falhar("dois clientes com a passiva devem conceder exatamente 2x XP")
			return
		var dash := preload("res://Habilidades/habilidadeHiperdash.tres").duplicate() as HabilidadeHiperdash
		var tempo_anterior := Engine.time_scale
		var flor := (load("res://Entities/BossFlorEquinocio.tscn") as PackedScene).instantiate() as ChefeBase
		flor.name = "FlorCicloVida"
		arena.add_child(flor, true)
		flor.set_physics_process(false)
		for indice in 3:
			var tiro := (load("res://Entities/EspinhoPrimaveril.tscn") as PackedScene).instantiate() as ProjetilInimigo
			tiro.position = Vector2(450 + indice * 30, 100)
			tiro.tempo_vida = 15.0
			tiro.velocidade = 0.01
			arena.add_child(tiro, true)
		await get_tree().create_timer(0.5).timeout
		flor.call("ativar_escudo", false)
		flor.set_physics_process(true)
		var vida_antes := flor.Vida
		dash.executar(local)
		if not is_equal_approx(Engine.time_scale, tempo_anterior):
			falhar("o hiperdash do host alterou o relogio da partida")
			return
		await get_tree().process_frame
		Input.action_press("pausar")
		await get_tree().process_frame
		await get_tree().process_frame
		Input.action_release("pausar")
		if not get_tree().paused:
			falhar("botao do host nao pausou")
			return
		var espinho := get_tree().get_first_node_in_group("projetil_primaveril") as ProjetilInimigo
		var tempo_ataque := float(flor.get("tempo_ataque"))
		var vida_do_tiro := espinho.tempo_vida
		var posicao_do_tiro := espinho.position
		if not await esperar(func() -> bool: return pausas_confirmadas.size() == 3):
			falhar("tres clientes nao confirmaram a pausa")
			return
		if (
			flor.Vida != vida_antes or float(flor.get("tempo_ataque")) != tempo_ataque
			or espinho.tempo_vida != vida_do_tiro or espinho.position != posicao_do_tiro
			or flor.can_process()
		):
			falhar("boss ou ataque avancou na pausa")
			return
		if not dash.em_uso() or local.UsandoHabilidade:
			falhar("preparo do hiperdash avancou durante a pausa")
			return
		arena.get_node("GUI/caixa pause/despause").pressed.emit()
		flor.set_physics_process(false)
		if not await esperar(func() -> bool: return local.UsandoHabilidade):
			falhar("o hiperdash nao executou ao retomar")
			return
		if not await esperar(func() -> bool: return not dash.em_uso()):
			falhar("o hiperdash nao terminou")
			return
		_ordenar_saida.rpc()
		iniciar_saida = true
	else:
		if not await esperar(func() -> bool: return get_tree().paused):
			falhar("a pausa do host nao chegou")
			return
		if not await esperar(func() -> bool: return progresso_igual(4, 1.5)):
			falhar("XP ou nível de uma das quatro naves divergiu")
			return
		var flor := arena.get_node("FlorCicloVida") as ChefeBase
		local.HabilidadeEquipada.cooldown_atual = 3.0
		var posicao := local.global_position
		var tiros_antes := local.contador_disparos_rede
		await get_tree().process_frame
		Input.action_press("pausar")
		Input.action_press("acelerar")
		Input.action_press("atirar")
		flor.tomarDano(8.0)
		await get_tree().create_timer(0.8, true).timeout
		for acao in ["pausar", "acelerar", "atirar"]:
			Input.action_release(acao)
		if not get_tree().paused or local.global_position != posicao or local.contador_disparos_rede != tiros_antes or local.HabilidadeEquipada.cooldown_atual != 3.0:
			falhar("cliente moveu, disparou, retomou ou perdeu recarga durante a pausa")
			return
		_confirmar_pausa.rpc_id(1)
	if not await esperar(func() -> bool: return iniciar_saida):
		falhar("ordem de saida nao chegou")
		return
	if papel == "client_a":
		var flor := arena.get_node_or_null("FlorCicloVida") as ChefeBase
		if not is_instance_valid(flor):
			falhar("flor nao foi replicada")
			return
		# Reproduz a chamada de morte local com a vida ja recebida como zero.
		flor.Vida = 0.0
		flor.morrer()
		for tiro in get_tree().get_nodes_in_group("projetil_primaveril"):
			if tiro.is_queued_for_deletion():
				falhar("morte local apagou espinho do spawner")
				return
	if papel == "client_b":
		await get_tree().create_timer(0.3).timeout
		await sair()
		print("TESTE OK: client_b saiu da arena")
		get_tree().quit(0)
		return
	if not await esperar(func() -> bool: return Rede.jogadores.size() == 3 and get_tree().get_nodes_in_group("player").size() == 3):
		falhar("a nave desconectada nao foi removida pelo host")
		return
	var aviso := arena.get_node("GUI/AvisoRede") as Label
	if not await esperar(func() -> bool: return aviso.visible and aviso.text.contains("CLIENT_B")):
		falhar("o aviso de desconexão não chegou com o nome do piloto")
		return
	if papel == "host" and arena.conceder_xp_equipe(1.0) != 2.0:
		falhar("a passiva do cliente restante não concedeu 2x XP")
		return
	if not await esperar(func() -> bool: return progresso_igual(4, 3.5)):
		falhar("o XP divergiu após a saída de um dos pilotos com a passiva")
		return
	if get_tree().get_nodes_in_group("projetil_primaveril").size() != 3:
		falhar("espinhos foram apagados no cliente")
		return
	if papel != "host":
		_confirmar_preservacao.rpc_id(1)
	if papel == "host":
		if not await esperar(func() -> bool: return confirmacoes_preservacao.size() == 2):
			falhar("cliente nao confirmou preservacao dos espinhos")
			return
		# Mantem o cliente sobrevivente ativo enquanto o host emite os despawns.
		arena.call("limpar_inimigos_sem_recompensa")
		await get_tree().create_timer(0.5).timeout
		_finalizar.rpc()
		concluido = true
	if not await esperar(func() -> bool: return concluido):
		falhar("fim do teste nao chegou")
		return
	if not await esperar(func() -> bool: return get_tree().get_nodes_in_group("projetil_primaveril").is_empty()):
		falhar("despawn dos espinhos nao chegou")
		return
	if papel != "host":
		_confirmar_fim.rpc_id(1)
		if not await esperar(func() -> bool: return saida_liberada):
			falhar("host nao liberou a saida")
			return
	else:
		if not await esperar(func() -> bool: return confirmacoes_fim.size() == 2):
			falhar("cliente nao confirmou recebimento do fim")
			return
		# Cada cliente pode receber o despawn do outro antes de fechar ENet.
		for id in multiplayer.get_peers():
			_liberar_saida.rpc_id(id)
			if not await esperar(func() -> bool: return not Rede.jogadores.has(id)):
				falhar("cliente nao encerrou apos a liberacao")
				return
	await sair()
	print("TESTE OK: %s preservou replicas e recebeu despawns apos saida de outro cliente" % papel)
	get_tree().quit(0)


@rpc("any_peer", "call_remote", "reliable")
func _confirmar_pausa() -> void:
	pausas_confirmadas[multiplayer.get_remote_sender_id()] = true


@rpc("any_peer", "call_remote", "reliable")
func _marcar_pronto() -> void:
	prontos[multiplayer.get_remote_sender_id()] = true


@rpc("authority", "call_remote", "reliable")
func _ordenar_saida() -> void:
	iniciar_saida = true


@rpc("authority", "call_remote", "reliable")
func _finalizar() -> void:
	concluido = true


@rpc("any_peer", "call_remote", "reliable")
func _confirmar_preservacao() -> void:
	confirmacoes_preservacao[multiplayer.get_remote_sender_id()] = true


@rpc("any_peer", "call_remote", "reliable")
func _confirmar_fim() -> void:
	confirmacoes_fim[multiplayer.get_remote_sender_id()] = true


@rpc("authority", "call_remote", "reliable")
func _liberar_saida() -> void:
	saida_liberada = true


func verificar_sizigia_rede() -> bool:
	var host := papel == "host"
	if host:
		var chefe := preload("res://Entities/BossEclipseColheita.tscn").instantiate() as BossSizigiaEterna
		chefe.name = "SizigiaCoop"
		arena.add_child(chefe)
		chefe.global_position = Vector2(480, 150)
		chefe.golpes.iniciar(SizigiaFinalController.Golpe.MARE)
	if not await esperar(func() -> bool: return arena.has_node("SizigiaCoop")):
		return false
	var boss := arena.get_node("SizigiaCoop") as BossSizigiaEterna
	if not await esperar(func() -> bool: return boss.golpes.tipo == SizigiaFinalController.Golpe.MARE and boss.golpes.lacunas.size() == 4):
		return false
	if not await confirmar_sizigia(1):
		return false
	var nave := arena.call("_obter_jogador_rede", Rede.peer_local()) as Player
	await get_tree().create_timer(0.20).timeout
	nave.cooldown = 20.0
	Input.action_press("atirar")
	# Mantém o botão até o host registrar todos, mesmo com latência diferente por peer.
	if host:
		if not await esperar(func() -> bool:
			for p in boss.golpes.pilotos_vivos():
				if boss.golpes.historicos_tiros.get(p.get_instance_id(), []).size() < 3:
					return false
			return true
		):
			return false
		boss.golpes.vez_clone = 1 # Copia um cliente e seus disparos recebidos pelo host.
		boss.golpes.iniciar(SizigiaFinalController.Golpe.ABSOLUTO)
	if not await esperar(func() -> bool:
		return is_instance_valid(boss.golpes.clone) and boss.golpes.alvo_id > 1 and boss.golpes.especial.tiros.size() >= 3 and boss.golpes.tempo > 0.75
	):
		return false
	Input.action_release("atirar")
	if not await confirmar_sizigia(2, hash(boss.golpes.especial.tiros)):
		return false
	if host:
		boss.golpes.iniciar(SizigiaFinalController.Golpe.SOMBRA)
	if not await esperar(func() -> bool:
		var sombra := boss.golpes.sombra
		return is_instance_valid(sombra) and sombra.invocacao > 0 and sombra.invocacao < sombra.INVOCACAO and sombra.collision_layer == 0
	):
		return false
	if not await esperar(func() -> bool:
		var sombra := boss.golpes.sombra
		return is_instance_valid(sombra) and sombra.disparos >= 1 and sombra.collision_layer == 4 and is_equal_approx(sombra.vida, boss.VidaMaxima * 0.2)
	):
		return false
	if not await confirmar_sizigia(3):
		return false
	if host:
		boss.golpes.iniciar(SizigiaFinalController.Golpe.METEOROS)
	if not await esperar(func() -> bool:
		return boss.golpes.tipo == SizigiaFinalController.Golpe.METEOROS and boss.golpes.especial.quedas.size() >= 12
	):
		return false
	# As três primeiras levas já estão fixas nos quatro peers, mesmo que a próxima chegue durante a barreira.
	var assinatura := hash([boss.golpes.pontos.slice(0, 12), boss.golpes.especial.raios.slice(0, 12),
		boss.golpes.especial.quedas.slice(0, 12), boss.golpes.especial.avisos.slice(0, 3)])
	if papel == "client_a":
		var tiro = preload("res://Entities/fireball.tscn").instantiate()
		tiro.position = boss.golpes.sombra.global_position
		tiro.dono_player = nave
		tiro.dmg = 3.0
		tiro.velocidade = 0.0
		arena.add_child(tiro)
		nave.registrar_projetil_rede(tiro, &"", Color.WHITE, {})
	if not await esperar(func() -> bool:
		return is_instance_valid(boss.golpes.sombra) and is_equal_approx(boss.golpes.sombra.vida, boss.VidaMaxima * 0.2 - 3.0)
	):
		return false
	if not await confirmar_sizigia(4, assinatura):
		return false
	if host:
		boss.tomarDano(boss.Vida)
	if not await esperar(func() -> bool: return boss.fase_atual == boss.Fase.SOL and boss.destino_fase == 0):
		return false
	if not await confirmar_sizigia(5):
		return false
	if not is_instance_valid(boss.golpes.sombra):
		return false
	if host:
		boss.golpes.iniciar(SizigiaFinalController.Golpe.MANCHAS)
	if not await esperar(func() -> bool: return boss.golpes.orbes.size() == 3):
		return false
	if papel == "client_b":
		var restante := boss.golpes.sombra.vida
		while restante > 0:
			var parcela := minf(restante, 1400.0)
			boss.golpes.sombra.tomarDano(parcela)
			restante -= parcela
	if not await esperar(func() -> bool: return not is_instance_valid(boss.golpes.sombra)):
		return false
	if not await confirmar_sizigia(6):
		return false
	if papel == "client_a":
		boss.golpes.orbes[1].tomarDano(3)
	if not await esperar(func() -> bool: return boss.golpes.mascara_orbes == 5):
		return false
	if not await confirmar_sizigia(7):
		return false
	if host:
		boss.tomarDano(boss.Vida)
	if not await esperar(func() -> bool: return boss.impacto_fusao):
		return false
	if not await esperar(func() -> bool: return boss.fase_atual == boss.Fase.ECLIPSE and boss.destino_fase == 0):
		return false
	if not await esperar(func() -> bool: return boss.golpes.tipo == SizigiaFinalController.Golpe.TOTALIDADE and boss.golpes.lacunas.size() == 4):
		return false
	var aneis := boss.golpes
	for i in 4:
		if not is_equal_approx(fposmod(aneis.lacunas[(i + 1) % 4] - aneis.lacunas[i], TAU), PI / 2):
			return false
	if not await confirmar_sizigia(8, hash([aneis.origem, aneis.lacunas, aneis.especial, aneis.serie, aneis.etapa])):
		return false
	if host:
		boss.tomarDano(boss.Vida * 0.75)
		aneis.iniciar(SizigiaFinalController.Golpe.TOTALIDADE)
	if not await esperar(func() -> bool:
		return boss.fase_da_barra() == 3 and aneis.etapa == 3 and aneis.quantidade_aneis() == 10
	):
		return false
	if not await confirmar_sizigia(9, hash([aneis.origem, aneis.lacunas, aneis.especial, aneis.serie, aneis.etapa])):
		return false
	if host:
		boss.queue_free()
	return await esperar(func() -> bool: return not arena.has_node("SizigiaCoop"))


func confirmar_sizigia(etapa: int, assinatura: int = 0) -> bool:
	if papel != "host":
		_confirmar_sizigia.rpc_id(1, etapa, assinatura)
		return true
	return await esperar(func() -> bool:
		for peer in multiplayer.get_peers():
			if etapa in [2, 4, 8, 9] and assinaturas_sizigia.get(peer) != assinatura:
				return false
			if int(sizigia_confirmada.get(peer, 0)) < etapa:
				return false
		return multiplayer.get_peers().size() == 3
	)


@rpc("any_peer", "call_remote", "reliable")
func _confirmar_sizigia(etapa: int, assinatura: int) -> void:
	if etapa in [2, 4, 8, 9]:
		assinaturas_sizigia[multiplayer.get_remote_sender_id()] = assinatura
	sizigia_confirmada[multiplayer.get_remote_sender_id()] = etapa


func progresso_igual(nivel: int, xp: float) -> bool:
	for piloto: Player in get_tree().get_nodes_in_group("player"):
		if piloto.nivel_atual != nivel or not is_equal_approx(piloto.xp_atual, xp):
			return false
	return true


func destino_teste(peer: int) -> Vector2:
	var origem: Vector2 = arena.call("_posicao_inicial_peer", peer)
	return origem + Vector2(50, 24)


func todos_chegaram() -> bool:
	var pilotos := get_tree().get_nodes_in_group("player")
	if pilotos.size() != 4:
		return false
	for candidato in pilotos:
		var piloto := candidato as Player
		if piloto.global_position.distance_to(destino_teste(piloto.peer_id_dono)) > 4.0:
			return false
	return true


func esperar(condicao: Callable) -> bool:
	var limite := 12.0
	while limite > 0.0:
		if condicao.call():
			return true
		await get_tree().create_timer(0.05).timeout
		limite -= 0.05
	return false


func sair() -> void:
	if is_instance_valid(arena):
		arena.call("preparar_saida_multiplayer")
		arena.queue_free()
		await get_tree().process_frame
	Rede.encerrar_lobby()
	# O processo headless termina logo após a arena. Deixe o mixer consumir a
	# parada e liberar o playback de Ogg antes de encerrar o AudioServer.
	await get_tree().create_timer(0.25, true, false, true).timeout


func falhar(mensagem: String) -> void:
	push_error("CICLO VIDA %s: %s" % [papel, mensagem])
	get_tree().quit(1)
