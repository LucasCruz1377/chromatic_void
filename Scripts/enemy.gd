extends CharacterBody2D

@export var Deathparticle : PackedScene

const SPEED = 10.0
var hp = 1
var dmg = 2

func _physics_process(delta: float) -> void:
	position.x = wrap(position.x,0,960)
	position.y = wrap(position.y,0,540)

	seguir(delta)
	move_and_slide()
	
	die()
func seguir(_delta):
	var players = get_tree().get_nodes_in_group("player")
	
	if players.size() == 0:	
		return
	
	var target = players[0]
	
	var direcao = (target.global_position - global_position).normalized()
	
	velocity += direcao * SPEED
	
	look_at(target.global_position)
	
func die():
	if hp <= 0:
		var _particle = Deathparticle.instantiate()
		_particle.position = global_position
		_particle.rotation = global_rotation
		_particle.emitting = true
		get_tree().current_scene.add_child(_particle)
		
		Global.Pontos += 10 + (10 * Global.Combo)
		Global.Combo += 1 
		queue_free()
