extends Node

const CAMINHO_SAVE := "user://save.json"
const CAMINHO_BACKUP := "user://save_backup.json"
const CAMINHO_TEMPORARIO := "user://save_pending.json"
const VERSAO_ATUAL_SAVE := 1

# Manter a ultima leitura valida nesta sessao evita perder progresso
# se o sistema de arquivos falhar temporariamente.
var _cache: Dictionary = {}


func salvar(dados_novos: Dictionary) -> void:
	var dados := carregar()
	for chave in dados_novos:
		dados[chave] = dados_novos[chave]
	dados["_save_version"] = VERSAO_ATUAL_SAVE
	var texto := JSON.stringify(dados)
	var comprovacao := JSON.new()
	if comprovacao.parse(texto) != OK or not comprovacao.data is Dictionary:
		push_error("Serializacao do save invalida. Dados anteriores preservados.")
		return

	# Duas instancias nao podem truncar o mesmo temporario.
	var caminho_temporario := CAMINHO_TEMPORARIO + ".%d" % OS.get_process_id()
	var temporario := FileAccess.open(caminho_temporario, FileAccess.WRITE)
	if temporario == null:
		push_error("Nao foi possivel abrir arquivo temporario do save: %s" % error_string(FileAccess.get_open_error()))
		return
	temporario.store_buffer(texto.to_utf8_buffer())
	temporario.flush()
	var erro_escrita := temporario.get_error()
	temporario.close()
	if erro_escrita != OK:
		push_error("Falha de escrita no save temporario: %s" % error_string(erro_escrita))
		return

	var origem := ProjectSettings.globalize_path(CAMINHO_SAVE)
	var backup := ProjectSettings.globalize_path(CAMINHO_BACKUP)
	var pendente := ProjectSettings.globalize_path(caminho_temporario)
	var principal_anterior := _ler_dicionario(CAMINHO_SAVE)
	# Backup somente do principal validado. Se estiver corrompido,
	# nao sobrescreve o backup de uma partida anterior.
	if not principal_anterior.is_empty():
		var erro_backup := DirAccess.copy_absolute(origem, backup)
		if erro_backup != OK:
			push_error("Falha ao criar backup: %s" % error_string(erro_backup))
			return

	# Valida o arquivo fechado antes de publicar. Rename faz a troca atomica;
	# copiar sobre o principal permitiria ler um JSON parcialmente escrito.
	if _ler_dicionario(caminho_temporario) != comprovacao.data:
		push_error("Save temporario invalido; progresso anterior preservado.")
		DirAccess.remove_absolute(pendente)
		return
	var erro_troca := DirAccess.rename_absolute(pendente, origem)
	if erro_troca != OK:
		push_error("Falha ao substituir save: %s. Progresso anterior preservado." % error_string(erro_troca))
		DirAccess.remove_absolute(pendente)
		return
	_cache = dados.duplicate(true)


func _ler_dicionario(caminho: String) -> Dictionary:
	if not FileAccess.file_exists(caminho):
		return {}
	var arquivo := FileAccess.open(caminho, FileAccess.READ)
	if arquivo == null:
		return {}
	var bytes := arquivo.get_buffer(arquivo.get_length())
	var erro_leitura := arquivo.get_error()
	arquivo.close()
	if erro_leitura != OK or bytes.is_empty():
		return {}
	var parser := JSON.new()
	if parser.parse(bytes.get_string_from_utf8()) != OK or not parser.data is Dictionary:
		return {}
	return parser.data


func carregar() -> Dictionary:
	var dados := _ler_dicionario(CAMINHO_SAVE)
	if dados.is_empty():
		dados = _ler_dicionario(CAMINHO_BACKUP)
	if dados.is_empty() and not _cache.is_empty():
		dados = _cache.duplicate(true)
	if dados.is_empty():
		dados = {"_save_version": VERSAO_ATUAL_SAVE}
	dados = _migrar_save(dados, int(dados.get("_save_version", 1)))
	_cache = dados.duplicate(true)
	return dados


func _carregar_backup() -> Dictionary:
	return _ler_dicionario(CAMINHO_BACKUP)


func _migrar_save(dados: Dictionary, versao: int) -> Dictionary:
	if versao < VERSAO_ATUAL_SAVE:
		dados["_save_version"] = VERSAO_ATUAL_SAVE
	return dados


func deletar_save() -> void:
	_cache.clear()
	for caminho in [CAMINHO_SAVE, CAMINHO_BACKUP, CAMINHO_TEMPORARIO, CAMINHO_TEMPORARIO + ".%d" % OS.get_process_id()]:
		if FileAccess.file_exists(caminho):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(caminho))
