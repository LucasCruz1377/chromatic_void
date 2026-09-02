extends Node


var falhas: Array[String] = []
var arena: Node2D
var boss: BossCaosPrimaveril


func verificar(condicao: bool, mensagem: String) -> void:
	if not condicao:
		falhas.append(mensagem)
		push_error("CAOS PRIMAVERIL: " + mensagem)


func _ready() -> void:
	arena = Node2D.new()
	get_tree().root.add_child.call_deferred(arena)
	await get_tree().process_frame
	get_tree().current_scene = arena

	var cena := load("res://Entities/BossFlorEquinocio.tscn") as PackedScene
	verificar(cena != null, "a cena do boss não carregou")
	if cena == null:
		finalizar()
		return

	boss = cena.instantiate() as BossCaosPrimaveril
	arena.add_child(boss)
	boss.global_position = Vector2(480.0, 270.0)
	await get_tree().process_frame
	boss.process_mode = Node.PROCESS_MODE_DISABLED

	verificar(boss.obter_nome_boss() == "CAOS PRIMAVERIL", "o HUD não recebeu o novo nome")
	verificar(boss.petalas.get_child_count() == 6, "a arte não possui seis pétalas separadas")
	verificar(boss.espinhos_ornamentais.get_child_count() == 6, "a arte não possui seis espinhos separados")
	verificar(boss.escudo_ativo and boss.polen.visible, "o escudo de pólen não inicia ativo")
	verificar(boss.VidaMaxima >= 350.0, "a vida do boss voltou ao valor fácil anterior")
	verificar(boss.Dano >= 34.0, "o dano do boss voltou ao valor fácil anterior")
	verificar(boss.intervalo_ataques <= 1.6, "o intervalo entre ataques está lento demais")
	var escala_boss := boss.scale
	boss.reproduzir_impacto()
	boss.reproduzir_impacto()
	verificar(
		boss.scale.is_equal_approx(escala_boss),
		"o feedback de dano alterou ou acumulou a escala do boss"
	)

	var vida_inicial: float = boss.Vida
	boss.tomarDano(40.0)
	verificar(is_equal_approx(boss.Vida, vida_inicial), "o pólen não bloqueou o dano")
	boss.ativar_escudo(false)
	boss.tomarDano(10.0)
	verificar(boss.Vida < vida_inicial, "a janela vulnerável não recebe dano")
	boss.Vida = boss.VidaMaxima

	limpar_projeteis()
	boss.fase = 3
	boss.disparar_anel_espinhos()
	await get_tree().process_frame
	verificar(
		get_tree().get_nodes_in_group("projetil_primaveril").size() == 11,
		"a onda da fase 3 não lançou onze espinhos"
	)
	limpar_projeteis()
	await get_tree().process_frame

	boss.iniciar_petalas_bumerangue()
	await get_tree().process_frame
	verificar(not boss.escudo_ativo, "o boss não ficou vulnerável durante as pétalas")
	verificar(boss.petalas_em_voo == 4, "a fase 3 não lançou quatro pétalas")
	verificar(contar_petalas_ocultas() == 4, "as pétalas lançadas continuaram presas ao corpo")
	verificar(
		get_tree().get_nodes_in_group("projetil_primaveril").size() == 4,
		"as pétalas não foram criadas como projéteis próprios"
	)
	await get_tree().create_timer(0.15).timeout
	verificar(contar_rastros() > 0, "as pétalas bumerangue não produziram rastro")
	await get_tree().create_timer(2.25).timeout
	verificar(boss.petalas_em_voo == 0, "as pétalas não voltaram ao boss em linha reta")
	verificar(contar_petalas_ocultas() == 0, "as pétalas não reencaixaram no corpo")

	boss.criar_vinhas()
	await get_tree().process_frame
	verificar(boss.vinhas_ativas.size() == 4, "a Dança dos Caules não criou quatro vinhas")
	var comprimentos_esperados := [560.0, 560.0, 560.0, 560.0]
	for indice in boss.vinhas_ativas.size():
		var vinha := boss.vinhas_ativas[indice]
		verificar(
			is_equal_approx(vinha.comprimento, comprimentos_esperados[indice]),
			"a vinha %d não alcança sua borda da arena" % indice
		)
		verificar(not vinha.dano_ativo, "uma vinha causou dano durante o crescimento")
		verificar(
			is_instance_valid(vinha.particulas) and vinha.particulas.emitting,
			"uma vinha foi criada sem partículas ativas"
		)
		vinha.ativar_dano()
		verificar(vinha.dano_ativo, "uma vinha não ativou o dano depois do aviso")
	boss.estado = BossCaosPrimaveril.Estado.CRESCENDO_VINHAS
	boss.tempo_estado = 0.0
	boss.crescer_vinhas(0.0)
	verificar(boss.tempo_estado >= 10.5, "a Dança dos Caules não recebeu os cinco segundos extras")
	verificar(boss.estado == BossCaosPrimaveril.Estado.DANCA_VINHAS, "a dança não iniciou após o crescimento")
	boss.limpar_vinhas()

	finalizar()


func contar_petalas_ocultas() -> int:
	var quantidade := 0
	for petala in boss.petalas.get_children():
		if not petala.visible:
			quantidade += 1
	return quantidade


func contar_rastros() -> int:
	return get_tree().get_nodes_in_group("rastro_petala").size()


func limpar_projeteis() -> void:
	for projetil in get_tree().get_nodes_in_group("projetil_primaveril"):
		if is_instance_valid(projetil):
			projetil.queue_free()


func finalizar() -> void:
	if is_instance_valid(boss):
		boss.queue_free()
	if is_instance_valid(arena):
		arena.queue_free()
	await get_tree().process_frame
	if falhas.is_empty():
		print("TESTE OK: quatro mecânicas do Caos Primaveril")
		get_tree().quit(0)
	else:
		print("TESTE FALHOU: %d problema(s) no Caos Primaveril" % falhas.size())
		get_tree().quit(1)
