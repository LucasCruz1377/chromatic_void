extends Area2D
class_name VinhaEspinhosa


signal crescimento_concluido

const TEXTURA_ESPINHO := preload(
	"res://Assets/Bosses/CaosPrimaveril/espinho.svg"
)

@export_range(0.6, 3.0, 0.05) var brilho_visual: float = 1.25

var dano: float = 15.0
var comprimento: float = 480.0
var duracao_crescimento := 0.8
var progresso_crescimento := 0.0
var crescendo := false
var dano_ativo := false
var atingidos: Dictionary = {}
var particulas: GPUParticles2D

@onready var corpo: Polygon2D = $Corpo
@onready var brilho: Line2D = $Brilho
@onready var espinhos: Node2D = $Espinhos
@onready var colisao: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	colisao.disabled = true
	criar_particulas_vinha()


func configurar(novo_comprimento: float, novo_dano: float) -> void:
	comprimento = maxf(novo_comprimento, 40.0)
	dano = novo_dano
	corpo.polygon = PackedVector2Array([
		Vector2(0.0, -7.0),
		Vector2(comprimento, -7.0),
		Vector2(comprimento, 7.0),
		Vector2(0.0, 7.0),
	])
	brilho.points = PackedVector2Array([
		Vector2.ZERO, Vector2(comprimento, 0.0)
	])
	var forma := RectangleShape2D.new()
	forma.size = Vector2(comprimento, 18.0)
	colisao.shape = forma
	colisao.position = Vector2(comprimento * 0.5, 0.0)
	atualizar_area_particulas()
	criar_espinhos()
	aplicar_glow()


func criar_particulas_vinha() -> void:
	particulas = GPUParticles2D.new()
	particulas.name = "ParticulasFolhas"
	particulas.z_index = 2
	particulas.amount = 52
	particulas.lifetime = 0.82
	particulas.randomness = 0.72
	particulas.preprocess = 0.35
	particulas.local_coords = true
	particulas.texture = TEXTURA_ESPINHO
	particulas.emitting = false
	var material := ParticleProcessMaterial.new()
	material.particle_flag_disable_z = true
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	material.emission_box_extents = Vector3(comprimento * 0.5, 9.0, 1.0)
	material.direction = Vector3(0.0, -1.0, 0.0)
	material.spread = 80.0
	material.initial_velocity_min = 12.0
	material.initial_velocity_max = 34.0
	material.gravity = Vector3(0.0, 18.0, 0.0)
	material.scale_min = 0.12
	material.scale_max = 0.28
	material.color = Color(0.62, 1.0, 0.38, 0.72)
	particulas.process_material = material
	add_child(particulas)
	atualizar_area_particulas()


func atualizar_area_particulas() -> void:
	if not is_instance_valid(particulas):
		return
	particulas.position = Vector2(comprimento * 0.5, 0.0)
	particulas.visibility_rect = Rect2(
		-comprimento * 0.55, -48.0, comprimento * 1.1, 96.0
	)
	var material := particulas.process_material as ParticleProcessMaterial
	if is_instance_valid(material):
		material.emission_box_extents = Vector3(comprimento * 0.5, 9.0, 1.0)


func criar_espinhos() -> void:
	for child in espinhos.get_children():
		child.queue_free()
	var quantidade := floori(comprimento / 34.0)
	for indice in range(1, quantidade + 1):
		var espinho := Sprite2D.new()
		espinho.texture = TEXTURA_ESPINHO
		espinho.position = Vector2(
			minf(float(indice) * 34.0, comprimento - 8.0),
			-10.0 if indice % 2 == 0 else 10.0
		)
		espinho.rotation = -0.45 if indice % 2 == 0 else PI + 0.45
		espinho.scale = Vector2(0.78, 0.78)
		espinhos.add_child(espinho)


func aplicar_glow() -> void:
	var intensidade := clampf(brilho_visual, 0.6, 3.0)
	for node in find_children("*", "CanvasItem", true, false):
		var item := node as CanvasItem
		if item is Polygon2D or item is Line2D or item is Sprite2D:
			item.self_modulate = Color(
				intensidade, intensidade, intensidade, item.self_modulate.a
			)


func iniciar_crescimento(duracao: float) -> void:
	duracao_crescimento = maxf(duracao, 0.05)
	progresso_crescimento = 0.0
	crescendo = true
	scale.x = 0.01
	if is_instance_valid(particulas):
		particulas.emitting = true
		particulas.restart()


func _physics_process(delta: float) -> void:
	for body in atingidos.keys():
		atingidos[body] = maxf(float(atingidos[body]) - delta, 0.0)
		if not is_instance_valid(body) or float(atingidos[body]) <= 0.0:
			atingidos.erase(body)
	if not crescendo:
		return
	progresso_crescimento += delta / duracao_crescimento
	scale.x = clampf(progresso_crescimento, 0.01, 1.0)
	if progresso_crescimento >= 1.0:
		crescendo = false
		scale.x = 1.0
		crescimento_concluido.emit()


func ativar_dano() -> void:
	dano_ativo = true
	colisao.set_deferred("disabled", false)


func desativar_dano() -> void:
	dano_ativo = false
	colisao.set_deferred("disabled", true)
	if is_instance_valid(particulas):
		particulas.emitting = false


func _on_body_entered(body: Node2D) -> void:
	if (
		not dano_ativo
		or not body.is_in_group("player")
		or not body.has_method("tomar_dano")
		or body in atingidos
	):
		return
	body.tomar_dano(dano)
	atingidos[body] = 0.65
