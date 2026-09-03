extends InimigoBase
class_name BossPet0


signal fase_alterada(fase_atual: int)
signal reciclagem_alterada(atual: int, meta: int)


const PROJETIL := preload("res://Entities/ProjetilInimigo.tscn")
const MINION := preload("res://Entities/InimigoMinion.tscn")
const FRAGMENTO := preload("res://Entities/FragmentoReciclavel.tscn")
const EFEITO_RECICLAGEM := preload("res://Entities/EfeitoReciclagem.tscn")


enum Estado {
	LIVRE,
	AVISANDO_ROLAMENTO,
	ROLANDO,
	PRESSIONANDO,
	RECUPERANDO,
}


@export_category("PET-0")
@export var velocidade_investida: float = 590.0
@export var tempo_aviso_investida: float = 0.9
@export var duracao_investida: float = 1.0
@export var intervalo_ataques: float = 2.2
@export var meta_reciclagem: int = 6
@export var max_minions: int = 6
@export var max_fragmentos: int = 8


var fase: int = 1
var estado := Estado.LIVRE
var tempo_estado: float = 0.0
var tempo_ataque: float = 1.4
var direcao_investida := Vector2.RIGHT
var reciclagem_atual: int = 0
var rotulo_removido: bool = false
var tempo_rastro_rolamento := 0.0

@onready var visual: Node2D = $Visual
@onready var corpo_visual: Polygon2D = $Visual/Corpo
@onready var rotulo: Polygon2D = $Visual/Rotulo
@onready var tampa: Polygon2D = $Visual/Tampa
@onready var linha_aviso: Line2D = $LinhaAviso


func _ready() -> void:
	super._ready()
	vida_alterada.emit(Vida, obter_vida_maxima_atual())
	fase_alterada.emit(fase)
	reciclagem_alterada.emit(reciclagem_atual, meta_reciclagem)


func Mover(delta: float) -> void:
	match estado:
		Estado.LIVRE:
			movimento_livre(delta)
		Estado.AVISANDO_ROLAMENTO:
			avisar_rolamento(delta)
		Estado.ROLANDO:
			rolar(delta)
		Estado.PRESSIONANDO:
			pressionar(delta)
		Estado.RECUPERANDO:
			recuperar(delta)


func obter_velocidade_maxima() -> float:
	if estado == Estado.ROLANDO:
		return velocidade_investida + float(fase - 1) * 55.0
	return Velocidade + float(fase - 1) * 18.0


func movimento_livre(delta: float) -> void:
	if not is_instance_valid(player):
		return

	var ate_player := global_position.direction_to(player.global_position)
	var distancia := global_position.distance_to(player.global_position)
	var direcao_movimento := ate_player

	if distancia < 210.0:
		direcao_movimento = (-ate_player + ate_player.orthogonal() * 0.45).normalized()
	elif distancia < 350.0:
		direcao_movimento = ate_player.orthogonal()

	velocity = velocity.move_toward(
		direcao_movimento * obter_velocidade_maxima(),
		150.0 * delta
	)
	visual.rotation = lerp_angle(visual.rotation, ate_player.angle(), 2.5 * delta)

	tempo_ataque -= delta
	if tempo_ataque <= 0.0:
		escolher_ataque()


func escolher_ataque() -> void:
	var ataques: Array[StringName] = [&"rolamento", &"tampinha"]

	if fase >= 2:
		ataques.append(&"microplasticos")
		ataques.append(&"pressao")
	if fase >= 3:
		ataques.append(&"rolamento")
		ataques.append(&"pressao")

	match ataques.pick_random():
		&"rolamento":
			iniciar_rolamento()
		&"tampinha":
			disparar_tampinhas()
		&"microplasticos":
			invocar_microplasticos()
		&"pressao":
			iniciar_pressao()


func iniciar_rolamento() -> void:
	if not is_instance_valid(player):
		return

	estado = Estado.AVISANDO_ROLAMENTO
	tempo_estado = tempo_aviso_investida
	direcao_investida = global_position.direction_to(player.global_position)
	linha_aviso.points = PackedVector2Array(
		[Vector2.ZERO, direcao_investida * 760.0]
	)
	linha_aviso.visible = true
	corpo_visual.modulate = Color(1.0, 0.55, 0.28, 1.0)
	EfeitoCombateCena.criar(
		get_tree().current_scene,
		global_position,
		EfeitoCombate.Tipo.AVISO,
		Color(1.0, 0.52, 0.18),
		1.8,
		direcao_investida
	)


func avisar_rolamento(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, 520.0 * delta)
	tempo_estado -= delta
	linha_aviso.modulate.a = 0.35 + absf(sin(Time.get_ticks_msec() * 0.017)) * 0.65
	visual.scale = Vector2.ONE * (1.0 + absf(sin(Time.get_ticks_msec() * 0.02)) * 0.08)

	if tempo_estado <= 0.0:
		estado = Estado.ROLANDO
		tempo_estado = duracao_investida
		linha_aviso.visible = false
		visual.scale = Vector2.ONE
		velocity = direcao_investida * obter_velocidade_maxima()
		tempo_rastro_rolamento = 0.0
		EfeitoCombateCena.criar(
			get_tree().current_scene,
			global_position,
			EfeitoCombate.Tipo.MORTE,
			Color(1.0, 0.42, 0.12),
			1.35,
			direcao_investida
		)


func rolar(delta: float) -> void:
	tempo_estado -= delta
	visual.rotation += delta * (9.0 + fase * 1.5)
	velocity = direcao_investida * obter_velocidade_maxima()
	tempo_rastro_rolamento -= delta
	if tempo_rastro_rolamento <= 0.0:
		tempo_rastro_rolamento = 0.045
		EfeitoCombateCena.criar(
			get_tree().current_scene,
			global_position - direcao_investida * 42.0,
			EfeitoCombate.Tipo.RASTRO,
			Color(0.22, 0.88, 1.0, 0.96),
			1.9,
			direcao_investida
		)

	if tempo_estado <= 0.0:
		iniciar_recuperacao(0.8)


func disparar_tampinhas() -> void:
	if not is_instance_valid(player):
		return

	var quantidade := 1 if fase < 3 else 3
	var direcao_base := global_position.direction_to(player.global_position)

	for indice in quantidade:
		var abertura := (float(indice) - float(quantidade - 1) * 0.5) * 0.22
		var direcao := direcao_base.rotated(abertura)
		var projetil := PROJETIL.instantiate() as ProjetilInimigo
		get_tree().current_scene.add_child(projetil)
		projetil.global_position = global_position + direcao * 55.0
		projetil.scale = Vector2(1.5, 1.5)
		projetil.modulate = Color(1.0, 0.25, 0.2, 1.0)
		projetil.tempo_vida = 7.0
		projetil.configurar(direcao, Dano * 0.7, 410.0, 4)

	iniciar_recuperacao(0.55)


func iniciar_pressao() -> void:
	estado = Estado.PRESSIONANDO
	tempo_estado = 1.0
	velocity = Vector2.ZERO
	corpo_visual.modulate = Color(0.35, 1.0, 0.8, 1.0)
	var tween := create_tween()
	tween.tween_property(visual, "scale", Vector2(0.68, 1.22), 0.72)


func pressionar(delta: float) -> void:
	tempo_estado -= delta
	velocity = velocity.move_toward(Vector2.ZERO, 450.0 * delta)

	if tempo_estado <= 0.0:
		liberar_pressao()
		visual.scale = Vector2.ONE
		iniciar_recuperacao(0.7)


func liberar_pressao() -> void:
	var quantidade := 10 + fase * 2
	for indice in quantidade:
		var angulo := TAU * float(indice) / float(quantidade)
		var projetil := PROJETIL.instantiate() as ProjetilInimigo
		get_tree().current_scene.add_child(projetil)
		projetil.global_position = global_position
		projetil.scale = Vector2(0.75, 0.75)
		projetil.modulate = Color(0.3, 1.0, 0.65, 1.0)
		projetil.configurar(Vector2.from_angle(angulo), Dano * 0.42, 220.0, 0)


func invocar_microplasticos() -> void:
	var minions_existentes := get_tree().get_nodes_in_group("minion_pet0").size()
	var quantidade_minions := mini(2 + fase - 2, max_minions - minions_existentes)

	for indice in maxi(quantidade_minions, 0):
		var minion := MINION.instantiate() as InimigoBase
		get_tree().current_scene.add_child(minion)
		minion.global_position = global_position + Vector2.from_angle(
			TAU * float(indice) / float(maxi(quantidade_minions, 1))
		) * 70.0

	var fragmentos_existentes := get_tree().get_nodes_in_group("residuo_pet0").size()
	var quantidade_fragmentos := mini(2, max_fragmentos - fragmentos_existentes)

	for indice in maxi(quantidade_fragmentos, 0):
		criar_fragmento(Vector2.from_angle(randf_range(0.0, TAU)) * (55.0 + indice * 18.0))

	iniciar_recuperacao(0.65)


func criar_fragmento(deslocamento: Vector2) -> void:
	var fragmento := FRAGMENTO.instantiate() as FragmentoReciclavel
	if not fragmento:
		return
	get_tree().current_scene.add_child(fragmento)
	fragmento.global_position = global_position + deslocamento
	fragmento.dono_boss = self


func iniciar_recuperacao(duracao: float) -> void:
	estado = Estado.RECUPERANDO
	tempo_estado = duracao
	linha_aviso.visible = false
	corpo_visual.modulate = Color(0.65, 0.65, 0.65, 1.0)


func recuperar(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, 520.0 * delta)
	tempo_estado -= delta
	if tempo_estado <= 0.0:
		estado = Estado.LIVRE
		tempo_ataque = maxf(intervalo_ataques - float(fase - 1) * 0.28, 1.25)
		corpo_visual.modulate = Color.WHITE


func tomarDano(valor: float) -> void:
	if morto:
		return

	super.tomarDano(valor)
	if morto:
		return

	atualizar_fase()


func atualizar_fase() -> void:
	var porcentagem := Vida / obter_vida_maxima_atual()
	var nova_fase := 1

	if porcentagem <= 0.35:
		nova_fase = 3
	elif porcentagem <= 0.70:
		nova_fase = 2

	if nova_fase == fase:
		return

	fase = nova_fase
	fase_alterada.emit(fase)
	velocidade_investida += 35.0

	if not rotulo_removido:
		multiplicador_dano_recebido = 0.6 + float(fase - 1) * 0.1

	corpo_visual.color = (
		Color(0.2, 1.0, 0.62, 0.78)
		if fase == 2
		else Color(1.0, 0.28, 0.18, 0.82)
	)

	criar_fragmento(Vector2(-70.0, -35.0))
	criar_fragmento(Vector2(70.0, 35.0))
	aplicar_atordoamento(1.1)


func registrar_reciclagem(quantidade: int) -> void:
	if morto or rotulo_removido:
		return

	reciclagem_atual = mini(reciclagem_atual + quantidade, meta_reciclagem)
	reciclagem_alterada.emit(reciclagem_atual, meta_reciclagem)

	if reciclagem_atual >= meta_reciclagem:
		remover_rotulo()


func remover_rotulo() -> void:
	rotulo_removido = true
	rotulo.visible = false
	multiplicador_dano_recebido = 1.25
	aplicar_atordoamento(3.0)
	velocity = Vector2.ZERO
	corpo_visual.modulate = Color(0.45, 1.0, 0.65, 1.0)


func ao_colidir_com_player(alvo: Node) -> void:
	if morto or not alvo.has_method("tomar_dano"):
		return

	var dano_contato := Dano if estado == Estado.ROLANDO else Dano * 0.45
	alvo.tomar_dano(dano_contato)

	if estado == Estado.ROLANDO:
		iniciar_recuperacao(0.9)


func morrer() -> void:
	if morto:
		return
	if Vida > 0.0:
		return

	for grupo in [&"minion_pet0", &"residuo_pet0", &"projetil_inimigo"]:
		for node in get_tree().get_nodes_in_group(grupo):
			if is_instance_valid(node):
				node.queue_free()

	var efeito := EFEITO_RECICLAGEM.instantiate() as Node2D
	if not efeito:
		super.morrer()
		return
	get_tree().current_scene.add_child(efeito)
	efeito.global_position = global_position

	Global.Pontos += 5000
	super.morrer()
