extends CharacterBody2D
class_name OrbeAstral


const ProjetilAstralCena = preload("res://Scripts/ProjetilAstral.gd")
const EfeitoCombateCena = preload("res://Scripts/EfeitoCombate.gd")


var boss_origem: Node2D
var vida := 3.0
var dano_explosao := 10.0
var tempo := 3.2
var angulo := 0.0
var raio_orbita := 115.0
var velocidade_orbita := 0.9
var cor := Color(1.0, 0.48, 0.1)
var destruido := false


func _ready() -> void:
	z_index = 4
	collision_layer = 4
	collision_mask = 0
	add_to_group("inimigo")
	add_to_group("projetil_inimigo")
	add_to_group("mancha_solar")
	var forma := CollisionShape2D.new()
	var circulo := CircleShape2D.new()
	circulo.radius = 15.0
	forma.shape = circulo
	add_child(forma)
	queue_redraw()


func configurar(origem: Node2D, angulo_inicial: float, novo_dano: float) -> void:
	boss_origem = origem
	angulo = angulo_inicial
	dano_explosao = novo_dano


func _physics_process(delta: float) -> void:
	if not is_instance_valid(boss_origem):
		queue_free()
		return
	angulo += velocidade_orbita * delta
	global_position = boss_origem.global_position + Vector2.from_angle(angulo) * raio_orbita
	tempo -= delta
	if tempo <= 0.0:
		explodir()
	queue_redraw()


func tomarDano(valor: float) -> void:
	if destruido:
		return
	vida -= maxf(valor, 0.0)
	modulate = Color(1.0, 0.85, 0.55)
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.09)
	if vida <= 0.0:
		destruido = true
		var cena := get_tree().current_scene
		if is_instance_valid(cena):
			EfeitoCombateCena.criar(cena, global_position, EfeitoCombate.Tipo.MORTE, cor, 0.8)
		queue_free()


func explodir() -> void:
	if destruido:
		return
	destruido = true
	var cena := get_tree().current_scene
	if is_instance_valid(cena):
		EfeitoCombateCena.criar(cena, global_position, EfeitoCombate.Tipo.AVISO, cor, 1.15)
		for indice in 8:
			var projetil := ProjetilAstralCena.new() as ProjetilAstral
			cena.add_child(projetil)
			projetil.configurar(
				global_position,
				Vector2.from_angle(TAU * indice / 8.0),
				dano_explosao,
				205.0,
				cor,
				ProjetilAstral.Tipo.FOGO,
				0.0,
				boss_origem,
				false,
				dano_explosao * 0.36,
				2.4
			)
	queue_free()


func _draw() -> void:
	var pulso := 1.0 + sin(Time.get_ticks_msec() * 0.014 + angulo) * 0.12
	draw_circle(Vector2.ZERO, 22.0 * pulso, Color(cor.r, cor.g, cor.b, 0.14))
	draw_circle(Vector2.ZERO, 15.0 * pulso, Color(0.19, 0.035, 0.018, 1.0))
	draw_arc(Vector2.ZERO, 14.0 * pulso, 0.0, TAU, 24, cor, 3.0, true)
	draw_circle(Vector2(-3.0, -2.0), 4.0, Color(1.0, 0.76, 0.2, 0.72))
