extends InimigoBase
class_name InimigoSetorial


const PROJETIL := preload("res://Entities/ProjetilInimigo.tscn")

enum Estilo {
	ESTILHACO, GUARDA, ECO, BROTO, ORBITAL,
	CENTELHA_GUIA, ELO_DOURADO, PRISMA_AMPARO, SATELITE_BERCO, PULSO_SOLAR,
	FITA_VIOLETA, NO_FLUTUANTE, ECO_AMETISTA, LAMINA_IRIS, CASULO_PRISMATICO,
	BROTO_PRIMAVERIL, SEMENTE_CANHAO, POLEN_ERRANTE, CIPO_ESPIRAL, FRUTO_EXPLOSIVO,
	FRAGMENTO_LUNAR, CENTELHA_SOLAR, METEORO_JOVEM, ECO_GRAVITACIONAL, SATELITE_COROA,
}

@export var estilo: Estilo = Estilo.ESTILHACO
@export var cor_setor := Color(0.45, 1.0, 0.68)
@export var intervalo_acao := 2.8

var tempo_acao := 1.4
var fase := 0.0
var preparando := false
var tempo_preparo := 0.0
var destino_eco := Vector2.ZERO
var visual: Polygon2D


func _ready() -> void:
	criar_visual_setorial()
	super._ready()
	tempo_acao = randf_range(0.8, intervalo_acao)


func criar_visual_setorial() -> void:
	visual = Polygon2D.new()
	visual.name = "VisualSetorial"
	visual.color = cor_setor
	visual.self_modulate = Color(1.35, 1.35, 1.35, 1.0)
	var papel := int(estilo) % 5
	match papel:
		0:
			visual.polygon = PackedVector2Array([Vector2(20, 0), Vector2(3, -7), Vector2(-8, -18), Vector2(-5, -5), Vector2(-20, 0), Vector2(-5, 5), Vector2(-8, 18), Vector2(3, 7)])
		1:
			visual.polygon = PackedVector2Array([Vector2(18, 0), Vector2(9, -15), Vector2(-9, -15), Vector2(-18, 0), Vector2(-9, 15), Vector2(9, 15)])
		2:
			visual.polygon = PackedVector2Array([Vector2(19, 0), Vector2(0, -17), Vector2(-8, -7), Vector2(-19, 0), Vector2(-8, 7), Vector2(0, 17)])
		3:
			visual.polygon = PackedVector2Array([Vector2(0, -20), Vector2(8, -7), Vector2(19, -2), Vector2(9, 7), Vector2(0, 20), Vector2(-9, 7), Vector2(-19, -2), Vector2(-8, -7)])
		4:
			visual.polygon = PackedVector2Array([Vector2(21, 0), Vector2(7, -7), Vector2(0, -20), Vector2(-7, -7), Vector2(-21, 0), Vector2(-7, 7), Vector2(0, 20), Vector2(7, 7)])
	add_child(visual)
	var nucleo := Polygon2D.new()
	nucleo.name = "Nucleo"
	nucleo.color = Color.WHITE
	nucleo.polygon = PackedVector2Array([Vector2(8, 0), Vector2(0, -8), Vector2(-8, 0), Vector2(0, 8)])
	visual.add_child(nucleo)
	# A família altera o núcleo, mantendo cada setor reconhecível mesmo quando
	# dois inimigos cumprem papéis parecidos.
	var familia := int(estilo) / 5
	if familia == 1:
		nucleo.rotation = PI * 0.25
	elif familia == 2:
		nucleo.scale = Vector2(0.62, 1.35)
	elif familia == 3:
		nucleo.polygon = PackedVector2Array([Vector2(0, -9), Vector2(8, 6), Vector2(-8, 6)])
	elif familia == 4:
		nucleo.polygon = PackedVector2Array([Vector2(9, 0), Vector2(4, -7), Vector2(-5, -7), Vector2(-9, 0), Vector2(-4, 7), Vector2(5, 7)])


func Mover(delta: float) -> void:
	if not is_instance_valid(player):
		velocity = velocity.move_toward(Vector2.ZERO, 260.0 * delta)
		return
	fase += delta
	if preparando:
		processar_preparo(delta)
		return
	var ate_player := global_position.direction_to(player.global_position)
	var distancia := global_position.distance_to(player.global_position)
	var papel := int(estilo) % 5
	match papel:
		0:
			var serpenteio := ate_player.rotated(sin(fase * 4.0) * 0.48)
			velocity = velocity.move_toward(serpenteio * Velocidade, 330.0 * delta)
			rotation += delta * 2.7
		1:
			var direcao := ate_player.orthogonal()
			if distancia > 280.0: direcao += ate_player * 0.8
			elif distancia < 210.0: direcao -= ate_player
			velocity = velocity.move_toward(direcao.normalized() * Velocidade, 210.0 * delta)
			rotation = ate_player.angle()
		2:
			velocity = velocity.move_toward(ate_player.rotated(sin(fase * 2.3) * 0.7) * Velocidade, 250.0 * delta)
			rotation = velocity.angle()
		3:
			var alvo := ate_player if distancia > 245.0 else -ate_player
			velocity = velocity.move_toward(alvo * Velocidade, 180.0 * delta)
			rotation += delta * 0.7
		4:
			var tangente := ate_player.orthogonal()
			var radial := ate_player * clampf((distancia - 250.0) / 90.0, -1.0, 1.0)
			velocity = velocity.move_toward((tangente + radial).normalized() * Velocidade, 230.0 * delta)
			rotation = ate_player.angle()
	tempo_acao -= delta
	if tempo_acao <= 0.0:
		iniciar_acao()


func iniciar_acao() -> void:
	preparando = true
	var papel := int(estilo) % 5
	tempo_preparo = 0.7 if papel == 2 else 0.5
	velocity *= 0.35
	if papel == 2 and is_instance_valid(player):
		var area := Global.obter_retangulo_area_visivel(55.0)
		destino_eco = Vector2(randf_range(area.position.x, area.end.x), randf_range(area.position.y, area.end.y))
	EfeitoCombateCena.criar(get_tree().current_scene, global_position, EfeitoCombate.Tipo.AVISO, cor_setor, 0.9, Vector2.RIGHT)
	var tween := create_tween().set_loops(2)
	tween.tween_property(visual, "scale", Vector2(1.22, 1.22), tempo_preparo * 0.25)
	tween.tween_property(visual, "scale", Vector2.ONE, tempo_preparo * 0.25)


func processar_preparo(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, 400.0 * delta)
	tempo_preparo -= delta
	if tempo_preparo > 0.0:
		return
	preparando = false
	executar_acao()
	tempo_acao = intervalo_acao * randf_range(0.85, 1.15)


func executar_acao() -> void:
	if not is_instance_valid(player):
		return
	var papel := int(estilo) % 5
	match papel:
		0:
			velocity = global_position.direction_to(player.global_position) * Velocidade * 2.2
		1:
			disparar_leque(3, 0.22, 280.0, Dano * 0.55)
		2:
			global_position = destino_eco
			EfeitoCombateCena.criar(get_tree().current_scene, global_position, EfeitoCombate.Tipo.MORTE, cor_setor, 0.8)
			velocity = global_position.direction_to(player.global_position) * Velocidade * 1.55
		3:
			disparar_radial(6, 175.0, Dano * 0.42)
		4:
			var direcao_prevista := global_position.direction_to(player.global_position + player.velocity * 0.35)
			disparar(direcao_prevista, 340.0, Dano * 0.7)


func disparar_leque(quantidade: int, abertura: float, velocidade_tiro: float, dano_tiro: float) -> void:
	var base := global_position.direction_to(player.global_position).angle()
	for indice in quantidade:
		var deslocamento := (float(indice) - float(quantidade - 1) * 0.5) * abertura
		disparar(Vector2.from_angle(base + deslocamento), velocidade_tiro, dano_tiro)


func disparar_radial(quantidade: int, velocidade_tiro: float, dano_tiro: float) -> void:
	for indice in quantidade:
		disparar(Vector2.from_angle(TAU * float(indice) / float(quantidade) + fase), velocidade_tiro, dano_tiro)


func disparar(direcao: Vector2, velocidade_tiro: float, dano_tiro: float) -> void:
	var projetil := PROJETIL.instantiate() as ProjetilInimigo
	get_tree().current_scene.add_child(projetil)
	projetil.global_position = global_position + direcao * 20.0
	var forma := projetil.get_node_or_null("Visual") as Polygon2D
	if is_instance_valid(forma):
		forma.color = cor_setor
	projetil.configurar(direcao, dano_tiro, velocidade_tiro, 0)
