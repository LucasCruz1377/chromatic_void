extends Habilidade
class_name HabilidadeRetrocesso

var memoria = []
var recordando = false
@export var intervalomemorias : float = 0
@export var max_memoria : int = 60
@export var intervalo_rastro_rewind : int = 3

func activate(player):
	if recordando:
		return
	
	player.BloquearGiro()
	player.BloquearControle()
	recordando = true
	player.velocity = Vector2.ZERO
	rewind(player)

func update(player, _delta):
	if !recordando:
		if memoria.size() >= max_memoria:
			memoria.pop_front()
		memoria.append({"posicao" : player.global_position , "rotacao" : player.rotation , "vida" : player.vida})
	
func rewind(player):
	if memoria.is_empty():
		recordando = false
		player.DesbloquearGiro()
		player.DesbloquearControle()
		return
		
	player.IniciarHabilidade()
	var camera = player.get_node_or_null("../Camera2D")
	
	for save in range(memoria.size() - 1, -1, -1):
		while player.get_tree().paused:
			await player.get_tree().process_frame
		
		player.global_position = memoria[save]["posicao"]
		player.rotation = memoria[save]["rotacao"]
		player.vida = memoria[save]["vida"] if memoria[save]["vida"] > player.vida else player.vida
		
		if camera and camera.has_method("shake") and save % 4 == 0: 
			camera.shake(2.5)
		
		player.modulate.a = randf_range(0.3, 0.9)
		
		if save % intervalo_rastro_rewind == 0:
			criar_rastro_temporal(player, player.corpo)
			criar_rastro_temporal(player, player.corpo_2)
		
		await player.get_tree().create_timer(intervalomemorias).timeout
	
	player.modulate.a = 1.0
	
	if camera and camera.has_method("shake"):
		camera.shake(4.0)
	
	player.EncerrarHabilidade()
	memoria.clear()
	recordando = false
	player.DesbloquearGiro()
	player.DesbloquearControle()

func criar_rastro_temporal(player, poligono_original: Polygon2D):
	if poligono_original:
		var copia = poligono_original.duplicate() as Polygon2D
		copia.global_position = poligono_original.global_position
		copia.global_rotation = poligono_original.global_rotation
		copia.global_scale = poligono_original.global_scale
		copia.modulate = Color(0.8, 0.0, 1.0, 0.6)
		
		player.get_parent().add_child(copia)
		
		var tween = player.create_tween()
		tween.tween_property(copia, "modulate:a", 0.0, 0.15)
		tween.tween_callback(copia.queue_free)
