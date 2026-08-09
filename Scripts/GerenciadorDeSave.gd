extends Node


const CAMINHO_SAVE := "user://save.json"


# ============================================================
# SALVAR
# ============================================================

func salvar(dados_novos: Dictionary) -> void:
	# Carrega o que já existia.
	var dados := carregar()


	# Atualiza somente as informações recebidas.
	#
	# Exemplo:
	#
	# salvar({
	#     "tutorialconcluido": true
	# })
	#
	# não vai apagar configurações futuras.
	for chave in dados_novos:

		dados[chave] = dados_novos[chave]


	var arquivo := FileAccess.open(
		CAMINHO_SAVE,
		FileAccess.WRITE
	)


	if arquivo == null:

		push_error(
			"Não foi possível abrir o save."
		)

		return


	arquivo.store_string(
		JSON.stringify(dados)
	)

	arquivo.close()


# ============================================================
# CARREGAR
# ============================================================

func carregar() -> Dictionary:
	if not FileAccess.file_exists(
		CAMINHO_SAVE
	):

		return {}


	var arquivo := FileAccess.open(
		CAMINHO_SAVE,
		FileAccess.READ
	)


	if arquivo == null:
		return {}


	var texto := arquivo.get_as_text()

	arquivo.close()


	var dados = JSON.parse_string(texto)


	if dados is Dictionary:
		return dados


	return {}


# ============================================================
# DELETAR
# ============================================================

func deletar_save() -> void:
	if FileAccess.file_exists(
		CAMINHO_SAVE
	):

		DirAccess.remove_absolute(
			ProjectSettings.globalize_path(
				CAMINHO_SAVE
			)
		)
