extends Node

var falhas: Array[String] = []


func verificar(condicao: bool, mensagem: String) -> void:
	if not condicao:
		falhas.append(mensagem)
		push_error("UPDATE: " + mensagem)


func _ready() -> void:
	verificar(UpdateManager._versao_eh_mais_nova("0.6.0", "0.5.9"), "não detectou versão estável mais nova")
	verificar(UpdateManager._versao_eh_mais_nova("0.6.0-beta.2", "0.6.0-alpha.9"), "não ordenou pré-releases")
	verificar(not UpdateManager._versao_eh_mais_nova("0.6.0-beta.1", "0.6.0"), "ofereceu pré-release sobre versão estável")
	verificar(not UpdateManager._versao_eh_mais_nova("versao-invalida", "0.6.0"), "aceitou versão inválida")
	verificar(
		UpdateManager.selecionar_versao_itch(
			{"latest": "v0.7.4-beta.2"}, "0.7.4-beta.1"
		) == "0.7.4-beta.2",
		"não usa a versão mais recente publicada no itch.io"
	)
	verificar(
		UpdateManager.selecionar_versao_itch({"latest": "v0.7.6"}, "0.7.6").is_empty(),
		"oferece novamente a versão que já está instalada"
	)

	var cena := load("res://janela_atualizacao.tscn") as PackedScene
	var janela := cena.instantiate()
	janela.verificar_automaticamente = false
	add_child(janela)
	await get_tree().process_frame

	UpdateManager.current_version = "0.5.0"
	janela._mostrar_atualizacao("0.6.0")
	await get_tree().process_frame
	var painel := janela.get_node("Centralizador/Painel") as Control
	var centro_painel := painel.get_global_rect().get_center()
	var centro_tela := get_viewport().get_visible_rect().get_center()
	verificar(centro_painel.distance_to(centro_tela) < 2.0, "a janela não ficou centralizada")
	verificar(janela.visible, "a janela não abriu ao receber uma atualização")
	verificar(janela._formatar_tempo(75) == "~1 min 15 s", "o tempo restante não foi formatado corretamente")
	janela._on_verificacao_sem_atualizacao()
	verificar(not janela.visible, "o aviso antigo não fechou após confirmar a versão atual")
	janela.show()
	janela._mostrar_atualizacao("0.6.0")
	janela._on_installer_opened(UpdateManager.PLATFORM_WINDOWS)
	verificar(not janela.visible, "o aviso não fechou após abrir o itch.io")
	janela.queue_free()

	if falhas.is_empty():
		print("TESTE OK: sistema de atualização e janela centralizada")
		get_tree().quit(0)
	else:
		print("TESTE FALHOU: %d problema(s) no sistema de atualização" % falhas.size())
		get_tree().quit(1)
