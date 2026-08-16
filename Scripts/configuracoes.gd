extends Control


@onready var janela_configuracoes: Control = $JanelaConfiguracoes


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false
	Engine.time_scale = 1.0
	Global.aplicar_configuracoes()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

	if janela_configuracoes.has_signal("voltar_solicitado"):
		janela_configuracoes.connect(
			"voltar_solicitado",
			Callable(self, "_on_voltar_solicitado")
		)


func _on_voltar_solicitado() -> void:
	Global.salvar_configuracoes()
	get_tree().change_scene_to_file("res://Rooms/TelaInicial.tscn")
