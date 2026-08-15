extends InimigoBase


@export var particulas_morte: PackedScene

@onready var anim: AnimationPlayer = $anim
@onready var dmg_taken_audio: AudioStreamPlayer2D = $dmg_taken_audio
@onready var camera: Camera2D = get_tree().get_first_node_in_group("camera")

var direcao := Vector2.ZERO
var morto := false


func _ready() -> void:
	if is_instance_valid(player):
		Vida = VidaMaxima + float(int(player.nivel_atual / 5))
	else:
		Vida = VidaMaxima


func _physics_process(delta: float) -> void:
	if morto:
		return

	atualizar_estados(delta)

	if usa_wrap:
		position.x = wrapf(position.x, 0.0, 960.0)
		position.y = wrapf(position.y, 0.0, 540.0)

	if esta_atordoado():
		velocity = velocity.move_toward(Vector2.ZERO, Velocidade * 2.0 * delta)
		move_and_slide()
		return

	Mover(delta)
	velocity = velocity.limit_length(Velocidade)
	move_and_slide()


func Mover(delta: float) -> void:
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")

	if not is_instance_valid(player):
		return

	direcao = (player.global_position - global_position).normalized()
	velocity += direcao * Velocidade * delta


func tomarDano(valor: float) -> void:
	if morto:
		return

	Vida -= valor

	if dmg_taken_audio:
		dmg_taken_audio.play()

	if anim:
		anim.play("flash-in")

	if Vida <= 0.0:
		morrer()


func morrer() -> void:
	if morto:
		return

	morto = true

	if camera and camera.has_method("shake"):
		camera.shake(5.0)

	if particulas_morte:
		var partes = particulas_morte.instantiate()
		partes.position = global_position
		partes.rotation = global_rotation
		partes.emitting = true
		get_tree().current_scene.add_child(partes)

	if is_instance_valid(player):
		player.ganhar_xp(ValorXP)

	Global.kills_max += 1
	Global.Combo += 1
	Global.Pontos += 100 + (100 * (Global.Combo - 1))
	queue_free()
