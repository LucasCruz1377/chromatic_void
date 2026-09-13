extends Control

const CAMINHO_MENU := "res://Rooms/TelaInicial.tscn"
const TEMPO_MAXIMO_CARREGAMENTO := 30.0

var path: String = "res://Rooms/Battle_area.tscn"
var requested: bool = false
var tempo_carregando := 0.0
var fallback_iniciado := false


func _ready() -> void:
	start_loading()


func start_loading() -> void:
	requested = true
	tempo_carregando = 0.0
	fallback_iniciado = false
	var erro: Error = ResourceLoader.load_threaded_request(path)
	if erro != OK:
		_usar_fallback()


func _process(delta: float) -> void:
	if not requested:
		return
	tempo_carregando += delta
	if tempo_carregando >= TEMPO_MAXIMO_CARREGAMENTO:
		push_warning("Carregamento assíncrono excedeu %.0f s: %s" % [TEMPO_MAXIMO_CARREGAMENTO, path])
		_usar_fallback()
		return

	var status: int = int(ResourceLoader.load_threaded_get_status(path))
	if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		return
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		requested = false
		var scene: Resource = ResourceLoader.load_threaded_get(path)
		if scene is PackedScene:
			call_deferred("_go_to_scene", scene as PackedScene)
		else:
			_usar_fallback()
		return
	if status in [
		ResourceLoader.THREAD_LOAD_FAILED,
		ResourceLoader.THREAD_LOAD_INVALID_RESOURCE,
	]:
		_usar_fallback()
		return

	# Um estado inesperado não pode prender o usuário nesta tela.
	_usar_fallback()


func _usar_fallback() -> void:
	if fallback_iniciado:
		return
	fallback_iniciado = true
	requested = false
	var erro := get_tree().change_scene_to_file(path)
	if erro != OK:
		push_error("Falha ao abrir %s (erro %d); retornando ao menu." % [path, erro])
		get_tree().change_scene_to_file(CAMINHO_MENU)


func _go_to_scene(scene: PackedScene) -> void:
	var erro := get_tree().change_scene_to_packed(scene)
	if erro != OK:
		fallback_iniciado = false
		_usar_fallback()
