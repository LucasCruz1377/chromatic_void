extends Node2D

@onready var player: CharacterBody2D = $"../CharacterBody2D"

func _ready() -> void:
	pass
func _process(_delta: float) -> void:
	global_position = get_global_mouse_position()
	
	if Input.is_action_pressed("fire"):
		pass
	else:
		pass
