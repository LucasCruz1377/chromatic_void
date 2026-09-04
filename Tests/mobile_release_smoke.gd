extends Node


const ControlesMobileCena = preload("res://Scripts/ControlesMobile.gd")

var falhas: Array[String] = []
var controles: ControlesMobile
var jogador_falso: Node2D


func verificar(condicao: bool, mensagem: String) -> void:
	if not condicao:
		falhas.append(mensagem)
		push_error("MOBILE/RELEASE: " + mensagem)


func _ready() -> void:
	verificar(
		Global.calcular_permissao_desenvolvedor(true, true, false),
		"o modo de desenvolvimento não ficou disponível no editor de testes"
	)
	verificar(
		not Global.calcular_permissao_desenvolvedor(true, true, true),
		"uma build Release ainda recebeu privilégios de desenvolvedor"
	)
	verificar(
		not Global.calcular_permissao_desenvolvedor(false, false, false),
		"uma execução comum recebeu privilégios sem ser editor nem debug"
	)
	verificar(
		not Global.calcular_permissao_desenvolvedor(false, true, false),
		"uma exportação Debug recebeu privilégios reservados ao editor"
	)

	var modo_original: bool = Global.modo_desenvolvedor
	Global.modo_desenvolvedor = false
	var cena_batalha := load("res://Rooms/Battle_area.tscn") as PackedScene
	var batalha := cena_batalha.instantiate() as Node2D
	get_tree().root.add_child.call_deferred(batalha)
	await get_tree().process_frame
	await get_tree().process_frame
	verificar(
		batalha.get_node_or_null("PainelDesenvolvedor") == null,
		"o painel de desenvolvedor foi criado quando a permissão estava bloqueada"
	)
	parar_audios(batalha)
	await get_tree().create_timer(0.08).timeout
	batalha.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	Global.modo_desenvolvedor = modo_original

	jogador_falso = Node2D.new()
	add_child(jogador_falso)
	controles = ControlesMobileCena.new()
	add_child(controles)
	controles.configurar(null, jogador_falso, true)
	await get_tree().process_frame
	verificar(controles.visible, "os controles de toque forçados não ficaram visíveis")
	verificar(
		controles.quantidade_botoes_toque_para_teste() == 4,
		"os quatro TouchScreenButtons não foram criados"
	)
	verificar(
		controles.superficie.size.x > 1.0 and controles.superficie.size.y > 1.0,
		"a superfície responsiva dos controles ficou sem tamanho"
	)

	controles.definir_analogico_para_teste(Vector2(0.8, -0.25))
	verificar(Global.controle_toque_ativo, "o analógico virtual não ativou o controle por toque")
	verificar(
		Global.direcao_controle_toque.distance_to(Vector2(0.8, -0.25)) < 0.01,
		"a direção do analógico virtual não chegou ao jogador"
	)
	var botao_tiro := controles.botoes_toque.get(&"atirar") as TouchScreenButton
	verificar(is_instance_valid(botao_tiro), "o TouchScreenButton de tiro não existe")
	if is_instance_valid(botao_tiro):
		var toque_tiro := InputEventScreenTouch.new()
		toque_tiro.index = 7
		toque_tiro.position = botao_tiro.position
		toque_tiro.pressed = true
		controles._input(toque_tiro)
		verificar(Input.is_action_pressed("atirar"), "o toque real não pressionou a ação de tiro")
		toque_tiro = toque_tiro.duplicate() as InputEventScreenTouch
		toque_tiro.pressed = false
		controles._input(toque_tiro)
		verificar(not Input.is_action_pressed("atirar"), "o tiro touch ficou preso após soltar o dedo")

	var cena_configuracoes := load("res://Janela_Configurações.tscn") as PackedScene
	var janela_configuracoes := cena_configuracoes.instantiate() as Control
	add_child(janela_configuracoes)
	await get_tree().process_frame
	janela_configuracoes.aplicar_layout_mobile_para_teste(true)
	var abas := janela_configuracoes.get_node("Painel/Margem/Coluna/Abas") as TabContainer
	var aba_controles := abas.get_node("CONTROLES") as Control
	var indice_controles := abas.get_tab_idx_from_control(aba_controles)
	verificar(abas.is_tab_hidden(indice_controles), "a aba de controles apareceu no mobile")
	janela_configuracoes.queue_free()
	await get_tree().process_frame

	verificar(
		str(ProjectSettings.get_setting("display/window/stretch/aspect")) == "keep",
		"a proporção 16:9 não está protegida na escala mobile"
	)
	verificar(
		str(ProjectSettings.get_setting("display/window/stretch/scale_mode")) == "fractional",
		"a escala não aceita resoluções fracionárias de celular"
	)

	controles.queue_free()
	await get_tree().process_frame
	verificar(not Global.controle_toque_ativo, "o analógico continuou ativo após fechar a interface")
	await finalizar()


func finalizar() -> void:
	if falhas.is_empty():
		print("TESTE OK: controles mobile e bloqueio de privilégios em Release")
		get_tree().quit(0)
	else:
		print("TESTE FALHOU: %d problema(s) mobile/release" % falhas.size())
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
