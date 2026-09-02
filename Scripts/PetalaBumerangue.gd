extends Area2D
class_name PetalaBumerangue


signal retornou(indice_petala: int)

@export_range(100.0, 700.0, 10.0) var velocidade: float = 310.0
@export_range(100.0, 600.0, 10.0) var distancia_maxima: float = 330.0
@export_range(0.6, 3.0, 0.05) var brilho_visual: float = 1.45

var dano: float = 12.0
var direcao := Vector2.RIGHT
var origem := Vector2.ZERO
var distancia_percorrida := 0.0
var voltando := false
var indice_petala := 0
var boss_origem: Node2D
var tempo_rastro := 0.0

@onready var visual: Sprite2D = $Visual


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	aplicar_glow()


func configurar(
	posicao_origem: Vector2,
	nova_direcao: Vector2,
	novo_dano: float,
	nova_distancia: float,
	nova_velocidade: float,
	novo_indice: int,
	novo_boss: Node2D
) -> void:
	origem = posicao_origem
	global_position = origem
	direcao = nova_direcao.normalized()
	dano = novo_dano
	distancia_maxima = nova_distancia
	velocidade = nova_velocidade
	indice_petala = novo_indice
	boss_origem = novo_boss
	global_rotation = direcao.angle() + PI * 0.5


func aplicar_glow() -> void:
	var intensidade := clampf(brilho_visual, 0.6, 3.0)
	visual.self_modulate = Color(intensidade, intensidade, intensidade, 1.0)


func _physics_process(delta: float) -> void:
	visual.rotation += (5.2 if not voltando else -4.0) * delta
	if not voltando:
		var passo := velocidade * delta
		global_position += direcao * passo
		distancia_percorrida += passo
		emitir_rastro(delta, direcao)
		if distancia_percorrida >= distancia_maxima:
			voltando = true
		return

	var alvo := origem
	if is_instance_valid(boss_origem):
		alvo = boss_origem.global_position + direcao * 38.0
	var distancia := global_position.distance_to(alvo)
	var direcao_retorno := global_position.direction_to(alvo)
	global_position = global_position.move_toward(alvo, velocidade * delta)
	emitir_rastro(delta, direcao_retorno)
	visual.rotation = lerp_angle(
		visual.rotation,
		0.0,
		clampf(1.0 - distancia / maxf(distancia_maxima, 1.0), 0.04, 0.30)
	)
	if global_position.distance_to(alvo) <= 8.0:
		retornou.emit(indice_petala)
		queue_free()


func emitir_rastro(delta: float, direcao_movimento: Vector2) -> void:
	tempo_rastro -= delta
	if tempo_rastro > 0.0 or direcao_movimento.length_squared() <= 0.0:
		return
	tempo_rastro = 0.045
	var cena := get_tree().current_scene
	if not is_instance_valid(cena):
		return
	var duplicata := Sprite2D.new()
	duplicata.texture = visual.texture
	duplicata.texture_filter = visual.texture_filter
	duplicata.z_index = z_index - 1
	duplicata.add_to_group("rastro_petala")
	cena.add_child(duplicata)
	duplicata.global_position = global_position - direcao_movimento * 10.0
	duplicata.global_rotation = visual.global_rotation
	duplicata.global_scale = visual.global_scale
	duplicata.modulate = Color(0.68, 1.0, 0.40, 0.58)
	duplicata.self_modulate = Color(1.22, 1.22, 1.22, 1.0)
	var tween := duplicata.create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(duplicata, "modulate:a", 0.0, 0.22)
	tween.tween_property(duplicata, "scale", duplicata.scale * 0.76, 0.22)
	tween.chain().tween_callback(duplicata.queue_free)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("tomar_dano"):
		body.tomar_dano(dano)


func cancelar() -> void:
	retornou.emit(indice_petala)
	queue_free()
