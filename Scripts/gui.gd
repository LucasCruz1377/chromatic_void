extends CanvasLayer

@onready var caixa_pause: VBoxContainer = $"caixa pause"


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pausar"):
		get_tree().paused = !get_tree().paused
	
	caixa_pause.visible = get_tree().paused
	
	if Input.is_action_just_pressed("reset"):
		get_tree().paused = false
		Global.Pontos = 0
		Global.Combo = 0
		get_tree().reload_current_scene()
	
	
func _on_tentar_de_novo_pressed() -> void:
		get_tree().paused = false
		Global.Pontos = 0
		Global.Combo = 0
		get_tree().reload_current_scene()


func _on_despause_pressed() -> void:
	get_tree().paused = false


func _on_voltarmenu_2_pressed() -> void:
	get_tree().change_scene_to_file("res://Rooms/TelaInicial.tscn")


func _on_voltarmenu_pressed() -> void:
	get_tree().change_scene_to_file("res://Rooms/TelaInicial.tscn")
