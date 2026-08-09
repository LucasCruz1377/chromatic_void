extends CharacterBody2D
class_name Player

# ============================================================
# EXPORTS
# ============================================================

@export_category("Combate")
@export var tiro: PackedScene
@export var HabilidadeEquipada: Habilidade
@export var dano := 1.0
@export var CD_MAX := 0.22

@export_category("Movimento")
@export var VelocidadeVirar := 4.0
@export var SPEED := 400.0
@export var MAX_VELOCIDADE := 500.0
@export var friction := 100.0

@export_category("Vida")
@export var VIDA_MAXIMA := 100.0

@export_category("Morte")
@export var ParticulaMorte: PackedScene


# ============================================================
# NODES
# ============================================================

@onready var PontaArma: Marker2D = $ponta
@onready var particles: GPUParticles2D = $particles

@onready var barra_vida = $"../GUI/Barra_vida"
@onready var barra_xp: TextureProgressBar = $"../GUI/Barra_xp"
@onready var display_skill: TextureRect = $"../GUI/DisplaySkill"
@onready var lvl_text: Label = $"../GUI/LvlText"

@onready var somtiro: AudioStreamPlayer2D = $somtiro
@onready var death: AudioStreamPlayer2D = $death


# ============================================================
# STATUS DO PLAYER
# ============================================================

var vida: float
var cooldown := 0.0

var mira_mouse = Global.mira_mouse
var vivo := true

var giroblock := false
var ctrlblock := false

var escala_base := 9.85

var UsandoHabilidade := false

var xp_atual: float = 0.0
var nivel_atual: int = 1
var xp_necessario: int = 3

var invencibilidade := false
var invencibilidade_cd := 0.0
var invencibilidade_cd_max := 3.0

var save := false


# ============================================================
# ENUM DE UPGRADES
# ============================================================

enum Upgrade {
	CADENCIA,
	BLINDAGEM,
	DANO,
	VELOCIDADE,
	TURNSPD
}


# ============================================================
# SIGNALS
# ============================================================

signal subiuDeNivel()


# ============================================================
# READY
# ============================================================

func _ready() -> void:
	vida = VIDA_MAXIMA


# ============================================================
# PROCESS
# ============================================================

func _process(delta: float) -> void:
	atualizar_ui()
	atualizar_invencibilidade(delta)
	atualizar_habilidade(delta)
	atualizar_movimento(delta)
	atualizar_combate(delta)
	atualizar_limites()
	atualizar_vida()


# ============================================================
# UI
# ============================================================

func atualizar_ui() -> void:
	lvl_text.text = "LVL: " + str(nivel_atual)

	if HabilidadeEquipada:
		display_skill.texture = HabilidadeEquipada.Icone

	barra_xp.value = xp_atual
	barra_xp.max_value = xp_necessario


func atualizar_vida() -> void:
	if vida > 0:
		barra_vida.scale.x = escala_base * (vida / VIDA_MAXIMA)

	if vida <= 0 and vivo:
		morrer()


# ============================================================
# INVENCIBILIDADE
# ============================================================

func atualizar_invencibilidade(delta: float) -> void:
	if invencibilidade_cd > 0:
		invencibilidade_cd -= delta

		modulate.a = abs(
			sin(Time.get_ticks_msec() / 100.0)
		)

	else:
		modulate.a = 1.0
		invencibilidade = false


# ============================================================
# HABILIDADE
# ============================================================

func atualizar_habilidade(delta: float) -> void:
	if not HabilidadeEquipada:
		return

	# Continua atualizando o cooldown normalmente.
	HabilidadeEquipada.update(
		self,
		delta
	)

	# Se o controle estiver bloqueado,
	# não permite ativar habilidades.
	if ctrlblock:
		return

	if vivo and Input.is_action_just_pressed(
		"Habilidade"
	):

		HabilidadeEquipada.activate(self)


func IniciarHabilidade() -> void:
	UsandoHabilidade = true


func EncerrarHabilidade() -> void:
	UsandoHabilidade = false


# ============================================================
# MOVIMENTO
# ============================================================

func atualizar_movimento(delta: float) -> void:
	if not vivo:
		return

	# Controle de direção
	if not giroblock:

		if mira_mouse:
			var target_angle = global_position.angle_to_point(
				get_global_mouse_position()
			)

			rotation = rotate_toward(
				rotation,
				target_angle,
				VelocidadeVirar * delta
			)

		else:
			arrowsctrl(delta)


	# Controle de aceleração
	if not ctrlblock:

		if Input.is_action_pressed("acelerar"):
			acelerar(delta)

		if Input.is_action_pressed("freio"):
			brake(delta)


	# Partículas
	if Input.is_action_pressed("acelerar") or UsandoHabilidade:
		particles.emitting = true
	else:
		particles.emitting = false


	# Redução de velocidade
	velocity = velocity.move_toward(
		Vector2.ZERO,
		friction * delta
	)


	# Limite de velocidade
	if not UsandoHabilidade:
		velocity = velocity.limit_length(MAX_VELOCIDADE)


	move_and_slide()


func acelerar(delta: float) -> void:
	velocity += transform.x * SPEED * delta


func brake(delta: float) -> void:
	velocity -= transform.x * SPEED * 0.8 * delta


func arrowsctrl(delta: float) -> void:
	rotation += Input.get_axis(
		"esquerda",
		"direita"
	) * VelocidadeVirar * delta


# ============================================================
# COMBATE
# ============================================================

func atualizar_combate(delta: float) -> void:
	cooldown -= delta


	if cooldown < 0:
		cooldown = 0


	# MUITO IMPORTANTE:
	#
	# Durante o tutorial o Astro usa o mesmo
	# clique esquerdo que normalmente atiraria.
	#
	# Como ctrlblock está ativo, não atira.
	if ctrlblock:
		return


	if vivo and Input.is_action_pressed(
		"atirar"
	):

		if cooldown <= 0:
			fire()


func fire() -> void:
	if not tiro:
		return

	var instance_bullet = tiro.instantiate()

	get_tree().current_scene.add_child(instance_bullet)

	instance_bullet.dmg = dano
	instance_bullet.global_position = PontaArma.global_position
	instance_bullet.rotation = rotation

	somtiro.pitch_scale = randf_range(0.9, 1.1)
	somtiro.play()

	cooldown = CD_MAX


# ============================================================
# VIDA
# ============================================================

func tomar_dano(valor: float) -> void:
	if invencibilidade:
		return

	if UsandoHabilidade:
		return

	if not vivo:
		return

	vida -= valor

	invencibilidade = true
	invencibilidade_cd = invencibilidade_cd_max


func curar(valor: float) -> void:
	vida += valor

	if vida > VIDA_MAXIMA:
		vida = VIDA_MAXIMA


# ============================================================
# XP
# ============================================================

func ganhar_xp(value: float) -> void:
	if invencibilidade:
		return

	xp_atual += value

	if xp_atual >= xp_necessario:
		subir_de_nivel()


func subir_de_nivel() -> void:
	nivel_atual += 1

	xp_atual = 0

	xp_necessario += 2

	subiuDeNivel.emit()


# ============================================================
# UPGRADES
# ============================================================

func receber_upgrade(tipo: Upgrade) -> void:

	match tipo:

		Upgrade.CADENCIA:
			# Reduz o cooldown do tiro.
			CD_MAX *= 0.9

			# Reduz também o cooldown da habilidade.
			if HabilidadeEquipada:
				HabilidadeEquipada.cooldown_max *= 0.9

				# Evita que o cooldown atual fique maior
				# que o novo máximo.
				HabilidadeEquipada.cooldown = min(
					HabilidadeEquipada.cooldown,
					HabilidadeEquipada.cooldown_max
				)


		Upgrade.BLINDAGEM:
			VIDA_MAXIMA *= 1.1
			vida = VIDA_MAXIMA


		Upgrade.DANO:
			dano += 0.5


		Upgrade.VELOCIDADE:
			MAX_VELOCIDADE *= 1.1
			SPEED *= 1.05


		Upgrade.TURNSPD:
			VelocidadeVirar *= 1.1


# ============================================================
# MORTE
# ============================================================

func morrer() -> void:
	if not vivo:
		return

	vivo = false

	velocity = Vector2.ZERO

	visible = false

	death.play()

	var particle = ParticulaMorte.instantiate()

	particle.position = global_position
	particle.rotation = global_rotation
	particle.emitting = true

	get_tree().current_scene.add_child(particle)

	await get_tree().create_timer(1.5).timeout

	queue_free()


# ============================================================
# BLOQUEIOS
# ============================================================

func BloquearControle() -> void:
	ctrlblock = true


func DesbloquearControle() -> void:
	ctrlblock = false


func BloquearGiro() -> void:
	giroblock = true


func DesbloquearGiro() -> void:
	giroblock = false


# ============================================================
# LIMITES DO MAPA
# ============================================================

func atualizar_limites() -> void:
	position.x = wrap(position.x, 0, 960)
	position.y = wrap(position.y, 0, 540)


# ============================================================
# COLISÃO
# ============================================================

func _on_hitbox_body_entered(body: Node2D) -> void:
	if not vivo:
		return

	if body.is_in_group("inimigo"):

		print("encostou em inimigo")

		tomar_dano(body.Dano)

		if body.has_method("morrer"):
			body.morrer()
