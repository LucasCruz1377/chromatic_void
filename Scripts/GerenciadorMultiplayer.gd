extends Node


signal lobby_alterado(jogadores: Dictionary)
signal status_alterado(mensagem: String, erro: bool)
signal conexao_alterada(conectado: bool)
signal jogador_desconectado(peer_id: int)
signal desconexao_detectada(mensagem: String, host_perdido: bool)


const PORTA := 24567
const MAX_JOGADORES := 2
const NICK_PADRAO := "PILOTO"


var nickname_local := NICK_PADRAO
var jogadores: Dictionary = {}
var hospedando := false
var em_lobby := false
var modo_multiplayer := false
var peer_enet: ENetMultiplayerPeer
var configuracao_teste: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_carregar_nickname()
	multiplayer.peer_connected.connect(_on_peer_conectado)
	multiplayer.peer_disconnected.connect(_on_peer_desconectado)
	multiplayer.connected_to_server.connect(_on_conectado_ao_servidor)
	multiplayer.connection_failed.connect(_on_falha_conexao)
	multiplayer.server_disconnected.connect(_on_servidor_desconectado)


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
	status_alterado.emit("Sala criada • porta UDP %d" % PORTA, false)
	return OK


func entrar_lobby(endereco: String, nickname: String) -> Error:
	encerrar_lobby()
	definir_nickname(nickname)
	var host := endereco.strip_edges()
	if host.is_empty():
		status_alterado.emit("Digite o IP do host.", true)
		return ERR_INVALID_PARAMETER
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
