extends Node

## ============================================================
## CHROMATIC VOID - GERENCIADOR DE ATUALIZAÇÕES
## ============================================================
##
## Responsável por:
## - Descobrir a versão instalada do jogo.
## - Identificar o canal correto do itch.io.
## - Consultar a última versão disponível.
## - Comparar versões semânticas.
## - Informar quando existe uma atualização.
## - Baixar a atualização do Windows.
## - Iniciar o Updater.exe.
##
## ============================================================


# ============================================================
# CONFIGURAÇÃO
# ============================================================

const ITCH_TARGET := "lukass-1377/chromatic-void"
const CHANNEL_WINDOWS := "windows"
const CHANNEL_ANDROID := "android"
const ITCH_API := "https://api.itch.io/wharf/latest"
const REQUEST_TIMEOUT := 10.0

const GITHUB_REPO := "LucasCruz1377/chromatic_void"
const WINDOWS_UPDATE_FILE := "user://Windows.Desktop.zip"
const GITHUB_RELEASE_DOWNLOAD := "https://github.com/" + GITHUB_REPO + "/releases/download/"

# Caminho do Updater dentro do jogo exportado.
const UPDATER_PATH := "Updater.exe"


# ============================================================
# SINAIS
# ============================================================

signal update_available(version: String)
signal update_check_finished()
signal update_check_failed(message: String)


# ============================================================
# ESTADO
# ============================================================

var current_version: String = ""
var latest_version: String = ""

var checking_update: bool = false


# ============================================================
# REFERÊNCIA HTTP
# ============================================================

var http_request: HTTPRequest


# ============================================================
# INICIALIZAÇÃO
# ============================================================

func _ready() -> void:
	_criar_http_request()


func _criar_http_request() -> void:
	http_request = HTTPRequest.new()
	http_request.timeout = REQUEST_TIMEOUT

	add_child(http_request)

	http_request.request_completed.connect(
		_on_request_completed
	)


# ============================================================
# VERIFICAÇÃO PRINCIPAL
# ============================================================

func verificar_atualizacao() -> void:
	# Evita duas verificações simultâneas.
	if checking_update:
		return

	checking_update = true

	current_version = _obter_versao_atual()

	var channel := _obter_canal()

	if channel.is_empty():
		checking_update = false

		update_check_failed.emit(
			"Não foi possível identificar o canal da plataforma."
		)

		return

	var url := _criar_url(channel)

	print("========================================")
	print("Chromatic Void - Verificação de atualização")
	print("Versão instalada: ", current_version)
	print("Canal: ", channel)
	print("Consultando: ", url)
	print("========================================")

	var erro := http_request.request(url)

	if erro != OK:
		checking_update = false

		push_error(
			"Não foi possível iniciar a requisição HTTP. Erro: "
			+ str(erro)
		)

		update_check_failed.emit(
			"Não foi possível verificar atualizações."
		)


# ============================================================
# VERSÃO INSTALADA
# ============================================================

func _obter_versao_atual() -> String:
	var versao := str(
		ProjectSettings.get_setting(
			"application/config/version",
			"0.0.0"
		)
	)

	return versao


# ============================================================
# PLATAFORMA / CANAL
# ============================================================

func _obter_canal() -> String:
	if OS.has_feature("android"):
		return CHANNEL_ANDROID

	if OS.has_feature("windows"):
		return CHANNEL_WINDOWS

	# Durante testes no editor, vamos usar Windows.
	if OS.has_feature("editor"):
		return CHANNEL_WINDOWS

	return ""


# ============================================================
# URL DO ITCH.IO
# ============================================================

func _criar_url(channel: String) -> String:
	return (
		ITCH_API
		+ "?target="
		+ ITCH_TARGET.uri_encode()
		+ "&channel_name="
		+ channel.uri_encode()
	)


# ============================================================
# RESPOSTA HTTP
# ============================================================

func _on_request_completed(
	result: int,
	response_code: int,
	headers: PackedStringArray,
	body: PackedByteArray
) -> void:

	checking_update = false

	# --------------------------------------------------------
	# Verifica erro de conexão
	# --------------------------------------------------------

	if result != HTTPRequest.RESULT_SUCCESS:
		push_error(
			"Erro de conexão ao consultar o itch.io. Resultado: "
			+ str(result)
		)

		update_check_failed.emit(
			"Não foi possível conectar ao servidor de atualizações."
		)

		return


	# --------------------------------------------------------
	# Verifica código HTTP
	# --------------------------------------------------------

	if response_code != 200:
		push_error(
			"itch.io respondeu com HTTP "
			+ str(response_code)
		)

		update_check_failed.emit(
			"Servidor de atualização respondeu com erro."
		)

		return


	# --------------------------------------------------------
	# Converte resposta para texto
	# --------------------------------------------------------

	var texto := body.get_string_from_utf8()

	print("Resposta do itch.io:")
	print(texto)


	# --------------------------------------------------------
	# Interpreta JSON
	# --------------------------------------------------------

	var dados = JSON.parse_string(texto)

	if dados == null:
		push_error(
			"Não foi possível interpretar a resposta JSON do itch.io."
		)

		update_check_failed.emit(
			"Resposta inválida do servidor de atualizações."
		)

		return


	if not (dados is Dictionary):
		push_error(
			"A resposta do itch.io não é um objeto JSON."
		)

		update_check_failed.emit(
			"Resposta inválida do servidor de atualizações."
		)

		return


	# --------------------------------------------------------
	# Verifica se existe latest
	# --------------------------------------------------------

	if not dados.has("latest"):
		print(
			"Nenhuma user-version foi encontrada no canal."
		)

		update_check_finished.emit()

		return


	latest_version = str(
		dados["latest"]
	).strip_edges()


	if latest_version.is_empty():
		update_check_finished.emit()
		return


	print("Versão instalada: ", current_version)
	print("Última versão no itch.io: ", latest_version)


	# --------------------------------------------------------
	# Compara versões
	# --------------------------------------------------------

	if _versao_eh_mais_nova(
		latest_version,
		current_version
	):

		print(
			"🆕 NOVA ATUALIZAÇÃO DISPONÍVEL: ",
			latest_version
		)

		update_available.emit(
			latest_version
		)

	else:

		print(
			"Chromatic Void já está atualizado."
		)


	update_check_finished.emit()


# ============================================================
# COMPARAÇÃO DE VERSÕES
# ============================================================

func _versao_eh_mais_nova(
	nova_versao: String,
	versao_atual: String
) -> bool:

	var nova := _analisar_versao(nova_versao)
	var atual := _analisar_versao(versao_atual)

	if nova.is_empty() or atual.is_empty():
		return false


	# --------------------------------------------------------
	# Major
	# --------------------------------------------------------

	if nova.major != atual.major:
		return nova.major > atual.major


	# --------------------------------------------------------
	# Minor
	# --------------------------------------------------------

	if nova.minor != atual.minor:
		return nova.minor > atual.minor


	# --------------------------------------------------------
	# Patch
	# --------------------------------------------------------

	if nova.patch != atual.patch:
		return nova.patch > atual.patch


	# --------------------------------------------------------
	# Release estável > pré-release
	# --------------------------------------------------------

	if nova.prerelease_type.is_empty():

		if atual.prerelease_type.is_empty():
			return false

		return true


	if atual.prerelease_type.is_empty():
		return false


	# --------------------------------------------------------
	# Compara tipo do pré-lançamento
	# --------------------------------------------------------

	var prioridade_nova := _prioridade_prerelease(
		nova.prerelease_type
	)

	var prioridade_atual := _prioridade_prerelease(
		atual.prerelease_type
	)


	if prioridade_nova != prioridade_atual:
		return prioridade_nova > prioridade_atual


	# --------------------------------------------------------
	# Compara número do pré-lançamento
	# --------------------------------------------------------

	return (
		nova.prerelease_number
		>
		atual.prerelease_number
	)


# ============================================================
# INTERPRETAÇÃO DE VERSÃO
# ============================================================

func _analisar_versao(versao: String) -> Dictionary:
	var texto := versao.strip_edges()

	# Aceita:
	#
	# 0.5.0
	# 0.6.0-beta.1
	# 0.6.0-rc.1
	#
	# Também aceita "v0.6.0".

	if texto.begins_with("v"):
		texto = texto.substr(1)


	var partes := texto.split("-")

	var numeros := partes[0].split(".")


	if numeros.size() != 3:
		return {}


	if not (
		numeros[0].is_valid_int()
		and numeros[1].is_valid_int()
		and numeros[2].is_valid_int()
	):
		return {}


	var resultado := {
		"major": int(numeros[0]),
		"minor": int(numeros[1]),
		"patch": int(numeros[2]),
		"prerelease_type": "",
		"prerelease_number": 0
	}


	# Versão estável.
	if partes.size() == 1:
		return resultado


	# Exemplo:
	#
	# 0.6.0-beta.1

	var prerelease := partes[1].split(".")


	if prerelease.size() != 2:
		return {}


	var tipo := prerelease[0]
	var numero := prerelease[1]


	if not numero.is_valid_int():
		return {}


	if not (
		tipo == "alpha"
		or tipo == "beta"
		or tipo == "rc"
	):
		return {}


	resultado.prerelease_type = tipo
	resultado.prerelease_number = int(numero)


	return resultado


# ============================================================
# PRIORIDADE DE PRÉ-RELEASE
# ============================================================

func _prioridade_prerelease(tipo: String) -> int:
	match tipo:

		"alpha":
			return 1

		"beta":
			return 2

		"rc":
			return 3

		_:
			return 0


# ============================================================
# DOWNLOAD DA ATUALIZAÇÃO WINDOWS
# ============================================================

func baixar_atualizacao_windows() -> void:

	if latest_version.is_empty():
		push_error(
			"Não existe uma versão de atualização definida."
		)

		return


	if not OS.has_feature("windows"):
		push_error(
			"O atualizador do Windows só pode ser executado no Windows."
		)

		return


	var url := (
		GITHUB_RELEASE_DOWNLOAD
		+ latest_version
		+ "/Windows.Desktop.zip"
	)


	print("========================================")
	print("BAIXANDO ATUALIZAÇÃO")
	print("Versão: ", latest_version)
	print("URL: ", url)
	print("Destino: ", WINDOWS_UPDATE_FILE)
	print("========================================")


	var download_request := HTTPRequest.new()

	download_request.timeout = 300.0
	download_request.download_file = WINDOWS_UPDATE_FILE

	add_child(download_request)

	download_request.request_completed.connect(
		_on_download_completed.bind(download_request)
	)


	var erro := download_request.request(url)


	if erro != OK:

		push_error(
			"Não foi possível iniciar o download. Erro: "
			+ str(erro)
		)

		download_request.queue_free()


# ============================================================
# DOWNLOAD CONCLUÍDO
# ============================================================

func _on_download_completed(
	result: int,
	response_code: int,
	headers: PackedStringArray,
	body: PackedByteArray,
	download_request: HTTPRequest
) -> void:

	download_request.queue_free()


	print("========================================")
	print("DOWNLOAD FINALIZADO")
	print("Resultado: ", result)
	print("HTTP: ", response_code)
	print("========================================")


	if result != HTTPRequest.RESULT_SUCCESS:

		push_error(
			"Falha ao baixar a atualização."
		)

		return


	if response_code != 200:

		push_error(
			"GitHub respondeu com HTTP "
			+ str(response_code)
		)

		return


	if not FileAccess.file_exists(
		WINDOWS_UPDATE_FILE
	):

		push_error(
			"O arquivo de atualização não foi encontrado."
		)

		return


	var arquivo := FileAccess.open(
		WINDOWS_UPDATE_FILE,
		FileAccess.READ
	)


	if arquivo == null:

		push_error(
			"Não foi possível abrir o arquivo baixado."
		)

		return


	var tamanho := arquivo.get_length()

	arquivo.close()


	print("Atualização baixada com sucesso.")
	print("Tamanho: ", tamanho, " bytes")
	print("Arquivo: ", WINDOWS_UPDATE_FILE)


	# --------------------------------------------------------
	# Inicia o Updater
	# --------------------------------------------------------

	iniciar_atualizacao_windows()


# ============================================================
# INICIAR UPDATER WINDOWS
# ============================================================

func iniciar_atualizacao_windows() -> void:

	if not OS.has_feature("windows"):

		push_error(
			"A atualização automática só está disponível no Windows."
		)

		return


	if not FileAccess.file_exists(
		WINDOWS_UPDATE_FILE
	):

		push_error(
			"ZIP da atualização não encontrado: "
			+ WINDOWS_UPDATE_FILE
		)

		return


	# --------------------------------------------------------
	# Localiza o Updater.exe
	# --------------------------------------------------------

	var caminho_updater := ProjectSettings.globalize_path(
		"res://" + UPDATER_PATH
	)


	if not FileAccess.file_exists(caminho_updater):

		push_error(
			"Updater.exe não encontrado: "
			+ caminho_updater
		)

		return


	# --------------------------------------------------------
	# Descobre onde o jogo está instalado
	# --------------------------------------------------------

	var executavel := OS.get_executable_path()

	var pasta_jogo := executavel.get_base_dir()

	var zip := ProjectSettings.globalize_path(
		WINDOWS_UPDATE_FILE
	)


	print("========================================")
	print("INICIANDO ATUALIZADOR")
	print("========================================")
	print("Updater: ", caminho_updater)
	print("ZIP: ", zip)
	print("Pasta do jogo: ", pasta_jogo)
	print("Executável: ", executavel)
	print("========================================")


	# --------------------------------------------------------
	# Argumentos enviados para o Updater
	# --------------------------------------------------------

	var argumentos := [
		zip,
		pasta_jogo,
		executavel
	]


	# --------------------------------------------------------
	# Executa Updater.exe
	# --------------------------------------------------------

	var pid := OS.create_process(
		caminho_updater,
		argumentos
	)


	if pid == -1:

		push_error(
			"Não foi possível iniciar o Updater.exe."
		)

		return


	print(
		"Updater.exe iniciado. PID: ",
		pid
	)


	# --------------------------------------------------------
	# Fecha o jogo
	# --------------------------------------------------------

	get_tree().quit()