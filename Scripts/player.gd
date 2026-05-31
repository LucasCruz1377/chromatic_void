extends CharacterBody2D

@export var DeathParticle : PackedScene
@export var BULLET : PackedScene

@onready var ponta: Marker2D = $ponta
@onready var particles: GPUParticles2D = $particles
@onready var barra_vida = $"../GUI/Barra_vida"
@onready var somhiperdash: AudioStreamPlayer2D = $somhiperdash
@onready var somtiro: AudioStreamPlayer2D = $somtiro
@onready var hiperdashprepare: AudioStreamPlayer2D = $hiperdashprepare
@onready var death: AudioStreamPlayer2D = $death
@onready var hd_particles = $hd_particles

const acceleration = 200.00
const TURN_SPD = 10.00
const SPEED = 500.00
const CD_MAX = 0.17
const MAX_HEALTH = 100.0

var mira_mouse = Global.mira_mouse
var health = MAX_HEALTH
var cooldown = CD_MAX
var mouseaim = Global.mira_mouse
var hiperdashing = false
var vivo = true
var giroblock = false
var ctrlblock = false
var friction = 300.0
var escala_base = 4.0


func _process(delta: float) -> void:
	
	position.x = wrap(position.x,0,960)
	position.y = wrap(position.y,0,540)
	

	
	if health >= 0:
		barra_vida.scale.x = escala_base * (health / MAX_HEALTH)
	
	if cooldown >= 0:
		cooldown -= delta
		
	if health <= 0:
		die()
	
	if !giroblock and vivo: #se nao dash e vivo, controla
		if mouseaim:
			var target_angle = global_position.angle_to_point(get_global_mouse_position())
			rotation = rotate_toward(rotation,target_angle,TURN_SPD * delta) 
		if !mouseaim:
			arrowsctrl(delta)
	if !ctrlblock and vivo:
		particles.emitting = Input.is_action_pressed("accelerate")
		if Input.is_action_pressed("accelerate"):
			accelerate(delta)
		if Input.is_action_pressed("brake"):
			brake(delta)
			
	if !Input.is_action_pressed("accelerate"):
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	if Input.is_action_just_pressed("ui_accept") and vivo:
		hiperdash()
	if Input.is_action_pressed("fire") and cooldown <= 0 and !hiperdashing and vivo:
		fire()
	
	move_and_slide() 
	
	colidir_com_inimigo()
func tomar_dano(corpo):
	health -= corpo.dmg
func accelerate(delta:float):
	velocity += transform.x * SPEED * delta  
func brake(delta:float):
	velocity -= transform.x * (SPEED/2) * delta
func fire():
		var instance_bullet = BULLET.instantiate()
		get_tree().current_scene.add_child(instance_bullet)
		somtiro.pitch_scale = 1 + randf_range(-0.1,0.1)
		somtiro.play()
		instance_bullet.global_position = ponta.global_position
		instance_bullet.rotation = rotation
		cooldown = CD_MAX
func arrowsctrl(delta):
	rotation += Input.get_axis("left","right") * TURN_SPD *delta
func hiperdash():
	if hiperdashing :
		return
	hiperdashprepare.play()
	hiperdashing = true
	ctrlblock = true
	Engine.time_scale = 0.2
	await get_tree().create_timer(0.2).timeout
	giroblock = true
	Engine.time_scale = 1
	somhiperdash.play()
	hd_particles.emitting = true
	velocity += transform.x * SPEED * 5
	await get_tree().create_timer(0.15).timeout
	hd_particles.emitting = false
	velocity *= 0.2
	
	await get_tree().create_timer(0.3).timeout
	hiperdashing = false
	ctrlblock = false
	giroblock = false
	particles.emitting = false
func die():
	if !death.playing:
		death.play()
	velocity *= 0
	vivo = false
	var _particle = DeathParticle.instantiate()
	_particle.position = global_position
	_particle.rotation = global_rotation
	_particle.emitting = true
	get_tree().current_scene.add_child(_particle)
	await get_tree().create_timer(1.5).timeout
	queue_free()
func colidir_com_inimigo():
	
	
		for i in get_slide_collision_count(): #colidir com inimigos
			var colisao = get_slide_collision(i)
			var corpo = colisao.get_collider()
			if corpo.is_in_group("enemies") and !hiperdashing:
				tomar_dano(corpo)
			else:
				corpo.tomar_dano(100)
