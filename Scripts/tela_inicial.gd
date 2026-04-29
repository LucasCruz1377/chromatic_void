extends Node2D

@onready var fx: ButtonsEffectsModule = $CanvasLayer/CaixaMenu/CaixaMenu2/Options/Start2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://Rooms/Battle_area.tscn")


func _on_exit_pressed() -> void:
	get_tree().quit()
