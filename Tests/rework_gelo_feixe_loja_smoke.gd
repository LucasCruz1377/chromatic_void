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
	jogador.tempo_uso_feixe_perielio = 0.0
	verificar(is_equal_approx(jogador.obter_dps_feixe_perielio(), 0.2), "feixe não começa em 0,2 DPS")
	jogador.tempo_uso_feixe_perielio = 0.49
	verificar(is_equal_approx(jogador.obter_dps_feixe_perielio(), 0.2), "feixe aumenta antes de completar 0,5 segundo")
	jogador.tempo_uso_feixe_perielio = 0.5
	verificar(jogador.obter_dps_feixe_perielio() > 0.2, "feixe não aumenta no primeiro intervalo de 0,5 segundo")
	jogador.tempo_uso_feixe_perielio = 10.0
	verificar(is_equal_approx(jogador.obter_dps_feixe_perielio(), 5.0), "feixe base não chega a 5 DPS")
	jogador.niveis_upgrades = {&"perielio_potencia": 3, &"perielio_resfriamento": 2}
	verificar(is_equal_approx(jogador.obter_dps_feixe_perielio(), 30.0), "melhorias não elevam o teto até 30 DPS")
	verificar(is_equal_approx(jogador.obter_limite_uso_feixe_perielio(), 15.0), "resfriamento não amplia o uso contínuo")
	jogador.free()


func testar_localizacao() -> void:
	var locale_anterior := TranslationServer.get_locale()
	TranslationServer.set_locale("en")
	verificar(tr("VAZIO") == "VOID", "locale inglês não traduz VAZIO para VOID")
	verificar(tr("FEIXE DO PERIÉLIO") == "PERIHELION BEAM", "catálogo da loja não usa a tradução em inglês")
	TranslationServer.set_locale(locale_anterior)


func testar_visual_feixe() -> void:
	var feixe := (load("res://Entities/fireball.tscn") as PackedScene).instantiate()
	add_child(feixe)
	feixe.configurar_estilo_monthly(&"perielio_ray", Color("ffd83d"), {})
	verificar(feixe.get("linha_feixe") is Line2D, "feixe externo não usa Line2D")
	verificar(feixe.get("centro_feixe") is Line2D, "centro branco do feixe não usa Line2D")
	verificar(feixe.get("raycast_feixe") is RayCast2D, "feixe não cria RayCast2D")
	var centro := feixe.get("centro_feixe") as Line2D
	verificar(is_instance_valid(centro) and centro.default_color == Color.WHITE, "centro do feixe não começa branco")
	feixe.queue_free()
	await get_tree().process_frame


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
