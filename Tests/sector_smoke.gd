extends Node


var falhas: Array[String] = []


func verificar(condicao: bool, mensagem: String) -> void:
	if not condicao:
		falhas.append(mensagem)
		push_error("TESTE: " + mensagem)


func _ready() -> void:
	var cena_batalha := load("res://Rooms/Battle_area.tscn") as PackedScene
	verificar(cena_batalha != null, "Battle_area.tscn não carregou")
	if cena_batalha == null:
		get_tree().quit(1)
		return

	var batalha := cena_batalha.instantiate()
	get_tree().root.add_child.call_deferred(batalha)
	await get_tree().process_frame
	get_tree().current_scene = batalha
	await get_tree().process_frame
	await get_tree().process_frame

	verificar(batalha.setor_atual == &"vazio_inicial", "a partida não começou no setor original")
	verificar(batalha.fundo_original.visible, "o fundo original não está visível no primeiro setor")
	verificar(not batalha.fundo_setor.visible, "um fundo temático apareceu no começo")
	verificar(not batalha.escolha_setor_ativa, "a escolha de setor apareceu no início")
	verificar(batalha.proximo_nivel_boss == 10, "o primeiro boss não está configurado para o nível 10")

	batalha.tutorial_ativo = false
	batalha.player.nivel_atual = 10
	batalha.invocar_boss_do_setor()
	await get_tree().process_frame
	verificar(batalha.boss_atual_id == &"pet0", "o boss do nível 10 não é o PET-0")
	verificar(batalha.boss_ativo is BossPet0, "a cena criada no nível 10 não é BossPet0")

	if is_instance_valid(batalha.boss_ativo):
		batalha.boss_ativo.Vida = 0.0
		batalha.boss_ativo.morrer()
	await get_tree().create_timer(1.35, true).timeout
	verificar(&"vazio_inicial" in batalha.setores_concluidos, "o primeiro setor não foi marcado como concluído")
	verificar(batalha.escolha_setor_ativa, "a escolha não apareceu após derrotar o PET-0")
	verificar(batalha.proximo_nivel_boss == 20, "o próximo boss não foi movido para o nível 20")

	var dados_setores = load("res://Scripts/SectorData.gd")
	var opcoes: Array[StringName] = dados_setores.sortear_opcoes(
		batalha.setores_concluidos, batalha.setor_atual, 2
	)
	verificar(opcoes.size() == 2, "a rota não ofereceu duas opções")
	verificar(&"vazio_inicial" not in opcoes, "o setor inicial foi repetido nas rotas")

	batalha.encerrar_escolha_setor()
	batalha.aplicar_setor(&"florescimento")
	verificar(not batalha.fundo_original.visible, "o fundo original permaneceu no setor temático")
	verificar(batalha.fundo_setor.visible, "o fundo minimalista do setor temático não apareceu")
	batalha.player.nivel_atual = 20
	batalha.invocar_boss_do_setor()
	await get_tree().process_frame
	verificar(batalha.boss_atual_id == &"flor_equinocio", "o segundo setor não criou seu próprio boss")
	verificar(not (batalha.boss_ativo is BossPet0), "o PET-0 foi repetido no segundo setor")

	for caminho in [
		"res://Entities/BossEclipseColheita.tscn",
		"res://Entities/BossSentinelaDourada.tscn",
		"res://Entities/BossRupturaLilas.tscn",
	]:
		var cena_boss := load(caminho) as PackedScene
		verificar(cena_boss != null, "%s não carregou" % caminho)
		if cena_boss != null:
			var boss := cena_boss.instantiate()
			batalha.add_child(boss)
			await get_tree().process_frame
			verificar(boss is BossMensal, "%s não usa a base de boss esperada" % caminho)
			verificar(boss.has_method("obter_nome_boss"), "%s não expõe nome no HUD" % caminho)
			boss.queue_free()
			await get_tree().process_frame

	batalha.queue_free()
	await get_tree().process_frame

	var cena_loja := load("res://Rooms/Loja.tscn") as PackedScene
	verificar(cena_loja != null, "Loja.tscn não carregou")
	if cena_loja != null:
		var loja := cena_loja.instantiate()
		get_tree().root.add_child(loja)
		get_tree().current_scene = loja
		await get_tree().process_frame
		await get_tree().process_frame
		verificar(loja.rolagem_grade is ScrollContainer, "a grade da loja não possui scroll")
		verificar(loja.rolagem_detalhes is ScrollContainer, "os detalhes da loja não possuem scroll")
		verificar(loja.botoes_habilidades.size() == loja.habilidades.size(), "cartões da loja não estão navegáveis")

		var aba := InputEventAction.new()
		aba.action = &"proxima_aba"
		aba.pressed = true
		loja._unhandled_input(aba)
		verificar(loja.categoria_atual == 1, "R1 não avançou a aba da loja")
		aba.action = &"aba_anterior"
		loja._unhandled_input(aba)
		verificar(loja.categoria_atual == 0, "L1 não voltou a aba da loja")
		await get_tree().process_frame
		await get_tree().process_frame
		if not loja.botoes_habilidades.is_empty():
			loja.botoes_habilidades[0].grab_focus()
			var aceitar := InputEventAction.new()
			aceitar.action = &"ui_accept"
			aceitar.pressed = true
			loja._input(aceitar)
			verificar(not loja.mensagem.text.is_empty(), "X não confirmou a habilidade focada")
		loja.queue_free()
		await get_tree().process_frame

	if falhas.is_empty():
		print("TESTE OK: setor inicial, PET-0, rotas e controle da loja")
		get_tree().quit(0)
	else:
		print("TESTE FALHOU: %d problema(s)" % falhas.size())
		get_tree().quit(1)
