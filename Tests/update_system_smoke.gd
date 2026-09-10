extends Node

var falhas: Array[String] = []


func verificar(condicao: bool, mensagem: String) -> void:
	if not condicao:
		falhas.append(mensagem)
		push_error("UPDATE: " + mensagem)


func criar_release(versao: String, prerelease: bool, asset: String) -> Dictionary:
	return {
		"tag_name": versao,
		"draft": false,
		"prerelease": prerelease,
		"html_url": "https://example.test/" + versao,
		"assets": [{
			"name": asset,
			"browser_download_url": "https://example.test/" + asset,
			"digest": "sha256:abc123",
			"size": 2048,
		}],
	}


func _ready() -> void:
	verificar(UpdateManager._versao_eh_mais_nova("0.6.0", "0.5.9"), "não detectou versão estável mais nova")
	verificar(UpdateManager._versao_eh_mais_nova("0.6.0-beta.2", "0.6.0-alpha.9"), "não ordenou pré-releases")
	verificar(not UpdateManager._versao_eh_mais_nova("0.6.0-beta.1", "0.6.0"), "ofereceu pré-release sobre versão estável")
	verificar(not UpdateManager._versao_eh_mais_nova("versao-invalida", "0.6.0"), "aceitou versão inválida")
	verificar(
		UpdateManager.selecionar_versao_itch(
			{"latest": "v0.7.4-beta.2"}, "0.7.4-beta.1"
		) == "0.7.4-beta.2",
		"Android não usa a versão mais recente publicada no itch.io"
	)

	var releases := [
		criar_release("v0.6.1", false, UpdateManager.ASSET_WINDOWS),
		criar_release("v0.7.0-beta.2", true, UpdateManager.ASSET_WINDOWS),
		criar_release("v0.6.2", false, UpdateManager.ASSET_ANDROID),
	]
	var windows_beta := UpdateManager.selecionar_melhor_release(releases, UpdateManager.PLATFORM_WINDOWS, "0.5.0-beta.1")
	verificar(str(windows_beta.get("version", "")) == "0.7.0-beta.2", "canal beta não escolheu a maior versão do Windows")
	var windows_estavel := UpdateManager.selecionar_melhor_release(releases, UpdateManager.PLATFORM_WINDOWS, "0.5.0")
	verificar(str(windows_estavel.get("version", "")) == "0.6.1", "canal estável selecionou pré-release")
	var android := UpdateManager.selecionar_melhor_release(releases, UpdateManager.PLATFORM_ANDROID, "0.5.0-beta.1")
	verificar(str(android.get("version", "")) == "0.6.2", "não encontrou o APK Android")

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
	janela.queue_free()

	if falhas.is_empty():
		print("TESTE OK: sistema de atualização e janela centralizada")
		get_tree().quit(0)
	else:
		print("TESTE FALHOU: %d problema(s) no sistema de atualização" % falhas.size())
		get_tree().quit(1)
