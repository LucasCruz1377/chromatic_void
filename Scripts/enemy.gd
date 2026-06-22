extends CharacterBody2D

@export var Deathparticle : PackedScene
@onready var anim = $anim


const SPEED = 200.0
var hp = 3
var dano = 20
var valorXp = 1

func _physics_process(delta: float) -> void:
	position.x = wrap(position.x,0,960)
	position.y = wrap(position.y,0,540)
	
	velocity.limit_length(SPEED)
	
	seguir(delta)
	move_and_slide()
	
	die()

func seguir(delta):
	var players = get_tree().get_nodes_in_group("player")
	
	if players.size() == 0:	
		return
	
	var target = players[0]
	
	var direcao = (target.global_position - global_position).normalized()
	
	velocity += direcao * SPEED * delta
	
	look_at(target.global_position)
	
func die():
	var player = get_tree().get_first_node_in_group("player")
	
	if hp <= 0:
		var _particle = Deathparticle.instantiate()
		_particle.position = global_position
		_particle.rotation = global_rotation
		_particle.emitting = true
		get_tree().current_scene.add_child(_particle)
		player.ganhar_xp(valorXp)
		Global.Combo += 1 
		Global.Pontos += 100 + (100 * (Global.Combo - 1))
		queue_free()

func tomar_dano(valor):
	$dmg_taken_audio.play()
	anim.play("flash-in")
	hp -= valor
