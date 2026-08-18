extends Area2D
class_name ProjetilInimigo


const BRILHO_PROJETEIS_PADRAO := 1.45

@export_category("Neon")
@export_range(0.6, 3.0, 0.05) var brilho_visual: float = BRILHO_PROJETEIS_PADRAO

@export_category("Movimento e dano")
@export var velocidade: float = 330.0
@export var dano: float = 10.0
@export var tempo_vida: float = 5.0
@export var rebotes_max: int = 0
@export var usa_wrap: bool = false

var direcao: Vector2 = Vector2.RIGHT
var rebotes: int = 0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	aplicar_glow()


func aplicar_glow() -> void:
	var intensidade := clampf(brilho_visual, 0.6, 3.0)
	for node in find_children("*", "CanvasItem", true, false):
		var item := node as CanvasItem
		if (
			item is Polygon2D
			or item is Line2D
			or item is Sprite2D
			or item is AnimatedSprite2D
		):
			item.self_modulate = Color(
				intensidade, intensidade, intensidade, item.self_modulate.a
			)


func configurar(
	nova_direcao: Vector2,
	novo_dano: float,
	nova_velocidade: float = -1.0,
	novos_rebotes: int = -1
) -> void:
	direcao = nova_direcao.normalized()
	dano = novo_dano
	rotation = direcao.angle()

	if nova_velocidade > 0.0:
		velocidade = nova_velocidade
	if novos_rebotes >= 0:
		rebotes_max = novos_rebotes


func _physics_process(delta: float) -> void:
	tempo_vida -= delta
	if tempo_vida <= 0.0:
		queue_free()
		return

	global_position += direcao * velocidade * delta

	if usa_wrap:
		global_position.x = wrapf(global_position.x, 0.0, 960.0)
		global_position.y = wrapf(global_position.y, 0.0, 540.0)
	else:
		processar_bordas()


func processar_bordas() -> void:
	var bateu := false

	if global_position.x <= 0.0 or global_position.x >= 960.0:
		direcao.x *= -1.0
		global_position.x = clampf(global_position.x, 2.0, 958.0)
		bateu = true

	if global_position.y <= 0.0 or global_position.y >= 540.0:
		direcao.y *= -1.0
		global_position.y = clampf(global_position.y, 2.0, 538.0)
		bateu = true

	if not bateu:
		return

	rebotes += 1
	rotation = direcao.angle()
	if rebotes > rebotes_max:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("tomar_dano"):
		body.tomar_dano(dano)
		queue_free()
