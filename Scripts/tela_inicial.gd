extends Node2D

@onready var transition: AnimationPlayer = $transition


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_start_pressed() -> void:
	transition.play("fade_in")
	await transition.animation_finished
	get_tree().change_scene_to_file("res://Rooms/Battle_area.tscn")	


func _on_exit_pressed() -> void:
	get_tree().quit()
