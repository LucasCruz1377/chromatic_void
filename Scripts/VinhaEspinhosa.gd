extends Area2D
class_name VinhaEspinhosa


const TRECHOS := 8
var trechos: Array[CollisionShape2D] = []

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
	var forma := RectangleShape2D.new()
	forma.size = Vector2(comprimento / TRECHOS + 0.8, 18.0)
	for i in TRECHOS:
		var trecho := colisao if i == 0 else CollisionShape2D.new()
		trecho.disabled = true
		trecho.shape = forma
		if i > 0:
			add_child(trecho)
		trechos.append(trecho)
	atualizar_area_particulas()
	criar_espinhos()
	aplicar_glow()
	aplicar_curva(0.0)
	# Toda a geometria segue um único ângulo e uma curvatura enviados pelo host.
	add_to_group("visual_boss_local")
	for item in find_children("*", "CanvasItem", true, false):
		item.add_to_group("visual_boss_local")


func aplicar_curva(flexao: float) -> void:
	var eixo := PackedVector2Array([Vector2.ZERO])
	var contorno := PackedVector2Array()
	contorno.resize(2 * (TRECHOS + 1))
	var passo := comprimento / TRECHOS
	for i in TRECHOS + 1:
		var t := float(i) / TRECHOS
		var tangente := Vector2.from_angle(flexao * t)
		var borda := tangente.orthogonal() * lerpf(7.0, 5.0, t)
		contorno[i] = eixo[i] + borda
		contorno[contorno.size() - 1 - i] = eixo[i] - borda
		if i < TRECHOS:
			var angulo := flexao * (i + 0.5) / TRECHOS
			var proximo := eixo[i] + Vector2.from_angle(angulo) * passo
			trechos[i].position = (eixo[i] + proximo) * 0.5
			trechos[i].rotation = angulo
			eixo.append(proximo)
	corpo.polygon = contorno
	brilho.points = eixo
	particulas.position = eixo[TRECHOS >> 1]
	particulas.rotation = flexao * 0.5
	for i in espinhos.get_child_count():
		var espinho := espinhos.get_child(i) as Sprite2D
		var distancia := minf(34.0 * (i + 1), comprimento - 8.0)
		var indice := mini(floori(distancia / passo), TRECHOS - 1)
		var angulo := trechos[indice].rotation
		var lado := -1.0 if (i + 1) % 2 == 0 else 1.0
		espinho.position = eixo[indice] + Vector2(distancia - indice * passo, 10.0 * lado).rotated(angulo)
		espinho.rotation = angulo + (-0.45 if lado < 0 else PI + 0.45)


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
	var material_particulas := ParticleProcessMaterial.new()
	material_particulas.particle_flag_disable_z = true
	material_particulas.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	material_particulas.emission_box_extents = Vector3(comprimento * 0.5, 9.0, 1.0)
	material_particulas.direction = Vector3(0.0, -1.0, 0.0)
	material_particulas.spread = 80.0
	material_particulas.initial_velocity_min = 12.0
	material_particulas.initial_velocity_max = 34.0
	material_particulas.gravity = Vector3(0.0, 18.0, 0.0)
	material_particulas.scale_min = 0.12
	material_particulas.scale_max = 0.28
	material_particulas.color = Color(0.62, 1.0, 0.38, 0.72)
	particulas.process_material = material_particulas
	add_child(particulas)
	atualizar_area_particulas()


func atualizar_area_particulas() -> void:
	if not is_instance_valid(particulas):
		return
	particulas.position = Vector2(comprimento * 0.5, 0.0)
	particulas.visibility_rect = Rect2(
		-comprimento * 0.55, -48.0, comprimento * 1.1, 96.0
	)
	var material_particulas := particulas.process_material as ParticleProcessMaterial
	if is_instance_valid(material_particulas):
		material_particulas.emission_box_extents = Vector3(comprimento * 0.5, 9.0, 1.0)


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
	for trecho in trechos:
		trecho.set_deferred("disabled", false)


func desativar_dano() -> void:
	dano_ativo = false
	for trecho in trechos:
		trecho.set_deferred("disabled", true)
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
	body.tomar_dano(dano, global_position)
	atingidos[body] = 0.65
