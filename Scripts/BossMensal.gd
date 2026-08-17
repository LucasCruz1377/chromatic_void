extends InimigoBase
class_name BossMensal


signal fase_alterada(fase_atual: int)

const PROJETIL := preload("res://Entities/ProjetilInimigo.tscn")

enum Tema {
	FLOR_EQUINOCIO,
	ECLIPSE_COLHEITA,
	SENTINELA_DOURADA,
	RUPTURA_LILAS,
}

enum Estado {
	MOVENDO,
	AVISANDO,
	INVESTINDO,
	RECUPERANDO,
}

@export_category("Identidade")
@export var tema := Tema.FLOR_EQUINOCIO
@export var nome_exibicao := "FLOR DO EQUINÓCIO"
@export var selo_monthly_colors := "PRIMAVERA • SETEMBRO"
@export var cor_principal := Color(1.0, 0.32, 0.68)
@export var cor_secundaria := Color(0.34, 1.0, 0.58)

@export_category("Ritmo")
@export var intervalo_ataques := 2.25
@export var tempo_aviso := 0.62
@export var velocidade_investida := 560.0

var fase := 1
var estado := Estado.MOVENDO
var tempo_estado := 0.0
var tempo_ataque := 1.25
var ataque_pendente := 0
var direcao_investida := Vector2.RIGHT
var angulo_visual := 0.0
var indice_dificuldade := 1
var linha_aviso: Line2D


func _ready() -> void:
	super._ready()
	self_modulate = Color(1.28, 1.28, 1.28, 1.0)
	linha_aviso = Line2D.new()
	linha_aviso.width = 4.0
	linha_aviso.default_color = Color(cor_secundaria, 0.78)
	linha_aviso.z_index = -1
	linha_aviso.visible = false
	add_child(linha_aviso)
	vida_alterada.emit(Vida, obter_vida_maxima_atual())
	fase_alterada.emit(fase)
	queue_redraw()


func configurar_dificuldade(indice: int) -> void:
	indice_dificuldade = maxi(indice, 1)
	var multiplicador_vida := 1.0 + float(indice_dificuldade - 1) * 0.32
	var multiplicador_dano := 1.0 + float(indice_dificuldade - 1) * 0.10
	VidaMaxima *= multiplicador_vida
	Vida = VidaMaxima
	Dano *= multiplicador_dano
	ValorXP += float(indice_dificuldade) * 2.0
	vida_alterada.emit(Vida, VidaMaxima)


func obter_nome_boss() -> String:
	return nome_exibicao


func obter_subtitulo_boss() -> String:
	return selo_monthly_colors


func Mover(delta: float) -> void:
	angulo_visual += delta * (0.65 + fase * 0.18)
	queue_redraw()
	match estado:
		Estado.MOVENDO:
			mover_livre(delta)
		Estado.AVISANDO:
			processar_aviso(delta)
		Estado.INVESTINDO:
			processar_investida(delta)
		Estado.RECUPERANDO:
			processar_recuperacao(delta)


func obter_velocidade_maxima() -> float:
	if estado == Estado.INVESTINDO:
		return velocidade_investida + float(fase - 1) * 45.0
	return Velocidade + float(fase - 1) * 12.0


func mover_livre(delta: float) -> void:
	if not is_instance_valid(player):
		return
	var ate_player := global_position.direction_to(player.global_position)
	var distancia := global_position.distance_to(player.global_position)
	var direcao := ate_player
	if distancia < 230.0:
		direcao = (-ate_player + ate_player.orthogonal() * 0.55).normalized()
	elif distancia < 360.0:
		direcao = ate_player.orthogonal()
	velocity = velocity.move_toward(direcao * obter_velocidade_maxima(), 145.0 * delta)

	tempo_ataque -= delta
	if tempo_ataque <= 0.0:
		preparar_ataque(escolher_ataque())


func escolher_ataque() -> int:
	var opcoes := [0, 1]
	if fase >= 2:
		opcoes.append(2)
	if fase >= 3:
		opcoes.append(3)
	return int(opcoes.pick_random())


func preparar_ataque(indice: int) -> void:
	if not is_instance_valid(player):
		return
	estado = Estado.AVISANDO
	ataque_pendente = indice
	tempo_estado = maxf(tempo_aviso - float(fase - 1) * 0.06, 0.38)
	direcao_investida = global_position.direction_to(player.global_position)
	linha_aviso.visible = true
	if indice == 0 and tema in [Tema.ECLIPSE_COLHEITA, Tema.RUPTURA_LILAS]:
		linha_aviso.points = PackedVector2Array([
			Vector2.ZERO, direcao_investida * 760.0
		])
	else:
		linha_aviso.points = criar_circulo_pontos(72.0 + indice * 12.0, 40)


func processar_aviso(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, 420.0 * delta)
	tempo_estado -= delta
	linha_aviso.modulate.a = 0.35 + absf(sin(Time.get_ticks_msec() * 0.019)) * 0.65
	if tempo_estado > 0.0:
		return
	linha_aviso.visible = false
	executar_ataque(ataque_pendente)


func executar_ataque(indice: int) -> void:
	match tema:
		Tema.FLOR_EQUINOCIO:
			executar_floresta(indice)
		Tema.ECLIPSE_COLHEITA:
			executar_eclipse(indice)
		Tema.SENTINELA_DOURADA:
			executar_sentinela(indice)
		Tema.RUPTURA_LILAS:
			executar_ruptura(indice)


func executar_floresta(indice: int) -> void:
	match indice:
		0:
			disparar_anel(7 + fase * 2, 210.0, 0.38, angulo_visual)
			iniciar_recuperacao(0.55)
		1:
			disparar_mira(3 + fase, 300.0, 0.48, 0.34)
			iniciar_recuperacao(0.60)
		2:
			disparar_espiral(12 + fase * 2, 235.0, 0.34)
			iniciar_recuperacao(0.75)
		_:
			disparar_anel(16, 175.0, 0.30, angulo_visual)
			disparar_anel(8, 315.0, 0.42, angulo_visual + PI / 8.0)
			iniciar_recuperacao(0.85)


func executar_eclipse(indice: int) -> void:
	match indice:
		0:
			iniciar_investida()
		1:
			disparar_anel(10 + fase * 2, 230.0, 0.40, angulo_visual)
			iniciar_recuperacao(0.6)
		2:
			disparar_relogio(8, 265.0, 0.46)
			iniciar_recuperacao(0.8)
		_:
			disparar_espiral(18, 250.0, 0.36)
			iniciar_recuperacao(0.9)


func executar_sentinela(indice: int) -> void:
	match indice:
		0:
			multiplicador_dano_recebido = 0.35
			disparar_anel(6 + fase * 2, 195.0, 0.36, angulo_visual)
			iniciar_recuperacao(0.85)
		1:
			disparar_mira(4, 340.0, 0.52, 0.42)
			iniciar_recuperacao(0.6)
		2:
			disparar_satelites()
			iniciar_recuperacao(0.8)
		_:
			disparar_anel(18, 205.0, 0.32, -angulo_visual)
			iniciar_recuperacao(0.95)


func executar_ruptura(indice: int) -> void:
	match indice:
		0:
			iniciar_investida()
		1:
			disparar_anel_com_fendas(16, 225.0, 0.40, 3)
			iniciar_recuperacao(0.7)
		2:
			disparar_mira(5, 315.0, 0.47, 0.54)
			iniciar_recuperacao(0.75)
		_:
			disparar_anel_com_fendas(24, 260.0, 0.34, 4)
			iniciar_recuperacao(0.9)


func iniciar_investida() -> void:
	estado = Estado.INVESTINDO
	tempo_estado = 0.72
	velocity = direcao_investida * obter_velocidade_maxima()


func processar_investida(delta: float) -> void:
	tempo_estado -= delta
	velocity = direcao_investida * obter_velocidade_maxima()
	if tempo_estado <= 0.0:
		disparar_anel(6 + fase * 2, 185.0, 0.32, angulo_visual)
		iniciar_recuperacao(0.72)


func iniciar_recuperacao(duracao: float) -> void:
	estado = Estado.RECUPERANDO
	tempo_estado = duracao
	linha_aviso.visible = false


func processar_recuperacao(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, 520.0 * delta)
	tempo_estado -= delta
	if tempo_estado <= 0.0:
		estado = Estado.MOVENDO
		multiplicador_dano_recebido = 1.0
		tempo_ataque = maxf(intervalo_ataques - float(fase - 1) * 0.22, 1.18)


func disparar_mira(
	quantidade: int,
	velocidade_projetil: float,
	multiplicador_dano: float,
	abertura: float
) -> void:
	if not is_instance_valid(player):
		return
	var base := global_position.direction_to(player.global_position)
	for indice in range(quantidade):
		var offset := 0.0
		if quantidade > 1:
			offset = lerpf(-abertura, abertura, float(indice) / float(quantidade - 1))
		criar_projetil(base.rotated(offset), velocidade_projetil, multiplicador_dano)


func disparar_anel(
	quantidade: int,
	velocidade_projetil: float,
	multiplicador_dano: float,
	deslocamento: float = 0.0
) -> void:
	for indice in range(quantidade):
		var angulo := deslocamento + TAU * float(indice) / float(quantidade)
		criar_projetil(Vector2.from_angle(angulo), velocidade_projetil, multiplicador_dano)


func disparar_espiral(quantidade: int, velocidade_projetil: float, multiplicador_dano: float) -> void:
	for indice in range(quantidade):
		var angulo := angulo_visual + float(indice) * 0.72
		var velocidade := velocidade_projetil + float(indice % 3) * 28.0
		criar_projetil(Vector2.from_angle(angulo), velocidade, multiplicador_dano)


func disparar_relogio(quantidade: int, velocidade_projetil: float, multiplicador_dano: float) -> void:
	for indice in range(quantidade):
		var angulo := angulo_visual + TAU * float(indice) / float(quantidade)
		criar_projetil(Vector2.from_angle(angulo), velocidade_projetil, multiplicador_dano, 2)


func disparar_satelites() -> void:
	var quantidade := 5 + fase
	for indice in range(quantidade):
		var angulo := angulo_visual + TAU * float(indice) / float(quantidade)
		var direcao := Vector2.from_angle(angulo)
		criar_projetil(direcao, 165.0 + indice * 18.0, 0.38)
		criar_projetil(direcao.rotated(0.18), 245.0, 0.28)


func disparar_anel_com_fendas(
	quantidade: int,
	velocidade_projetil: float,
	multiplicador_dano: float,
	tamanho_fenda: int
) -> void:
	var inicio_fenda := randi_range(0, quantidade - 1)
	for indice in range(quantidade):
		var distancia_fenda := posmod(indice - inicio_fenda, quantidade)
		if distancia_fenda < tamanho_fenda:
			continue
		var angulo := angulo_visual + TAU * float(indice) / float(quantidade)
		criar_projetil(Vector2.from_angle(angulo), velocidade_projetil, multiplicador_dano)


func criar_projetil(
	direcao: Vector2,
	velocidade_projetil: float,
	multiplicador_dano: float,
	rebotes: int = 0
) -> void:
	var projetil := PROJETIL.instantiate() as ProjetilInimigo
	get_tree().current_scene.add_child(projetil)
	projetil.global_position = global_position + direcao.normalized() * 48.0
	projetil.configurar(direcao, Dano * multiplicador_dano, velocidade_projetil, rebotes)
	projetil.modulate = Color.WHITE
	var forma := projetil.get_node_or_null("Visual") as Polygon2D
	if is_instance_valid(forma):
		forma.color = cor_principal.lerp(cor_secundaria, randf_range(0.0, 0.75))
		forma.self_modulate = Color(1.45, 1.45, 1.45, 1.0)


func tomarDano(valor: float) -> void:
	if morto:
		return
	super.tomarDano(valor)
	if not morto:
		atualizar_fase()


func atualizar_fase() -> void:
	var porcentagem := Vida / maxf(VidaMaxima, 1.0)
	var nova_fase := 1
	if porcentagem <= 0.34:
		nova_fase = 3
	elif porcentagem <= 0.68:
		nova_fase = 2
	if nova_fase == fase:
		return
	fase = nova_fase
	fase_alterada.emit(fase)
	aplicar_atordoamento(0.8)
	disparar_anel(5 + fase * 2, 155.0, 0.24, angulo_visual)


func ao_colidir_com_player(alvo: Node) -> void:
	if not alvo.has_method("tomar_dano"):
		return
	var multiplicador := 1.0 if estado == Estado.INVESTINDO else 0.42
	alvo.tomar_dano(Dano * multiplicador)
	if estado == Estado.INVESTINDO:
		iniciar_recuperacao(0.8)


func criar_circulo_pontos(raio: float, segmentos: int) -> PackedVector2Array:
	var pontos := PackedVector2Array()
	for indice in range(segmentos + 1):
		pontos.append(Vector2.from_angle(TAU * float(indice) / float(segmentos)) * raio)
	return pontos


func _draw() -> void:
	var pulso := 1.0 + sin(Time.get_ticks_msec() * 0.006) * 0.06
	match tema:
		Tema.FLOR_EQUINOCIO:
			for indice in range(8):
				var angulo := angulo_visual + TAU * float(indice) / 8.0
				var centro := Vector2.from_angle(angulo) * 39.0
				draw_circle(centro, 16.0 * pulso, cor_principal)
			draw_circle(Vector2.ZERO, 23.0, cor_secundaria)
			draw_circle(Vector2.ZERO, 10.0, Color(1.0, 0.88, 0.22))
		Tema.ECLIPSE_COLHEITA:
			draw_circle(Vector2.ZERO, 47.0, cor_principal)
			draw_circle(Vector2(17, -7), 44.0, Color(0.008, 0.01, 0.035))
			draw_arc(Vector2.ZERO, 55.0 * pulso, -1.25, 1.25, 32, cor_secundaria, 5.0)
		Tema.SENTINELA_DOURADA:
			var pontos := PackedVector2Array()
			for indice in range(6):
				pontos.append(Vector2.from_angle(angulo_visual + TAU * float(indice) / 6.0) * 38.0)
			draw_colored_polygon(pontos, cor_principal)
			draw_circle(Vector2.ZERO, 22.0, cor_secundaria)
			for indice in range(4 + fase):
				var angulo := -angulo_visual * 1.4 + TAU * float(indice) / float(4 + fase)
				draw_circle(Vector2.from_angle(angulo) * 64.0, 7.0, cor_secundaria)
		Tema.RUPTURA_LILAS:
			for raio in [24.0, 40.0, 56.0]:
				draw_arc(Vector2.ZERO, raio * pulso, angulo_visual, angulo_visual + 4.8, 38, cor_principal, 5.0)
			draw_circle(Vector2.ZERO, 15.0, cor_secundaria)
