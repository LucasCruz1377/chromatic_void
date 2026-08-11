extends Habilidade
class_name HabilidadeHiperdash

@export var velocidade_dash : int = 200
@export var desaceleracao : float = 0.2
@export var desaceleracao_tempo : float = 0.3 # Ex: 0.3 para slow motion inicial
@export var intervalo : float = 0.2
@export var intervalo_rastro : float = 0.03 # Tempo entre cada cópia do rastro

var ativo = false

func activate(player):
	if ativo:
		return

	ativo = true
	player.BloquearControle()
	
	Engine.time_scale = desaceleracao_tempo
	await player.get_tree().create_timer(intervalo * desaceleracao_tempo).timeout
	
	player.BloquearGiro()
	Engine.time_scale = 1
	
	var camera = player.get_node_or_null("../Camera2D")
	if camera and camera.has_method("shake"):
		camera.shake(5.0) # 5 é a intensidade média que você pediu
	
	player.velocity += player.transform.x * player.SPEED * 5
	
	gerar_loop_de_rastros(player)
	
	await player.get_tree().create_timer(0.25).timeout
	player.velocity *= desaceleracao
	
	await player.get_tree().create_timer(intervalo).timeout
	ativo = false
	player.DesbloquearControle()
	player.DesbloquearGiro()

func update(player, _delta):
	if ativo:
		player.IniciarHabilidade()
	else:
		player.EncerrarHabilidade()

func gerar_loop_de_rastros(player):
	while ativo and player.velocity.length() > 100:
		criar_copia_poligono(player, player.corpo)
		criar_copia_poligono(player, player.corpo_2)
		
		await player.get_tree().create_timer(intervalo_rastro).timeout

func criar_copia_poligono(player, poligono_original: Polygon2D):
	if poligono_original:
		var copia = poligono_original.duplicate() as Polygon2D
		
		copia.global_position = poligono_original.global_position
		copia.global_rotation = poligono_original.global_rotation
		copia.global_scale = poligono_original.global_scale
		
		copia.modulate = Color(0.0, 0.7, 1.0, 0.5)
		
		player.get_parent().add_child(copia)
		
		var tween = player.create_tween()
		tween.tween_property(copia, "modulate:a", 0.0, 0.3)
		tween.tween_callback(copia.queue_free)
