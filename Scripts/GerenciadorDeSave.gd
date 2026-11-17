extends Node

const CAMINHO_SAVE := "user://save.json"
const CAMINHO_BACKUP := "user://save_backup.json"
const CAMINHO_TEMPORARIO := "user://save_pending.json"
const VERSAO_ATUAL_SAVE := 1

# Salva primeiro em arquivo temporario e so substitui o principal
# quando o JSON novo puder ser lido integralmente.
func salvar(dados_novos: Dictionary) -> void:
	var dados := carregar()
	for chave in dados_novos:
		dados[chave] = dados_novos[chave]
	dados["_save_version"] = VERSAO_ATUAL_SAVE
	var arquivo := FileAccess.open(CAMINHO_TEMPORARIO, FileAccess.WRITE)
	if arquivo == null:
		push_error("Nao foi possivel abrir save temporario.")
		return
	arquivo.store_string(JSON.stringify(dados))
	arquivo.flush()
	arquivo.close()
	if _ler_dicionario(CAMINHO_TEMPORARIO).is_empty():
		push_error("Save temporario invalido; progresso anterior preservado.")
		return
	var origem := ProjectSettings.globalize_path(CAMINHO_SAVE)
	var destino := ProjectSettings.globalize_path(CAMINHO_BACKUP)
	var temporario := ProjectSettings.globalize_path(CAMINHO_TEMPORARIO)
	if not _ler_dicionario(CAMINHO_SAVE).is_empty():
		if DirAccess.copy_absolute(origem, destino) != OK:
			push_error("Nao foi possivel gerar backup do save.")
			return
	if FileAccess.file_exists(CAMINHO_SAVE):
		if DirAccess.remove_absolute(origem) != OK:
			push_error("Nao foi possivel substituir o save.")
			return
	if DirAccess.rename_absolute(temporario, origem) != OK:
		push_error("Falha ao finalizar save; restaurando backup.")
		if FileAccess.file_exists(CAMINHO_BACKUP):
			DirAccess.copy_absolute(destino, origem)


func _ler_dicionario(caminho: String) -> Dictionary:
	if not FileAccess.file_exists(caminho):
		return {}
	var arquivo := FileAccess.open(caminho, FileAccess.READ)
	if arquivo == null:
		return {}
	var texto := arquivo.get_as_text()
	arquivo.close()
	if texto.is_empty():
		return {}
	var parser := JSON.new()
	if parser.parse(texto) != OK:
		return {}
	if not parser.data is Dictionary:
		return {}
	return parser.data


func carregar() -> Dictionary:
	var dados := _ler_dicionario(CAMINHO_SAVE)
	if dados.is_empty():
		dados = _carregar_backup()
	if dados.is_empty():
		dados = {"_save_version": VERSAO_ATUAL_SAVE}
	return _migrar_save(dados, int(dados.get("_save_version", 1)))


func _carregar_backup() -> Dictionary:
	return _ler_dicionario(CAMINHO_BACKUP)


func _migrar_save(dados: Dictionary, versao: int) -> Dictionary:
	if versao < VERSAO_ATUAL_SAVE:
		dados["_save_version"] = VERSAO_ATUAL_SAVE
	return dados


func deletar_save() -> void:
	for caminho in [CAMINHO_SAVE, CAMINHO_BACKUP, CAMINHO_TEMPORARIO]:
		if FileAccess.file_exists(caminho):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(caminho))
