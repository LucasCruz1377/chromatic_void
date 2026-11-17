# PolenErrante: comportamento especifico, derivado diretamente de InimigoBase.
extends InimigoBase

const Perigo := preload("res://Scripts/PerigoSetorial.gd")

enum Estilo { ESTILHACO, GUARDA, ECO, BROTO, ORBITAL, CENTELHA_GUIA, ELO_DOURADO, PRISMA_AMPARO, SATELITE_BERCO, PULSO_SOLAR, FITA_VIOLETA, NO_FLUTUANTE, ECO_AMETISTA, LAMINA_IRIS, CASULO_PRISMATICO, BROTO_PRIMAVERIL, SEMENTE_CANHAO, POLEN_ERRANTE, CIPO_ESPIRAL, FRUTO_EXPLOSIVO, FRAGMENTO_LUNAR, CENTELHA_SOLAR, METEORO_JOVEM, ECO_GRAVITACIONAL, SATELITE_COROA }

var estilo: Estilo = Estilo.POLEN_ERRANTE
@export var cor_setor := Color(0.45, 1.0, 0.68)
@export var intervalo_acao := 2.8

var visual: CanvasItem
var tempo := 0.0
var recarga := 1.0
var preparando := false
var preparo := 0.0
var direcao := Vector2.RIGHT
var direcao_memorizada := Vector2.RIGHT
var parceiro: InimigoBase
var trilha := Vector2.ZERO
var tempo_trilha := 0.0

func _ready() -> void:
	# As espécies setoriais atacam por padrões próprios e sobrevivem ao contato.
	# Antes elas herdavam o comportamento descartável dos inimigos clássicos.
	morre_ao_colidir_player = false
	add_to_group("inimigo_setorial")
	set_meta("tipo_setorial", int(estilo))
	visual = self; trilha = global_position
	super._ready()
	intervalo_acao = calcular_intervalo_ataque(intervalo_acao)
	recarga = randf_range(0.4, intervalo_acao)
	queue_redraw()

func Mover(delta: float) -> void:
	if not is_instance_valid(player): return
	tempo += delta; tempo_trilha -= delta
	if player.velocity.length_squared() > 20.0: direcao_memorizada = player.velocity.normalized()
	if preparando:
		velocity = velocity.move_toward(Vector2.ZERO, 420.0 * delta); preparo -= delta
		if preparo <= 0.0: preparando = false; _executar(); recarga = intervalo_acao * randf_range(0.9, 1.12)
		_atualizar_desenho(delta); return
	var ate := global_position.direction_to(player.global_position)
	var distancia := global_position.distance_to(player.global_position)
	direcao = ate
	velocity = velocity.move_toward(ate.rotated(sin(tempo * 1.6) * 0.75) * Velocidade, 150.0 * delta)
	recarga -= delta
	if recarga <= 0.0: _preparar()
	_atualizar_desenho(delta)

func _atualizar_desenho(_delta: float) -> void:
	queue_redraw()

func _preparar() -> void:
	if not is_instance_valid(player):
		return
	preparando = true; direcao = global_position.direction_to(player.global_position)
	var preparo_base := 0.58
	preparo = maxf(preparo_base * pow(0.90, indice_setor_dificuldade), 0.28)
	_destino_e_aviso()

func _destino_e_aviso() -> void:
	var cena := get_tree().current_scene
	if not is_instance_valid(cena):
		return
	Perigo.criar(cena, Perigo.Forma.PUXAO, global_position, global_position, cor_setor, preparo, 1.15, Dano * 0.12, 92.0, -1.0)

func _executar() -> void:
	EfeitoCombateCena.criar(get_tree().current_scene, global_position, EfeitoCombate.Tipo.ACERTO, cor_setor, 0.55, direcao)

func tomarDano(valor:float)->void:
	# Os clientes detectam impacto, mas apenas o host pode executar
	# consequencias do ataque, alterar defesas ou criar drones.
	if Rede.modo_multiplayer and not multiplayer.is_server():
		super.tomarDano(valor)
		return
	if morto or valor <= 0.0:
		return
	super.tomarDano(valor)

func morrer()->void:
	parceiro = null
	super.morrer()

func _draw()->void:
	var c:=cor_setor.lightened(0.1)
	for i in 7:
		draw_circle(Vector2.from_angle(i*2.4+tempo)*float(5+i*2),3.5,c)
	# Núcleo e partículas de carga preservam a silhueta de cada espécie.
	draw_circle(Vector2.ZERO, 4.0, Color(0.03, 0.04, 0.10))
	draw_circle(direcao * 2.0, 1.8, Color.WHITE)
	if preparando:
		for i in 5:
			var ponto := Vector2.from_angle(float(i) * TAU / 5.0 + tempo) * (12.0 + maxf(preparo, 0.0) * 22.0)
			draw_circle(ponto, 2.0, cor_setor.lightened(0.4))

func obter_descricao_vinculo() -> String:
	return ""
