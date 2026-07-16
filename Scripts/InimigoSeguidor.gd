extends InimigoBase

@export var particulas_morte : PackedScene

@onready var dmg_taken_audio = $dmg_taken_audio

var direcao = Vector2.ZERO

func _physics_process(delta):
	Mover(delta)
	
	move_and_slide()
func Mover(Delta):
	if player:
		direcao = (player.global_position - global_position).normalized()
		velocity += direcao * Velocidade * Delta

func tomarDano(valor):
	if Vida <= 0:
		morrer()
	
	Vida -= valor
	dmg_taken_audio.play()
	
func morrer():
	print("Inimigo Morto")
	var parts = particulas_morte.instantiate()
	get_tree().current_scene.add_child(parts)
	queue_free()
