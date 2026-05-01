extends Control

var path := "res://Rooms/Battle_area.tscn"
var requested := false

func _ready():
	start_loading()

func start_loading():
	requested = true
	ResourceLoader.load_threaded_request(path)

func _process(_delta):
	if not requested:
		return
	
	var status = ResourceLoader.load_threaded_get_status(path)
	
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		requested = false
		
		var scene = ResourceLoader.load_threaded_get(path)
		
		# MUITO IMPORTANTE: limpa antes de trocar
		call_deferred("_go_to_scene", scene)

func _go_to_scene(scene):
	get_tree().change_scene_to_packed(scene)
