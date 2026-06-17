extends Node2D

func _ready() -> void:
	pass
func _process(_delta: float) -> void:
	global_position = get_global_mouse_position()
	
