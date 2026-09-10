extends Node


var falhas: Array[String] = []


func verificar(condicao: bool, mensagem: String) -> void:
	if not condicao:
		falhas.append(mensagem)
		push_error("REWORK HABILIDADES: " + mensagem)


func _ready() -> void:
	var ids: Array[StringName] = []
	for item in MonthlyCatalog.ativos():
		ids.append(StringName(item.get("id", &"")))
	verificar(ids.size() == 14, "catálogo ativo não ficou com 14 habilidades")
	verificar(&"p09_recomeco" not in ids, "Recomeço continua disponível")

	var ovo := load("res://Habilidades/monthly_p01.tres") as HabilidadeMonthly
	var flor := load("res://Habilidades/monthly_p05.tres") as HabilidadeMonthly
	var tempestade := load("res://Habilidades/monthly_p14.tres") as HabilidadeMonthly
	verificar(ovo.obter_upgrades_especificos().size() == 3, "Ovo não recebeu cura, dano e duração")
	verificar(flor.obter_upgrades_especificos().size() == 4, "Florescimento não recebeu a melhoria de raízes")
	verificar(tempestade.obter_upgrades_especificos().size() == 3, "Tempestade não recebeu dano, duração e perfuração")

	var cura_inicial := float(ovo._config_rework().get("cura", 0.0))
	ovo.aplicar_upgrade_especifico(&"ovo_cura", 1)
	verificar(float(ovo._config_rework().get("cura", 0.0)) > cura_inicial, "upgrade de cura do Ovo não altera o efeito")
	flor.aplicar_upgrade_especifico(&"flor_sementes", 1)
	verificar(bool(flor._config_rework().get("projeteis_explosao", false)), "Florescimento não libera pétalas na explosão")
	verificar(int(flor._config_rework().get("limite_raizes", 0)) == 3, "Florescimento não começa limitado a três raízes")
	flor.aplicar_upgrade_especifico(&"flor_raizes", 1)
	flor.aplicar_upgrade_especifico(&"flor_raizes", 2)
	verificar(int(flor._config_rework().get("limite_raizes", 0)) == 5, "melhoria não eleva as raízes até cinco")
	tempestade.aplicar_upgrade_especifico(&"tempestade_perfuracao", 1)
	verificar(int(tempestade._config_rework().get("perfuracao", 0)) == 1, "Tempestade não ganhou perfuração")
	verificar(float(tempestade._config_rework().get("duracao", 0.0)) >= 7.0, "Tempestade dura menos de 7 segundos")
	verificar(float(tempestade._config_rework().get("dano", 0.0)) >= 5.0, "Tempestade causa menos de 5 por folha")

	var efeito := FileAccess.get_file_as_string("res://Scripts/MonthlyAbilityEffect.gd")
	verificar('duracao = 3.5' in efeito, "Forma Fantasma não dura 3,5 segundos")
	verificar('randf_range(0.5, 0.7)' in efeito, "orbes fantasmas não respeitam intervalo de 0,5–0,7 s")
	verificar('deg_to_rad(315.0)' in efeito, "folhas não apontam para 315 graus")
	verificar(efeito.count('_criar_folha()') >= 3, "Tempestade não gera duas folhas por ciclo")
	verificar('tempestade_gerando = false' in efeito, "Tempestade não preserva as folhas após parar a chuva")
	verificar('set_collision_mask_value(3, false)' in efeito, "Forma Fantasma não desliga colisão com inimigos")
	var interface_upgrades := FileAccess.get_file_as_string("res://Scripts/tela_upgrades.gd")
	verificar('[TAB]' not in interface_upgrades, "botão de melhorias ainda fixa TAB no texto")
	verificar('obter_evento_mapeado(&"abrir_melhorias"' in interface_upgrades, "botão de melhorias não consulta o remapeamento")
	var seguidor_cena := load("res://Entities/InimigoSeguidor.tscn") as PackedScene
	var seguidor_config := seguidor_cena.instantiate() as InimigoBase
	verificar(not seguidor_config.morre_ao_colidir_player, "Seguidor ainda morre ao colidir com o jogador")
	seguidor_config.free()

	var foco := FileAccess.get_file_as_string("res://Habilidades/FocoAbsoluto.gd")
	verificar('foco_movimento_tempo_real = true' in foco, "Foco Absoluto não preserva o movimento real")

	await _testar_execucao_em_batalha()

	if falhas.is_empty():
		print("TESTE OK: sete reworks, upgrades e remoção de Recomeço protegidos")
	get_tree().quit(0 if falhas.is_empty() else 1)


func _testar_execucao_em_batalha() -> void:
	var batalha := (load("res://Rooms/Battle_area.tscn") as PackedScene).instantiate()
	add_child(batalha)
	await get_tree().process_frame
	var jogador := batalha.get_node("Player") as Player
	for modo in [&"florescimento", &"presente"]:
		var efeito := MonthlyAbilityEffect.criar(batalha, jogador, modo, Color("ff68ae"), 1.0, {"duracao": 0.2})
		efeito._process(0.1)
		efeito._finalizar()
	var tempestade_efeito := MonthlyAbilityEffect.criar(
		batalha, jogador, &"tempestade", Color("69ff8f"), 1.0, {"duracao": 0.05}
	)
	# Encurta somente o relógio deste teste para validar a transição pós-chuva.
	tempestade_efeito.duracao = 0.05
	tempestade_efeito._process(0.06)
	verificar(tempestade_efeito.folhas.size() == 2, "Tempestade não dobrou a densidade de folhas")
	verificar(not tempestade_efeito.is_queued_for_deletion(), "Tempestade apagou folhas ainda em percurso")
	verificar(not tempestade_efeito.tempestade_gerando, "Tempestade continuou gerando após a duração")
	tempestade_efeito.folhas.clear()
	tempestade_efeito._process(0.01)
	var seguidor := (load("res://Entities/InimigoSeguidor.tscn") as PackedScene).instantiate() as InimigoBase
	batalha.add_child(seguidor)
	seguidor.global_position = jogador.global_position + Vector2(250.0, 0.0)
	var presente_efeito := MonthlyAbilityEffect.criar(batalha, jogador, &"presente", Color("ff68ae"), 1.0)
	presente_efeito._processar_presente(0.1)
	verificar(seguidor.has_meta("presente_misterioso_alvo"), "Presente não captura o inimigo que entra no raio")
	presente_efeito._finalizar()
	var alvos_laco: Array[Node2D] = [seguidor]
	var laco := LacoUniaoAlvo.new()
	batalha.add_child(laco)
	laco.configurar(Global.obter_retangulo_area_visivel().get_center(), alvos_laco, Color("ff5b8d"), 1.0)
	laco._process(1.1)
	verificar(laco.alvos.size() == 1, "Laço perdeu seus alvos por erro de tipagem")
	verificar(laco.get_child_count() > 0 and laco.get_child(0) is CollisionShape2D, "Laço central não possui colisão destrutível")
	laco._romper()
	verificar(seguidor.morto, "Romper o laço não derrotou o inimigo conectado")
	var fantasma := MonthlyAbilityEffect.criar(batalha, jogador, &"fantasma", Color("a978ff"), 1.0)
	verificar(not jogador.get_collision_mask_value(3), "Forma Fantasma manteve colisão inimiga")
	fantasma._finalizar()
	verificar(jogador.get_collision_mask_value(3), "Forma Fantasma não restaurou a colisão")
	var ovo_efeito := MonthlyAbilityEffect.criar(batalha, jogador, &"ovo", Color("ffd45a"), 1.0)
	ovo_efeito.resultado_ovo = 0
	ovo_efeito._resolver_ovo()
	await get_tree().process_frame
	verificar(not get_tree().get_nodes_in_group("ajudante_ovo").is_empty(), "Ovo não criou o ajudante")
	batalha.queue_free()
	await get_tree().process_frame
