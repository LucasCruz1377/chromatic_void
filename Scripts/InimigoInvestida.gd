extends InimigoBase


enum Estado {
	PERSEGUINDO,
	AVISANDO,
	INVESTINDO,
	RECUPERANDO,
}

@export var aceleracao: float = 240.0
@export var velocidade_investida: float = 650.0
@export var tempo_aviso: float = 0.85
@export var duracao_investida: float = 0.75
@export var tempo_recuperacao: float = 0.9
@export var intervalo_investida: float = 2.4

var estado := Estado.PERSEGUINDO
var tempo_estado: float = 0.0
var espera_investida: float = 1.2
var direcao_investida := Vector2.RIGHT

@onready var linha_aviso: Line2D = $LinhaAviso
@onready var visual: Node2D = $Visual


func Mover(delta: float) -> void:
	match estado:
		Estado.PERSEGUINDO:
			mover_perseguindo(delta)
		Estado.AVISANDO:
			atualizar_aviso(delta)
		Estado.INVESTINDO:
			atualizar_investida(delta)
		Estado.RECUPERANDO:
			atualizar_recuperacao(delta)


func obter_velocidade_maxima() -> float:
	if estado == Estado.INVESTINDO:
		return velocidade_investida
	return Velocidade


func mover_perseguindo(delta: float) -> void:
	if not is_instance_valid(player):
		return

	var direcao := global_position.direction_to(player.global_position)
	velocity = velocity.move_toward(direcao * Velocidade, aceleracao * delta)
	espera_investida -= delta

	if espera_investida <= 0.0:
		iniciar_aviso()


func iniciar_aviso() -> void:
	if not is_instance_valid(player):
		return

	estado = Estado.AVISANDO
	tempo_estado = tempo_aviso
	direcao_investida = global_position.direction_to(player.global_position)
	linha_aviso.points = PackedVector2Array(
		[Vector2.ZERO, direcao_investida * 720.0]
	)
	linha_aviso.visible = true
	visual.modulate = Color(1.8, 0.5, 0.25, 1.0)


func atualizar_aviso(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, aceleracao * 2.0 * delta)
	tempo_estado -= delta
	linha_aviso.modulate.a = 0.35 + absf(sin(Time.get_ticks_msec() * 0.018)) * 0.65

	if tempo_estado <= 0.0:
		estado = Estado.INVESTINDO
		tempo_estado = duracao_investida
		linha_aviso.visible = false
		velocity = direcao_investida * velocidade_investida


func atualizar_investida(delta: float) -> void:
	tempo_estado -= delta
	velocity = direcao_investida * velocidade_investida
	if tempo_estado <= 0.0:
		iniciar_recuperacao()


func atualizar_recuperacao(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, velocidade_investida * 1.8 * delta)
	tempo_estado -= delta
	if tempo_estado <= 0.0:
		estado = Estado.PERSEGUINDO
		espera_investida = intervalo_investida
		visual.modulate = Color.WHITE


func iniciar_recuperacao() -> void:
	estado = Estado.RECUPERANDO
	tempo_estado = tempo_recuperacao
	linha_aviso.visible = false
	visual.modulate = Color(0.55, 0.55, 0.55, 1.0)


func ao_colidir_com_player(alvo: Node) -> void:
	if estado != Estado.INVESTINDO:
		return
	super.ao_colidir_com_player(alvo)
	if not morto:
		iniciar_recuperacao()
