extends Node


const DIRETORIOS := ["res://Scripts", "res://Habilidades", "res://Tests"]


func _ready() -> void:
	var caminhos: Array[String] = []
	for diretorio in DIRETORIOS:
		_coletar_scripts(diretorio, caminhos)
	caminhos.sort()

	var falhas: Array[String] = []
	for caminho in caminhos:
		var recurso: Resource = ResourceLoader.load(
			caminho,
			"GDScript",
			ResourceLoader.CACHE_MODE_REPLACE
		)
		if recurso == null or not recurso is GDScript:
			falhas.append(caminho)

	if not falhas.is_empty():
		push_error("Scripts que não puderam ser compilados: %s" % [falhas])
		get_tree().quit(1)
		return

	print("TESTE OK: %d scripts carregados e compilados no contexto do projeto" % caminhos.size())
	get_tree().quit(0)


func _coletar_scripts(diretorio: String, saida: Array[String]) -> void:
	for nome_arquivo in DirAccess.get_files_at(diretorio):
		if nome_arquivo.ends_with(".gd"):
			saida.append(diretorio.path_join(nome_arquivo))
	for nome_diretorio in DirAccess.get_directories_at(diretorio):
		if not nome_diretorio.begins_with("."):
			_coletar_scripts(diretorio.path_join(nome_diretorio), saida)
