extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if get_tree().paused:
		get_tree().paused = false



func _on_mouse_teclado_toggled(toggled_on: bool) -> void:
	if toggled_on:
		Global.MiraMouse = true	
	if !toggled_on:
		Global.MiraMouse = false

func _on_volume_value_changed(value):
	AudioServer.set_bus_volume_db(0,value)


func _on_voltar_pressed() -> void:
	get_tree().change_scene_to_file("res://Rooms/TelaInicial.tscn")
