extends InimigoBase


const PROJETIL := preload("res://Entities/ProjetilInimigo.tscn")
const COR_PROJETIL_TANQUE := Color(1.0, 0.42, 0.10, 1.0)

@export var aceleracao: float = 110.0
@export var intervalo_pulso: float = 4.5
@export var quantidade_projeteis_pulso: int = 8

var tempo_pulso: float = 2.5
var armadura_quebrada: bool = false
var avisando_pulso := false
var tempo_aviso_pulso := 0.0

@onready var visual: Node2D = $Visual


func Mover(delta: float) -> void:
	if not is_instance_valid(player):
		velocity = velocity.move_toward(Vector2.ZERO, aceleracao * delta)
		return

	var direcao := global_position.direction_to(player.global_position)
	velocity = velocity.move_toward(direcao * Velocidade, aceleracao * delta)

	if avisando_pulso:
		tempo_aviso_pulso -= delta
		velocity *= 0.94
		if tempo_aviso_pulso <= 0.0:
			avisando_pulso = false
			disparar_pulso()
		return

	tempo_pulso -= delta
	if tempo_pulso <= 0.0:
		tempo_pulso = intervalo_pulso
		iniciar_aviso_pulso()


func iniciar_aviso_pulso() -> void:
	avisando_pulso = true
	tempo_aviso_pulso = 0.62
	var tween := create_tween().set_loops(2)
	tween.tween_property(visual, "scale", Vector2(1.18, 1.18), 0.155)
	tween.tween_property(visual, "scale", Vector2.ONE, 0.155)
	EfeitoCombateCena.criar(
		get_tree().current_scene,
		global_position,
		EfeitoCombate.Tipo.AVISO,
		COR_PROJETIL_TANQUE,
		1.35,
		Vector2.RIGHT
	)


func tomarDano(valor: float) -> void:
	if morto:
		return

	super.tomarDano(valor)
	if morto:
		return

	if not armadura_quebrada and Vida <= obter_vida_maxima_atual() * 0.5:
		armadura_quebrada = true
		multiplicador_dano_recebido = 1.0
		Velocidade *= 1.35
		visual.modulate = Color(1.0, 0.65, 0.35, 1.0)


func disparar_pulso() -> void:
	if morto:
		return

	var tween := create_tween()
	tween.tween_property(visual, "scale", Vector2(1.22, 1.22), 0.18)
	tween.tween_property(visual, "scale", Vector2.ONE, 0.18)
	EfeitoCombateCena.criar(
		get_tree().current_scene,
		global_position,
		EfeitoCombate.Tipo.MORTE,
		COR_PROJETIL_TANQUE,
		1.1,
		Vector2.RIGHT
	)

	for indice in quantidade_projeteis_pulso:
		var angulo := TAU * float(indice) / float(quantidade_projeteis_pulso)
		var projetil := PROJETIL.instantiate() as ProjetilInimigo
		get_tree().current_scene.add_child(projetil)
		projetil.global_position = global_position
		projetil.scale = Vector2(0.7, 0.7)
		projetil.modulate = Color.WHITE
		var forma := projetil.get_node_or_null("Visual") as Polygon2D
		if is_instance_valid(forma):
			forma.color = COR_PROJETIL_TANQUE
		projetil.aplicar_glow()
		projetil.configurar(Vector2.from_angle(angulo), Dano * 0.45, 185.0, 0)
