extends Node


var falhas: Array[String] = []
var batalha: Node2D
var player: Player
var menu_upgrades: Control


func verificar(condicao: bool, mensagem: String) -> void:
	if not condicao:
		falhas.append(mensagem)
		push_error("INTERFACE: " + mensagem)


func _ready() -> void:
	var cena := load("res://Rooms/Battle_area.tscn") as PackedScene
	verificar(cena != null, "a cena de batalha não carregou")
	if cena == null:
		await finalizar()
		return

	batalha = cena.instantiate()
	get_tree().root.add_child.call_deferred(batalha)
	await get_tree().process_frame
	get_tree().current_scene = batalha
	await get_tree().process_frame
	await get_tree().process_frame

	player = batalha.get_node("Player") as Player
	menu_upgrades = batalha.get_node("GUI/TelaUpgrades") as Control
	batalha.tutorial_ativo = false
	var painel_dev := batalha.get_node_or_null("PainelDesenvolvedor")
	if Global.modo_desenvolvedor:
		verificar(
			painel_dev is PainelDesenvolvedor,
			"o laboratório de testes não foi criado no modo desenvolvedor"
		)
		if painel_dev is PainelDesenvolvedor:
			var nivel_antes: int = player.nivel_atual
			var pontos_antes: int = player.pontos_upgrade_pendentes
			painel_dev.abrir()
			verificar(painel_dev.aberto, "o laboratório de testes não abriu")
			verificar(get_tree().paused, "o laboratório não pausou a batalha")
			painel_dev._subir_niveis(1)
			verificar(
				player.nivel_atual == nivel_antes + 1
				and player.pontos_upgrade_pendentes == pontos_antes + 1,
				"o atalho de nível do laboratório não ajustou a progressão"
			)
			painel_dev._alternar_invulnerabilidade()
			verificar(
				player.invulneravel_desenvolvedor,
				"a invulnerabilidade de desenvolvimento não foi ativada"
			)
			painel_dev._alternar_spawns()
			verificar(
				batalha.spawns_pausados_desenvolvedor,
				"a pausa de spawns do laboratório não foi ativada"
			)
			painel_dev._alternar_spawns()
			painel_dev._alternar_invulnerabilidade()
			painel_dev.fechar()
			verificar(not get_tree().paused, "o laboratório não devolveu a partida")

			var setores_antes: Array = batalha.setores_concluidos.duplicate()
			var proximo_boss_antes: int = batalha.proximo_nivel_boss
			batalha.invocar_boss_teste(&"pet0")
			verificar(
				is_instance_valid(batalha.boss_ativo) and batalha.boss_em_teste,
				"o seletor não invocou o boss em modo de teste"
			)
			batalha._on_boss_morreu(batalha.boss_ativo)
			verificar(
				batalha.setores_concluidos == setores_antes
				and batalha.proximo_nivel_boss == proximo_boss_antes,
				"um boss de teste alterou a progressão da partida"
			)
			batalha.limpar_arena_teste()
	else:
		verificar(painel_dev == null, "o laboratório apareceu fora do modo desenvolvedor")
	player.pontos_upgrade_pendentes = 1

	player.UsandoHabilidade = true
	menu_upgrades.abrir_menu()
	verificar(not menu_upgrades.esta_aberta(), "melhorias abriram durante uma habilidade")

	player.UsandoHabilidade = false
	player.vida = 0.0
	menu_upgrades.abrir_menu()
	verificar(not menu_upgrades.esta_aberta(), "melhorias abriram com vida zerada")

	player.vida = player.VIDA_MAXIMA
	player.vivo = true
	batalha.criar_hud_boss()
	menu_upgrades.abrir_menu()
	verificar(menu_upgrades.esta_aberta(), "melhorias não abriram em um estado válido")
	verificar(not batalha.boss_hud.visible, "a barra do boss sobrepôs as melhorias")
	await get_tree().process_frame
	var foco_upgrade := get_viewport().gui_get_focus_owner()
	verificar(foco_upgrade is Button, "os cards de melhoria não receberam foco do controle")
	if menu_upgrades.container_cards.get_child_count() > 0:
		var card := menu_upgrades.container_cards.get_child(0) as PanelContainer
		var estilo_card := card.get_theme_stylebox("panel") as StyleBoxFlat
		verificar(
			is_instance_valid(estilo_card)
			and estilo_card.corner_radius_top_left >= 20
			and estilo_card.corner_radius_top_right >= 20
			and estilo_card.corner_radius_bottom_left >= 20
			and estilo_card.corner_radius_bottom_right >= 20,
			"os cards de melhoria não mantiveram as quatro bordas arredondadas"
		)
	verificar(
		is_instance_valid(menu_upgrades.botao_rerrolar)
		and menu_upgrades.botao_rerrolar.focus_mode == Control.FOCUS_ALL,
		"o botão de reroll não ficou acessível pelo controle"
	)
	verificar(
		not menu_upgrades.texto_rotas.text.is_empty(),
		"o resumo das rotas estruturais não foi exibido"
	)
	var rerolls_antes: int = player.rerolls_upgrades_restantes
	menu_upgrades._on_rerrolar_pressed()
	verificar(
		player.rerolls_upgrades_restantes == rerolls_antes - 1,
		"o reroll acionado pelo botão não consumiu uma carga"
	)

	if player.HabilidadeEquipada:
		player.HabilidadeEquipada.cooldown_atual = 1.0
		player.atualizar_barra_cooldown_habilidade()
		verificar(
			not player.barra_cooldown_habilidade.visible,
			"o relógio de cooldown sobrepôs as melhorias"
		)

	player.UsandoHabilidade = true
	menu_upgrades._process(0.0)
	verificar(not menu_upgrades.esta_aberta(), "a tela não fechou ao iniciar uma habilidade")
	verificar(batalha.boss_hud.visible, "a barra do boss não voltou após fechar as melhorias")

	var gui := batalha.get_node("GUI")
	var caixa_gameover := batalha.get_node("GUI/caixa gameover") as Control
	var botao_gameover := batalha.get_node("GUI/caixa gameover/Tentar de novo") as Button
	var efeito_foco := botao_gameover.get_node("tryagain")
	caixa_gameover.show()
	gui._process(0.0)
	await get_tree().process_frame
	verificar(
		get_viewport().gui_get_focus_owner() == botao_gameover,
		"o Game Over não recebeu foco do controle"
	)
	verificar(
		efeito_foco.tem_foco and efeito_foco.destacado,
		"o foco do controle não ativou o tween configurado"
	)
	caixa_gameover.hide()

	player.UsandoHabilidade = false
	player.vivo = false
	menu_upgrades.abrir_menu()
	verificar(not menu_upgrades.esta_aberta(), "melhorias abriram depois da morte")

	await finalizar()


func finalizar() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	if is_instance_valid(batalha):
		parar_audios(batalha)
		await get_tree().create_timer(0.08).timeout
		batalha.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	if falhas.is_empty():
		print("TESTE OK: bloqueios e camadas da interface")
		get_tree().quit(0)
	else:
		print("TESTE FALHOU: %d problema(s) de interface" % falhas.size())
		get_tree().quit(1)


func parar_audios(raiz: Node) -> void:
	for no in raiz.get_children():
		if no is AudioStreamPlayer:
			(no as AudioStreamPlayer).stop()
			(no as AudioStreamPlayer).stream = null
		elif no is AudioStreamPlayer2D:
			(no as AudioStreamPlayer2D).stop()
			(no as AudioStreamPlayer2D).stream = null
		parar_audios(no)
