extends Node


const DadosUpgrades = preload("res://Scripts/UpgradeData.gd")


var falhas: Array[String] = []


func verificar(condicao: bool, mensagem: String) -> void:
	if not condicao:
		falhas.append(mensagem)
		push_error("GELO/FEIXE/LOJA: " + mensagem)


func _ready() -> void:
	testar_catalogo_e_upgrades()
	testar_curva_feixe()
	testar_localizacao()
	await testar_visual_feixe()
	await testar_gelo()
	await testar_loja()
	if falhas.is_empty():
		print("TESTE OK: loja, combo, gelo acumulável e feixe do periélio")
	get_tree().quit(0 if falhas.is_empty() else 1)


func testar_catalogo_e_upgrades() -> void:
	var solsticio := MonthlyCatalog.encontrar(&"a13_canhao_lua_fria")
	verificar(int(solsticio.get("preco", 0)) == 16500, "Canhão do Solstício não custa 16,5k")
	verificar(StringName(solsticio.get("requer_conquista", &"")) == &"", "Canhão do Solstício ainda depende de conquista")
	verificar(is_equal_approx(InimigoBase.calcular_fator_xp_combo(20, 0), 1.10), "combo 20x não dá 10% de XP")
	verificar(str(DadosUpgrades.obter(&"solsticio_nucleo").get("nome", "")) == "NEVASCA", "melhoria Nevasca ausente")
	verificar(str(DadosUpgrades.obter(&"solsticio_absorcao").get("nome", "")) == "ABAIXO DE ZERO", "melhoria Abaixo de Zero ausente")
	verificar(int(DadosUpgrades.obter(&"perielio_potencia").get("max_nivel", 0)) == 3, "teto de dano do Periélio não tem três níveis")
	verificar(str(DadosUpgrades.obter(&"perielio_infinito").get("raridade", "")) == "ULTRARRARA", "rota infinita não é ultrarrara")
	var player_script := FileAccess.get_file_as_string("res://Scripts/player.gd")
	verificar('rotation, 0.5, false, null, 0.0, &"ice_stack"' in player_script, "Canhão do Solstício não usa dano base 0,5")


func testar_curva_feixe() -> void:
	var jogador := Player.new()
	var anterior := jogador.obter_dps_feixe_perielio()
	verificar(is_equal_approx(anterior, 1.0), "potência inicial incorreta")
	var razao := pow(10.0, 0.25 / 10.0)
	for hit in range(1, 41):
		jogador.tempo_uso_feixe_perielio = hit * 0.25
		var atual := jogador.obter_dps_feixe_perielio()
		verificar(is_equal_approx(atual / anterior, razao), "crescimento incorreto no hit %d" % hit)
		anterior = atual
	verificar(is_equal_approx(anterior, 10.0), "teto base incorreto")
	jogador.niveis_upgrades = {&"perielio_potencia": 3, &"perielio_resfriamento": 2}
	verificar(is_equal_approx(jogador.obter_dps_feixe_perielio(), 33.75), "teto com melhorias incorreto")
	verificar(is_equal_approx(jogador.obter_limite_uso_feixe_perielio(), 15.0), "resfriamento não amplia o uso contínuo")
	jogador.free()


func testar_localizacao() -> void:
	var locale_anterior := TranslationServer.get_locale()
	TranslationServer.set_locale("en")
	verificar(tr("VAZIO") == "VOID", "locale inglês não traduz VAZIO para VOID")
	verificar(tr("FEIXE DO PERIÉLIO") == "PERIHELION BEAM", "catálogo da loja não usa a tradução em inglês")
	TranslationServer.set_locale(locale_anterior)


func testar_visual_feixe() -> void:
	var arena := preload("res://Rooms/Battle_area.tscn").instantiate()
	add_child(arena)
	arena.set_process(false)
	var jogador := arena.get_node("Player") as Player
	jogador.arma_monthly = &"a06_feixe_perielio"
	jogador.ctrlblock = false
	jogador.set_physics_process(false)
	jogador.global_position = Vector2(50, 100)
	jogador._iniciar_feixe_perielio()
	var feixe := jogador.feixe_perielio_ativo
	verificar(feixe.get("linha_feixe") is Line2D, "feixe externo não usa Line2D")
	var centro := feixe.get("centro_feixe") as Line2D
	verificar(is_instance_valid(centro) and centro.default_color == Color.WHITE, "centro do feixe não começa branco")
	var lua := preload("res://Entities/BossEclipseColheita.tscn").instantiate() as BossSizigiaEterna
	arena.add_child(lua)
	lua.set_physics_process(false)
	lua.global_position = Vector2(450, 155)
	var vida := lua.Vida
	var ultimo_quadro := -1
	var acertos := 0
	var fator_critico := 1.5 if bool(feixe.get("eh_critico")) else 1.0
	for quadro in range(116):
		jogador.tempo_uso_feixe_perielio = quadro / 60.0
		vida = lua.Vida
		feixe._processar_feixe_perielio(1.0 / 60.0)
		if lua.Vida < vida:
			var esperado := 0.25 * pow(10.0, jogador.tempo_uso_feixe_perielio / 10.0) * fator_critico
			verificar(absf(vida - lua.Vida - esperado) < 0.0001, "dano real por hit incorreto")
			if ultimo_quadro >= 0:
				verificar(absi(quadro - ultimo_quadro - 15) <= 1, "o mesmo alvo não recebeu um hit a cada 0,25 s")
			ultimo_quadro = quadro
			acertos += 1
	verificar(acertos == 8, "a borda da Lua não recebeu quatro hits por segundo")
	lua.global_position.y = 180.0
	vida = lua.Vida
	feixe._processar_feixe_perielio(0.25)
	verificar(is_equal_approx(lua.Vida, vida), "feixe no espaço vazio acertou a Lua")
	testar_impacto_remoto(arena, jogador, lua)
	Input.action_press("atirar")
	jogador._atualizar_feixe_perielio(10.0)
	verificar(jogador.feixe_perielio_ativo == null and feixe.is_queued_for_deletion(), "o feixe não se apagou ao superaquecer")
	jogador._atualizar_feixe_perielio(1.1)
	verificar(is_equal_approx(jogador.calor_feixe_perielio, 0.5) and not jogador.feixe_perielio_pode_causar_dano(), "o bloqueio não acompanha o calor")
	jogador._atualizar_feixe_perielio(1.1)
	jogador._atualizar_feixe_perielio(0.016)
	verificar(is_instance_valid(jogador.feixe_perielio_ativo), "o disparo não retomou ao esfriar")
	Input.action_release("atirar")
	jogador._atualizar_feixe_perielio(0.016)
	await testar_pecas_moveis(arena)
	arena.queue_free()
	await get_tree().process_frame


func testar_pecas_moveis(arena: Node) -> void:
	var feixe := preload("res://Entities/fireball.tscn").instantiate()
	arena.add_child(feixe)
	feixe.set_physics_process(false)
	feixe.configurar_estilo_monthly(&"perielio_ray", Color.GOLD, {})
	feixe.global_position = Vector2(50, 100)
	var pet := preload("res://Entities/BossPet0.tscn").instantiate() as BossPet0
	arena.add_child(pet)
	pet.set_physics_process(false)
	pet.global_position = Vector2(450, 172)
	verificar(not feixe.feixe_intersecta(pet), "o feixe acertou acima da garrafa horizontal")
	pet.visual.rotation = -PI / 2
	await get_tree().process_frame
	verificar(feixe.feixe_intersecta(pet), "a colisão não acompanhou a tampa da garrafa ao girar")
	var flor := preload("res://Entities/BossFlorEquinocio.tscn").instantiate() as BossCaosPrimaveril
	arena.add_child(flor)
	flor.set_physics_process(false)
	flor.global_position = Vector2(450, 162)
	await get_tree().process_frame
	verificar(feixe.feixe_intersecta(flor), "a ponta da pétala visível não foi atingida")
	flor.get_node("Visual/Petalas/Petala0").hide()
	await get_tree().process_frame
	verificar(not feixe.feixe_intersecta(flor), "uma pétala destacada ainda recebeu dano")


func testar_impacto_remoto(arena: Node, jogador: Player, lua: BossSizigiaEterna) -> void:
	var id := "2:1"
	arena.jogadores_rede[2] = jogador
	arena._criar_disparo_visual_rede({
		"id_disparo": id, "peer_id": 2, "estilo": "perielio_ray",
		"posicao": jogador.PontaArma.global_position, "velocidade": 0.0,
	})
	var remoto: Node2D = arena._obter_disparo_visual(id)
	remoto._processar_feixe_perielio(0.25)
	arena.disparos_autorizados_rede[id]["criado_ms"] = Time.get_ticks_msec() - 7000
	arena._limpar_registros_rede()
	verificar(arena.disparos_autorizados_rede.has(id), "o host descartou um feixe ainda ativo")
	arena.disparos_autorizados_rede[id]["criado_ms"] = 1
	var entrada := {
		"chave": id + "#1", "id_disparo": id, "peer_id": 2, "dano": 1.0,
		"caminho": arena.get_path_to(lua), "posicao": jogador.global_position
	}
	lua.global_position.y = 155
	var vida := lua.Vida
	arena._aplicar_impacto_aguardando_rede(entrada, 16001)
	verificar(lua.Vida < vida, "o host recusou o acerto distante de um feixe ativo")
	vida = lua.Vida
	lua.global_position.y = 180
	entrada["chave"] = id + "#2"
	arena._aplicar_impacto_aguardando_rede(entrada, 16251)
	verificar(is_equal_approx(vida, lua.Vida), "o host aceitou um alvo fora do feixe")
	arena._finalizar_disparo_visual(id)


func testar_gelo() -> void:
	var inimigo := InimigoBase.new()
	add_child(inimigo)
	await get_tree().process_frame
	for camada in range(4):
		inimigo.aplicar_camada_gelo(1, true, true)
	verificar(inimigo.camadas_gelo == 4, "as quatro primeiras camadas não acumularam")
	verificar(is_equal_approx(inimigo._fator_velocidade_gelo(), 0.6), "cada camada não reduz 10% da velocidade")
	inimigo.aplicar_camada_gelo(1, true, true)
	verificar(inimigo.congelado_totalmente, "a quinta camada não congelou o inimigo")
	verificar(inimigo.self_modulate.is_equal_approx(Color(0.40, 0.86, 1.0)), "quinta camada não deixa o inimigo totalmente azul-claro")
	verificar(is_equal_approx(inimigo.tempo_morte_congelado, 5.0), "Abaixo de Zero não prolongou o congelamento")
	inimigo.queue_free()
	await get_tree().process_frame


func testar_loja() -> void:
	var loja := (load("res://Rooms/Loja.tscn") as PackedScene).instantiate()
	add_child(loja)
	await get_tree().process_frame
	var rolagem := loja.get("rolagem_detalhes") as ScrollContainer
	var preco := loja.get("detalhe_preco") as Label
	var acao := loja.get("botao_acao") as Button
	var icone := loja.get("detalhe_icone") as TextureRect
	var contexto := loja.get("detalhe_contexto") as Label
	var descricao := loja.get("detalhe_descricao") as Label
	verificar(is_instance_valid(preco) and is_instance_valid(acao), "preço ou botão de ação não foi criado")
	verificar(icone.get_parent() == contexto.get_parent(), "ícone e contexto não usam a linha da v0.7.1")
	verificar(icone.get_parent() is HBoxContainer, "composição de detalhes não restaurou a linha horizontal")
	verificar(descricao.custom_minimum_size.y >= 72.0, "descrição perdeu a altura da v0.7.1")
	verificar(descricao.get_theme_font_size("font_size") == 11, "descrição não usa a tipografia da v0.7.1")
	verificar(not rolagem.is_ancestor_of(preco), "preço ainda está preso à rolagem da descrição")
	verificar(not rolagem.is_ancestor_of(acao), "botão Equipar ainda está preso à rolagem da descrição")
	verificar(acao.custom_minimum_size.y >= 44.0, "botão de ação ficou pequeno demais")
	loja.queue_free()
	await get_tree().process_frame
