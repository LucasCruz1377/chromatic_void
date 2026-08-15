extends CharacterBody2D
class_name Player


const CAMINHO_HABILIDADE_PADRAO := "res://Habilidades/habilidadeRetrocesso.tres"


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


@onready var PontaArma: Marker2D = $ponta
@onready var particles: GPUParticles2D = $particles

@onready var barra_vida = $"../GUI/Barra_vida"
@onready var barra_xp: TextureProgressBar = $"../GUI/Barra_xp"
@onready var display_skill: TextureRect = $"../GUI/DisplaySkill"
@onready var lvl_text: Label = $"../GUI/LvlText"

@onready var somtiro: AudioStreamPlayer2D = $somtiro
@onready var death: AudioStreamPlayer2D = $death


var vida: float
var cooldown := 0.0

var mira_mouse = Global.mira_mouse
var vivo := true

var giroblock := false
var ctrlblock := false

var escala_base := 9.85

var UsandoHabilidade := false
var invulneravel_por_habilidade := false
var multiplicador_dano_recebido := 1.0
var multiplicador_cura_recebida := 1.0
var multiplicador_velocidade_habilidade := 1.0

var xp_atual: float = 0.0
var nivel_atual: int = 1
var xp_necessario: int = 3

var invencibilidade := false
var invencibilidade_cd := 0.0
var invencibilidade_cd_max := 3.0

var save := false


enum Upgrade {
	CADENCIA,
	BLINDAGEM,
	DANO,
	VELOCIDADE,
	TURNSPD
}


signal subiuDeNivel()


func _ready() -> void:
	vida = VIDA_MAXIMA
	carregar_habilidade_equipada()


func _exit_tree() -> void:
	if HabilidadeEquipada:
		HabilidadeEquipada.ao_desequipar(self)


func _process(delta: float) -> void:
	atualizar_ui()
	atualizar_invencibilidade(delta)
	atualizar_habilidade(delta)
	atualizar_movimento(delta)
	atualizar_combate(delta)
	atualizar_limites()
	atualizar_vida()


func carregar_habilidade_equipada() -> void:
	var dados := GerenciadorDeSave.carregar()
	var caminho := str(dados.get("habilidade_equipada", ""))
	var habilidade_carregada: Habilidade

	if not caminho.is_empty() and ResourceLoader.exists(caminho):
		var recurso := load(caminho)
		if recurso is Habilidade:
			habilidade_carregada = recurso

	if not habilidade_carregada and HabilidadeEquipada:
		habilidade_carregada = HabilidadeEquipada

	if not habilidade_carregada and ResourceLoader.exists(CAMINHO_HABILIDADE_PADRAO):
		var recurso_padrao := load(CAMINHO_HABILIDADE_PADRAO)
		if recurso_padrao is Habilidade:
			habilidade_carregada = recurso_padrao

	if not habilidade_carregada:
		push_warning("Nenhuma habilidade válida foi encontrada para o Player.")
		HabilidadeEquipada = null
		return

	var copia := habilidade_carregada.duplicate(true) as Habilidade
	if not copia:
		push_error("Não foi possível duplicar a habilidade equipada.")
		HabilidadeEquipada = null
		return

	HabilidadeEquipada = copia
	HabilidadeEquipada.reiniciar_estado()
	HabilidadeEquipada.ao_equipar(self)


func atualizar_ui() -> void:
	lvl_text.text = "LVL: " + str(nivel_atual)

	if HabilidadeEquipada:
		display_skill.texture = HabilidadeEquipada.Icone
	else:
		display_skill.texture = null

	barra_xp.value = xp_atual
	barra_xp.max_value = xp_necessario


func atualizar_vida() -> void:
	vida = clampf(vida, 0.0, VIDA_MAXIMA)
	barra_vida.scale.x = escala_base * (vida / VIDA_MAXIMA)

	if vida <= 0.0 and vivo:
		morrer()


func atualizar_invencibilidade(delta: float) -> void:
	if invencibilidade_cd > 0.0:
		invencibilidade_cd = maxf(invencibilidade_cd - delta, 0.0)
		modulate.a = absf(sin(Time.get_ticks_msec() / 100.0))
	else:
		modulate.a = 1.0
		invencibilidade = false


func atualizar_habilidade(delta: float) -> void:
	if not HabilidadeEquipada:
		return

	HabilidadeEquipada.update(self, delta)

	if ctrlblock:
		return

	if vivo and Input.is_action_just_pressed("Habilidade"):
		HabilidadeEquipada.activate(self)


func IniciarHabilidade(concede_invulnerabilidade := false) -> void:
	UsandoHabilidade = true
	invulneravel_por_habilidade = concede_invulnerabilidade


func EncerrarHabilidade() -> void:
	UsandoHabilidade = false
	invulneravel_por_habilidade = false


func atualizar_movimento(delta: float) -> void:
	if not vivo:
		return

	var fator_movimento := multiplicador_velocidade_habilidade

	if not giroblock:
		if mira_mouse:
			var target_angle := global_position.angle_to_point(get_global_mouse_position())
			rotation = rotate_toward(
				rotation,
				target_angle,
				VelocidadeVirar * fator_movimento * delta
			)
		else:
			arrowsctrl(delta, fator_movimento)

	if not ctrlblock:
		if Input.is_action_pressed("acelerar"):
			acelerar(delta, fator_movimento)

		if Input.is_action_pressed("freio"):
			brake(delta, fator_movimento)

	particles.emitting = Input.is_action_pressed("acelerar") or UsandoHabilidade

	velocity = velocity.move_toward(
		Vector2.ZERO,
		friction * fator_movimento * delta
	)

	if not UsandoHabilidade:
		velocity = velocity.limit_length(MAX_VELOCIDADE * fator_movimento)

	move_and_slide()


func acelerar(delta: float, fator_movimento := 1.0) -> void:
	velocity += transform.x * SPEED * fator_movimento * delta


func brake(delta: float, fator_movimento := 1.0) -> void:
	velocity -= transform.x * SPEED * 0.8 * fator_movimento * delta


func arrowsctrl(delta: float, fator_movimento := 1.0) -> void:
	rotation += (
		Input.get_axis("esquerda", "direita")
		* VelocidadeVirar
		* fator_movimento
		* delta
	)


func atualizar_combate(delta: float) -> void:
	cooldown = maxf(cooldown - delta, 0.0)

	if ctrlblock:
		return

	if vivo and Input.is_action_pressed("atirar") and cooldown <= 0.0:
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


func tomar_dano(valor: float) -> void:
	if invencibilidade or invulneravel_por_habilidade or not vivo:
		return

	var dano_final := maxf(valor * multiplicador_dano_recebido, 0.0)
	vida = maxf(vida - dano_final, 0.0)

	invencibilidade = true
	invencibilidade_cd = invencibilidade_cd_max


func curar(valor: float) -> void:
	if valor <= 0.0 or not vivo:
		return

	vida = minf(
		vida + (valor * multiplicador_cura_recebida),
		VIDA_MAXIMA
	)


func ganhar_xp(value: float) -> void:
	xp_atual += value

	if xp_atual >= xp_necessario:
		subir_de_nivel()


func subir_de_nivel() -> void:
	nivel_atual += 1
	xp_atual = 0.0
	xp_necessario += 2
	subiuDeNivel.emit()


func receber_upgrade(tipo: Upgrade) -> void:
	match tipo:
		Upgrade.CADENCIA:
			CD_MAX *= 0.9
			if HabilidadeEquipada:
				HabilidadeEquipada.reduzir_cooldown(0.9)

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


func morrer() -> void:
	if not vivo:
		return

	vivo = false
	velocity = Vector2.ZERO

	if HabilidadeEquipada:
		HabilidadeEquipada.ao_desequipar(self)

	visible = false
	death.play()

	if ParticulaMorte:
		var particle = ParticulaMorte.instantiate()
		particle.position = global_position
		particle.rotation = global_rotation
		particle.emitting = true
		get_tree().current_scene.add_child(particle)

	await get_tree().create_timer(1.5).timeout
	queue_free()


func BloquearControle() -> void:
	ctrlblock = true


func DesbloquearControle() -> void:
	ctrlblock = false


func BloquearGiro() -> void:
	giroblock = true


func DesbloquearGiro() -> void:
	giroblock = false


func atualizar_limites() -> void:
	position.x = wrapf(position.x, 0.0, 960.0)
	position.y = wrapf(position.y, 0.0, 540.0)


func _on_hitbox_body_entered(body: Node2D) -> void:
	if not vivo:
		return

	if body.is_in_group("inimigo"):
		tomar_dano(float(body.Dano))

		if body.has_method("morrer"):
			body.morrer()
