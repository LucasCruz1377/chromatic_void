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
		finalizar()
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

	finalizar()


func finalizar() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	if is_instance_valid(batalha):
		batalha.queue_free()
	await get_tree().process_frame
	if falhas.is_empty():
		print("TESTE OK: bloqueios e camadas da interface")
		get_tree().quit(0)
	else:
		print("TESTE FALHOU: %d problema(s) de interface" % falhas.size())
		get_tree().quit(1)
