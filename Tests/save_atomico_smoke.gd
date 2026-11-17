extends Node

var falhas: Array[String] = []


func verificar(condicao: bool, mensagem: String) -> void:
	if not condicao:
		falhas.append(mensagem)
		push_error(mensagem)


func _ready() -> void:
	var originais: Dictionary = {}
	for caminho in [GerenciadorDeSave.CAMINHO_SAVE, GerenciadorDeSave.CAMINHO_BACKUP]:
		if FileAccess.file_exists(caminho):
			originais[caminho] = FileAccess.get_file_as_bytes(caminho)
	GerenciadorDeSave.deletar_save()
	GerenciadorDeSave.salvar(
		{"nickname": "Lúcas • çã", "cristais": 123, "equipamentos": {"1": "teste"}}
	)
	GerenciadorDeSave.salvar({"cristais": 456})
	var dados := GerenciadorDeSave.carregar()
	verificar(dados.get("nickname") == "Lúcas • çã", "save perdeu UTF-8 ou campos anteriores")
	verificar(int(dados.get("cristais", 0)) == 456, "save nao publicou a ultima escrita")
	verificar(dados.get("equipamentos", {}).get("1") == "teste", "save perdeu dicionario aninhado")
	var backup := GerenciadorDeSave._ler_dicionario(GerenciadorDeSave.CAMINHO_BACKUP)
	verificar(int(backup.get("cristais", 0)) == 123, "backup nao preservou a versao anterior")
	var arquivo := FileAccess.open(GerenciadorDeSave.CAMINHO_SAVE, FileAccess.WRITE)
	arquivo.store_string("{corrompido")
	arquivo.close()
	GerenciadorDeSave._cache.clear()
	verificar(
		int(GerenciadorDeSave.carregar().get("cristais", 0)) == 123,
		"backup nao recuperou principal corrompido"
	)
	GerenciadorDeSave.salvar({"cristais": 789})
	verificar(
		int(GerenciadorDeSave.carregar().get("cristais", 0)) == 789,
		"save nao recuperou escrita apos corrupcao"
	)
	verificar(
		(
			int(
				GerenciadorDeSave._ler_dicionario(GerenciadorDeSave.CAMINHO_BACKUP).get(
					"cristais", 0
				)
			)
			== 123
		),
		"principal corrompido sobrescreveu backup valido"
	)
	verificar(
		not FileAccess.file_exists(
			GerenciadorDeSave.CAMINHO_TEMPORARIO + ".%d" % OS.get_process_id()
		),
		"temporario ficou aberto/pendente apos publicar"
	)
	GerenciadorDeSave.deletar_save()
	for caminho in originais:
		arquivo = FileAccess.open(caminho, FileAccess.WRITE)
		arquivo.store_buffer(originais[caminho])
		arquivo.close()
	GerenciadorDeSave._cache.clear()
	print(
		(
			"TESTE %s: save UTF-8, substituicao e recuperacao por backup"
			% ("OK" if falhas.is_empty() else "FALHOU")
		)
	)
	get_tree().quit(0 if falhas.is_empty() else 1)
