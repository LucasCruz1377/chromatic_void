extends Area2D
class_name ProjetilAstral


const EfeitoCombateCena = preload("res://Scripts/EfeitoCombate.gd")


enum Tipo {
	CRESCENTE,
	FOGO,
	CORONA,
}


var tipo := Tipo.CRESCENTE
var direcao := Vector2.RIGHT
var velocidade := 260.0
var dano := 12.0
var cor := Color(0.72, 0.84, 1.0)
var distancia_maxima := 1100.0
var distancia_percorrida := 0.0
var curvatura := 0.0
var queimadura_total := 0.0
var duracao_queimadura := 0.0
var retorna_ao_boss := false
var retornando := false
var distancia_retorno := 360.0
var boss_origem: Node2D
var tempo_rastro := 0.0


func _ready() -> void:
	z_index = 4
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	add_to_group("projetil_inimigo")
	add_to_group("projetil_astral")
	var forma := CollisionShape2D.new()
	var circulo := CircleShape2D.new()
	circulo.radius = 11.0 if tipo == Tipo.CRESCENTE else 8.0
	forma.shape = circulo
	add_child(forma)
	body_entered.connect(_on_body_entered)
	queue_redraw()


func configurar(
	posicao: Vector2,
	nova_direcao: Vector2,
	novo_dano: float,
	nova_velocidade: float,
	nova_cor: Color,
	novo_tipo: Tipo = Tipo.CRESCENTE,
	nova_curvatura: float = 0.0,
	origem: Node2D = null,
	boomerang: bool = false,
	dano_queimadura: float = 0.0,
	tempo_queimadura: float = 0.0
) -> void:
	global_position = posicao
	direcao = nova_direcao.normalized()
	dano = novo_dano
	velocidade = nova_velocidade
	cor = nova_cor
	tipo = novo_tipo
	curvatura = nova_curvatura
	boss_origem = origem
	retorna_ao_boss = boomerang
	queimadura_total = dano_queimadura
	duracao_queimadura = tempo_queimadura
	rotation = direcao.angle()
	queue_redraw()


func _physics_process(delta: float) -> void:
	if curvatura != 0.0 and not retornando:
		direcao = direcao.rotated(curvatura * delta).normalized()

	if retorna_ao_boss and not retornando and distancia_percorrida >= distancia_retorno:
		retornando = true
	if retornando:
		if not is_instance_valid(boss_origem):
			queue_free()
			return
		direcao = global_position.direction_to(boss_origem.global_position)
		if global_position.distance_to(boss_origem.global_position) < 28.0:
			queue_free()
			return

	var deslocamento := direcao * velocidade * delta
	global_position += deslocamento
	distancia_percorrida += deslocamento.length()
	rotation = direcao.angle()
	tempo_rastro -= delta
	if tempo_rastro <= 0.0:
		tempo_rastro = 0.055 if tipo == Tipo.FOGO else 0.085
		criar_rastro()

	if not retorna_ao_boss and distancia_percorrida >= distancia_maxima:
		queue_free()


func criar_rastro() -> void:
	var cena := get_tree().current_scene
	if not is_instance_valid(cena):
		return
	EfeitoCombateCena.criar(
		cena,
		global_position - direcao * 8.0,
		EfeitoCombate.Tipo.RASTRO,
		cor,
		0.55 if tipo == Tipo.FOGO else 0.38,
		-direcao
	)


func _on_body_entered(alvo: Node) -> void:
	if not alvo.is_in_group("player"):
		return
	if alvo.has_method("tomar_dano"):
		alvo.tomar_dano(dano)
	if queimadura_total > 0.0 and alvo.has_method("aplicar_queimadura"):
		alvo.aplicar_queimadura(queimadura_total, duracao_queimadura)
	queue_free()


func _draw() -> void:
	var brilho := cor
	brilho.a = 0.28
	if tipo == Tipo.CRESCENTE:
		draw_circle(Vector2.ZERO, 18.0, brilho)
		draw_line(Vector2(-24.0, 0.0), Vector2(-11.0, 0.0), Color(cor.r, cor.g, cor.b, 0.68), 4.0, true)
		draw_arc(Vector2.ZERO, 11.0, -1.9, 1.9, 20, cor, 6.0, true)
		draw_circle(Vector2(4.0, 0.0), 7.0, Color(0.02, 0.025, 0.08, 0.96))
	elif tipo == Tipo.FOGO:
		draw_circle(Vector2.ZERO, 16.0, brilho)
		draw_colored_polygon(
			PackedVector2Array([
				Vector2(13.0, 0.0), Vector2(-8.0, -8.0),
				Vector2(-3.0, 0.0), Vector2(-8.0, 8.0)
			]),
			cor
		)
		draw_circle(Vector2(2.0, 0.0), 4.0, Color(1.0, 0.95, 0.56))
	else:
		draw_circle(Vector2.ZERO, 12.0, brilho)
		draw_arc(Vector2.ZERO, 8.0, 0.0, TAU, 18, cor, 3.0, true)
		draw_line(Vector2(-7.0, 0.0), Vector2(7.0, 0.0), cor, 2.0, true)
