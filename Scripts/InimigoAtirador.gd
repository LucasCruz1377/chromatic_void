extends InimigoBase


const PROJETIL := preload("res://Entities/ProjetilInimigo.tscn")

@export var aceleracao: float = 220.0
@export var distancia_ideal: float = 310.0
@export var margem_distancia: float = 55.0
@export var intervalo_tiro: float = 2.1
@export var tempo_aviso: float = 0.45
@export var velocidade_projetil: float = 360.0

var tempo_tiro: float = 1.0
var avisando: bool = false
var tempo_aviso_atual: float = 0.0
var direcao_tiro := Vector2.RIGHT

@onready var linha_aviso: Line2D = $LinhaAviso
@onready var visual: Node2D = $Visual


func Mover(delta: float) -> void:
	if not is_instance_valid(player):
		return

	var distancia := global_position.distance_to(player.global_position)
	var ate_player := global_position.direction_to(player.global_position)
	var direcao_movimento := Vector2.ZERO

	if distancia > distancia_ideal + margem_distancia:
		direcao_movimento = ate_player
	elif distancia < distancia_ideal - margem_distancia:
		direcao_movimento = -ate_player
	else:
		direcao_movimento = ate_player.orthogonal()

	velocity = velocity.move_toward(
		direcao_movimento * Velocidade,
		aceleracao * delta
	)

	if avisando:
		atualizar_aviso(delta)
	else:
		tempo_tiro -= delta
		if tempo_tiro <= 0.0:
			iniciar_aviso(ate_player)


func iniciar_aviso(direcao: Vector2) -> void:
	avisando = true
	tempo_aviso_atual = tempo_aviso
	direcao_tiro = direcao
	linha_aviso.points = PackedVector2Array([Vector2.ZERO, direcao_tiro * 520.0])
	linha_aviso.visible = true
	visual.modulate = Color(1.0, 0.55, 1.0, 1.0)


func atualizar_aviso(delta: float) -> void:
	tempo_aviso_atual -= delta
	linha_aviso.modulate.a = 0.4 + absf(sin(Time.get_ticks_msec() * 0.02)) * 0.6

	if tempo_aviso_atual <= 0.0:
		disparar()
		avisando = false
		linha_aviso.visible = false
		visual.modulate = Color.WHITE
		tempo_tiro = intervalo_tiro


func disparar() -> void:
	var projetil := PROJETIL.instantiate() as ProjetilInimigo
	get_tree().current_scene.add_child(projetil)
	projetil.global_position = global_position + direcao_tiro * 24.0
	projetil.modulate = Color(1.0, 0.2, 0.85, 1.0)
	projetil.configurar(direcao_tiro, Dano, velocidade_projetil, 0)
