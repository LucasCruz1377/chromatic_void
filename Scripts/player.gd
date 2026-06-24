extends CharacterBody2D
class_name Player

@export var ParticulaMorte : PackedScene
@export var tiro : PackedScene
@export var HabilidadeEquipada : Habilidade
@onready var PontaArma: Marker2D = $ponta
@onready var particles: GPUParticles2D = $particles
@onready var barra_vida = $"../GUI/Barra_vida"
@onready var barra_xp: TextureProgressBar = $"../GUI/Barra_xp"
@onready var somtiro: AudioStreamPlayer2D = $somtiro
@onready var death: AudioStreamPlayer2D = $death
@onready var camera : Camera2D = get_tree().get_first_node_in_group("camera")
@onready var corpo: Polygon2D = $corpo
@onready var corpo_2: Polygon2D = $corpo2
@onready var display_skill: TextureRect = $"../GUI/DisplaySkill"
@onready var lvl_text: Label = $"../GUI/LvlText"




var VelocidadeVirar = 6.00
var SPEED = 500.00
var VIDA_MAXIMA = 100.0
var CD_MAX = 0.20
var MAX_VELOCIDADE = 500
var mira_mouse = Global.mira_mouse
var vida = VIDA_MAXIMA
var cooldown = CD_MAX
var miramouse = Global.mira_mouse
var vivo = true
var giroblock = false
var ctrlblock = false
var friction = 100.0
var escala_base = 9.85
var UsandoHabilidade = false
var xp_atual : float
var nivel_atual : int = 1
var xp_necessario : int = 3
var dano = 1
var invencibilidade : bool = false
var invencibilidade_cd : float = 0
var invencibilidade_cd_max : float = 1

signal subiuDeNivel(nivel)

func _process(delta: float) -> void:
	lvl_text.text = "LVL: " + str(nivel_atual)
	display_skill.texture = HabilidadeEquipada.Icone
	
	if Input.is_key_label_pressed(KEY_G) and OS.is_debug_build():
		ganhar_xp(1)
	
	if invencibilidade_cd > 0:
		invencibilidade_cd -= delta
		$anim.play("invencivel")
	else:
		invencibilidade = false
		$anim.play("RESET")
	barra_xp.value = xp_atual
	barra_xp.max_value = xp_necessario
	
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
	if invencibilidade or UsandoHabilidade:
		return
	
	vida -= valor
	invencibilidade_cd += invencibilidade_cd_max
	invencibilidade = true
	
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
		instance_bullet.dmg = dano
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
	
	if xp_atual >= xp_necessario:
		nivel_atual += 1
		xp_atual = 0
		xp_necessario += 2
		subiuDeNivel.emit()

func receber_upgrade(tipo):
	match tipo:
		0: 
			CD_MAX -= 0.01
		1:
			VIDA_MAXIMA *= 1.1
			vida = VIDA_MAXIMA
			print(str(VIDA_MAXIMA))
		2:
			dano += 1
		3:
			MAX_VELOCIDADE *= 1.1
			SPEED *= 1.05
		4:
			VelocidadeVirar *= 1.1

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("inimigo") and vivo:
		print("encostou em inimigo")
		tomar_dano(body.dano)
		if body.has_method("die"):
			body.die()
