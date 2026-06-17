extends CharacterBody2D
class_name Player

@export var ParticulaMorte : PackedScene
@export var tiro : PackedScene
@export var HabilidadeEquipada : Habilidade
@onready var PontaArma: Marker2D = $ponta
@onready var particles: GPUParticles2D = $particles
@onready var barra_vida = $"../GUI/Barra_vida"
@onready var somtiro: AudioStreamPlayer2D = $somtiro
@onready var death: AudioStreamPlayer2D = $death
@onready var camera : Camera2D = get_tree().get_first_node_in_group("camera")
@onready var corpo: Polygon2D = $corpo
@onready var corpo_2: Polygon2D = $corpo2



const VelocidadeVirar = 7.00
const SPEED = 500.00
const CD_MAX = 0.16
const VIDA_MAXIMA = 100.0

var MAX_VELOCIDADE = 500
var mira_mouse = Global.mira_mouse
var vida = VIDA_MAXIMA
var cooldown = CD_MAX
var miramouse = Global.mira_mouse
var vivo = true
var giroblock = false
var ctrlblock = false
var friction = 100.0
var escala_base = 4.0
var UsandoHabilidade = false
var xp_atual : float
var nivel_atual : int = 1
var xp_necessario : int = 5

signal subiuDeNivel(nivel)

func _process(delta: float) -> void:
	
	HabilidadeEquipada.update(self,delta)
	
	if vivo and Input.is_action_just_pressed("Habilidade"):
		HabilidadeEquipada.activate(self)
	
			
	position.x = wrap(position.x,0,960)
	position.y = wrap(position.y,0,540)
	
	
	if vida >= 0:
		barra_vida.scale.x = escala_base * (vida / VIDA_MAXIMA)
	
	if cooldown >= 0:
		cooldown -= delta
		
	if vida <= 0:
		morrer()
	
	if !giroblock and vivo: #se nao dash e vivo, controla
		if miramouse:
			var target_angle = global_position.angle_to_point(get_global_mouse_position())
			rotation = rotate_toward(rotation,target_angle,VelocidadeVirar * delta) 
		if !miramouse:
			arrowsctrl(delta)
	if vivo:
		if Input.is_action_pressed("acelerar") or UsandoHabilidade:
			particles.emitting = true
		else:
			particles.emitting = false
		if Input.is_action_pressed("acelerar"):
			acelerar(delta)
		if Input.is_action_pressed("freio"):
			brake(delta)
			
			
	if Input.is_action_pressed("atirar") and cooldown <= 0 and vivo:
		fire()
	
	velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	if !UsandoHabilidade:
		velocity = velocity.limit_length(MAX_VELOCIDADE)
	move_and_slide() 
	
func tomar_dano(valor):
	vida -= valor
	
func curar(valor):
	vida += valor
	
func acelerar(delta:float):
	velocity += transform.x * SPEED * delta
func brake(delta:float):
	velocity -= transform.x * SPEED * 0.8 * delta
func fire():
		var instance_bullet = tiro.instantiate()
		get_tree().current_scene.add_child(instance_bullet)
		camera.Shake()
		somtiro.pitch_scale = 1 + randf_range(-0.1,0.1)
		somtiro.play()
		instance_bullet.global_position = PontaArma.global_position
		instance_bullet.rotation = rotation
		cooldown = CD_MAX
func arrowsctrl(delta):
	rotation += Input.get_axis("left","right") * VelocidadeVirar * delta	
func morrer():
	if !death.playing:
		visible = false
		death.play()
	velocity *= 0
	vivo = false
	var _particle = ParticulaMorte.instantiate()
	_particle.position = global_position
	_particle.rotation = global_rotation
	_particle.emitting = true
	get_tree().current_scene.add_child(_particle)
	await get_tree().create_timer(1.5).timeout
	queue_free()

func BloquearControle():
	ctrlblock = true
func BloquearGiro():
	giroblock = true
func DesbloquearControle():
	ctrlblock = false
func DesbloquearGiro():
	giroblock = false

func IniciarHabilidade():
	UsandoHabilidade = true
func EncerrarHabilidade():
	UsandoHabilidade = false

func ganhar_xp(value):
	xp_atual += value
	print(str(xp_atual))
	
	if xp_atual >= xp_necessario:
		nivel_atual += 1
		xp_atual = 0
		xp_necessario += 5
		print(str(xp_atual))
		print(str(nivel_atual))
		subiuDeNivel.emit()
