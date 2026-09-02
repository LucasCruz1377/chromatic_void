extends InimigoBase
class_name BossCaosPrimaveril


signal fase_alterada(fase_atual: int)

const ESPINHO := preload("res://Entities/EspinhoPrimaveril.tscn")
const PETALA_BUMERANGUE := preload("res://Entities/PetalaBumerangue.tscn")
const VINHA := preload("res://Entities/VinhaEspinhosa.tscn")

enum Ataque {
	ONDA_ESPINHOS,
	PETALA_BUMERANGUE,
	DANCA_CAULES,
}

enum Estado {
	MOVENDO,
	PREPARANDO_ESPINHOS,
	ONDA_ESPINHOS,
	PETALAS_ATIVAS,
	INDO_AO_CENTRO,
	AVISANDO_VINHAS,
	CRESCENDO_VINHAS,
	DANCA_VINHAS,
	RECUPERANDO,
}

@export_category("Identidade")
@export var nome_exibicao := "CAOS PRIMAVERIL"
@export var selo_monthly_colors := "PRIMAVERA • SETEMBRO"

@export_category("Ritmo")
@export_range(0.5, 5.0, 0.1) var intervalo_ataques := 1.55
@export_range(0.4, 2.0, 0.1) var tempo_aviso_espinhos := 0.78
@export_range(0.5, 2.5, 0.1) var tempo_aviso_vinhas := 1.0

var fase := 1
var estado := Estado.MOVENDO
var tempo_estado := 0.0
var tempo_ataque := 1.5
var tempo_disparo := 0.0
var ultimo_ataque := -1
var indice_dificuldade := 1
var escudo_ativo := true
var sentido_rotacao := 1.0
var petalas_em_voo := 0
var petalas_lancadas: Array[PetalaBumerangue] = []
var vinhas_ativas: Array[VinhaEspinhosa] = []
var tween_escudo: Tween
var velocidade_vinhas_atual := 0.0
var velocidade_vinhas_alvo := 0.0
var tempo_mudar_sentido_vinhas := 0.0
var sentido_vinhas := 1.0

@onready var visual: Node2D = $Visual
@onready var petalas: Node2D = $Visual/Petalas
@onready var espinhos_ornamentais: Node2D = $Visual/Espinhos
@onready var polen: GPUParticles2D = $Polen
@onready var aviso_espinhos: Line2D = $AvisoEspinhos
@onready var aviso_vinhas: Node2D = $AvisoVinhas
@onready var vinhas_pivot: Node2D = $VinhasPivot


func _ready() -> void:
	super._ready()
	configurar_circulo_aviso()
	ativar_escudo(true)
	vida_alterada.emit(Vida, obter_vida_maxima_atual())
	fase_alterada.emit(fase)


func configurar_dificuldade(indice: int) -> void:
	indice_dificuldade = maxi(indice, 1)
	var multiplicador_vida := 1.0 + float(indice_dificuldade - 1) * 0.28
	var multiplicador_dano := 1.0 + float(indice_dificuldade - 1) * 0.08
	VidaMaxima *= multiplicador_vida
	Vida = VidaMaxima
	Dano *= multiplicador_dano
	ValorXP += float(indice_dificuldade) * 2.0
	vida_alterada.emit(Vida, VidaMaxima)


func obter_nome_boss() -> String:
	return nome_exibicao


func obter_subtitulo_boss() -> String:
	return selo_monthly_colors


func obter_velocidade_maxima() -> float:
	return Velocidade + float(fase - 1) * 10.0


func Mover(delta: float) -> void:
	polen.rotation += (0.7 + fase * 0.18) * sentido_rotacao * delta
	match estado:
		Estado.MOVENDO:
			mover_livre(delta)
		Estado.PREPARANDO_ESPINHOS:
			preparar_onda_espinhos(delta)
		Estado.ONDA_ESPINHOS:
			processar_onda_espinhos(delta)
		Estado.PETALAS_ATIVAS:
			processar_petalas(delta)
		Estado.INDO_AO_CENTRO:
			ir_ao_centro(delta)
		Estado.AVISANDO_VINHAS:
			avisar_vinhas(delta)
		Estado.CRESCENDO_VINHAS:
			crescer_vinhas(delta)
		Estado.DANCA_VINHAS:
			processar_danca_vinhas(delta)
		Estado.RECUPERANDO:
			processar_recuperacao(delta)


func mover_livre(delta: float) -> void:
	petalas.rotation += 0.26 * sentido_rotacao * delta
	espinhos_ornamentais.rotation = petalas.rotation
	if not is_instance_valid(player):
		return
	var ate_player := global_position.direction_to(player.global_position)
	var distancia := global_position.distance_to(player.global_position)
	var direcao := ate_player.orthogonal() * sentido_rotacao
	if distancia > 390.0:
		direcao = (ate_player + direcao * 0.4).normalized()
	elif distancia < 245.0:
		direcao = (-ate_player + direcao * 0.6).normalized()
	velocity = velocity.move_toward(direcao * obter_velocidade_maxima(), 135.0 * delta)
	tempo_ataque -= delta
	if tempo_ataque <= 0.0:
		iniciar_proximo_ataque()


func iniciar_proximo_ataque() -> void:
	var opcoes: Array[int] = [
		Ataque.ONDA_ESPINHOS,
		Ataque.PETALA_BUMERANGUE,
		Ataque.DANCA_CAULES,
	]
	if opcoes.size() > 1:
		opcoes.erase(ultimo_ataque)
	var ataque := int(opcoes.pick_random())
	ultimo_ataque = ataque
	match ataque:
		Ataque.ONDA_ESPINHOS:
			iniciar_onda_espinhos()
		Ataque.PETALA_BUMERANGUE:
			iniciar_petalas_bumerangue()
		Ataque.DANCA_CAULES:
			iniciar_danca_caules()


func iniciar_onda_espinhos() -> void:
	estado = Estado.PREPARANDO_ESPINHOS
	tempo_estado = tempo_aviso_espinhos
	velocity = Vector2.ZERO
	ativar_escudo(true)
	aviso_espinhos.visible = true


func preparar_onda_espinhos(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, 500.0 * delta)
	var giro := (1.4 + fase * 0.55) * sentido_rotacao
	petalas.rotation += giro * delta
	espinhos_ornamentais.rotation = petalas.rotation
	aviso_espinhos.rotation += giro * 0.55 * delta
	aviso_espinhos.modulate.a = 0.34 + absf(sin(Time.get_ticks_msec() * 0.018)) * 0.58
	tempo_estado -= delta
	if tempo_estado <= 0.0:
		estado = Estado.ONDA_ESPINHOS
		tempo_estado = 1.6 + fase * 0.45
		tempo_disparo = 0.0


func processar_onda_espinhos(delta: float) -> void:
	velocity = Vector2.ZERO
	var giro := (1.7 + fase * 0.68) * sentido_rotacao
	petalas.rotation += giro * delta
	espinhos_ornamentais.rotation = petalas.rotation
	aviso_espinhos.rotation = petalas.rotation
	tempo_disparo -= delta
	if tempo_disparo <= 0.0:
		disparar_anel_espinhos()
		tempo_disparo = maxf(0.54 - fase * 0.07, 0.30)
	tempo_estado -= delta
	if tempo_estado <= 0.0:
		aviso_espinhos.visible = false
		iniciar_recuperacao(1.8)


func disparar_anel_espinhos() -> void:
	var quantidade := 5 + fase * 2
	var deslocamento := petalas.rotation
	for indice in quantidade:
		var angulo := deslocamento + TAU * float(indice) / float(quantidade)
		var direcao := Vector2.from_angle(angulo)
		var espinho := ESPINHO.instantiate() as ProjetilInimigo
		get_tree().current_scene.add_child(espinho)
		espinho.global_position = global_position + direcao * 54.0
		espinho.configurar(
			direcao,
			Dano * 0.42,
			235.0 + fase * 30.0,
			0
		)


func iniciar_petalas_bumerangue() -> void:
	estado = Estado.PETALAS_ATIVAS
	tempo_estado = 4.8
	velocity = Vector2.ZERO
	ativar_escudo(false)
	petalas_em_voo = 0
	petalas_lancadas.clear()
	var quantidade := mini(fase + 1, 4)
	var indice_alvo := obter_petala_na_direcao_do_player()
	var indices: Array[int] = [indice_alvo]
	if quantidade >= 2:
		indices.append(posmod(indice_alvo + 2, 6))
	if quantidade >= 3:
		indices.append(posmod(indice_alvo - 2, 6))
	if quantidade >= 4:
		indices.append(posmod(indice_alvo + 3, 6))
	for indice in indices:
		lancar_petala(indice)


func obter_petala_na_direcao_do_player() -> int:
	if not is_instance_valid(player):
		return 0
	var angulo_player := global_position.angle_to_point(player.global_position)
	var melhor_indice := 0
	var menor_diferenca := INF
	for indice in 6:
		var angulo_petala := petalas.global_rotation - PI * 0.5 + TAU * float(indice) / 6.0
		var diferenca := absf(angle_difference(angulo_petala, angulo_player))
		if diferenca < menor_diferenca:
			menor_diferenca = diferenca
			melhor_indice = indice
	return melhor_indice


func lancar_petala(indice: int) -> void:
	var sprite := petalas.get_node("Petala%d" % indice) as Sprite2D
	if not is_instance_valid(sprite):
		return
	sprite.visible = false
	var direcao := Vector2.UP.rotated(
		petalas.global_rotation + TAU * float(indice) / 6.0
	)
	var petala := PETALA_BUMERANGUE.instantiate() as PetalaBumerangue
	get_tree().current_scene.add_child(petala)
	petala.configurar(
		global_position + direcao * 38.0,
		direcao,
		Dano * 0.54,
		315.0 + fase * 25.0,
		400.0 + fase * 35.0,
		indice,
		self
	)
	petala.retornou.connect(_on_petala_retornou)
	petalas_lancadas.append(petala)
	petalas_em_voo += 1


func processar_petalas(delta: float) -> void:
	velocity = Vector2.ZERO
	tempo_estado -= delta
	if petalas_em_voo <= 0:
		iniciar_recuperacao(1.0)
	elif tempo_estado <= 0.0:
		cancelar_petalas_restantes()
		iniciar_recuperacao(1.0)


func _on_petala_retornou(indice: int) -> void:
	var sprite := petalas.get_node_or_null("Petala%d" % indice) as Sprite2D
	if is_instance_valid(sprite):
		sprite.visible = true
	petalas_em_voo = maxi(petalas_em_voo - 1, 0)


func cancelar_petalas_restantes() -> void:
	for petala in petalas_lancadas:
		if is_instance_valid(petala):
			petala.cancelar()
	for indice in 6:
		var sprite := petalas.get_node_or_null("Petala%d" % indice) as Sprite2D
		if is_instance_valid(sprite):
			sprite.visible = true
	petalas_lancadas.clear()
	petalas_em_voo = 0


func iniciar_danca_caules() -> void:
	estado = Estado.INDO_AO_CENTRO
	ativar_escudo(true)
	velocity = Vector2.ZERO
	sentido_rotacao = -1.0 if randf() < 0.5 else 1.0
	sentido_vinhas = sentido_rotacao
	velocidade_vinhas_atual = 0.0
	velocidade_vinhas_alvo = (0.34 + fase * 0.10) * sentido_vinhas
	tempo_mudar_sentido_vinhas = maxf(3.0 - fase * 0.38, 1.55)


func ir_ao_centro(_delta: float) -> void:
	var centro := Vector2(480.0, 270.0)
	var distancia := global_position.distance_to(centro)
	if distancia <= 7.0:
		global_position = centro
		velocity = Vector2.ZERO
		estado = Estado.AVISANDO_VINHAS
		tempo_estado = tempo_aviso_vinhas
		aviso_vinhas.visible = true
		return
	velocity = global_position.direction_to(centro) * minf(260.0, distancia * 2.2)


func avisar_vinhas(delta: float) -> void:
	velocity = Vector2.ZERO
	aviso_vinhas.modulate.a = 0.28 + absf(sin(Time.get_ticks_msec() * 0.021)) * 0.70
	visual.rotation += 0.34 * sentido_rotacao * delta
	tempo_estado -= delta
	if tempo_estado <= 0.0:
		aviso_vinhas.visible = false
		criar_vinhas()
		estado = Estado.CRESCENDO_VINHAS
		tempo_estado = 0.82


func criar_vinhas() -> void:
	limpar_vinhas()
	vinhas_pivot.rotation = visual.rotation
	# A diagonal da arena mede ~551 px a partir do centro. Usar 560 px em
	# todos os braços garante que nenhuma vinha deixe de tocar a borda ao girar.
	var comprimentos := [560.0, 560.0, 560.0, 560.0]
	for indice in 4:
		var vinha := VINHA.instantiate() as VinhaEspinhosa
		vinhas_pivot.add_child(vinha)
		vinha.rotation = float(indice) * PI * 0.5
		vinha.configurar(comprimentos[indice], Dano * 0.58)
		vinha.iniciar_crescimento(0.70)
		vinhas_ativas.append(vinha)


func crescer_vinhas(delta: float) -> void:
	velocity = Vector2.ZERO
	tempo_estado -= delta
	if tempo_estado <= 0.0:
		for vinha in vinhas_ativas:
			if is_instance_valid(vinha):
				vinha.ativar_dano()
		estado = Estado.DANCA_VINHAS
		# Cinco segundos extras em todas as fases para tornar a dança uma ameaça
		# longa, mas as inversões continuam suaves e previsíveis visualmente.
		tempo_estado = 9.0 + fase * 0.5


func processar_danca_vinhas(delta: float) -> void:
	velocity = Vector2.ZERO
	tempo_mudar_sentido_vinhas -= delta
	if tempo_mudar_sentido_vinhas <= 0.0:
		sentido_vinhas *= -1.0
		velocidade_vinhas_alvo = (0.34 + fase * 0.10) * sentido_vinhas
		tempo_mudar_sentido_vinhas = (
			maxf(3.05 - fase * 0.42, 1.45) + randf_range(-0.12, 0.28)
		)
	# Interpolação exponencial: desacelera, cruza o zero e acelera na direção
	# oposta. Fases altas convergem mais rápido para o novo sentido.
	var rapidez_lerp := 0.80 + fase * 0.58
	var peso_lerp := 1.0 - exp(-rapidez_lerp * delta)
	velocidade_vinhas_atual = lerpf(
		velocidade_vinhas_atual,
		velocidade_vinhas_alvo,
		peso_lerp
	)
	visual.rotation += velocidade_vinhas_atual * delta
	vinhas_pivot.rotation += velocidade_vinhas_atual * delta
	tempo_estado -= delta
	if tempo_estado <= 0.0:
		encerrar_vinhas()
		iniciar_recuperacao(2.2)


func encerrar_vinhas() -> void:
	for vinha in vinhas_ativas:
		if not is_instance_valid(vinha):
			continue
		vinha.desativar_dano()
		var tween := vinha.create_tween()
		tween.tween_property(vinha, "modulate:a", 0.0, 0.28)
		tween.tween_callback(vinha.queue_free)
	vinhas_ativas.clear()


func limpar_vinhas() -> void:
	for vinha in vinhas_ativas:
		if is_instance_valid(vinha):
			vinha.queue_free()
	vinhas_ativas.clear()


func iniciar_recuperacao(duracao: float) -> void:
	estado = Estado.RECUPERANDO
	tempo_estado = duracao
	velocity = Vector2.ZERO
	ativar_escudo(false)


func processar_recuperacao(delta: float) -> void:
	velocity = Vector2.ZERO
	petalas.rotation += 0.18 * sentido_rotacao * delta
	espinhos_ornamentais.rotation = petalas.rotation
	tempo_estado -= delta
	if tempo_estado <= 0.0:
		ativar_escudo(true)
		estado = Estado.MOVENDO
		tempo_ataque = maxf(intervalo_ataques - fase * 0.13, 0.95)


func ativar_escudo(ativar: bool) -> void:
	escudo_ativo = ativar
	multiplicador_dano_recebido = 0.0 if ativar else 1.0
	polen.visible = ativar
	polen.emitting = ativar
	if ativar:
		polen.restart()


func tomarDano(valor: float) -> void:
	if morto or valor <= 0.0:
		return
	if escudo_ativo:
		pulsar_escudo()
		return
	super.tomarDano(valor)
	if not morto:
		atualizar_fase()


func pulsar_escudo() -> void:
	if tween_escudo and tween_escudo.is_valid():
		tween_escudo.kill()
	polen.scale = Vector2.ONE
	tween_escudo = create_tween()
	tween_escudo.tween_property(polen, "scale", Vector2(1.16, 1.16), 0.08)
	tween_escudo.tween_property(polen, "scale", Vector2.ONE, 0.15)


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
	sentido_rotacao *= -1.0


func configurar_circulo_aviso() -> void:
	var pontos := PackedVector2Array()
	for indice in range(49):
		pontos.append(Vector2.from_angle(TAU * float(indice) / 48.0) * 74.0)
	aviso_espinhos.points = pontos


func ao_colidir_com_player(alvo: Node) -> void:
	if alvo.has_method("tomar_dano"):
		alvo.tomar_dano(Dano * 0.42)


func morrer() -> void:
	if morto or Vida > 0.0:
		return
	cancelar_petalas_restantes()
	limpar_vinhas()
	for node in get_tree().get_nodes_in_group("projetil_primaveril"):
		if is_instance_valid(node):
			node.queue_free()
	super.morrer()
