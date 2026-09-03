extends Node


var falhas: Array[String] = []


func verificar(condicao: bool, mensagem: String) -> void:
	if not condicao:
		falhas.append(mensagem)
		push_error("ASTRO/SAVE: " + mensagem)


func _ready() -> void:
	await _testar_astro()
	await _testar_configuracoes()
	_encerrar()


func _testar_astro() -> void:
	var cena_astro := load("res://Entities/astro.tscn") as PackedScene
	verificar(cena_astro != null, "a cena do Astro não carregou")
	if cena_astro == null:
		return

	var astro := cena_astro.instantiate()
	add_child(astro)
	await get_tree().process_frame
	verificar(
		bool(astro.call("_deve_se_apresentar", {})),
		"o Astro não se apresenta quando o save é novo"
	)
	verificar(
		not bool(astro.call("_deve_se_apresentar", {"astro_apresentado_menu": true})),
		"o Astro repete a apresentação pessoal em um save conhecido"
	)
	verificar(
		not bool(astro.call("_deve_se_apresentar", {"tutorialconcluido": true})),
		"o Astro se reapresenta para quem já jogava antes da atualização"
	)

	var primeira: String = str(astro.call("_sortear_curiosidade"))
	var segunda: String = str(astro.call("_sortear_curiosidade"))
	verificar(not primeira.is_empty(), "o sorteio retornou uma curiosidade vazia")
	verificar(primeira != segunda, "o sorteio repetiu imediatamente a mesma curiosidade")

	astro.set("modo_menu", true)
	astro.call("falar", "Frase de teste")
	await get_tree().process_frame
	var clique := InputEventMouseButton.new()
	clique.button_index = MOUSE_BUTTON_LEFT
	clique.pressed = true
	astro.call("_input", clique)
	verificar(not bool(astro.get("escrevendo")), "o primeiro clique não completou a digitação")
	var texto_completo: RichTextLabel = astro.get_node("DialogoAstro") as RichTextLabel
	verificar(texto_completo.visible_ratio >= 1.0, "o primeiro clique não revelou toda a frase")
	astro.call("_input", clique)
	verificar(bool(astro.get("escrevendo")), "o segundo clique não iniciou outra curiosidade")

	astro.queue_free()
	await get_tree().process_frame


func _testar_configuracoes() -> void:
	var cena_configuracoes := load("res://Janela_Configurações.tscn") as PackedScene
	verificar(cena_configuracoes != null, "a janela de configurações não carregou")
	if cena_configuracoes == null:
		return

	var janela := cena_configuracoes.instantiate()
	add_child(janela)
	await get_tree().process_frame

	var botao_apagar: Button = janela.get("apagar_save") as Button
	var dialogo: ConfirmationDialog = janela.get("confirmar_apagar_save") as ConfirmationDialog
	verificar(is_instance_valid(botao_apagar), "o botão Apagar Save não foi criado nas configurações")
	verificar(is_instance_valid(dialogo), "a confirmação de exclusão não foi criada")
	if is_instance_valid(botao_apagar):
		verificar(botao_apagar.get_parent().name == &"Rodape", "o botão Apagar Save não está no rodapé")

	var save_existia: bool = FileAccess.file_exists(GerenciadorDeSave.CAMINHO_SAVE)
	var conteudo_antes: String = _ler_save()
	if is_instance_valid(dialogo):
		janela.call("_on_apagar_save_pressed")
		await get_tree().process_frame
		verificar(dialogo.visible, "o botão não abriu a confirmação")
		verificar(
			FileAccess.file_exists(GerenciadorDeSave.CAMINHO_SAVE) == save_existia
				and _ler_save() == conteudo_antes,
			"abrir a confirmação alterou o save antes da resposta do jogador"
		)
		dialogo.hide()

	janela.queue_free()
	await get_tree().process_frame


func _ler_save() -> String:
	if not FileAccess.file_exists(GerenciadorDeSave.CAMINHO_SAVE):
		return ""
	var arquivo := FileAccess.open(GerenciadorDeSave.CAMINHO_SAVE, FileAccess.READ)
	if arquivo == null:
		return ""
	var conteudo: String = arquivo.get_as_text()
	arquivo.close()
	return conteudo


func _encerrar() -> void:
	if falhas.is_empty():
		print("TESTE OK: Astro no menu e exclusão protegida por confirmação")
		get_tree().quit(0)
	else:
		print("TESTE FALHOU: %d problema(s) no Astro/save" % falhas.size())
		get_tree().quit(1)
