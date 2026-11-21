extends Node

var papel := ""
var arena: Node2D
var prontos: Dictionary = {}
var iniciar_saida := false
var concluido := false
var confirmacoes_fim: Dictionary = {}
var confirmacoes_preservacao: Dictionary = {}


func _ready() -> void:
	for argumento in OS.get_cmdline_user_args():
		if argumento.begins_with("--lifecycle-role="):
			papel = argumento.trim_prefix("--lifecycle-role=")
	if papel.is_empty():
		get_tree().quit(0)
		return
	GerenciadorDeSave.salvar({"tutorialconcluido": true})
	var erro := Rede.criar_lobby(papel) if papel == "host" else Rede.entrar_lobby("127.0.0.1", papel)
	if erro != OK:
		falhar("nao abriu conexao")
		return
	if not await esperar(func() -> bool: return Rede.jogadores.size() == 4):
		falhar("lobby nao chegou a quatro pilotos")
		return
	arena = (load("res://Rooms/Battle_area.tscn") as PackedScene).instantiate() as Node2D
	get_tree().root.add_child(arena)
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
		_marcar_pronto.rpc_id(1)
	if papel == "host":
		if not await esperar(func() -> bool: return prontos.size() == 4):
			falhar("peers nao confirmaram entrada")
			return
		var dash := preload("res://Habilidades/habilidadeHiperdash.tres").duplicate() as HabilidadeHiperdash
		var tempo_anterior := Engine.time_scale
		dash.executar(local)
		if not is_equal_approx(Engine.time_scale, tempo_anterior):
			falhar("o hiperdash do host alterou o relogio da partida")
			return
		if not await esperar(func() -> bool: return not dash.em_uso()):
			falhar("o hiperdash do host nao terminou")
			return
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
		_ordenar_saida.rpc()
		iniciar_saida = true
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
		await get_tree().create_timer(0.2).timeout
	elif not await esperar(func() -> bool: return confirmacoes_fim.size() == 2):
		falhar("cliente nao confirmou recebimento do fim")
		return
	await sair()
	print("TESTE OK: %s preservou replicas e recebeu despawns apos saida de outro cliente" % papel)
	get_tree().quit(0)


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


func falhar(mensagem: String) -> void:
	push_error("CICLO VIDA %s: %s" % [papel, mensagem])
	get_tree().quit(1)
