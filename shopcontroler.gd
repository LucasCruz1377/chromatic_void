extends Control

@onready var h_box_container: HBoxContainer = $HBoxContainer

var itematual = 1

func _process(delta: float) -> void:
	h_box_container.global_position.x = itematual * 222


func _on_left_pressed() -> void:
	itematual -= 1


func _on_right_pressed() -> void:
	itematual += 1
