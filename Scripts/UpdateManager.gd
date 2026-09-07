extends Node

## Gerencia a descoberta e a instalação de novas versões do Chromatic Void.
## A versão disponível é consultada no canal correspondente do itch.io.
## Os arquivos continuam vindo da GitHub Release com a mesma tag.

const ITCH_TARGET := "lukass-1377/chromatic-void"
const ITCH_API := "https://api.itch.io/wharf/latest"
const GITHUB_REPO := "LucasCruz1377/chromatic_void"
var request_headers := PackedStringArray([
	"Accept: application/vnd.github+json",
	"X-GitHub-Api-Version: 2022-11-28",
	"User-Agent: Chromatic-Void-Updater",
])
var download_headers := PackedStringArray([
	"User-Agent: Chromatic-Void-Updater",
])
const REQUEST_TIMEOUT := 15.0
const DOWNLOAD_TIMEOUT := 600.0

const PLATFORM_WINDOWS := "windows"
const PLATFORM_ANDROID := "android"
const ASSET_WINDOWS := "Windows.Desktop.zip"
const ASSET_ANDROID := "ChromaticVoid-Android.apk"
const WINDOWS_UPDATE_FILE := "user://Windows.Desktop.zip"
const UPDATER_NAME := "Updater.exe"

signal update_available(version: String)
signal update_check_finished()
signal update_check_failed(message: String)
signal update_download_started(total_bytes: int)
signal update_download_progress(downloaded_bytes: int, total_bytes: int)
signal update_download_failed(message: String)
signal installer_opened(platform: String)

var current_version := ""
var latest_version := ""
var latest_asset_url := ""
var latest_release_url := ""
var latest_asset_digest := ""
var latest_asset_size := 0
var checking_update := false

var http_request: HTTPRequest
var download_request: HTTPRequest
var _ultimo_progresso_emitido := -1


func _ready() -> void:
	http_request = HTTPRequest.new()
	http_request.timeout = REQUEST_TIMEOUT
	add_child(http_request)
	http_request.request_completed.connect(_on_itch_request_completed)
	set_process(false)


func verificar_atualizacao() -> void:
	if checking_update:
		return

	var plataforma := obter_plataforma_atual()
	if plataforma.is_empty():
		update_check_failed.emit("Atualizações automáticas não estão disponíveis nesta plataforma.")
		return

	checking_update = true
	current_version = _obter_versao_atual()
	_limpar_release_selecionada()

	var canal := obter_plataforma_atual()
	var url := "%s?target=%s&channel_name=%s" % [
		ITCH_API, ITCH_TARGET.uri_encode(), canal.uri_encode()
	]
	var erro := http_request.request(url, request_headers)
	if erro != OK:
		checking_update = false
		update_check_failed.emit("Não foi possível iniciar a verificação de atualizações.")


func _on_itch_request_completed(
	result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray
) -> void:
	checking_update = false

	if result != HTTPRequest.RESULT_SUCCESS:
		push_warning("Falha HTTP ao verificar atualização. Resultado: %d" % result)
		update_check_failed.emit("Sem conexão com o servidor de atualizações.")
		return

	if response_code != 200:
		update_check_failed.emit("O itch.io respondeu com erro HTTP %d." % response_code)
		return

	var dados = JSON.parse_string(body.get_string_from_utf8())
	if not (dados is Dictionary) or not dados.has("latest"):
		update_check_failed.emit("O itch.io retornou uma versão inválida.")
		return

	latest_version = str(dados.get("latest", "")).strip_edges()
	if latest_version.is_empty() or not _versao_eh_mais_nova(latest_version, current_version):
		update_check_finished.emit()
		return

	var tag := latest_version if latest_version.begins_with("v") else "v" + latest_version
	var nome_asset := obter_nome_asset(obter_plataforma_atual())
	latest_asset_url = "https://github.com/%s/releases/download/%s/%s" % [GITHUB_REPO, tag, nome_asset]
	latest_release_url = "https://github.com/%s/releases/tag/%s" % [GITHUB_REPO, tag]
	latest_asset_digest = ""
	latest_asset_size = 0

	update_available.emit(latest_version)
	update_check_finished.emit()


func selecionar_melhor_release(
	releases: Array,
	plataforma: String,
	versao_instalada: String
) -> Dictionary:
	var nome_asset := obter_nome_asset(plataforma)
	var melhor: Dictionary = {}
	var instalada := _analisar_versao(versao_instalada)

	if nome_asset.is_empty() or instalada.is_empty():
		return melhor

	var instalada_estavel := str(instalada["prerelease_type"]).is_empty()
	for item in releases:
		if not (item is Dictionary):
			continue

		var release := item as Dictionary
		if bool(release.get("draft", false)):
			continue
		if instalada_estavel and bool(release.get("prerelease", false)):
			continue

		var versao := str(release.get("tag_name", "")).strip_edges()
		if not _versao_eh_mais_nova(versao, versao_instalada):
			continue

		var asset_escolhido: Dictionary = {}
		var assets = release.get("assets", [])
		if assets is Array:
			for item_asset in assets:
				if item_asset is Dictionary and str(item_asset.get("name", "")) == nome_asset:
					asset_escolhido = item_asset
					break

		if asset_escolhido.is_empty():
			continue
		if not melhor.is_empty() and not _versao_eh_mais_nova(versao, str(melhor["version"])):
			continue

		var digest := str(asset_escolhido.get("digest", ""))
		if digest.begins_with("sha256:"):
			digest = digest.trim_prefix("sha256:")

		melhor = {
			"version": versao.trim_prefix("v"),
			"asset_url": str(asset_escolhido.get("browser_download_url", "")),
			"release_url": str(release.get("html_url", "")),
			"digest": digest.to_lower(),
			"size": int(asset_escolhido.get("size", 0)),
		}

	return melhor


func iniciar_atualizacao() -> void:
	if latest_asset_url.is_empty():
		update_download_failed.emit("O arquivo desta atualização não foi encontrado.")
		return

	# Força a gravação e cria o backup antes de sair do jogo ou abrir o APK.
	GerenciadorDeSave.salvar({})

	match obter_plataforma_atual():
		PLATFORM_WINDOWS:
			_baixar_atualizacao_windows()
		PLATFORM_ANDROID:
			_abrir_atualizacao_android()
		_:
			update_download_failed.emit("Esta plataforma não possui instalação automática.")


func _abrir_atualizacao_android() -> void:
	# O navegador/gerenciador de downloads entrega o APK ao instalador do Android.
	# O usuário confirma a atualização do app existente; não deve desinstalá-lo.
	var erro := OS.shell_open(latest_asset_url)
	if erro != OK and not latest_release_url.is_empty():
		erro = OS.shell_open(latest_release_url)

	if erro != OK:
		update_download_failed.emit("Não foi possível abrir o download do APK.")
		return

	installer_opened.emit(PLATFORM_ANDROID)


func _baixar_atualizacao_windows() -> void:
	if is_instance_valid(download_request):
		return

	var caminho_absoluto := ProjectSettings.globalize_path(WINDOWS_UPDATE_FILE)
	if FileAccess.file_exists(WINDOWS_UPDATE_FILE):
		DirAccess.remove_absolute(caminho_absoluto)

	download_request = HTTPRequest.new()
	download_request.timeout = DOWNLOAD_TIMEOUT
	download_request.download_file = WINDOWS_UPDATE_FILE
	add_child(download_request)
	download_request.request_completed.connect(_on_download_windows_completed)

	var erro := download_request.request(latest_asset_url, download_headers)
	if erro != OK:
		_encerrar_download_request()
		update_download_failed.emit("Não foi possível iniciar o download da atualização.")
		return

	_ultimo_progresso_emitido = -1
	set_process(true)
	update_download_started.emit(latest_asset_size)


func _process(_delta: float) -> void:
	if not is_instance_valid(download_request):
		set_process(false)
		return

	var baixado := download_request.get_downloaded_bytes()
	var total := download_request.get_body_size()
	if total <= 0:
		total = latest_asset_size

	var porcentagem := int(float(baixado) / float(total) * 100.0) if total > 0 else 0
	if porcentagem != _ultimo_progresso_emitido:
		_ultimo_progresso_emitido = porcentagem
		update_download_progress.emit(baixado, total)


func _on_download_windows_completed(
	result: int,
	response_code: int,
	_headers: PackedStringArray,
	_body: PackedByteArray
) -> void:
	_encerrar_download_request()

	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		_apagar_download_incompleto()
		update_download_failed.emit("Falha ao baixar a atualização (HTTP %d)." % response_code)
		return

	if not FileAccess.file_exists(WINDOWS_UPDATE_FILE):
		update_download_failed.emit("O arquivo baixado não foi encontrado.")
		return

	var arquivo := FileAccess.open(WINDOWS_UPDATE_FILE, FileAccess.READ)
	var tamanho := arquivo.get_length() if arquivo != null else 0
	if arquivo != null:
		arquivo.close()

	if latest_asset_size > 0 and tamanho != latest_asset_size:
		_apagar_download_incompleto()
		update_download_failed.emit("O download ficou incompleto. Tente novamente.")
		return

	if not latest_asset_digest.is_empty():
		var digest_local := FileAccess.get_sha256(WINDOWS_UPDATE_FILE).to_lower()
		if digest_local != latest_asset_digest:
			_apagar_download_incompleto()
			update_download_failed.emit("A verificação de integridade da atualização falhou.")
			return

	_iniciar_updater_windows()


func _iniciar_updater_windows() -> void:
	var executavel := OS.get_executable_path()
	var pasta_jogo := executavel.get_base_dir()
	var caminho_updater := pasta_jogo.path_join(UPDATER_NAME)

	if not FileAccess.file_exists(caminho_updater):
		update_download_failed.emit("Updater.exe não foi encontrado ao lado do jogo.")
		return

	if not _pasta_instalacao_gravavel(pasta_jogo):
		update_download_failed.emit("A pasta do jogo não permite alterações. Mova o jogo para uma pasta do seu usuário.")
		return

	var argumentos := [
		ProjectSettings.globalize_path(WINDOWS_UPDATE_FILE),
		pasta_jogo,
		executavel,
		str(OS.get_process_id()),
	]
	var pid := OS.create_process(caminho_updater, argumentos)
	if pid == -1:
		update_download_failed.emit("Não foi possível iniciar o atualizador do Windows.")
		return

	installer_opened.emit(PLATFORM_WINDOWS)
	get_tree().quit()


func _pasta_instalacao_gravavel(pasta: String) -> bool:
	var teste := pasta.path_join(".chromatic_update_write_test")
	var arquivo := FileAccess.open(teste, FileAccess.WRITE)
	if arquivo == null:
		return false
	arquivo.store_8(1)
	arquivo.close()
	DirAccess.remove_absolute(teste)
	return true


func obter_plataforma_atual() -> String:
	if OS.has_feature("android"):
		return PLATFORM_ANDROID
	if OS.has_feature("windows") or OS.has_feature("editor"):
		return PLATFORM_WINDOWS
	return ""


func obter_nome_asset(plataforma: String) -> String:
	match plataforma:
		PLATFORM_WINDOWS:
			return ASSET_WINDOWS
		PLATFORM_ANDROID:
			return ASSET_ANDROID
		_:
			return ""


func _obter_versao_atual() -> String:
	return str(ProjectSettings.get_setting("application/config/version", "0.0.0"))


func _versao_eh_mais_nova(nova_versao: String, versao_atual: String) -> bool:
	var nova := _analisar_versao(nova_versao)
	var atual := _analisar_versao(versao_atual)
	if nova.is_empty() or atual.is_empty():
		return false

	for chave in ["major", "minor", "patch"]:
		if int(nova[chave]) != int(atual[chave]):
			return int(nova[chave]) > int(atual[chave])

	var tipo_novo := str(nova["prerelease_type"])
	var tipo_atual := str(atual["prerelease_type"])
	if tipo_novo.is_empty():
		return not tipo_atual.is_empty()
	if tipo_atual.is_empty():
		return false

	var prioridade_nova := _prioridade_prerelease(tipo_novo)
	var prioridade_atual := _prioridade_prerelease(tipo_atual)
	if prioridade_nova != prioridade_atual:
		return prioridade_nova > prioridade_atual

	return int(nova["prerelease_number"]) > int(atual["prerelease_number"])


func _analisar_versao(versao: String) -> Dictionary:
	var texto := versao.strip_edges().trim_prefix("v")
	var partes := texto.split("-")
	var numeros := partes[0].split(".")
	if numeros.size() != 3:
		return {}
	if not numeros[0].is_valid_int() or not numeros[1].is_valid_int() or not numeros[2].is_valid_int():
		return {}
	if partes.size() > 2:
		return {}

	var resultado := {
		"major": int(numeros[0]),
		"minor": int(numeros[1]),
		"patch": int(numeros[2]),
		"prerelease_type": "",
		"prerelease_number": 0,
	}
	if partes.size() == 1:
		return resultado

	var prerelease := partes[1].split(".")
	if prerelease.size() != 2 or not prerelease[1].is_valid_int():
		return {}
	var tipo := str(prerelease[0])
	if tipo not in ["alpha", "beta", "rc"]:
		return {}

	resultado["prerelease_type"] = tipo
	resultado["prerelease_number"] = int(prerelease[1])
	return resultado


func _prioridade_prerelease(tipo: String) -> int:
	return {"alpha": 1, "beta": 2, "rc": 3}.get(tipo, 0)


func _limpar_release_selecionada() -> void:
	latest_version = ""
	latest_asset_url = ""
	latest_release_url = ""
	latest_asset_digest = ""
	latest_asset_size = 0


func _encerrar_download_request() -> void:
	set_process(false)
	if is_instance_valid(download_request):
		download_request.queue_free()
	download_request = null


func _apagar_download_incompleto() -> void:
	if FileAccess.file_exists(WINDOWS_UPDATE_FILE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(WINDOWS_UPDATE_FILE))
