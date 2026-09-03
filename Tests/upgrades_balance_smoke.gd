extends Node


const DadosUpgrades = preload("res://Scripts/UpgradeData.gd")

var falhas: Array[String] = []


func verificar(condicao: bool, mensagem: String) -> void:
	if condicao:
		return
	falhas.append(mensagem)
	push_error("UPGRADES: " + mensagem)


func _ready() -> void:
	testar_rotas_exclusivas()
	testar_estilos_de_tiro()
	testar_supermod_unico()
	testar_orcamento_de_dano()
	testar_geometria_multitiro()
	testar_evolucoes_de_estilo()
	testar_passivos_de_pilotagem()
	testar_curva_de_xp()
	testar_rerolls_limitados()
	testar_sorteio_compativel()
	finalizar()


func testar_rotas_exclusivas() -> void:
	var niveis := {&"mira_gravitacional": 1}
	verificar(
		not DadosUpgrades.disponivel(&"ricochete", niveis),
		"ricochete permaneceu disponível após escolher a rota gravitacional"
	)
	verificar(
		DadosUpgrades.disponivel(&"mira_gravitacional", niveis),
		"um novo nível da rota gravitacional foi bloqueado indevidamente"
	)
	var carga_pesada := {&"calibre_pesado": 1}
	verificar(
		not DadosUpgrades.disponivel(&"fragmentacao", carga_pesada),
		"fragmentação permaneceu disponível após escolher impacto pesado"
	)


func testar_estilos_de_tiro() -> void:
	var raizes: Array[StringName] = [
		&"tiro_duplo",
		&"calibre_pesado",
		&"fragmentacao",
		&"mira_gravitacional",
		&"ricochete",
	]
	for raiz in raizes:
		verificar(
			DadosUpgrades.disponivel(raiz, {}),
			"o estilo %s não pode ser escolhido desde o começo" % raiz
		)

	var prisma := {&"tiro_duplo": 1}
	for raiz in raizes:
		if raiz == &"tiro_duplo":
			continue
		verificar(
			not DadosUpgrades.disponivel(raiz, prisma),
			"o estilo Prisma não bloqueou a rota incompatível %s" % raiz
		)
	verificar(
		DadosUpgrades.disponivel(&"tiro_triplo", prisma),
		"a evolução Tridente não apareceu após escolher Prisma"
	)
	var rotas := DadosUpgrades.rotas_ativas(prisma)
	verificar(
		rotas[DadosUpgrades.SLOT_ESTILO_TIRO] == &"multitiro",
		"a construção atual não identificou o estilo Prisma"
	)

	for _tentativa in range(30):
		var opcoes := DadosUpgrades.sortear(prisma, 3)
		for id in opcoes:
			var dados := DadosUpgrades.obter(id)
			if dados.get("slot_estrutural", &"") != DadosUpgrades.SLOT_ESTILO_TIRO:
				continue
			verificar(
				dados.get("rota_estrutural", &"") == &"multitiro",
				"o sorteio misturou outro estilo com a construção Prisma"
			)


func testar_supermod_unico() -> void:
	var niveis := {
		&"tempestade_prismatica": 1,
		&"calibre_pesado": 2,
		&"mira_gravitacional": 2,
	}
	verificar(
		not DadosUpgrades.disponivel(&"singularidade", niveis),
		"um segundo Supermod ficou disponível na mesma partida"
	)
	var somente_nova := {&"nova_ativacao": 1}
	var rotas := DadosUpgrades.rotas_ativas(somente_nova)
	verificar(
		rotas[DadosUpgrades.SLOT_SUPERMOD] == &"",
		"Nova de Ativação ocupou incorretamente o espaço de Supermod"
	)


func testar_orcamento_de_dano() -> void:
	var player := Player.new()
	player.niveis_upgrades[&"tiro_duplo"] = 1
	player.aplicar_upgrade(&"tiro_duplo")
	verificar(player.projeteis_por_tiro == 2, "Tiro Duplo não criou 2 projéteis")
	verificar(
		is_equal_approx(player.multiplicador_dano_forma, 0.62),
		"Tiro Duplo não aplicou 62% de dano por projétil"
	)

	player.niveis_upgrades[&"tiro_triplo"] = 1
	player.aplicar_upgrade(&"tiro_triplo")
	verificar(player.projeteis_por_tiro == 3, "Tiro Triplo não criou 3 projéteis")
	verificar(
		is_equal_approx(player.multiplicador_dano_forma, 0.42),
		"Tiro Triplo não aplicou 42% de dano por projétil"
	)

	player.niveis_upgrades[&"mira_gravitacional"] = 1
	player.aplicar_upgrade(&"mira_gravitacional")
	verificar(
		is_equal_approx(player.multiplicador_dano_mira, 0.88),
		"Mira Gravitacional não aplicou seu custo de 12% de dano"
	)
	var dps_teorico := (
		player.projeteis_por_tiro
		* player.multiplicador_dano_forma
		* player.multiplicador_dano_mira
	)
	verificar(
		dps_teorico <= 1.12,
		"Tiro Triplo com gravidade ultrapassou o orçamento inicial previsto"
	)
	player.free()


func testar_geometria_multitiro() -> void:
	var player := Player.new()
	var duplo_esquerdo := player.calcular_padrao_multitiro(0, 2)
	var duplo_direito := player.calcular_padrao_multitiro(1, 2)
	verificar(
		is_zero_approx(duplo_esquerdo.x) and is_zero_approx(duplo_direito.x),
		"o Tiro Duplo deixou de viajar em paralelo"
	)
	verificar(
		duplo_esquerdo.y < 0.0 and duplo_direito.y > 0.0,
		"o Tiro Duplo não separou as duas linhas na origem"
	)

	var tridente_esquerdo := player.calcular_padrao_multitiro(0, 3)
	var tridente_centro := player.calcular_padrao_multitiro(1, 3)
	var tridente_direito := player.calcular_padrao_multitiro(2, 3)
	verificar(
		tridente_esquerdo.x < 0.0
		and is_zero_approx(tridente_centro.x)
		and tridente_direito.x > 0.0,
		"a Formação Tridente perdeu o centro e os dois laterais"
	)

	player.formacao_convergente = true
	var convergente_esquerdo := player.calcular_padrao_multitiro(0, 3)
	var convergente_direito := player.calcular_padrao_multitiro(2, 3)
	verificar(
		convergente_esquerdo.x > 0.0 and convergente_direito.x < 0.0,
		"a Formação Convergente não cruza as trajetórias à frente"
	)
	player.free()


func testar_evolucoes_de_estilo() -> void:
	var player := Player.new()
	player.niveis_upgrades = {
		&"tiro_duplo": 1,
		&"tiro_triplo": 1,
		&"formacao_convergente": 1,
	}
	player.aplicar_upgrade(&"tiro_duplo")
	player.aplicar_upgrade(&"tiro_triplo")
	player.aplicar_upgrade(&"formacao_convergente")
	verificar(player.formacao_convergente, "a formação convergente não foi ativada")

	var pesado := Player.new()
	pesado.niveis_upgrades = {&"calibre_pesado": 2, &"onda_impacto": 1}
	pesado.aplicar_upgrade(&"calibre_pesado")
	pesado.aplicar_upgrade(&"onda_impacto")
	verificar(pesado.dano_explosao_impacto > 0.0, "a onda de impacto não ganhou dano em área")
	verificar(pesado.raio_explosao_impacto >= 54.0, "a onda de impacto não ganhou raio")
	player.free()
	pesado.free()


func testar_passivos_de_pilotagem() -> void:
	var player := Player.new()
	player.niveis_upgrades = {
		&"vetor_ofensivo": 1,
		&"casco_regenerativo": 1,
		&"capacitor_cinetico": 1,
		&"reacao_adrenal": 1,
	}
	for id in player.niveis_upgrades:
		player.aplicar_upgrade(id)
	verificar(player.bonus_vetor_ofensivo > 0.0, "Vetor Ofensivo não alterou a pilotagem")
	verificar(player.regeneracao_casco_por_segundo > 0.0, "Casco Regenerativo não foi ativado")
	verificar(player.nivel_capacitor_cinetico == 1, "Capacitor Cinético não ganhou nível")
	verificar(player.bonus_cadencia_reacao > 0.0, "Reação Adrenal não foi ativada")
	player.free()


func testar_curva_de_xp() -> void:
	var player := Player.new()
	var esperada := [2, 3, 4, 6, 8, 11, 14, 18, 23]
	for indice in range(esperada.size()):
		verificar(
			player.calcular_xp_proximo_nivel(indice + 1) == esperada[indice],
			"a curva inicial de XP divergiu no nível %d" % (indice + 1)
		)
	verificar(
		player.calcular_xp_proximo_nivel(11) > player.calcular_xp_proximo_nivel(10),
		"a curva de XP não continuou crescendo após o nível 10"
	)
	player.free()


func testar_rerolls_limitados() -> void:
	var player := Player.new()
	verificar(player.gastar_reroll_upgrade(), "o primeiro reroll falhou")
	verificar(player.gastar_reroll_upgrade(), "o segundo reroll falhou")
	verificar(player.gastar_reroll_upgrade(), "o terceiro reroll falhou")
	verificar(not player.gastar_reroll_upgrade(), "um quarto reroll foi permitido")
	verificar(
		player.rerolls_upgrades_restantes == 0,
		"a contagem de rerolls ficou negativa ou inconsistente"
	)
	player.free()


func testar_sorteio_compativel() -> void:
	var niveis := {&"mira_gravitacional": 1}
	for _tentativa in range(40):
		var opcoes := DadosUpgrades.sortear(niveis, 3)
		verificar(&"ricochete" not in opcoes, "o sorteio ofereceu uma rota incompatível")
		var unicas := {}
		for id in opcoes:
			unicas[id] = true
		verificar(unicas.size() == opcoes.size(), "o sorteio repetiu uma carta na oferta")


func finalizar() -> void:
	if falhas.is_empty():
		print("TESTE OK: rotas, limites e orçamento das melhorias")
		get_tree().quit(0)
	else:
		print("TESTE FALHOU: %d problema(s) de balanceamento" % falhas.size())
		get_tree().quit(1)
