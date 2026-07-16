extends InimigoBase

@export var particulas_morte : PackedScene
@onready var anim = $anim
@onready var dmg_taken_audio = $dmg_taken_audio
@onready var camera : Camera2D = get_tree().get_first_node_in_group("camera")

var direcao = Vector2.ZERO

func _ready():
	Vida = VidaMaxima + (1 * int(player.nivel_atual / 5))

func _physics_process(delta):
	if usa_wrap:
		position.x = wrap(position.x,0,960)
		position.y = wrap(position.y,0,540)
		
	velocity.limit_length(Velocidade)
	Mover(delta)
	
	move_and_slide()
func Mover(Delta):
	if player:
		direcao = (player.global_position - global_position).normalized()
		velocity += direcao * Velocidade * Delta

func tomarDano(valor):
	if Vida <= 0:
		morrer()
	
	dmg_taken_audio.play()
	anim.play("flash-in")
	Vida -= valor
	
func morrer():
	camera.shake(5.0)
	print("Inimigo Morto")
	var parts = particulas_morte.instantiate()
	parts.position = global_position
	parts.rotation = global_rotation
	parts.emitting = true
	get_tree().current_scene.add_child(parts)
	player.ganhar_xp(ValorXP)
	Global.Combo += 1
	Global.Pontos += 100 + (100 * (Global.Combo - 1))
	queue_free()
