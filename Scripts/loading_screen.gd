extends Control

var path: String = "res://Rooms/Battle_area.tscn"
var requested: bool = false


func _ready() -> void:
	start_loading()


func start_loading() -> void:
	requested = true
	var erro: Error = ResourceLoader.load_threaded_request(path)
	if erro != OK:
		requested = false
		push_error("Falha ao iniciar carregamento: %s" % path)


func _process(_delta: float) -> void:
	if not requested:
		return
	
	var status: int = int(ResourceLoader.load_threaded_get_status(path))
	
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		requested = false
		
		var scene: Resource = ResourceLoader.load_threaded_get(path)
		
		# MUITO IMPORTANTE: limpa antes de trocar
		if scene is PackedScene:
			call_deferred("_go_to_scene", scene as PackedScene)
	elif status == ResourceLoader.THREAD_LOAD_FAILED:
		requested = false
		push_error("Falha durante o carregamento: %s" % path)


func _go_to_scene(scene: PackedScene) -> void:
	get_tree().change_scene_to_packed(scene)
