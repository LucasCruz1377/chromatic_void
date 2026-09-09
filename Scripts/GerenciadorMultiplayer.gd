extends Node


signal lobby_alterado(jogadores: Dictionary)
signal status_alterado(mensagem: String, erro: bool)
signal conexao_alterada(conectado: bool)
signal jogador_desconectado(peer_id: int)
signal desconexao_detectada(mensagem: String, host_perdido: bool)
signal lobbies_lan_alterados(lobbies: Array)


const PORTA := 24567
const MAX_JOGADORES := 2
const NICK_PADRAO := "PILOTO"
const PORTA_DESCOBERTA := 24568
const ASSINATURA_DESCOBERTA := "CHROMATIC_VOID_LAN_V1"
const INTERVALO_ANUNCIO_LAN := 0.75
const EXPIRACAO_LOBBY_LAN := 3.0


var nickname_local := NICK_PADRAO
var jogadores: Dictionary = {}
var hospedando := false
var em_lobby := false
var modo_multiplayer := false
var peer_enet: ENetMultiplayerPeer
var configuracao_teste: Dictionary = {}
var emissor_lan: PacketPeerUDP
var receptor_lan: PacketPeerUDP
var lobbies_lan: Dictionary = {}
var tempo_anuncio_lan := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)
	_carregar_nickname()
	multiplayer.peer_connected.connect(_on_peer_conectado)
	multiplayer.peer_disconnected.connect(_on_peer_desconectado)
	multiplayer.connected_to_server.connect(_on_conectado_ao_servidor)
	multiplayer.connection_failed.connect(_on_falha_conexao)
	multiplayer.server_disconnected.connect(_on_servidor_desconectado)


func _process(delta: float) -> void:
	if hospedando and em_lobby and is_instance_valid(emissor_lan):
		tempo_anuncio_lan -= delta
		if tempo_anuncio_lan <= 0.0:
			tempo_anuncio_lan = INTERVALO_ANUNCIO_LAN
			_anunciar_lobby_lan()
	_processar_descoberta_lan()


func sanitizar_nickname(valor: String) -> String:
	var limpo := valor.strip_edges().replace("\n", "").replace("\r", "").replace("\t", " ")
	if limpo.length() > 16:
		limpo = limpo.substr(0, 16)
	return NICK_PADRAO if limpo.is_empty() else limpo


func definir_nickname(valor: String, salvar := true) -> String:
	nickname_local = sanitizar_nickname(valor)
	if salvar:
		GerenciadorDeSave.salvar({"nickname": nickname_local})
	return nickname_local


func _carregar_nickname() -> void:
	var dados := GerenciadorDeSave.carregar()
	nickname_local = sanitizar_nickname(str(dados.get("nickname", NICK_PADRAO)))


func iniciar_solo() -> void:
	encerrar_lobby()
	modo_multiplayer = false


func criar_lobby(nickname: String) -> Error:
	encerrar_lobby()
	definir_nickname(nickname)
	peer_enet = ENetMultiplayerPeer.new()
	var erro := peer_enet.create_server(PORTA, MAX_JOGADORES - 1)
	if erro != OK:
		peer_enet = null
		status_alterado.emit("Não foi possível criar a sala na porta UDP %d." % PORTA, true)
		return erro
	multiplayer.multiplayer_peer = peer_enet
	hospedando = true
	em_lobby = true
	modo_multiplayer = true
	jogadores = {1: nickname_local}
	lobby_alterado.emit(jogadores.duplicate())
	conexao_alterada.emit(true)
	_iniciar_anuncio_lan()
	var ips := obter_enderecos_host()
	status_alterado.emit(
		"Sala criada • IP %s • porta UDP %d" % [ips[0] if not ips.is_empty() else "indisponível", PORTA],
		false
	)
	return OK


func entrar_lobby(endereco: String, nickname: String) -> Error:
	encerrar_lobby()
	definir_nickname(nickname)
	var host := endereco.strip_edges()
	if host.is_empty():
		status_alterado.emit("Digite o IP do host.", true)
		return ERR_INVALID_PARAMETER
	_encerrar_descoberta_lan()
	GerenciadorDeSave.salvar({"ultimo_ip_host": host})
	peer_enet = ENetMultiplayerPeer.new()
	var erro := peer_enet.create_client(host, PORTA)
	if erro != OK:
		peer_enet = null
		status_alterado.emit("Não foi possível iniciar a conexão com %s." % host, true)
		return erro
	multiplayer.multiplayer_peer = peer_enet
	hospedando = false
	em_lobby = true
	modo_multiplayer = true
	jogadores.clear()
	lobby_alterado.emit(jogadores.duplicate())
	status_alterado.emit("Conectando a %s:%d..." % [host, PORTA], false)
	return OK


func encerrar_lobby() -> void:
	_encerrar_anuncio_lan()
	_encerrar_descoberta_lan()
	if is_instance_valid(peer_enet):
		peer_enet.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	peer_enet = null
	hospedando = false
	em_lobby = false
	modo_multiplayer = false
	jogadores.clear()
	lobby_alterado.emit({})
	conexao_alterada.emit(false)


func obter_enderecos_host() -> Array[String]:
	var enderecos: Array[String] = []
	for endereco in IP.get_local_addresses():
		var valor := str(endereco)
		if ":" in valor or valor.begins_with("127.") or valor == "0.0.0.0":
			continue
		if valor.count(".") == 3 and valor not in enderecos:
			enderecos.append(valor)
	enderecos.sort()
	return enderecos


func iniciar_busca_lan() -> Error:
	if is_instance_valid(receptor_lan):
		return OK
	_encerrar_anuncio_lan()
	receptor_lan = PacketPeerUDP.new()
	receptor_lan.set_broadcast_enabled(true)
	var erro := receptor_lan.bind(PORTA_DESCOBERTA, "*")
	if erro != OK:
		receptor_lan = null
		status_alterado.emit("Busca automática indisponível; ainda é possível digitar o IP.", true)
		return erro
	lobbies_lan.clear()
	lobbies_lan_alterados.emit([])
	return OK


func parar_busca_lan() -> void:
	_encerrar_descoberta_lan()


func obter_lobbies_lan() -> Array[Dictionary]:
	var resultado: Array[Dictionary] = []
	for dados in lobbies_lan.values():
		if not dados is Dictionary:
			continue
		var lobby := dados as Dictionary
		var ocupacao := int(lobby.get("jogadores", 1))
		var capacidade := maxi(int(lobby.get("capacidade", MAX_JOGADORES)), 1)
		if ocupacao >= capacidade:
			continue
		resultado.append(lobby.duplicate(true))
	resultado.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return str(a.get("ip", "")) < str(b.get("ip", "")))
	return resultado


func _iniciar_anuncio_lan() -> void:
	_encerrar_descoberta_lan()
	emissor_lan = PacketPeerUDP.new()
	emissor_lan.set_broadcast_enabled(true)
	emissor_lan.set_dest_address("255.255.255.255", PORTA_DESCOBERTA)
	tempo_anuncio_lan = 0.0


func _encerrar_anuncio_lan() -> void:
	if is_instance_valid(emissor_lan):
		emissor_lan.close()
	emissor_lan = null


func _encerrar_descoberta_lan() -> void:
	if is_instance_valid(receptor_lan):
		receptor_lan.close()
	receptor_lan = null
	if not lobbies_lan.is_empty():
		lobbies_lan.clear()


func _anunciar_lobby_lan() -> void:
	if not is_instance_valid(emissor_lan):
		return
	var anuncio := {
		"assinatura": ASSINATURA_DESCOBERTA,
		"nickname": nickname_local,
		"porta": PORTA,
		"jogadores": jogadores.size(),
		"capacidade": MAX_JOGADORES,
	}
	emissor_lan.put_packet(JSON.stringify(anuncio).to_utf8_buffer())


func _processar_descoberta_lan() -> void:
	if not is_instance_valid(receptor_lan):
		return
	var alterou := false
	while receptor_lan.get_available_packet_count() > 0:
		var pacote := receptor_lan.get_packet().get_string_from_utf8()
		var recebido: Variant = JSON.parse_string(pacote)
		if not recebido is Dictionary or str(recebido.get("assinatura", "")) != ASSINATURA_DESCOBERTA:
			continue
		var endereco := receptor_lan.get_packet_ip()
		if endereco.is_empty():
			continue
		var novos_dados := {
			"ip": endereco,
			"nickname": sanitizar_nickname(str(recebido.get("nickname", NICK_PADRAO))),
			"porta": int(recebido.get("porta", PORTA)),
			"jogadores": clampi(int(recebido.get("jogadores", 1)), 1, MAX_JOGADORES),
			"capacidade": maxi(int(recebido.get("capacidade", MAX_JOGADORES)), 1),
			"ultimo_anuncio": Time.get_ticks_msec(),
		}
		var anterior: Dictionary = lobbies_lan.get(endereco, {})
		alterou = alterou or _dados_lobby_mudaram(anterior, novos_dados)
		lobbies_lan[endereco] = novos_dados
	var agora := Time.get_ticks_msec()
	for endereco in lobbies_lan.keys():
		var dados: Dictionary = lobbies_lan[endereco]
		if float(agora - int(dados.get("ultimo_anuncio", 0))) / 1000.0 > EXPIRACAO_LOBBY_LAN:
			lobbies_lan.erase(endereco)
			alterou = true
	if alterou:
		lobbies_lan_alterados.emit(obter_lobbies_lan())


func _dados_lobby_mudaram(anterior: Dictionary, atual: Dictionary) -> bool:
	for campo in ["ip", "nickname", "porta", "jogadores", "capacidade"]:
		if anterior.get(campo) != atual.get(campo):
			return true
	return false


func esta_conectado() -> bool:
	return (
		modo_multiplayer
		and is_instance_valid(peer_enet)
		and peer_enet.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED
	)


func peer_local() -> int:
	return multiplayer.get_unique_id() if esta_conectado() else 1


func obter_configuracao_nave_local() -> Dictionary:
	if not configuracao_teste.is_empty():
		return configuracao_teste.duplicate(true)
	var dados: Dictionary = GerenciadorDeSave.carregar()
	var equipamentos: Dictionary = dados.get("equipamentos_loja", {})
	var personalizacao: Dictionary = dados.get("personalizacao_nave", {})
	return {
		"arma": str(equipamentos.get("1", "")),
		"modulo": str(equipamentos.get("2", "")),
		"mutacao": str(equipamentos.get("3", "")),
		"modelo": str(personalizacao.get("modelo", "c01_modelo_padrao")),
		"cor": str(personalizacao.get("cor", "c10_verde_original")),
		"rastro": str(personalizacao.get("rastro", "c20_rastro_padrao")),
		"habilidade": str(dados.get("habilidade_equipada", "")),
		"upgrades": {},
	}


func pode_iniciar_partida() -> bool:
	return hospedando and em_lobby and jogadores.size() == MAX_JOGADORES


func solicitar_inicio_partida() -> bool:
	if not pode_iniciar_partida():
		status_alterado.emit("Aguardando o segundo jogador entrar na sala.", true)
		return false
	_iniciar_partida_remota.rpc()
	return true


@rpc("authority", "call_local", "reliable")
func _iniciar_partida_remota() -> void:
	modo_multiplayer = true
	em_lobby = false
	Global.primeira_vez_jogando = false
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Rooms/Battle_area.tscn")


@rpc("any_peer", "reliable")
func _registrar_nickname_remoto(nickname: String) -> void:
	if not multiplayer.is_server():
		return
	var id := multiplayer.get_remote_sender_id()
	if id <= 1 or jogadores.size() >= MAX_JOGADORES and not jogadores.has(id):
		return
	jogadores[id] = sanitizar_nickname(nickname)
	_enviar_lista_jogadores()


@rpc("authority", "call_local", "reliable")
func _receber_lista_jogadores(nova_lista: Dictionary) -> void:
	jogadores = nova_lista.duplicate(true)
	lobby_alterado.emit(jogadores.duplicate())
	conexao_alterada.emit(true)


func _enviar_lista_jogadores() -> void:
	if multiplayer.is_server():
		_receber_lista_jogadores.rpc(jogadores)


func _on_peer_conectado(_id: int) -> void:
	if hospedando:
		status_alterado.emit("Piloto conectado. Recebendo nickname...", false)


func _on_peer_desconectado(id: int) -> void:
	if jogadores.has(id):
		jogadores.erase(id)
	if hospedando:
		_enviar_lista_jogadores()
	status_alterado.emit("Um jogador saiu da sala.", true)
	lobby_alterado.emit(jogadores.duplicate())
	jogador_desconectado.emit(id)


func _on_conectado_ao_servidor() -> void:
	status_alterado.emit("Conectado ao lobby.", false)
	_registrar_nickname_remoto.rpc_id(1, nickname_local)


func _on_falha_conexao() -> void:
	status_alterado.emit("Falha ao conectar. Confira o IP e a porta UDP %d." % PORTA, true)
	encerrar_lobby()


func _on_servidor_desconectado() -> void:
	status_alterado.emit("O host encerrou a sala.", true)
	desconexao_detectada.emit("CONEXÃO PERDIDA: o host encerrou a partida.", true)
	encerrar_lobby()
