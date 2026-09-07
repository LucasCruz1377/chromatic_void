extends Node

const CAMINHO_SAVE := "user://save.json"
const CAMINHO_BACKUP := "user://save_backup.json"

const VERSAO_ATUAL_SAVE := 1


# ============================================================
# SALVAR
# ============================================================

func salvar(dados_novos: Dictionary) -> void:
	var dados := carregar()

	# Atualiza somente as informações recebidas.
	#
	# Exemplo:
	#
	# salvar({
	#     "tutorialconcluido": true
	# })
	#
	# Isso não apaga outras informações existentes.

	for chave in dados_novos:
		dados[chave] = dados_novos[chave]

	# Garante que o save tenha uma versão.
	dados["_save_version"] = VERSAO_ATUAL_SAVE

	# Cria backup do save atual antes de sobrescrever.
	_criar_backup()

	var arquivo := FileAccess.open(
		CAMINHO_SAVE,
		FileAccess.WRITE
	)

	if arquivo == null:
		push_error("Não foi possível abrir o save para salvar.")
		return

	arquivo.store_string(JSON.stringify(dados))
	arquivo.flush()
	arquivo.close()


# ============================================================
# CARREGAR
# ============================================================

func carregar() -> Dictionary:
	if not FileAccess.file_exists(CAMINHO_SAVE):
		return {
			"_save_version": VERSAO_ATUAL_SAVE
		}

	var arquivo := FileAccess.open(
		CAMINHO_SAVE,
		FileAccess.READ
	)

	if arquivo == null:
		push_error("Não foi possível abrir o save.")
		return _carregar_backup()

	var texto := arquivo.get_as_text()
	arquivo.close()

	var dados = JSON.parse_string(texto)

	if not (dados is Dictionary):
		push_error("O save principal está corrompido. Tentando backup.")
		return _carregar_backup()

	# Verifica a versão do save.
	var versao_save := int(
		dados.get("_save_version", 1)
	)

	dados = _migrar_save(
		dados,
		versao_save
	)

	return dados


# ============================================================
# BACKUP
# ============================================================

func _criar_backup() -> void:
	if not FileAccess.file_exists(CAMINHO_SAVE):
		return

	var arquivo_original := FileAccess.open(
		CAMINHO_SAVE,
		FileAccess.READ
	)

	if arquivo_original == null:
		return

	var conteudo := arquivo_original.get_as_text()
	arquivo_original.close()

	var backup := FileAccess.open(
		CAMINHO_BACKUP,
		FileAccess.WRITE
	)

	if backup == null:
		push_error("Não foi possível criar backup do save.")
		return

	backup.store_string(conteudo)
	backup.flush()
	backup.close()


func _carregar_backup() -> Dictionary:
	if not FileAccess.file_exists(CAMINHO_BACKUP):
		return {
			"_save_version": VERSAO_ATUAL_SAVE
		}

	var arquivo := FileAccess.open(
		CAMINHO_BACKUP,
		FileAccess.READ
	)

	if arquivo == null:
		return {
			"_save_version": VERSAO_ATUAL_SAVE
		}

	var texto := arquivo.get_as_text()
	arquivo.close()

	var dados = JSON.parse_string(texto)

	if dados is Dictionary:
		push_warning("Save principal inválido. Backup restaurado.")
		return dados

	push_error("O backup também está corrompido.")

	return {
		"_save_version": VERSAO_ATUAL_SAVE
	}


# ============================================================
# MIGRAÇÃO DE SAVE
# ============================================================

func _migrar_save(
	dados: Dictionary,
	versao: int
) -> Dictionary:

	# Atualmente estamos na versão 1.
	#
	# No futuro poderemos fazer:
	#
	# if versao < 2:
	#     ...
	#
	# if versao < 3:
	#     ...
	#
	# Isso permite que jogadores antigos continuem
	# usando seus saves depois das atualizações.

	if versao < VERSAO_ATUAL_SAVE:
		dados["_save_version"] = VERSAO_ATUAL_SAVE

	return dados


# ============================================================
# DELETAR
# ============================================================

func deletar_save() -> void:
	if FileAccess.file_exists(CAMINHO_SAVE):
		DirAccess.remove_absolute(
			ProjectSettings.globalize_path(
				CAMINHO_SAVE
			)
		)

	if FileAccess.file_exists(CAMINHO_BACKUP):
		DirAccess.remove_absolute(
			ProjectSettings.globalize_path(
				CAMINHO_BACKUP
			)
		)
