extends Node

class AlvoTeste extends Node2D:
	var morto := false
	var dano_recebido := 0.0
	func tomarDano(valor: float) -> void:
		dano_recebido += valor

var falhas: Array[String] = []


func verificar(condicao: bool, mensagem: String) -> void:
	if not condicao:
		falhas.append(mensagem)
		push_error("PASSIVAS: " + mensagem)


func _ready() -> void:
	var neon_anterior: float = Global.neon
	var bloom_anterior: float = Global.bloom
	Global.neon = 2.0
	Global.bloom = 0.5
	verificar(is_equal_approx(Global.neon, 0.4) and is_equal_approx(Global.bloom, 0.1), "limites nao impediram brilho acima de 40%/20%")
	for renderer in [&"mobile", &"gl_compatibility", &"forward_plus"]:
		var ambiente := Environment.new()
		Global.configurar_glow(ambiente, renderer)
		verificar(ambiente.glow_intensity <= 0.4001 and ambiente.glow_bloom <= 0.1001, "renderer ultrapassou limite de brilho")
	Global.neon = -1.0
	Global.bloom = -1.0
	verificar(is_zero_approx(Global.neon) and is_zero_approx(Global.bloom), "limite inferior nao respeitado")
	Global.neon = neon_anterior
	Global.bloom = bloom_anterior
	var configuracoes := (load("res://Janela_Configurações.tscn") as PackedScene).instantiate()
	var graficos := configuracoes.get_node("Painel/Margem/Coluna/Abas/GRAFICOS/Conteudo")
	verificar(is_equal_approx(graficos.get_node("Neon/Controle").max_value, 0.4), "slider permite neon excessivo")
	verificar(is_equal_approx(graficos.get_node("Bloom/Controle").max_value, 0.1), "slider permite bloom excessivo")
	configuracoes.free()
	var catalogo = preload("res://Scripts/MonthlyCatalog.gd")
	verificar(catalogo.encontrar(&"n04_armadura_aco").is_empty(), "armadura ainda esta no catalogo")
	verificar(catalogo.encontrar(&"n06_scanner_preventivo").is_empty(), "scanner ainda esta no catalogo")
	verificar(catalogo.encontrar(&"n05_reserva_solidaria").nome == "ESTRELAS SOLIDÁRIAS", "nome novo nao preservou o ID do save")

	var batalha := (load("res://Rooms/Battle_area.tscn") as PackedScene).instantiate()
	get_tree().root.add_child.call_deferred(batalha)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	batalha.set("tutorial_ativo", false)
	batalha.set("spawns_pausados_desenvolvedor", true)
	var astro := batalha.get_node_or_null("GUI/Astro")
	if is_instance_valid(astro):
		astro.set_process_input(false)
		astro.hide()
	var jogador := batalha.get_node("Player") as Player
	jogador.set_process(false)
	jogador.DesbloquearControle()
	jogador.giroblock = false
	jogador.invulneravel_por_habilidade = false
	jogador.invulneravel_desenvolvedor = false
	jogador.multiplicador_dano_recebido = 1.0
	jogador.resistencia_temporaria_multiplicador = 1.0
	jogador.vivo = true
	var passivas = jogador.passivas_nave
	passivas.set_process(false)
	jogador.rotation = 0.0
	jogador.modulo_nave = &"n01_reflexos_rapidos"
	passivas.atualizar_propulsao(true, false, 0.01)
	verificar(is_zero_approx(passivas.tempo_arrancada), "um toque ativou arrancada")
	passivas.atualizar_propulsao(true, false, 0.1)
	verificar(is_zero_approx(passivas.tempo_arrancada), "segurar acelerar ativou arrancada")
	passivas.atualizar_propulsao(false, false, 0.03)
	jogador.velocity = Vector2.ZERO
	passivas.atualizar_propulsao(true, false, 0.03)
	verificar(jogador.velocity.x > 170.0 and passivas.tempo_arrancada > 0.0, "duplo toque nao deu arrancada frontal")
	verificar(is_zero_approx(jogador.rotation), "arrancada alterou a mira")
	passivas.atualizar_propulsao(false, false, 0.01)
	passivas.atualizar_propulsao(true, false, 0.2)
	verificar(is_zero_approx(passivas.tempo_arrancada), "recarga permitiu repetir arrancada")
	passivas.atualizar_propulsao(false, false, 1.2)
	passivas.atualizar_propulsao(true, false, 0.01)
	passivas.atualizar_propulsao(false, false, 0.31)
	passivas.atualizar_propulsao(true, false, 0.01)
	verificar(is_zero_approx(passivas.tempo_arrancada), "toques distantes ativaram arrancada")
	# Integra a deteccao com a entrada real e com o limite de velocidade.
	passivas.recarga = 0.0
	passivas.janela_toque = 0.0
	passivas.frente_anterior = false
	var mira_anterior: bool = jogador.mira_mouse
	jogador.mira_mouse = false
	jogador.velocity = Vector2(jogador.MAX_VELOCIDADE, 0)
	Input.action_press("acelerar")
	jogador.atualizar_movimento(0.01)
	Input.action_release("acelerar")
	jogador.atualizar_movimento(0.03)
	Input.action_press("acelerar")
	jogador.atualizar_movimento(0.03)
	Input.action_release("acelerar")
	verificar(jogador.velocity.length() > jogador.MAX_VELOCIDADE, "limite normal anulou o impulso da arrancada")
	jogador.mira_mouse = mira_anterior

	jogador.modulo_nave = &"n07_propulsor_janus"
	passivas.atualizar_propulsao(true, false, 0.01)
	var frente: Vector2 = jogador.global_position + Vector2(100, 0)
	var traseira: Vector2 = jogador.global_position - Vector2(100, 0)
	var lateral: Vector2 = jogador.global_position + Vector2(0, 100)
	verificar(passivas.multiplicador_protecao(frente) < 1.0, "acelerar nao protegeu a frente")
	verificar(is_equal_approx(passivas.multiplicador_protecao(traseira), 1.0), "acelerar protegeu o lado errado")
	verificar(is_equal_approx(passivas.multiplicador_protecao(lateral), 1.0), "lateral recebeu protecao indevida")
	passivas.atualizar_propulsao(false, true, 0.01)
	verificar(passivas.multiplicador_protecao(traseira) < 1.0 and is_equal_approx(passivas.multiplicador_protecao(frente), 1.0), "re nao inverteu protecao")
	passivas.atualizar_propulsao(false, false, 0.01)
	verificar(is_equal_approx(passivas.multiplicador_protecao(traseira), 1.0), "inercia manteve protecao sem propulsao")
	passivas.atualizar_propulsao(true, false, 0.01)
	jogador.vida = 100.0
	jogador.invencibilidade = false
	jogador.escudo_habilidade = 0.0
	jogador.tomar_dano(10.0, frente)
	verificar(is_equal_approx(jogador.vida, 92.2), "dano direcional nao aplicou protecao real")
	verificar(is_equal_approx(passivas.multiplicador_protecao(Vector2.INF), 1.0), "dano sem origem recebeu protecao")

	jogador.modulo_nave = &"n05_reserva_solidaria"
	jogador.VIDA_MAXIMA = 100.0
	jogador.vida = 90.0
	jogador.curar(8.0)
	verificar(jogador.estrelas_solidarias == Vector4.ZERO, "cura sem excedente criou estrelas")
	jogador.curar(10.0)
	verificar(is_equal_approx(jogador.vida, 100.0) and jogador.estrelas_solidarias.is_equal_approx(Vector4.ONE * 2.0), "cura excedente nao foi dividida em quatro estrelas")
	jogador.invencibilidade = false
	jogador.tomar_dano(5.0)
	verificar(is_equal_approx(jogador.vida, 95.0) and jogador.estrelas_solidarias.is_equal_approx(Vector4.ONE * 2.0), "estrelas ainda absorvem dano")
	var alvo := AlvoTeste.new()
	get_tree().root.add_child(alvo)
	alvo.add_to_group("inimigo")
	alvo.global_position = passivas.to_global(passivas.posicao_estrela(0))
	passivas.atingir_inimigos()
	verificar(is_equal_approx(alvo.dano_recebido, 2.0) and is_zero_approx(jogador.estrelas_solidarias.x), "estrela nao gastou sua carga ao atingir inimigo")
	passivas.atingir_inimigos()
	verificar(is_equal_approx(alvo.dano_recebido, 2.0), "estrela consumida causou dano duplicado")
	jogador.curar(1000.0)
	verificar(jogador.estrelas_solidarias.is_equal_approx(Vector4.ONE * 8.75), "cura excedente acumulou dano ilimitado")
	# Uma copia remota apenas desenha: nao consome estrelas nem aplica dano.
	jogador.set_multiplayer_authority(2)
	Rede.modo_multiplayer = true
	passivas.atingir_inimigos()
	verificar(is_equal_approx(alvo.dano_recebido, 2.0) and jogador.estrelas_solidarias.x > 0.0, "copia remota causou dano ou gastou carga")
	Rede.modo_multiplayer = false
	jogador.set_multiplayer_authority(1)
	var sync := jogador.get_node("MultiplayerSynchronizer") as MultiplayerSynchronizer
	verificar(sync.replication_config.has_property(NodePath(".:estrelas_solidarias")), "cargas nao entram na replicacao")
	verificar(sync.replication_config.has_property(NodePath(".:direcao_propulsao")), "lado de protecao nao entra na replicacao")
	jogador.vivo = false
	passivas._process(0.01)
	verificar(jogador.estrelas_solidarias == Vector4.ZERO, "morte manteve estrelas ativas")
	alvo.queue_free()
	batalha.queue_free()
	await get_tree().process_frame
	print("TESTE %s: limites de brilho, duplo toque, quatro estrelas, protecao direcional e remocao de passivas" % ("OK" if falhas.is_empty() else "FALHOU"))
	get_tree().quit(0 if falhas.is_empty() else 1)
