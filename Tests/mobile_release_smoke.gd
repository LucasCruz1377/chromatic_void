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

	controles.definir_analogico_para_teste(Vector2(0.8, -0.25))
	verificar(Global.controle_toque_ativo, "o analógico virtual não ativou o controle por toque")
	verificar(
		Global.direcao_controle_toque.distance_to(Vector2(0.8, -0.25)) < 0.01,
		"a direção do analógico virtual não chegou ao jogador"
	)
	controles.pressionar_acao_para_teste(&"atirar")
	verificar(Input.is_action_pressed("atirar"), "o botão virtual de tiro não pressionou a ação")
	controles.liberar_acao_para_teste(&"atirar")
	verificar(not Input.is_action_pressed("atirar"), "o botão virtual de tiro ficou preso")

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
