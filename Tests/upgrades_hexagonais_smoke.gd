extends Node

var falhas: Array[String] = []
var batalha: Node2D
var jogador: Player
var menu: Control


func verificar(condicao: bool, mensagem: String) -> void:
	if not condicao:
		falhas.append(mensagem)
		push_error("HEXAGONOS: " + mensagem)


func _ready() -> void:
	for argumento in OS.get_cmdline_user_args():
		if argumento.begins_with("--hex-preview="):
			Global.idioma = "pt_BR"
			TranslationServer.set_locale("pt_BR")
	batalha = (load("res://Rooms/Battle_area.tscn") as PackedScene).instantiate() as Node2D
	get_tree().root.add_child.call_deferred(batalha)
	await get_tree().process_frame
	get_tree().current_scene = batalha
	await get_tree().process_frame
	await get_tree().process_frame
	batalha.set("tutorial_ativo", false)
	var astro := batalha.get_node_or_null("GUI/Astro")
	if is_instance_valid(astro):
		astro.set_process_input(false)
		astro.hide()
	batalha.set("spawns_pausados_desenvolvedor", true)
	jogador = batalha.get_node("Player") as Player
	jogador.DesbloquearControle()
	jogador.vida = jogador.VIDA_MAXIMA
	jogador.vivo = true
	jogador.UsandoHabilidade = false
	jogador.pontos_upgrade_pendentes = 1
	menu = batalha.get_node("GUI/TelaUpgrades") as Control
	menu.abrir_menu()
	await get_tree().process_frame
	await get_tree().process_frame
	verificar(menu.container_cards.get_child_count() == 3, "a tela nao apresentou tres opcoes")
	verificar(not menu.painel_descricao.visible, "descricao apareceu antes da primeira escolha")
	var primeiro := menu.container_cards.get_child(0) as UpgradeCardNova
	var segundo := menu.container_cards.get_child(1) as UpgradeCardNova
	var terceiro := menu.container_cards.get_child(2) as UpgradeCardNova
	verificar(is_equal_approx(primeiro.position.x + primeiro.size.x, segundo.position.x), "existe margem entre o primeiro e segundo hexagonos")
	verificar(is_equal_approx(segundo.position.x + segundo.size.x, terceiro.position.x), "existe margem entre o segundo e terceiro hexagonos")
	verificar(primeiro.scale == Vector2.ONE, "hexagono foi escalado e rompeu o encaixe")
	await clicar(primeiro.botao, Vector2(2, 2))
	verificar(menu.upgrade_previsualizado == &"", "canto fora do hexagono aceitou clique")
	await clicar(primeiro.botao, primeiro.size * 0.5)
	verificar(jogador.pontos_upgrade_pendentes == 1, "primeiro clique gastou ponto")
	verificar(primeiro.selecionado and not segundo.selecionado, "primeiro clique nao destacou somente uma opcao")
	verificar(menu.painel_descricao.visible, "primeiro clique nao revelou a descricao")
	var dados := UpgradeData.obter(primeiro.upgrade_id, jogador.HabilidadeEquipada)
	verificar(menu.nome_melhoria.text == tr(str(dados.nome)), "nome exibido nao corresponde a opcao selecionada")
	verificar(menu.descricao_melhoria.text == tr(str(dados.descricao)), "descricao exibida nao corresponde a opcao selecionada")
	verificar(menu.linha_destaque.color.is_equal_approx(primeiro.cor_destaque), "destaque nao usa a cor da melhoria")
	await salvar_previa_se_solicitada()
	await clicar(segundo.botao, segundo.size * 0.5)
	verificar(jogador.pontos_upgrade_pendentes == 1 and not primeiro.selecionado and segundo.selecionado, "trocar de opcao comprou ou manteve destaque antigo")
	var escolhido := segundo.upgrade_id
	var nivel_antes := int(jogador.niveis_upgrades.get(escolhido, 0))
	await clicar(segundo.botao, segundo.size * 0.5)
	verificar(jogador.pontos_upgrade_pendentes == 0, "segundo clique nao consumiu o ponto")
	verificar(int(jogador.niveis_upgrades.get(escolhido, 0)) == nivel_antes + 1, "segundo clique nao aplicou exatamente uma melhoria")
	verificar(not menu.esta_aberta() and menu.upgrade_previsualizado == &"", "compra final nao fechou e limpou a selecao")
	verificar(is_equal_approx(Engine.time_scale, 1.0), "fechar melhorias nao restaurou o tempo")

	jogador.pontos_upgrade_pendentes = 2
	menu.abrir_menu()
	await get_tree().process_frame
	primeiro = menu.container_cards.get_child(0) as UpgradeCardNova
	# O mesmo sinal e acionado pelo botao ao confirmar com teclado/controle.
	primeiro.botao.grab_focus()
	primeiro.botao.pressed.emit()
	verificar(jogador.pontos_upgrade_pendentes == 2 and primeiro.selecionado, "ativacao pelo controle comprou sem previsualizar")
	var rerolls_antes := jogador.rerolls_upgrades_restantes
	menu.botao_rerrolar.pressed.emit()
	await get_tree().process_frame
	verificar(jogador.rerolls_upgrades_restantes == rerolls_antes - 1, "contador de rerolls nao permitiu trocar opcoes")
	verificar(menu.upgrade_previsualizado == &"" and not menu.painel_descricao.visible, "reroll manteve descricao ou confirmacao antiga")
	primeiro = menu.container_cards.get_child(0) as UpgradeCardNova
	primeiro.botao.pressed.emit()
	jogador.compra_upgrade_pendente_rede = true
	var rerolls_pendentes := jogador.rerolls_upgrades_restantes
	primeiro.botao.pressed.emit()
	menu._on_rerrolar_pressed()
	verificar(jogador.pontos_upgrade_pendentes == 2 and jogador.rerolls_upgrades_restantes == rerolls_pendentes, "compra pendente permitiu gasto duplicado ou reroll")
	jogador.compra_upgrade_pendente_rede = false
	menu.fechar_menu()
	menu.abrir_menu()
	verificar(menu.upgrade_previsualizado == &"" and not menu.painel_descricao.visible, "reabrir menu manteve selecao antiga")
	menu.fechar_menu()
	batalha.queue_free()
	await get_tree().process_frame
	print("TESTE %s: hexagonos contiguos, hitbox, previsualizacao, confirmacao e reroll" % ("OK" if falhas.is_empty() else "FALHOU"))
	get_tree().quit(0 if falhas.is_empty() else 1)


func clicar(botao: Button, ponto_local: Vector2) -> void:
	var posicao := botao.get_global_transform_with_canvas() * ponto_local
	var movimento := InputEventMouseMotion.new()
	movimento.position = posicao
	movimento.global_position = posicao
	get_viewport().push_input(movimento, true)
	await get_tree().process_frame
	for pressionado in [true, false]:
		var evento := InputEventMouseButton.new()
		evento.button_index = MOUSE_BUTTON_LEFT
		evento.position = posicao
		evento.global_position = posicao
		evento.pressed = pressionado
		get_viewport().push_input(evento, true)
	await get_tree().process_frame


func salvar_previa_se_solicitada() -> void:
	for argumento in OS.get_cmdline_user_args():
		if argumento.begins_with("--hex-preview=") and DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(argumento.trim_prefix("--hex-preview="))
