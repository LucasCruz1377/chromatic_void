extends CharacterBody2D
class_name InimigoBase


const EfeitoCombateCena = preload("res://Scripts/EfeitoCombate.gd")
const IndicadorDanoCena = preload("res://Scripts/IndicadorDano.gd")
const ShaderHitflash = preload("res://FX/canvas_shader/enemy.gdshader")

# AJUSTE GLOBAL DO BRILHO DOS INIMIGOS.
# 1.35 recupera o neon alto antigo. Para regular, tente entre 0.80 e 1.60.
# Também é possível sobrescrever "brilho_visual" em cada cena pelo Inspector.
const BRILHO_INIMIGOS_PADRAO := 1.35

signal vida_alterada(atual: float, maxima: float)
signal morreu(inimigo: InimigoBase)


@export_category("Atributos")
@export var VidaMaxima: float = 100.0
@export var Dano: float = 2.0
@export var ValorXP: float = 1.0
@export var Velocidade: float = 30.0
@export_range(0.0, 2.0, 0.05) var multiplicador_dano_recebido: float = 1.0
@export_range(0.0, 1.0, 0.05) var resistencia_empurrao: float = 0.0

@export_category("Comportamento")
@export var usa_wrap: bool = true
@export var morre_ao_colidir_player: bool = true
@export var concede_recompensa: bool = true
@export var pontos_base: int = 100
@export_range(0, 1000, 1) var valor_cristais: int = 8

@export_category("Efeitos opcionais")
@export var particulas_morte: PackedScene
@export_range(0.0, 1.0, 0.05) var intensidade_flash: float = 0.35
@export_range(0.6, 2.0, 0.05) var brilho_visual: float = BRILHO_INIMIGOS_PADRAO
@export_range(0.0, 18.0, 0.5) var tremor_morte: float = 0.0


var Vida: float = 0.0
var tempo_atordoado: float = 0.0
var morto: bool = false
var tween_impacto: Tween
var modulacao_base := Color.WHITE
var escala_base_impacto := Vector2.ONE
var materiais_hitflash: Array[ShaderMaterial] = []

@onready var player = get_tree().get_first_node_in_group("player")
@onready var anim: AnimationPlayer = get_node_or_null("anim") as AnimationPlayer
@onready var dmg_taken_audio: AudioStreamPlayer2D = (
	get_node_or_null("dmg_taken_audio") as AudioStreamPlayer2D
)
@onready var camera: Camera2D = get_tree().get_first_node_in_group("camera") as Camera2D


func _ready() -> void:
	escala_base_impacto = scale
	modulacao_base = Color(
		minf(modulate.r, 1.0),
		minf(modulate.g, 1.0),
		minf(modulate.b, 1.0),
		modulate.a
	)
	modulate = modulacao_base
	normalizar_brilho_visual()
	preparar_materiais_hitflash()

	var bonus_vida := 0.0
	if is_instance_valid(player):
		var nivel = player.get("nivel_atual")
		if nivel != null:
			bonus_vida = float(int(nivel / 5))

	Vida = VidaMaxima + bonus_vida
	vida_alterada.emit(Vida, VidaMaxima + bonus_vida)


func _physics_process(delta: float) -> void:
	if morto:
		return

	atualizar_estados(delta)
	atualizar_referencia_player()

	if esta_atordoado():
		velocity = velocity.move_toward(Vector2.ZERO, Velocidade * 4.0 * delta)
	else:
		Mover(delta)

	velocity = velocity.limit_length(obter_velocidade_maxima())
	move_and_slide()

	if usa_wrap:
		aplicar_wrap()


func atualizar_referencia_player() -> void:
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")


func atualizar_estados(delta: float) -> void:
	if tempo_atordoado > 0.0:
		tempo_atordoado = maxf(tempo_atordoado - delta, 0.0)


func aplicar_atordoamento(duracao: float) -> void:
	if morto:
		return
	tempo_atordoado = maxf(tempo_atordoado, duracao)


func esta_atordoado() -> bool:
	return tempo_atordoado > 0.0


func aplicar_empurrao(forca: Vector2) -> void:
	velocity += forca * (1.0 - resistencia_empurrao)


func aplicar_wrap() -> void:
	global_position.x = wrapf(global_position.x, 0.0, 960.0)
	global_position.y = wrapf(global_position.y, 0.0, 540.0)


func obter_velocidade_maxima() -> float:
	return Velocidade


func Mover(_delta: float) -> void:
	pass


func tomarDano(valor: float) -> void:
	if morto or valor <= 0.0:
		return

	var dano_final := maxf(valor * multiplicador_dano_recebido, 0.0)
	Vida = maxf(Vida - dano_final, 0.0)
	vida_alterada.emit(Vida, obter_vida_maxima_atual())
	reproduzir_impacto(dano_final)
	if has_meta("laco_parceiro") and Time.get_ticks_msec() <= int(get_meta("laco_expira", 0)):
		var parceiro = get_meta("laco_parceiro")
		if is_instance_valid(parceiro) and parceiro.has_method("receber_eco_laco"):
			parceiro.call("receber_eco_laco", dano_final * 0.38)

	if Vida <= 0.0:
		morrer()


func receber_eco_laco(valor: float) -> void:
	if morto or valor <= 0.0:
		return
	Vida = maxf(Vida - valor * multiplicador_dano_recebido, 0.0)
	vida_alterada.emit(Vida, obter_vida_maxima_atual())
	var cena := get_tree().current_scene
	if is_instance_valid(cena):
		EfeitoCombateCena.criar(cena, global_position, EfeitoCombate.Tipo.ACERTO, Color(1.0, 0.34, 0.58), 0.65)
		IndicadorDanoCena.criar(cena, global_position, valor * multiplicador_dano_recebido, Color(1.0, 0.42, 0.68))
	if Vida <= 0.0:
		morrer()


func obter_vida_maxima_atual() -> float:
	var bonus_vida := 0.0
	if is_instance_valid(player):
		var nivel = player.get("nivel_atual")
		if nivel != null:
			bonus_vida = float(int(nivel / 5))
	return VidaMaxima + bonus_vida


func reproduzir_impacto(dano_exibido: float = 0.0) -> void:
	if is_instance_valid(dmg_taken_audio):
		dmg_taken_audio.pitch_scale = randf_range(0.92, 1.08)
		dmg_taken_audio.play()

	# O flash antigo usava HDR acima de 1.0 e somava com o bloom. Em impactos
	# rápidos a animação recomeçava no pico, criando o clarão acumulado.
	if is_instance_valid(anim) and anim.current_animation == "flash-in":
		anim.stop()
	_definir_hitflash_shader(0.0)

	if tween_impacto and tween_impacto.is_valid():
		tween_impacto.kill()
	# Um tween interrompido podia deixar a escala ampliada como ponto inicial
	# do próximo impacto, fazendo bosses crescerem a cada tiro recebido.
	scale = escala_base_impacto

	var forca_flash := clampf(maxf(intensidade_flash, 0.76), 0.76, 1.0)
	var cor_impacto := modulacao_base.lerp(Color(1.45, 1.45, 1.45, modulacao_base.a), 0.72)
	modulate = cor_impacto
	tween_impacto = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween_impacto.set_parallel(true)
	_definir_hitflash_shader(forca_flash)
	tween_impacto.tween_method(_definir_hitflash_shader, forca_flash, 0.0, 0.13)
	tween_impacto.tween_property(self, "modulate", modulacao_base, 0.13)
	# Bosses já possuem silhuetas e animações próprias; o feedback de acerto não
	# altera seu tamanho. Inimigos comuns conservam uma pulsação leve e limitada.
	if not is_in_group("boss"):
		tween_impacto.tween_property(
			self, "scale", escala_base_impacto * 1.035, 0.04
		)
		tween_impacto.chain().tween_property(
			self, "scale", escala_base_impacto, 0.065
		)

	var cena := get_tree().current_scene
	if is_instance_valid(cena):
		EfeitoCombateCena.criar(
			cena,
			global_position,
			EfeitoCombate.Tipo.ACERTO,
			obter_cor_feedback(),
			clampf(0.72 + sqrt(maxf(VidaMaxima, 1.0)) * 0.035, 0.8, 1.45)
		)
		if dano_exibido > 0.0:
			IndicadorDanoCena.criar(
				cena, global_position, dano_exibido, obter_cor_feedback(),
				dano_exibido >= maxf(obter_vida_maxima_atual() * 0.12, 4.0)
			)


func normalizar_brilho_visual() -> void:
	for node in find_children("*", "CanvasItem", true, false):
		var item := node as CanvasItem
		if not item:
			continue
		# Ajusta apenas nós que realmente desenham. Modificar Node2D intermediários
		# faria o valor se multiplicar em cascata e apagaria o inimigo.
		if (
			item is Polygon2D
			or item is Line2D
			or item is Sprite2D
			or item is AnimatedSprite2D
		):
			var alpha := item.self_modulate.a
			var intensidade := clampf(brilho_visual, 0.6, 2.0)
			item.self_modulate = Color(intensidade, intensidade, intensidade, alpha)
	zerar_brilho_dos_materiais()


func preparar_materiais_hitflash() -> void:
	materiais_hitflash.clear()
	for node in find_children("*", "CanvasItem", true, false):
		var item := node as CanvasItem
		if not item or not (
			item is Polygon2D
			or item is Line2D
			or item is Sprite2D
			or item is AnimatedSprite2D
		):
			continue
		var material_hitflash: ShaderMaterial
		if item.material is ShaderMaterial:
			var material_existente := item.material as ShaderMaterial
			if material_existente.get_shader_parameter("brightness") == null:
				continue
			material_hitflash = material_existente.duplicate(true) as ShaderMaterial
		elif item.material == null:
			material_hitflash = ShaderMaterial.new()
			material_hitflash.shader = ShaderHitflash
		if not is_instance_valid(material_hitflash):
			continue
		material_hitflash.set_shader_parameter("brightness", 0.0)
		item.material = material_hitflash
		materiais_hitflash.append(material_hitflash)


func _definir_hitflash_shader(valor: float) -> void:
	for material in materiais_hitflash:
		if is_instance_valid(material):
			material.set_shader_parameter("brightness", clampf(valor, 0.0, 1.0))


func zerar_brilho_dos_materiais() -> void:
	for node in find_children("*", "CanvasItem", true, false):
		var item := node as CanvasItem
		if not item or not (item.material is ShaderMaterial):
			continue
		var shader_material := item.material as ShaderMaterial
		if shader_material.get_shader_parameter("brightness") != null:
			shader_material.set_shader_parameter("brightness", 0.0)


func ao_colidir_com_player(alvo: Node) -> void:
	if morto:
		return

	if alvo.has_method("tomar_dano"):
		alvo.tomar_dano(Dano)

	if morre_ao_colidir_player:
		morrer()


func morrer() -> void:
	if morto:
		return
	# Mantém compatibilidade com o Player antigo, que chama morrer() em todo
	# inimigo tocado. Inimigos persistentes só morrem quando a vida chega a zero.
	if Vida > 0.0 and not morre_ao_colidir_player:
		return

	morto = true
	morreu.emit(self)

	if is_instance_valid(camera) and camera.has_method("shake"):
		camera.shake(obter_tremor_morte(), is_in_group("boss"))

	var cena := get_tree().current_scene
	if is_instance_valid(cena):
		EfeitoCombateCena.criar(
			cena,
			global_position,
			EfeitoCombate.Tipo.MORTE,
			obter_cor_feedback(),
			clampf(0.75 + sqrt(maxf(VidaMaxima, 1.0)) * 0.05, 0.9, 2.1),
			velocity.normalized()
		)

	criar_particulas_morte()

	if concede_recompensa:
		conceder_recompensa()

	queue_free()


func obter_cor_feedback() -> Color:
	for node in find_children("*", "Polygon2D", true, false):
		var poligono := node as Polygon2D
		if is_instance_valid(poligono):
			return poligono.color.lightened(0.18)
	return Color(0.55, 0.9, 1.0)


func obter_tremor_morte() -> float:
	if tremor_morte > 0.0:
		return tremor_morte
	# Inimigos leves fazem um toque curto; tanques e chefes usam a própria
	# vida máxima para produzir um impacto mais forte, sem estourar a câmera.
	return clampf(2.4 + sqrt(maxf(VidaMaxima, 1.0)) * 0.82, 3.0, 14.0)


func criar_particulas_morte() -> void:
	if not particulas_morte:
		return

	var partes := particulas_morte.instantiate() as Node2D
	if not partes:
		return
	partes.global_position = global_position
	partes.global_rotation = global_rotation
	get_tree().current_scene.add_child(partes)

	if partes is GPUParticles2D:
		var particulas := partes as GPUParticles2D
		particulas.emitting = true


func conceder_recompensa() -> void:
	if is_instance_valid(player) and player.has_method("ganhar_xp"):
		player.ganhar_xp(ValorXP)

	Global.registrar_kill()
	Global.Combo += 1
	Global.Pontos += pontos_base + (pontos_base * (Global.Combo - 1))
	Global.adicionar_cristais(valor_cristais)
