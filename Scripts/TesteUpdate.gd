
extends Node

func _ready() -> void:
	UpdateManager.update_available.connect(
		_on_update_available
	)

	UpdateManager.update_check_finished.connect(
		_on_update_check_finished
	)

	UpdateManager.update_check_failed.connect(
		_on_update_check_failed
	)

	UpdateManager.verificar_atualizacao()


func _on_update_available(version: String) -> void:
	print("========================================")
	print("🆕 ATUALIZAÇÃO ENCONTRADA!")
	print("Nova versão: ", version)
	print("========================================")


func _on_update_check_finished() -> void:
	print("========================================")
	print("Verificação de atualização concluída.")
	print("========================================")


func _on_update_check_failed(message: String) -> void:
	print("========================================")
	print("ERRO AO VERIFICAR ATUALIZAÇÃO")
	print(message)
	print("========================================")
