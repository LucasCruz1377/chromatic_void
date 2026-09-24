extends Node

## Gerencia a descoberta e a instalação de novas versões do Chromatic Void.
## A versão instalada vem de application/config/version, preenchida com a tag
## usada na exportação. A versão pública vem exclusivamente do canal itch.io
## correspondente à plataforma; assim a verificação funciona com o repositório
## privado e só oferece builds que já foram publicadas aos jogadores.

const ITCH_TARGET := "lukass-1377/chromatic-void"
const ITCH_LATEST_API := "https://api.itch.io/wharf/latest?target=%s&channel_name=%s"
const ITCH_GAME_URL := "https://lukass-1377.itch.io/chromatic-void"
var request_headers := PackedStringArray([
	"Accept: application/json",
	"User-Agent: Chromatic-Void-Updater",
])
const REQUEST_TIMEOUT := 15.0

const PLATFORM_WINDOWS := "windows"
const PLATFORM_ANDROID := "android"

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
var canal_itch_atual := ""

var http_request: HTTPRequest


func _ready() -> void:
	http_request = HTTPRequest.new()
	http_request.timeout = REQUEST_TIMEOUT
	add_child(http_request)
	http_request.request_completed.connect(_on_release_request_completed)
	set_process(false)


func verificar_atualizacao() -> void:
	if checking_update:
		return

	var plataforma := obter_plataforma_atual()
	if plataforma.is_empty():
		update_check_failed.emit(tr("Atualizações automáticas não estão disponíveis nesta plataforma."))
		return

	checking_update = true
	current_version = _obter_versao_atual()
	_limpar_release_selecionada()

	canal_itch_atual = plataforma
	var endpoint := ITCH_LATEST_API % [ITCH_TARGET.uri_encode(), canal_itch_atual.uri_encode()]
	var erro := http_request.request(endpoint, request_headers)
	if erro != OK:
		checking_update = false
		canal_itch_atual = ""
		update_check_failed.emit(tr("Não foi possível iniciar a verificação de atualizações."))


func _on_release_request_completed(
	result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray
) -> void:
	checking_update = false
	canal_itch_atual = ""

	if result != HTTPRequest.RESULT_SUCCESS:
		push_warning("Falha HTTP ao verificar atualização. Resultado: %d" % result)
		update_check_failed.emit(tr("Sem conexão com o servidor de atualizações."))
		return

	if response_code == 403:
		update_check_failed.emit(tr("O servidor limitou temporariamente as verificações. Tente novamente mais tarde."))
		return

	if response_code != 200:
		update_check_failed.emit(tr("O servidor de atualizações respondeu com erro HTTP %d.") % response_code)
		return

	var resposta = JSON.parse_string(body.get_string_from_utf8())
	var versao_itch := selecionar_versao_itch(resposta, current_version)
	if resposta == null or not resposta is Dictionary:
		update_check_failed.emit(tr("O servidor retornou uma versão inválida."))
		return
	if versao_itch.is_empty():
		update_check_finished.emit()
		return
	latest_version = versao_itch
	latest_asset_url = ITCH_GAME_URL
	latest_release_url = ITCH_GAME_URL
	update_available.emit(latest_version)
	update_check_finished.emit()


func selecionar_versao_itch(resposta: Variant, versao_instalada: String) -> String:
	if not resposta is Dictionary:
		return ""
	var versao := str((resposta as Dictionary).get("latest", "")).strip_edges()
	return versao.trim_prefix("v") if _versao_eh_mais_nova(versao, versao_instalada) else ""


func iniciar_atualizacao() -> void:
	if latest_asset_url.is_empty():
		update_download_failed.emit(tr("O arquivo desta atualização não foi encontrado."))
		return

	# Força a gravação e cria o backup antes de sair do jogo ou abrir o APK.
	GerenciadorDeSave.salvar({})

	var plataforma := obter_plataforma_atual()
	if plataforma.is_empty():
		update_download_failed.emit(tr("Esta plataforma não possui instalação automática."))
		return
	_abrir_atualizacao_itch(plataforma)


func _abrir_atualizacao_itch(plataforma: String) -> void:
	# O endpoint público do Wharf divulga a versão, mas não uma URL permanente
	# para o arquivo. A página do itch.io entrega a build correta da plataforma.
	var erro := OS.shell_open(latest_asset_url)
	if erro != OK and not latest_release_url.is_empty():
		erro = OS.shell_open(latest_release_url)

	if erro != OK:
		update_download_failed.emit(tr("Não foi possível abrir a página de download do itch.io."))
		return

	installer_opened.emit(plataforma)


func obter_plataforma_atual() -> String:
	if OS.has_feature("android"):
		return PLATFORM_ANDROID
	if OS.has_feature("windows") or OS.has_feature("editor"):
		return PLATFORM_WINDOWS
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
