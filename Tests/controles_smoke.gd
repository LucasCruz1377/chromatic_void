extends Node


const IconesControle = preload("res://Scripts/IndicadoresControle.gd")

var falhas: Array[String] = []
var janela: Control
var tela_configuracoes: Control


func verificar(condicao: bool, mensagem: String) -> void:
	if not condicao:
		falhas.append(mensagem)
		push_error("CONTROLES: " + mensagem)


func _ready() -> void:
	Global.restaurar_mapeamentos_padrao()
	var cena := load("res://Rooms/configuracoes.tscn") as PackedScene
	verificar(cena != null, "a janela de configurações não carregou")
	if cena == null:
		finalizar()
		return

	tela_configuracoes = cena.instantiate()
	get_tree().root.add_child.call_deferred(tela_configuracoes)
	await get_tree().process_frame
	await get_tree().process_frame
	janela = tela_configuracoes.get_node("JanelaConfiguracoes")
	verificar(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "a tela de configurações ocultou o cursor")
	verificar(janela.controle_avancado != null, "a opção de controle avançado não foi criada")
	verificar(
		janela.controle_avancado.button_pressed == Global.controle_avancado,
		"a opção de controle avançado não carregou o valor salvo"
	)
	for arquivo in [
		"A.svg", "B.svg", "X.svg", "Y.svg", "LB.svg", "LT.svg", "RB.svg", "RT.svg",
		"xis.svg", "bola.svg", "quad.svg", "tri.svg", "L1.svg", "L2.svg", "R1.svg", "R2.svg"
	]:
		verificar(
			ResourceLoader.exists("res://Assets/UI/IndicadoresControle/" + arquivo),
			"o indicador %s não foi incluído" % arquivo
		)

	var acoes := Global.obter_acoes_remapeaveis()
	verificar(acoes.size() == 12, "a lista não contém as doze ações jogáveis")
	verificar(janela.botoes_mapeamento.size() == acoes.size() * 3, "cada ação não recebeu três slots")
	verificar(janela.lista_mapeamentos.get_child_count() == acoes.size() + 1, "a lista visual não criou todas as linhas")
	janela.abas.current_tab = 4
	await get_tree().process_frame
	var rolagem := janela.get_node("Painel/Margem/Coluna/Abas/CONTROLES/Conteudo/Rolagem") as ScrollContainer
	verificar(janela.lista_mapeamentos.size.x <= rolagem.size.x, "as três caixas ultrapassam a largura da janela")
	verificar(rolagem.follow_focus, "a rolagem não acompanha o slot focado pelo controle")
	var ultimo_slot = janela.botoes_mapeamento["mirar_baixo:2"] as Button
	ultimo_slot.grab_focus()
	await get_tree().process_frame
	await get_tree().process_frame
	verificar(rolagem.scroll_vertical > 0, "o foco do controle não rolou até o último slot")

	var tecla_g := InputEventKey.new()
	tecla_g.physical_keycode = KEY_G
	tecla_g.pressed = true
	Global.definir_mapeamento(&"acelerar", 2, tecla_g)
	var evento_g := Global.obter_evento_mapeado(&"acelerar", 2) as InputEventKey
	verificar(evento_g != null and evento_g.physical_keycode == KEY_G, "uma tecla física não foi mapeada")
	verificar(InputMap.action_has_event(&"acelerar", evento_g), "o InputMap não recebeu a tecla remapeada")

	Global.definir_mapeamento(&"freio", 2, tecla_g)
	verificar(Global.obter_evento_mapeado(&"acelerar", 2) == null, "um comando duplicado permaneceu em duas ações")
	var evento_freio := Global.obter_evento_mapeado(&"freio", 2)
	verificar(evento_freio != null, "o comando não foi transferido para a nova ação")

	var botao_habilidade = janela.botoes_mapeamento["Habilidade:2"] as Button
	botao_habilidade.pressed.emit()
	await get_tree().process_frame
	var movimento_mouse := InputEventMouseMotion.new()
	movimento_mouse.relative = Vector2(3.0, 2.0)
	Input.parse_input_event(movimento_mouse)
	await get_tree().process_frame
	verificar(
		janela.capturando_entrada,
		"mover o mouse após clicar encerrou a espera pelo próximo comando"
	)
	var gatilho := InputEventJoypadMotion.new()
	gatilho.device = 4
	gatilho.axis = JOY_AXIS_TRIGGER_RIGHT
	gatilho.axis_value = 0.94
	Input.parse_input_event(gatilho)
	await get_tree().process_frame
	var evento_gatilho := Global.obter_evento_mapeado(&"Habilidade", 2) as InputEventJoypadMotion
	verificar(evento_gatilho != null, "o gatilho do controle não foi capturado")
	verificar(evento_gatilho != null and evento_gatilho.device == -1, "o vínculo ficou preso a apenas um controle")
	verificar(not janela.capturando_entrada, "a janela continuou aguardando entrada após mapear")

	var botao_pausa = janela.botoes_mapeamento["pausar:2"] as Button
	botao_pausa.grab_focus()
	var aceitar_press := InputEventJoypadButton.new()
	aceitar_press.button_index = JOY_BUTTON_A
	aceitar_press.pressed = true
	Input.parse_input_event(aceitar_press)
	await get_tree().process_frame
	var aceitar_soltar := InputEventJoypadButton.new()
	aceitar_soltar.button_index = JOY_BUTTON_A
	aceitar_soltar.pressed = false
	Input.parse_input_event(aceitar_soltar)
	await get_tree().process_frame
	verificar(janela.capturando_entrada, "ativar um slot pelo controle não iniciou a captura")
	var cancelar := InputEventKey.new()
	cancelar.keycode = KEY_ESCAPE
	cancelar.pressed = true
	Input.parse_input_event(cancelar)
	await get_tree().process_frame
	verificar(not janela.capturando_entrada, "Esc não cancelou a captura")

	botao_pausa.pressed.emit()
	await get_tree().process_frame
	var circulo := InputEventJoypadButton.new()
	circulo.device = 3
	circulo.button_index = JOY_BUTTON_B
	circulo.pressed = true
	Input.parse_input_event(circulo)
	await get_tree().process_frame
	var evento_pausa := Global.obter_evento_mapeado(&"pausar", 2) as InputEventJoypadButton
	verificar(
		evento_pausa != null and evento_pausa.button_index == JOY_BUTTON_B,
		"um botão do controle não foi capturado pela interface"
	)

	var botao_controle := InputEventJoypadButton.new()
	botao_controle.device = 7
	botao_controle.button_index = JOY_BUTTON_LEFT_SHOULDER
	Global.definir_mapeamento(&"abrir_melhorias", 2, botao_controle)
	var evento_botao := Global.obter_evento_mapeado(&"abrir_melhorias", 2) as InputEventJoypadButton
	verificar(evento_botao != null and evento_botao.device == -1, "um botão ficou preso ao controle usado na captura")
	janela._atualizar_textos_mapeamentos()
	var slot_com_icone = janela.botoes_mapeamento["abrir_melhorias:2"] as Button
	verificar(slot_com_icone.icon != null, "um botão compatível não recebeu seu indicador SVG")

	var mouse := InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_RIGHT
	Global.definir_mapeamento(&"atirar", 1, mouse)
	verificar(Global.obter_evento_mapeado(&"atirar", 1) is InputEventMouseButton, "um botão do mouse não foi mapeado")

	var dados := GerenciadorDeSave.carregar()
	var config = dados.get("configuracoes", {})
	verificar(config is Dictionary and config.has("mapeamentos_controles"), "os controles não foram persistidos no save")
	Global.controle_avancado = true
	Global.salvar_configuracoes()
	Global.controle_avancado = false
	Global.carregar_configuracoes()
	verificar(Global.controle_avancado, "a opção de controle avançado não foi persistida")
	Global.controle_avancado = false
	Global.salvar_configuracoes()
	Global.mapeamentos_controles = {}
	Global.carregar_configuracoes()
	Global.aplicar_configuracoes()
	verificar(Global.obter_evento_mapeado(&"atirar", 1) is InputEventMouseButton, "o mapeamento não voltou após recarregar o save")

	Global.restaurar_mapeamentos_padrao()
	verificar(Global.obter_evento_mapeado(&"acelerar", 0) != null, "restaurar controles apagou o padrão")
	finalizar()


func finalizar() -> void:
	if is_instance_valid(tela_configuracoes):
		tela_configuracoes.queue_free()
	await get_tree().process_frame
	if falhas.is_empty():
		print("TESTE OK: três slots, captura, conflito, controle genérico e persistência")
		get_tree().quit(0)
	else:
		print("TESTE FALHOU: %d problema(s) no remapeamento" % falhas.size())
		get_tree().quit(1)
