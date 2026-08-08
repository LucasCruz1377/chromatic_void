extends Node

const CAMINHO_SAVE = "user://save.json"

func salvar(dados : Dictionary) -> void:
	var arquivo = FileAccess.open(CAMINHO_SAVE, FileAccess.WRITE)
	
	if arquivo == null:
		return
	
	arquivo.store_string(JSON.stringify(dados))
	arquivo.close()
	
func carregar() -> Dictionary:
	if not FileAccess.file_exists(CAMINHO_SAVE):
		return{}
	
	var arquivo = FileAccess.open(CAMINHO_SAVE,FileAccess.READ)
	
	if arquivo == null:
		return {}
	
	var texto = arquivo.get_as_text()
	arquivo.close()
	
	var dados = JSON.parse_string(texto)
	
	if dados is Dictionary:
		return dados
		
	return {}
	
func deletar_save() -> void:
	if FileAccess.file_exists(CAMINHO_SAVE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(CAMINHO_SAVE))
