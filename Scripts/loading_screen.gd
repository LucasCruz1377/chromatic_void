extends Control

var path := "res://Rooms/Battle_area.tscn"

func _ready():
	ResourceLoader.load_threaded_request(path)

func _process(_delta):
	var status = ResourceLoader.load_threaded_get_status(path)
	
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		var scene = ResourceLoader.load_threaded_get(path)
		get_tree().change_scene_to_packed(scene)
