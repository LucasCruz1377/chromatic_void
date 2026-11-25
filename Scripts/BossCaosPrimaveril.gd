extends "res://Scripts/ChefeBase.gd"
class_name BossCaosPrimaveril


signal fase_alterada(fase_atual: int)

const ESPINHO := preload("res://Entities/EspinhoPrimaveril.tscn")
const PETALA_BUMERANGUE := preload("res://Entities/PetalaBumerangue.tscn")
const VINHA := preload("res://Entities/VinhaEspinhosa.tscn")
const COMPRIMENTO_VINHA := 560.0

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

@export var forma_miolo: CircleShape2D
@export var forma_petala: ConvexPolygonShape2D
@export var forma_espinho: ConvexPolygonShape2D

@export_category("Identidade")
@export var nome_exibicao := "CAOS PRIMAVERIL"
@export var selo_monthly_colors := "PRIMAVERA • SETEMBRO"

@export_category("Ritmo")
@export_range(0.5, 5.0, 0.1) var intervalo_ataques := 1.15
@export_range(0.4, 2.0, 0.1) var tempo_aviso_espinhos := 0.78
@export_range(0.5, 2.5, 0.1) var tempo_aviso_vinhas := 1.0
@export_range(1.5, 3.0, 0.05) var janela_vulneravel_base := 3.0

var fase := 1
var estado := Estado.MOVENDO
var tempo_estado := 0.0
var tempo_ataque := 1.1
var tempo_disparo := 0.0
var tempo_janela_vulneravel := 0.0
var ultimo_ataque := -1
var ataques_desde_vinhas := 3
var indice_dificuldade := 1
var escudo_ativo := true
var sentido_rotacao := 1.0
var petalas_em_voo := 0
var petalas_lancadas: Array[PetalaBumerangue] = []
var vinhas_ativas: Array[VinhaEspinhosa] = []
var tween_escudo: Tween
var velocidade_vinhas_atual := 0.0
var velocidade_vinhas_alvo := 0.0
var velocidade_inicio_giro := 0.0
var progresso_giro := 0.0
var flexao_vinhas := 0.0
var angulo_replica := 0.0
var flexao_replica := 0.0
var previsao_vinhas := 0.0
var tempo_mudar_sentido_vinhas := 0.0
var sentido_vinhas := 1.0
var inversao_vinhas_pendente := false

@onready var visual: Node2D = $Visual
@onready var petalas: Node2D = $Visual/Petalas
@onready var espinhos_ornamentais: Node2D = $Visual/Espinhos
@onready var polen: GPUParticles2D = $Polen
@onready var aviso_espinhos: Line2D = $AvisoEspinhos
@onready var aviso_vinhas: Node2D = $AvisoVinhas
@onready var vinhas_pivot: Node2D = $VinhasPivot


func _ready() -> void:
	super._ready()
	vincular_colisao_visual($Visual/Miolo, forma_miolo)
	for petala in petalas.get_children():
		vincular_colisao_visual(petala, forma_petala)
	for espinho in espinhos_ornamentais.get_children():
		vincular_colisao_visual(espinho, forma_espinho)
	configurar_circulo_aviso()
	configurar_aviso_vinhas()
	ativar_escudo(true)
	vida_alterada.emit(Vida, obter_vida_maxima_atual())
	fase_alterada.emit(fase)


func configurar_dificuldade(indice: int) -> void:
	indice_dificuldade = maxi(indice, 1)
	var multiplicador_vida := 1.0 + float(indice_dificuldade - 1) * 0.28
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
	processar_janela_vulneravel(delta)


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


func sortear_proximo_ataque() -> int:
	# Nenhuma vinha na fase 1. Depois: chance de 15%, com pelo menos três
	# ataques comuns entre duas danças, evitando sequências longas de vinhas.
	if fase >= 2 and ataques_desde_vinhas >= 3 and randf() < 0.15:
		ataques_desde_vinhas = 0
		return Ataque.DANCA_CAULES
	var opcoes: Array[int] = [Ataque.ONDA_ESPINHOS, Ataque.PETALA_BUMERANGUE]
	opcoes.erase(ultimo_ataque)
	ataques_desde_vinhas += 1
	return int(opcoes.pick_random())


func iniciar_proximo_ataque() -> void:
	var ataque := sortear_proximo_ataque()
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
	aviso_espinhos.modulate.a = 0.34 + absf(sin(Global.tempo_combate_ms() * 0.018)) * 0.58
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
		iniciar_recuperacao(1.05)


func disparar_anel_espinhos() -> void:
	preload("res://Scripts/AudioCombate.gd").tocar(
		self, &"espinhos_flor", 0.16, 0.88, 1.14, -4.0
	)
	var quantidade := 5 + fase * 2
	var deslocamento := petalas.rotation
	for indice in quantidade:
		var angulo := deslocamento + TAU * float(indice) / float(quantidade)
		var direcao := Vector2.from_angle(angulo)
		var espinho := ESPINHO.instantiate() as ProjetilInimigo
		get_tree().current_scene.add_child(espinho, true)
		espinho.global_position = global_position + direcao * 54.0
		espinho.configurar(
			direcao,
			Dano * 0.42,
			235.0 + fase * 30.0,
			0
		)


func iniciar_petalas_bumerangue() -> void:
	preload("res://Scripts/AudioCombate.gd").tocar(self, &"petalas")
	estado = Estado.PETALAS_ATIVAS
	tempo_estado = 4.8
	velocity = Vector2.ZERO
	abrir_janela_vulneravel(_duracao_janela_vulneravel())
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
	get_tree().current_scene.add_child(petala, true)
	petala.configurar(
		global_position + direcao * 38.0,
		direcao,
		Dano * 0.54,
		315.0 + fase * 25.0,
		400.0 + fase * 35.0,
		indice,
		self
	)
	if Rede.modo_multiplayer and multiplayer.is_server():
		_replicar_petala_boss.rpc(
			petala.global_position, direcao, Dano * 0.54,
			315.0 + fase * 25.0, 400.0 + fase * 35.0, indice
		)
	petala.retornou.connect(_on_petala_retornou)
	petalas_lancadas.append(petala)
	petalas_em_voo += 1


func processar_petalas(delta: float) -> void:
	velocity = Vector2.ZERO
	tempo_estado -= delta
	if petalas_em_voo <= 0:
		iniciar_recuperacao(0.80, false)
	elif tempo_estado <= 0.0:
		cancelar_petalas_restantes()
		iniciar_recuperacao(0.80, false)


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
	velocidade_inicio_giro = 0.0
	progresso_giro = 0.0
	flexao_vinhas = 0.0
	velocidade_vinhas_alvo = _velocidade_base_vinhas() * randf_range(0.88, 1.15) * sentido_vinhas
	_agendar_intervalo_vinhas()
	inversao_vinhas_pendente = false


func ir_ao_centro(_delta: float) -> void:
	var centro := Global.obter_centro_area_visivel()
	var distancia := global_position.distance_to(centro)
	if distancia <= 7.0:
		global_position = centro
		velocity = Vector2.ZERO
		estado = Estado.AVISANDO_VINHAS
		tempo_estado = tempo_aviso_vinhas
		aviso_vinhas.rotation = visual.rotation
		aviso_vinhas.visible = true
		return
	velocity = global_position.direction_to(centro) * minf(260.0, distancia * 2.2)


func avisar_vinhas(delta: float) -> void:
	velocity = Vector2.ZERO
	aviso_vinhas.modulate.a = 0.28 + absf(sin(Global.tempo_combate_ms() * 0.021)) * 0.70
	visual.rotation += 0.34 * sentido_rotacao * delta
	# O aviso acompanha exatamente o ângulo que será entregue ao pivô real.
	aviso_vinhas.rotation = visual.rotation
	tempo_estado -= delta
	if tempo_estado <= 0.0:
		aviso_vinhas.visible = false
		criar_vinhas()
		estado = Estado.CRESCENDO_VINHAS
		tempo_estado = 0.82


func criar_vinhas() -> void:
	limpar_vinhas()
	# Aviso e ataque compartilham o mesmo ângulo e o mesmo comprimento.
	vinhas_pivot.rotation = aviso_vinhas.rotation
	for indice in 4:
		var vinha := VINHA.instantiate() as VinhaEspinhosa
		vinha.name = "VinhaRede%d" % indice
		vinhas_pivot.add_child(vinha)
		vinha.rotation = float(indice) * PI * 0.5
		vinha.configurar(COMPRIMENTO_VINHA, Dano * 0.58)
		vinha.iniciar_crescimento(0.70)
		vinhas_ativas.append(vinha)


@rpc("authority", "call_remote", "reliable")
func _replicar_petala_boss(
	posicao: Vector2,
	direcao: Vector2,
	dano: float,
	velocidade: float,
	velocidade_retorno: float,
	indice: int
) -> void:
	if multiplayer.is_server():
		return
	var sprite := petalas.get_node_or_null("Petala%d" % indice) as Sprite2D
	if is_instance_valid(sprite):
		sprite.visible = false
	var petala := PETALA_BUMERANGUE.instantiate() as PetalaBumerangue
	petala.name = "PetalaRede%d_%d" % [indice, Time.get_ticks_usec()]
	get_tree().current_scene.add_child(petala, true)
	petala.configurar(posicao, direcao, dano, velocidade, velocidade_retorno, indice, self)
	petala.set_meta("apenas_visual_rede", true)
	petala.collision_layer = 0
	petala.collision_mask = 0
	petala.monitoring = false
	petala.monitorable = false
	petala.retornou.connect(_on_petala_retornou)


func _capturar_snapshot_visual_boss(seq: int = 0) -> Dictionary:
	var pacote := super._capturar_snapshot_visual_boss(seq)
	if not vinhas_ativas.is_empty() and is_instance_valid(vinhas_ativas[0]):
		pacote["vinhas"] = [vinhas_pivot.rotation, velocidade_vinhas_atual, flexao_vinhas, vinhas_ativas[0].progresso_crescimento]
	return pacote


@rpc("authority", "call_remote", "unreliable_ordered", 0)
func _aplicar_snapshot_visual_boss(pacote: Dictionary) -> void:
	if multiplayer.is_server() or int(pacote.get("sequencia", 0)) <= ultima_sequencia_snapshot_visual_rede:
		return
	var angulo_anterior := vinhas_pivot.rotation
	super._aplicar_snapshot_visual_boss(pacote)
	if not pacote.has("vinhas"):
		if not vinhas_ativas.is_empty():
			encerrar_vinhas()
		return
	var dados: Array = pacote.vinhas
	var nova := vinhas_ativas.is_empty()
	if nova:
		criar_vinhas()
	angulo_replica = dados[0]
	velocidade_vinhas_atual = dados[1]
	flexao_replica = dados[2]
	if nova:
		flexao_vinhas = flexao_replica
	previsao_vinhas = 0.0
	vinhas_pivot.rotation = angulo_replica if nova else angulo_anterior
	for vinha in vinhas_ativas:
		vinha.progresso_crescimento = maxf(vinha.progresso_crescimento, dados[3])


func _process(delta: float) -> void:
	super._process(delta)
	if Rede.modo_multiplayer and not multiplayer.is_server() and not vinhas_ativas.is_empty():
		previsao_vinhas = minf(previsao_vinhas + delta, 0.12)
		var previsto := angulo_replica + velocidade_vinhas_atual * previsao_vinhas
		var peso := 1.0 - exp(-30.0 * delta)
		vinhas_pivot.rotation = lerp_angle(vinhas_pivot.rotation, previsto, peso)
		flexao_vinhas = lerpf(flexao_vinhas, flexao_replica, peso)
		for vinha in vinhas_ativas:
			vinha.aplicar_curva(flexao_vinhas)


func crescer_vinhas(delta: float) -> void:
	velocity = Vector2.ZERO
	tempo_estado -= delta
	if tempo_estado <= 0.0:
		for vinha in vinhas_ativas:
			if is_instance_valid(vinha):
				vinha.ativar_dano()
		estado = Estado.DANCA_VINHAS
		# Cinco segundos extras em todas as fases: a ameaça dura o bastante para
		# exigir acompanhamento, com mudanças suaves porém não memorizáveis.
		tempo_estado = 9.0 + fase * 0.5


func processar_danca_vinhas(delta: float) -> void:
	velocity = Vector2.ZERO
	tempo_mudar_sentido_vinhas -= delta
	if tempo_mudar_sentido_vinhas <= 0.0:
		_sortear_proximo_movimento_vinhas()
	# A base freia antes de inverter. A ponta conserva a curva do giro anterior.
	progresso_giro = minf(progresso_giro + delta / (1.12 - fase * 0.09), 1.0)
	velocidade_vinhas_atual = lerpf(velocidade_inicio_giro, velocidade_vinhas_alvo, smoothstep(0.0, 1.0, progresso_giro))
	var flexao_alvo := -velocidade_vinhas_atual * 0.36
	flexao_vinhas = lerpf(flexao_vinhas, flexao_alvo, 1.0 - exp(-4.0 * delta))
	for vinha in vinhas_ativas:
		vinha.aplicar_curva(flexao_vinhas)
	visual.rotation += velocidade_vinhas_atual * delta
	vinhas_pivot.rotation += velocidade_vinhas_atual * delta
	tempo_estado -= delta
	if tempo_estado <= 0.0:
		encerrar_vinhas()
		iniciar_recuperacao(1.0)


func _velocidade_base_vinhas() -> float:
	return 0.58 + fase * 0.14


func _agendar_intervalo_vinhas() -> void:
	var minimo := maxf(1.45 - float(fase - 1) * 0.24, 0.82)
	var maximo := maxf(2.35 - float(fase - 1) * 0.38, 1.32)
	tempo_mudar_sentido_vinhas = randf_range(minimo, maximo)


func _sortear_proximo_movimento_vinhas(forcar_inversao: bool = false) -> void:
	velocidade_inicio_giro = velocidade_vinhas_atual
	progresso_giro = 0.0
	var velocidade_base := _velocidade_base_vinhas()
	# Em alguns momentos a vinha apenas desacelera, criando uma finta curta.
	# A próxima mudança obrigatoriamente completa a inversão prometida.
	if not forcar_inversao and not inversao_vinhas_pendente and randf() < 0.24:
		velocidade_vinhas_alvo = sentido_vinhas * velocidade_base * randf_range(0.12, 0.28)
		tempo_mudar_sentido_vinhas = randf_range(0.34, 0.62)
		inversao_vinhas_pendente = true
		return

	sentido_vinhas *= -1.0
	velocidade_vinhas_alvo = sentido_vinhas * velocidade_base * randf_range(0.84, 1.24)
	inversao_vinhas_pendente = false
	_agendar_intervalo_vinhas()


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


func iniciar_recuperacao(duracao: float, abrir_vulnerabilidade := true) -> void:
	estado = Estado.RECUPERANDO
	tempo_estado = duracao
	velocity = Vector2.ZERO
	if abrir_vulnerabilidade:
		tempo_estado = maxf(duracao, _duracao_janela_vulneravel())
		abrir_janela_vulneravel(tempo_estado)
	elif tempo_janela_vulneravel > 0.0:
		tempo_estado = maxf(duracao, tempo_janela_vulneravel)
	else:
		ativar_escudo(true)


func processar_recuperacao(delta: float) -> void:
	velocity = Vector2.ZERO
	petalas.rotation += 0.18 * sentido_rotacao * delta
	espinhos_ornamentais.rotation = petalas.rotation
	tempo_estado -= delta
	if tempo_estado <= 0.0:
		ativar_escudo(true)
		estado = Estado.MOVENDO
		tempo_ataque = maxf(intervalo_ataques - float(fase - 1) * 0.10, 0.72)


func _duracao_janela_vulneravel() -> float:
	return clampf(janela_vulneravel_base - float(fase - 1) * 0.75, 1.5, 3.0)


func abrir_janela_vulneravel(duracao: float) -> void:
	tempo_janela_vulneravel = maxf(duracao, 0.05)
	ativar_escudo(false)


func processar_janela_vulneravel(delta: float) -> void:
	if escudo_ativo or tempo_janela_vulneravel <= 0.0:
		return
	tempo_janela_vulneravel -= delta
	if tempo_janela_vulneravel <= 0.0:
		ativar_escudo(true)


func ativar_escudo(ativar: bool) -> void:
	escudo_ativo = ativar
	if ativar:
		tempo_janela_vulneravel = 0.0
	multiplicador_dano_recebido = 0.0 if ativar else 1.0
	polen.visible = ativar
	polen.emitting = ativar
	if ativar:
		polen.restart()


func tomarDano(valor: float) -> void:
	if Rede.modo_multiplayer and not multiplayer.is_server():
		_solicitar_dano_ao_host.rpc_id(1, clampf(valor, 0.0, 10000.0))
		return
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


func configurar_aviso_vinhas() -> void:
	var nomes: Array[StringName] = [&"Direita", &"Baixo", &"Esquerda", &"Cima"]
	for indice in nomes.size():
		var linha := aviso_vinhas.get_node_or_null(NodePath(str(nomes[indice]))) as Line2D
		if not is_instance_valid(linha):
			continue
		var direcao := Vector2.RIGHT.rotated(float(indice) * PI * 0.5)
		linha.points = PackedVector2Array([Vector2.ZERO, direcao * COMPRIMENTO_VINHA])


func ao_colidir_com_player(alvo: Node) -> void:
	if alvo.has_method("tomar_dano"):
		alvo.tomar_dano(Dano * 0.42, global_position)


func morrer() -> void:
	if Rede.modo_multiplayer and not multiplayer.is_server():
		return
	if morto or Vida > 0.0:
		return
	set_meta("som_morte_personalizado", true)
	preload("res://Scripts/AudioCombate.gd").tocar_posicional(
		get_tree().current_scene,
		global_position,
		&"morte_flor",
		0.0,
		0.94,
		1.06,
		-1.5
	)
	cancelar_petalas_restantes()
	limpar_vinhas()
	for node in get_tree().get_nodes_in_group("projetil_primaveril"):
		if is_instance_valid(node):
			node.queue_free()
	super.morrer()

