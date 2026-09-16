extends Node


const AudioCombate = preload("res://Scripts/AudioCombate.gd")


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().node_added.connect(_ao_no_adicionado)
	call_deferred("_conectar_botoes_existentes")


func _conectar_botoes_existentes() -> void:
	var cena := get_tree().current_scene
	if not is_instance_valid(cena):
		return
	_conectar_recursivamente(cena)


func _conectar_recursivamente(no: Node) -> void:
	_conectar_botao(no)
	for filho in no.get_children():
		_conectar_recursivamente(filho)


func _ao_no_adicionado(no: Node) -> void:
	_conectar_botao(no)


func _conectar_botao(no: Node) -> void:
	if not is_instance_valid(no) or not no is BaseButton:
		return
	var botao := no as BaseButton
	if not botao.pressed.is_connected(_ao_botao_pressionado):
		botao.pressed.connect(_ao_botao_pressionado)


func _ao_botao_pressionado() -> void:
	AudioCombate.tocar(self, &"menu", 0.035, 0.90, 1.13, -7.0)
