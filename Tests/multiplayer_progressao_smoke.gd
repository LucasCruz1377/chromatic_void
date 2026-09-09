extends Node


var falhas: Array[String] = []


func verificar(condicao: bool, mensagem: String) -> void:
	if not condicao:
		falhas.append(mensagem)
		push_error("MULTIPLAYER/PROGRESSÃO: " + mensagem)


func _ready() -> void:
	verificar(Rede.sanitizar_nickname("  Lucas  ") == "Lucas", "nickname não é normalizado")
	verificar(Rede.sanitizar_nickname("") == Rede.NICK_PADRAO, "nickname vazio não recebe padrão")
	var erro_lobby := Rede.criar_lobby("Teste Host")
	verificar(erro_lobby == OK, "servidor ENet não criou o lobby")
	verificar(Rede.hospedando and Rede.jogadores.size() == 1, "host não aparece na lista do lobby")
	verificar(not Rede.pode_iniciar_partida(), "lobby iniciou sem o segundo jogador")
	Rede.encerrar_lobby()

	var cena_menu := load("res://Rooms/TelaInicial.tscn") as PackedScene
	var menu := cena_menu.instantiate()
	add_child(menu)
	await get_tree().process_frame
	verificar(menu.get("campo_nickname") is LineEdit, "tela inicial não criou o campo de nickname")
	var campo_nickname := menu.get("campo_nickname") as LineEdit
	verificar(campo_nickname.virtual_keyboard_enabled, "nickname não habilita teclado virtual")
	menu.call("_mostrar_escolha_modo")
	var conteudo := menu.get("conteudo_fluxo") as VBoxContainer
	var textos: Array[String] = []
	for filho in conteudo.get_children():
		if filho is Button:
			textos.append((filho as Button).text)
	verificar(textos.size() >= 2 and textos[0] == "JOGAR SOLO" and textos[1] == "MULTIPLAYER", "Start não mostra Solo acima de Multiplayer")
	var painel_fluxo := menu.get("painel_fluxo") as PanelContainer
	var largura_fluxo_normal := painel_fluxo.custom_minimum_size.x
	await get_tree().process_frame
	menu.call("_mostrar_escolha_multiplayer")
	verificar(is_instance_valid(Rede.receptor_lan), "busca automática de lobby LAN não foi iniciada")
	verificar(
		painel_fluxo.custom_minimum_size.x > largura_fluxo_normal,
		"a janela de seleção multiplayer não ficou maior"
	)
	var opcoes := conteudo.get_node_or_null("OpcoesMultiplayer") as HBoxContainer
	verificar(is_instance_valid(opcoes), "Criar e Entrar por IP não estão em uma linha horizontal")
	if is_instance_valid(opcoes):
		verificar(
			opcoes.get_child_count() == 2
				and (opcoes.get_child(0) as Button).text == "CRIAR LOBBY"
				and (opcoes.get_child(1) as Button).text == "ENTRAR POR IP",
			"as ações principais do multiplayer não estão lado a lado"
		)
	verificar(
		conteudo.get_node_or_null("PainelLobbiesLan") is PanelContainer,
		"faltou a área própria de lobbies encontrados"
	)
	Rede.lobbies_lan = {
		"192.168.0.20": {
			"ip": "192.168.0.20", "nickname": "HOST LIVRE", "porta": Rede.PORTA,
			"jogadores": 1, "capacidade": 2, "ultimo_anuncio": Time.get_ticks_msec(),
		},
		"192.168.0.21": {
			"ip": "192.168.0.21", "nickname": "HOST CHEIO", "porta": Rede.PORTA,
			"jogadores": 2, "capacidade": 2, "ultimo_anuncio": Time.get_ticks_msec(),
		},
	}
	var lobbies_visiveis := Rede.obter_lobbies_lan()
	verificar(
		lobbies_visiveis.size() == 1
			and str(lobbies_visiveis[0].get("nickname", "")) == "HOST LIVRE",
		"um lobby cheio apareceu entre os lobbies disponíveis"
	)
	menu.call("_on_lobbies_lan_alterados", lobbies_visiveis)
	var lista_lan := menu.get("lista_lobbies_lan") as VBoxContainer
	verificar(
		is_instance_valid(lista_lan) and lista_lan.get_child_count() == 1,
		"a lista LAN não atualizou apenas os lobbies disponíveis"
	)
	if is_instance_valid(lista_lan) and lista_lan.get_child_count() == 1:
		var linha_lobby := lista_lan.get_child(0) as HBoxContainer
		var informacoes_lobby := linha_lobby.get_child(0) as VBoxContainer
		verificar(
			(informacoes_lobby.get_child(0) as Label).text == "HOST: HOST LIVRE",
			"a lista LAN não mostra o nickname do criador"
		)
	var lobby_renovado: Dictionary = lobbies_visiveis[0].duplicate(true)
	lobby_renovado["ultimo_anuncio"] = 999999
	verificar(
		not Rede._dados_lobby_mudaram(lobbies_visiveis[0], lobby_renovado),
		"somente renovar o anúncio ainda força a reconstrução dos botões"
	)
	Rede.parar_busca_lan()
	menu.call("_mostrar_entrada_ip")
	verificar(
		is_equal_approx(painel_fluxo.custom_minimum_size.x, largura_fluxo_normal),
		"a tela de entrada por IP não voltou ao tamanho original"
	)
	var campo_ip := menu.get("campo_ip") as LineEdit
	verificar(is_instance_valid(campo_ip) and campo_ip.virtual_keyboard_enabled, "IP não habilita teclado virtual")
	menu.queue_free()
	await get_tree().process_frame

	Rede.modo_multiplayer = false
	var jogador_solo := Player.new()
	var pontos_solo := jogador_solo.pontos_upgrade_pendentes
	jogador_solo.subir_de_nivel()
	verificar(
		jogador_solo.nivel_atual == 2
			and jogador_solo.pontos_upgrade_pendentes == pontos_solo + 1,
		"singleplayer não concedeu um ponto de melhoria a cada nível"
	)
	jogador_solo.free()

	Rede.modo_multiplayer = true
	Rede.jogadores = {1: "HOST_TESTE", 2: "CLIENTE_TESTE"}
	var batalha := (load("res://Rooms/Battle_area.tscn") as PackedScene).instantiate()
	add_child(batalha)
	await get_tree().process_frame
	batalha.tutorial_ativo = false
	verificar(batalha.get_node_or_null("PlayerSpawner") is MultiplayerSpawner, "faltou MultiplayerSpawner dos jogadores")
	verificar(batalha.get_node_or_null("WorldSpawner") is MultiplayerSpawner, "faltou MultiplayerSpawner do mundo")
	var remoto := batalha._instanciar_jogador_rede({
		"peer_id": 2,
		"nickname": "CLIENTE_TESTE",
		"configuracao": {
			"modelo": "c02_asa_delta", "cor": "c11_azul_neon",
			"rastro": "c20_rastro_padrao",
		},
	}) as Player
	batalha.add_child(remoto)
	await get_tree().process_frame
	verificar(remoto is Player, "segundo piloto não usa a cena Player real")
	verificar(remoto.get_node_or_null("MultiplayerSynchronizer") is MultiplayerSynchronizer, "Player real não possui MultiplayerSynchronizer")
	verificar(remoto.nickname_rede == "CLIENTE_TESTE", "nickname não foi aplicado à nave real")
	verificar(remoto.modelo_visual_nave == &"c02_asa_delta", "modelo equipado foi substituído por uma nave genérica")
	verificar(remoto.get_node_or_null("NicknameRede") != null, "nickname não aparece sobre a nave")
	var barra_remota := remoto.get_node_or_null("NicknameRede/BarraVidaRede") as ProgressBar
	verificar(is_instance_valid(barra_remota), "barra de vida não aparece sob o nickname")
	remoto.vida = 42.0
	remoto._atualizar_nickname_rede()
	verificar(is_equal_approx(barra_remota.value, 42.0), "barra sob o nickname não acompanha a vida sincronizada")
	remoto.rastro_ativo_rede = true
	remoto._atualizar_efeitos_visuais_rede()
	verificar(not remoto.particulas_rastro_modelo_o.emitting, "rastro estelar apareceu sem Modelo O equipado")
	remoto.configuracao_visual_rede = {
		"modelo": "c08_modelo_spectrum", "cor": "c11_ciano",
		"rastro": "c22_rastro_spectrum",
	}
	remoto.aplicar_configuracao_visual_rede()
	remoto._atualizar_efeitos_visuais_rede()
	var sprite_spectrum := remoto.sprites_modelos_exclusivos.get(&"c08_modelo_spectrum") as Sprite2D
	verificar(is_instance_valid(sprite_spectrum) and sprite_spectrum.visible, "modelo Spectrum não usa o SVG B-EL")
	verificar(remoto.rastro_exclusivo.ativo, "rastro arco-íris exclusivo do Spectrum não ativou")
	remoto.configuracao_visual_rede = {
		"modelo": "c09_modelo_fspeed", "cor": "c13_violeta",
		"rastro": "c23_rastro_fspeed",
	}
	remoto.aplicar_configuracao_visual_rede()
	remoto._atualizar_efeitos_visuais_rede()
	var sprite_fspeed := remoto.sprites_modelos_exclusivos.get(&"c09_modelo_fspeed") as Sprite2D
	verificar(is_instance_valid(sprite_fspeed) and sprite_fspeed.visible, "modelo Fspeed não usa o SVG C4RLOS")
	verificar(remoto.rastro_exclusivo.tipo == &"fspeed", "rastro de marcas de pneu do Fspeed não ativou")
	var area_comum := batalha.calcular_area_comum([Vector2(1920, 1080), Vector2(1024, 768)])
	verificar(area_comum.size.is_equal_approx(Vector2(960, 540)), "arena não escolheu o menor campo visível")
	verificar(batalha.resolucoes_sao_diferentes([Vector2(1920, 1080), Vector2(1024, 768)]), "resoluções diferentes não foram detectadas")
	batalha._receber_area_coop(area_comum.position, area_comum.size, true)
	verificar(is_instance_valid(batalha.limite_arena_coop) and batalha.limite_arena_coop.resolucoes_diferentes, "barreiras visuais da arena comum não apareceram")
	batalha._on_jogador_rede_desconectado(2)
	var aviso_rede := batalha.get_node("GUI/AvisoRede") as Label
	verificar(aviso_rede.visible and "DESCONECTOU" in aviso_rede.text, "desconexão não mostra aviso durante a partida")
	var disparo_liberado := Node2D.new()
	batalha.add_child(disparo_liberado)
	batalha.disparos_visuais_rede["2:liberado"] = disparo_liberado
	disparo_liberado.queue_free()
	await get_tree().process_frame
	batalha._aplicar_estado_disparo_visual({
		"id_disparo": "2:liberado", "posicao": Vector2.ONE,
	})
	verificar(
		not batalha.disparos_visuais_rede.has("2:liberado"),
		"referência de ataque liberado permaneceu no cache de rede"
	)
	var jogador := batalha.get_node("Player") as Player
	var menu_upgrades := batalha.get_node("GUI/TelaUpgrades") as Control
	var pontos_iniciais := jogador.pontos_upgrade_pendentes
	jogador.subir_de_nivel()
	await get_tree().process_frame
	verificar(jogador.nivel_atual == 2, "primeiro level up não chegou ao nível 2")
	verificar(jogador.pontos_upgrade_pendentes == pontos_iniciais + 1, "nível 2 não concedeu a melhoria")
	verificar(not bool(menu_upgrades.call("esta_aberta")), "tela de melhorias abriu sem o jogador pedir")
	menu_upgrades.call("abrir_menu")
	verificar(bool(menu_upgrades.call("esta_aberta")), "jogador não conseguiu abrir seu menu individual")
	verificar(is_equal_approx(Engine.time_scale, 1.0), "menu individual pausou a partida multiplayer")
	menu_upgrades.call("fechar_menu")
	jogador.subir_de_nivel()
	await get_tree().process_frame
	verificar(jogador.nivel_atual == 3, "segundo level up não chegou ao nível 3")
	verificar(jogador.pontos_upgrade_pendentes == pontos_iniciais + 1, "nível ímpar concedeu melhoria indevida")

	for caminho_boss in [
		"res://Entities/BossPet0.tscn",
		"res://Entities/BossFlorEquinocio.tscn",
		"res://Entities/BossEclipseColheita.tscn",
		"res://Entities/BossConstelacaoAmparo.tscn",
		"res://Entities/BossNoAmetista.tscn",
	]:
		var boss := (load(caminho_boss) as PackedScene).instantiate() as InimigoBase
		var vida_anterior := boss.VidaMaxima
		batalha.add_child(boss)
		await get_tree().process_frame
		boss.process_mode = Node.PROCESS_MODE_DISABLED
		verificar(
			float(boss.call("obter_vida_maxima_atual")) >= vida_anterior * 1.75,
			"%s não recebeu 175%% da vida anterior" % caminho_boss
		)
		boss.queue_free()
		await get_tree().process_frame

	batalha._on_player_morreu(jogador)
	verificar(batalha.caixa_gameover.visible, "morte local não abriu o painel de espera")
	verificar(batalha.get_node("GUI/caixa gameover/Tentar de novo").visible, "host morto não pode reiniciar a partida")

	batalha.queue_free()
	await get_tree().process_frame
	if falhas.is_empty():
		print("TESTE OK: lobby, Player real, spawners, synchronizer, melhoria bianível e bosses")
	get_tree().quit(0 if falhas.is_empty() else 1)
