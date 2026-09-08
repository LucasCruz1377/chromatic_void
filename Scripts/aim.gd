extends Node2D


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Global.dispositivo_alterado.connect(_on_dispositivo_alterado)
	if Global.dispositivo_mobile():
		visible = false
		set_process(false)
		return
	_on_dispositivo_alterado(Global.ultimo_dispositivo)


func _process(_delta: float) -> void:
	if Global.dispositivo_mobile():
		visible = false
		return
	if Global.ultimo_dispositivo == &"teclado_mouse":
		global_position = get_global_mouse_position()
	visible = (
		Global.ultimo_dispositivo == &"teclado_mouse"
		and Input.mouse_mode != Input.MOUSE_MODE_VISIBLE
	)


func _on_dispositivo_alterado(tipo: StringName) -> void:
	if Global.dispositivo_mobile():
		visible = false
		return
	visible = (
		tipo == &"teclado_mouse"
		and Input.mouse_mode != Input.MOUSE_MODE_VISIBLE
	)
