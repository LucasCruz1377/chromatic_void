# CentelhaGuia: comportamento especifico, derivado diretamente de InimigoBase.
extends InimigoBase


enum Estilo { ESTILHACO, GUARDA, ECO, BROTO, ORBITAL, CENTELHA_GUIA, ELO_DOURADO, PRISMA_AMPARO, SATELITE_BERCO, PULSO_SOLAR, FITA_VIOLETA, NO_FLUTUANTE, ECO_AMETISTA, LAMINA_IRIS, CASULO_PRISMATICO, BROTO_PRIMAVERIL, SEMENTE_CANHAO, POLEN_ERRANTE, CIPO_ESPIRAL, FRUTO_EXPLOSIVO, FRAGMENTO_LUNAR, CENTELHA_SOLAR, METEORO_JOVEM, ECO_GRAVITACIONAL, SATELITE_COROA }

var estilo: Estilo = Estilo.CENTELHA_GUIA
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
var protegido: InimigoBase
var trilha := Vector2.ZERO
var tempo_trilha := 0.0
var aliado_movimento: InimigoBase
var tempo_busca_aliado := 0.0

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
	tempo += delta; tempo_trilha -= delta; _manter_vinculos()
	if player.velocity.length_squared() > 20.0: direcao_memorizada = player.velocity.normalized()
	if preparando:
		velocity = velocity.move_toward(Vector2.ZERO, 420.0 * delta); preparo -= delta
		if preparo <= 0.0: preparando = false; _executar(); recarga = intervalo_acao * randf_range(0.9, 1.12)
		_atualizar_desenho(delta); return
	var ate := global_position.direction_to(player.global_position)
	var distancia := global_position.distance_to(player.global_position)
	direcao = ate
	_mover_para_aliado(ate, distancia, delta)
	recarga -= delta
	if recarga <= 0.0: _preparar()
	_atualizar_desenho(delta)

func _atualizar_desenho(_delta: float) -> void:
	queue_redraw()

func _distancia(ate: Vector2, atual: float, ideal: float) -> Vector2:
	if atual < ideal - 35.0: return -ate
	if atual > ideal + 35.0: return ate
	return ate.orthogonal()

func _mover_para_aliado(ate: Vector2, distancia: float, delta: float) -> void:
	tempo_busca_aliado -= delta
	if not is_instance_valid(aliado_movimento) or tempo_busca_aliado <= 0.0:
		aliado_movimento = protegido if is_instance_valid(protegido) else _mais_proximo(false)
		tempo_busca_aliado = 0.28
	var aliado := aliado_movimento
	if is_instance_valid(aliado):
		var d := global_position.distance_to(aliado.global_position)
		velocity = velocity.move_toward(_distancia(global_position.direction_to(aliado.global_position), d, 105.0) * Velocidade, 250.0 * delta)
	else: velocity = velocity.move_toward(_distancia(ate, distancia, 290.0) * Velocidade, 210.0 * delta)

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
	EfeitoCombateCena.criar(cena, global_position, EfeitoCombate.Tipo.AVISO, cor_setor, 0.85, direcao)

func _executar() -> void:
	EfeitoCombateCena.criar(get_tree().current_scene, global_position, EfeitoCombate.Tipo.ACERTO, cor_setor, 0.55, direcao)
	_escudar()

func _escudar() -> void:
	protegido = _mais_proximo(false)
	if is_instance_valid(protegido): protegido.multiplicador_dano_recebido = 0.48; protegido.set_meta("escudo_guia", self)

func _manter_vinculos() -> void:
	if protegido != null and not is_instance_valid(protegido):
		protegido = null
	elif is_instance_valid(protegido) and global_position.distance_to(protegido.global_position)>185:
		_limpar_escudo()
	if parceiro != null and not is_instance_valid(parceiro):
		parceiro = null
	elif estilo == Estilo.NO_FLUTUANTE and is_instance_valid(parceiro) and global_position.distance_to(parceiro.global_position)>205:
		parceiro.multiplicador_dano_recebido=1.0; parceiro=null

func _limpar_escudo() -> void:
	if is_instance_valid(protegido) and protegido.has_meta("escudo_guia") and protegido.get_meta("escudo_guia")==self: protegido.multiplicador_dano_recebido=1.0; protegido.remove_meta("escudo_guia")
	protegido=null

func _mais_proximo(mesmo: bool) -> InimigoBase:
	var melhor: InimigoBase; var menor:=INF
	for n in get_tree().get_nodes_in_group("inimigo"):
		if n==self or not n is InimigoBase or n.is_in_group("boss") or n.is_queued_for_deletion() or n.morto: continue
		if mesmo and (not n.is_in_group("inimigo_setorial") or int(n.get_meta("tipo_setorial", -1)) != int(estilo)): continue
		var d:=global_position.distance_squared_to(n.global_position)
		if d<menor: menor=d; melhor=n
	return melhor

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
	_limpar_escudo()
	parceiro = null
	super.morrer()

func _draw()->void:
	var c:=cor_setor.lightened(0.1)
	draw_circle(Vector2.ZERO,8,c); draw_arc(Vector2.ZERO,17,0,TAU,24,c,3)
	# Núcleo e partículas de carga preservam a silhueta de cada espécie.
	draw_circle(Vector2.ZERO, 4.0, Color(0.03, 0.04, 0.10))
	draw_circle(direcao * 2.0, 1.8, Color.WHITE)
	if preparando:
		for i in 5:
			var ponto := Vector2.from_angle(float(i) * TAU / 5.0 + tempo) * (12.0 + maxf(preparo, 0.0) * 22.0)
			draw_circle(ponto, 2.0, cor_setor.lightened(0.4))
	if is_instance_valid(protegido):
		_desenhar_vinculo(protegido, "ESCUDO  •  -52% DANO", Color(1.0, 0.82, 0.24), true)
	if is_instance_valid(parceiro):
		if estilo == Estilo.ELO_DOURADO:
			_desenhar_vinculo(parceiro, "ELO  •  DANO COMPARTILHADO", Color(1.0, 0.72, 0.18), false)
		elif estilo == Estilo.NO_FLUTUANTE:
			_desenhar_vinculo(parceiro, "NÓ  •  RESISTÊNCIA", Color(0.82, 0.46, 1.0), true)
		elif estilo == Estilo.SATELITE_COROA:
			_desenhar_vinculo(parceiro, "FORMAÇÃO ORBITAL", Color(0.58, 0.72, 1.0), false)

func obter_descricao_vinculo() -> String:
	return "ESCUDO  •  -52% DANO"
	return ""

func _desenhar_vinculo(
	alvo: Node2D, texto: String, cor_vinculo: Color, desenhar_escudo: bool
) -> void:
	if not is_instance_valid(alvo):
		return
	texto = tr(texto)
	var fim := alvo.global_position - global_position
	draw_line(Vector2.ZERO, fim, Color(cor_vinculo, 0.22), 8.0, true)
	draw_line(Vector2.ZERO, fim, Color(cor_vinculo, 0.88), 2.5, true)
	for indice in 3:
		var progresso := fposmod(tempo * 0.72 + float(indice) / 3.0, 1.0)
		var ponto := fim * progresso
		draw_circle(ponto, 3.3, Color.WHITE)
		draw_circle(ponto, 6.0, Color(cor_vinculo, 0.25))
	if desenhar_escudo:
		var hexagono := PackedVector2Array()
		for indice in 6:
			hexagono.append(fim + Vector2.from_angle(float(indice) * TAU / 6.0) * 25.0)
		hexagono.append(hexagono[0])
		draw_polyline(hexagono, Color(cor_vinculo, 0.92), 3.0, true)
	var fonte := ThemeDB.fallback_font
	var tamanho_fonte := 9
	var medida := fonte.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho_fonte)
	var centro := fim * 0.5 + Vector2(0.0, -14.0)
	draw_rect(
		Rect2(centro - Vector2(medida.x * 0.5 + 5.0, 11.0), Vector2(medida.x + 10.0, 16.0)),
		Color(0.01, 0.015, 0.045, 0.84),
		true
	)
	draw_string(
		fonte, centro + Vector2(-medida.x * 0.5, 4.0), texto,
		HORIZONTAL_ALIGNMENT_LEFT, -1.0, tamanho_fonte, Color.WHITE
	)
