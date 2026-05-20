extends Node2D

@onready var transition: AnimationPlayer = $transition
@onready var som: AudioStreamPlayer2D = $som


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var musicbus = AudioServer.get_bus_index("Music")
	var soundbus = AudioServer.get_bus_index("Sound") 
	AudioServer.set_bus_volume_db(musicbus,Global.volume_musica)
	AudioServer.set_bus_volume_db(soundbus,Global.volume_som)
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	
	
	if get_tree().paused:
		get_tree().paused = false


func _on_start_pressed() -> void:
	click_som()
	transition.play("fade_in")
	await transition.animation_finished
	get_tree().change_scene_to_file("res://Rooms/Battle_area.tscn")	


func _on_exit_pressed() -> void:
	click_som()
	await get_tree().create_timer(0.5).timeout
	get_tree().quit()


func _on_options_pressed() -> void:
	transition.play("fade_in")
	click_som()
	await transition.animation_finished
	get_tree().change_scene_to_file("res://Rooms/configuracoes.tscn")

func click_som():
	som.play()
