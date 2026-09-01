extends InimigoBase
class_name BossSizigiaEterna


const ProjetilAstralCena = preload("res://Scripts/ProjetilAstral.gd")
const RaioAstralCena = preload("res://Scripts/RaioAstral.gd")
const PerigoAstralCena = preload("res://Scripts/PerigoAstral.gd")
const OrbeAstralCena = preload("res://Scripts/OrbeAstral.gd")
const IndicadorGravitacionalCena = preload("res://Scripts/IndicadorGravitacional.gd")
const SHADER_TRANSICAO = preload("res://FX/eclipse_transicao.gdshader")


signal fase_alterada(fase: int)
signal subtitulo_alterado(texto: String)


enum Fase {
	LUA = 1,
	SOL = 2,
	ECLIPSE = 3,
}

enum Estado {
	MOVENDO,
	AVISANDO,
	INVESTINDO,
	RECUPERANDO,
	TRANSICAO,
}


const VIDA_BASE_FASES := [330.0, 390.0, 520.0]
const CENTRO_FUSAO := Vector2(480.0, 188.0)
const CORES_FASES := [
	Color(0.58, 0.72, 1.0),
	Color(1.0, 0.56, 0.12),
	Color(0.88, 0.42, 1.0),
]


var fase_atual := Fase.LUA
var estado := Estado.MOVENDO
var vidas_fases := VIDA_BASE_FASES.duplicate()
var dificuldade_atual := 1
var tempo_ataque := 1.8
var tempo_estado := 0.0
var tempo_contato := 0.0
var ultimo_ataque := -1
var gravidade_tempo := 0.0
var gravidade_sinal := 1.0
var direcao_investida := Vector2.LEFT
var token_acao := 0
var token_transicao := 0
var progresso_fusao := 0.0
var overlay_transicao: CanvasLayer
var material_transicao: ShaderMaterial
var invulnerabilidade_anterior := false


func _ready() -> void:
	super._ready()
	add_to_group("boss_sizigia")
	VidaMaxima = vidas_fases[0]
	Vida = VidaMaxima
	escala_base_impacto = scale
	atualizar_colisao(46.0)
	vida_alterada.emit(Vida, VidaMaxima)
	queue_redraw()


func configurar_dificuldade(nivel_dificuldade: int) -> void:
	dificuldade_atual = maxi(nivel_dificuldade, 1)
	var fator_vida := 1.0 + float(dificuldade_atual - 1) * 0.16
	var fator_dano := 1.0 + float(dificuldade_atual - 1) * 0.09
	vidas_fases = []
	for vida_base in VIDA_BASE_FASES:
		vidas_fases.append(float(vida_base) * fator_vida)
	Dano = 34.0 * fator_dano
	VidaMaxima = vidas_fases[fase_atual - 1]
	Vida = VidaMaxima
	vida_alterada.emit(Vida, VidaMaxima)


func obter_vida_maxima_atual() -> float:
	return vidas_fases[fase_atual - 1]


func obter_nome_boss() -> String:
	match fase_atual:
		Fase.LUA:
			return "LUA DA SIZÍGIA"
		Fase.SOL:
			return "SOL DA SIZÍGIA"
		_:
			return "SIZÍGIA ETERNA — ECLIPSE ABSOLUTO"


func obter_subtitulo_boss() -> String:
	match fase_atual:
		Fase.LUA:
			return "MARÉS, CRATERAS E A FACE OCULTA"
		Fase.SOL:
			return "CORONA INCANDESCENTE — QUEIMADURA NÃO ACUMULA"
		_:
			return "TOTALIDADE — SOBREVIVA À UNIÃO DOS ASTROS"


func obter_cor_fase() -> Color:
	return CORES_FASES[fase_atual - 1]


func tomarDano(valor: float) -> void:
	if morto or estado == Estado.TRANSICAO or valor <= 0.0:
		return
	var dano_final := maxf(valor * multiplicador_dano_recebido, 0.0)
	Vida = maxf(Vida - dano_final, 0.0)
	vida_alterada.emit(Vida, obter_vida_maxima_atual())
	reproduzir_impacto()
	if Vida > 0.0:
		return
	if fase_atual < Fase.ECLIPSE:
		iniciar_transicao(fase_atual + 1)
	else:
		limpar_ataques_astrais()
		remover_overlay_transicao()
		super.morrer()


func Mover(delta: float) -> void:
	atualizar_contato(delta)
	atualizar_gravidade(delta)
	if estado == Estado.TRANSICAO:
		velocity = velocity.move_toward(Vector2.ZERO, 520.0 * delta)
		queue_redraw()
		return
	if estado == Estado.AVISANDO:
		velocity = velocity.move_toward(Vector2.ZERO, 450.0 * delta)
		tempo_estado -= delta
		queue_redraw()
		return
	if estado == Estado.INVESTINDO:
		velocity = direcao_investida * (560.0 if fase_atual == Fase.SOL else 620.0)
		criar_rastro_investida(delta)
		tempo_estado -= delta
		if tempo_estado <= 0.0:
			estado = Estado.RECUPERANDO
			tempo_estado = 0.55
		queue_redraw()
		return
	if estado == Estado.RECUPERANDO:
		velocity = velocity.move_toward(Vector2.ZERO, 720.0 * delta)
		tempo_estado -= delta
		if tempo_estado <= 0.0:
			estado = Estado.MOVENDO
		queue_redraw()
		return

	if is_instance_valid(player):
		var direcao_player := global_position.direction_to(player.global_position)
		var distancia := global_position.distance_to(player.global_position)
		var alvo_distancia := 280.0 if fase_atual == Fase.LUA else 235.0
		var fator := 1.0 if distancia > alvo_distancia else -0.58
		var tangente := direcao_player.rotated(PI * 0.5) * sin(Time.get_ticks_msec() * 0.0016)
		velocity = (direcao_player * fator + tangente * 0.52).normalized() * Velocidade
	else:
		velocity = velocity.move_toward(Vector2.ZERO, Velocidade * delta)

	tempo_ataque -= delta
	if tempo_ataque <= 0.0:
		escolher_ataque()
	queue_redraw()


func atualizar_contato(delta: float) -> void:
	tempo_contato = maxf(tempo_contato - delta, 0.0)
	if not is_instance_valid(player) or tempo_contato > 0.0:
		return
	var raio_contato := 76.0 if fase_atual == Fase.ECLIPSE else 67.0
	if global_position.distance_to(player.global_position) <= raio_contato:
		tempo_contato = 0.85
		if player.has_method("tomar_dano"):
			player.tomar_dano(Dano * 0.56)
		if fase_atual >= Fase.SOL and player.has_method("aplicar_queimadura"):
			player.aplicar_queimadura(Dano * 0.24, 2.7)


func atualizar_gravidade(delta: float) -> void:
	gravidade_tempo = maxf(gravidade_tempo - delta, 0.0)
	if gravidade_tempo <= 0.0 or not is_instance_valid(player):
		return
	var direcao = player.global_position.direction_to(global_position) * gravidade_sinal
	var impulso := 150.0 if fase_atual == Fase.LUA else 205.0
	player.velocity += direcao * impulso * delta
	player.velocity = player.velocity.limit_length(720.0)


func escolher_ataque() -> void:
	var total := 5 if fase_atual < Fase.ECLIPSE else 6
	var escolha := randi_range(0, total - 1)
	if escolha == ultimo_ataque:
		escolha = (escolha + randi_range(1, total - 1)) % total
	ultimo_ataque = escolha
	var frenesi := fase_atual == Fase.ECLIPSE and Vida <= obter_vida_maxima_atual() * 0.25
	tempo_ataque = (1.28 if frenesi else 1.72) + randf_range(0.12, 0.48)
	if fase_atual == Fase.LUA:
		executar_ataque_lua(escolha)
	elif fase_atual == Fase.SOL:
		executar_ataque_sol(escolha)
	else:
		executar_ataque_eclipse(escolha, frenesi)


func executar_ataque_lua(indice: int) -> void:
	match indice:
		0:
			anunciar_ataque("CRESCENTES LUNARES — ATRAVESSE AS ABERTURAS")
			lancar_crescentes(4, 0.21, false, false)
		1:
			ativar_mare_gravitacional()
		2:
			anunciar_ataque("CHUVA DE CRATERAS — SAIA DOS ALVOS MARCADOS")
			criar_chuva_meteoros(5, Color(0.52, 0.68, 1.0), Dano * 0.42)
		3:
			anunciar_ataque("PRISÃO CRESCENTE — PROCURE A LACUNA AZUL")
			criar_prisao_crescente()
		_:
			anunciar_ataque("FACE OCULTA — PERMANEÇA NO CORREDOR CLARO")
			criar_umbra(4.2, Dano * 0.22, 0.14)


func executar_ataque_sol(indice: int) -> void:
	match indice:
		0:
			anunciar_ataque("INVESTIDA SOLAR — SAIA DA LINHA VERMELHA")
			iniciar_investida_solar()
		1:
			anunciar_ataque("RAIO SOLAR — A MIRA TRAVA ANTES DO DISPARO")
			criar_raio_solar(false)
		2:
			anunciar_ataque("PROMINÊNCIAS — CHAMAS CURVAS EM ALTERNÂNCIA")
			lancar_prominencias(10)
		3:
			anunciar_ataque("CORONA — ATRAVESSE SOMENTE PELA LACUNA")
			criar_corona(3, false)
		_:
			anunciar_ataque("MANCHAS SOLARES — DESTRUA-AS ANTES DA EXPLOSÃO")
			criar_manchas_solares(3)


func executar_ataque_eclipse(indice: int, frenesi: bool) -> void:
	match indice:
		0:
			anunciar_ataque("CRESCENTES INCENDIÁRIOS — ELES RETORNAM")
			lancar_crescentes(6 if frenesi else 5, 0.17, true, true)
		1:
			ativar_gravidade_eclipse()
			criar_raio_solar(true)
		2:
			anunciar_ataque("UMBRA TOTAL — SIGA O CORREDOR DE LUZ")
			criar_umbra(5.0, Dano * 0.24, 0.29)
		3:
			anunciar_ataque("FRATURA DA CORONA — ONDAS ALTERNADAS")
			criar_corona(5 if frenesi else 4, true)
		4:
			anunciar_ataque("REFLEXOS ASTRAIS — ATAQUE VINDO DOS DOIS LADOS")
			criar_reflexos_astrais(frenesi)
		_:
			anunciar_ataque("TOTALIDADE — SOBREVIVA E LEIA OS MARCADORES")
			iniciar_totalidade(frenesi)


func anunciar_ataque(texto: String) -> void:
	subtitulo_alterado.emit(texto)
	var cena := get_tree().current_scene
	if is_instance_valid(cena):
		EfeitoCombateCena.criar(
			cena,
			global_position,
			EfeitoCombate.Tipo.AVISO,
			obter_cor_fase(),
			1.18
		)


func lancar_crescentes(quantidade: int, abertura: float, em_chamas: bool, boomerang: bool) -> void:
	if not is_instance_valid(player):
		return
	tempo_ataque = maxf(tempo_ataque, 2.45 if boomerang else 2.05)
	var base := global_position.direction_to(player.global_position).angle()
	for indice in quantidade:
		var desloc := (float(indice) - float(quantidade - 1) * 0.5) * abertura
		var proj := ProjetilAstralCena.new() as ProjetilAstral
		get_tree().current_scene.add_child(proj)
		proj.configurar(
			global_position,
			Vector2.from_angle(base + desloc),
			Dano * (0.30 if quantidade >= 5 else 0.34),
			285.0 if em_chamas else 245.0,
			Color(1.0, 0.42, 0.12) if em_chamas else Color(0.62, 0.78, 1.0),
			ProjetilAstral.Tipo.CRESCENTE,
			desloc * 0.18,
			self,
			boomerang,
			Dano * 0.18 if em_chamas else 0.0,
			2.4
		)


func ativar_mare_gravitacional() -> void:
	gravidade_tempo = 3.8
	gravidade_sinal *= -1.0
	tempo_ataque = maxf(tempo_ataque, 4.45)
	anunciar_ataque(
		"MARÉ GRAVITACIONAL — PUXÃO PARA O CENTRO"
		if gravidade_sinal > 0.0
		else "MARÉ GRAVITACIONAL — REPULSÃO PARA FORA"
	)
	criar_campo_gravitacional(gravidade_tempo)
	criar_corona(2, gravidade_sinal < 0.0)
	criar_chuva_meteoros(3, Color(0.48, 0.66, 1.0), Dano * 0.34)


func ativar_gravidade_eclipse() -> void:
	gravidade_tempo = 3.35
	gravidade_sinal = 1.0
	tempo_ataque = maxf(tempo_ataque, 4.2)
	anunciar_ataque("SINGULARIDADE SOLAR — O CAMPO PUXA E O RAIO TRAVA")
	criar_campo_gravitacional(gravidade_tempo)


func criar_campo_gravitacional(duracao: float) -> void:
	var campo := IndicadorGravitacionalCena.new() as IndicadorGravitacional
	get_tree().current_scene.add_child(campo)
	campo.configurar(self, gravidade_sinal, duracao)


func criar_chuva_meteoros(quantidade: int, nova_cor: Color, novo_dano: float) -> void:
	if not is_instance_valid(player):
		return
	tempo_ataque = maxf(tempo_ataque, 2.65)
	for indice in quantidade:
		var perigo := PerigoAstralCena.new() as PerigoAstral
		get_tree().current_scene.add_child(perigo)
		var antecipacao = player.velocity * (0.18 + indice * 0.035)
		var desloc := Vector2(randf_range(-160.0, 160.0), randf_range(-120.0, 120.0))
		perigo.configurar_meteoro(player.global_position + antecipacao + desloc, novo_dano, nova_cor, 1.12 + indice * 0.10, 58.0)


func criar_prisao_crescente() -> void:
	tempo_ataque = maxf(tempo_ataque, 3.15)
	var centro = player.global_position if is_instance_valid(player) else Vector2(480.0, 270.0)
	for indice in 3:
		var onda := PerigoAstralCena.new() as PerigoAstral
		get_tree().current_scene.add_child(onda)
		onda.configurar_onda(centro, Dano * 0.34, Color(0.58, 0.74, 1.0), 250.0 + indice * 55.0, 35.0, 1.45 + indice * 0.18, randf_range(-PI, PI), 0.72)


func criar_umbra(duracao: float, novo_dano: float, velocidade: float) -> void:
	tempo_ataque = maxf(tempo_ataque, duracao + 0.45)
	var umbra := PerigoAstralCena.new() as PerigoAstral
	get_tree().current_scene.add_child(umbra)
	umbra.configurar_umbra(Vector2(480.0, 270.0), novo_dano, duracao, randf_range(-PI, PI), velocidade)


func iniciar_investida_solar() -> void:
	if not is_instance_valid(player):
		return
	token_acao += 1
	var token := token_acao
	direcao_investida = global_position.direction_to(player.global_position)
	tempo_ataque = maxf(tempo_ataque, 2.65)
	estado = Estado.AVISANDO
	tempo_estado = 0.72
	_ativar_investida_depois(token, fase_atual)


func _ativar_investida_depois(token: int, fase_esperada: int) -> void:
	await get_tree().create_timer(0.72).timeout
	if morto or token != token_acao or fase_atual != fase_esperada or estado == Estado.TRANSICAO:
		return
	estado = Estado.INVESTINDO
	tempo_estado = 0.82
	Global.vibrar_controle(0.5, 0.85, 0.13)


func criar_rastro_investida(delta: float) -> void:
	if randf() > delta * 22.0:
		return
	EfeitoCombateCena.criar(get_tree().current_scene, global_position - direcao_investida * 42.0, EfeitoCombate.Tipo.RASTRO, Color(1.0, 0.36, 0.08), 1.0, -direcao_investida)


func criar_raio_solar(eclipse: bool) -> void:
	if not is_instance_valid(player):
		return
	var raio := RaioAstralCena.new() as RaioAstral
	tempo_ataque = maxf(tempo_ataque, 2.8 if eclipse else 2.65)
	get_tree().current_scene.add_child(raio)
	raio.configurar(self, global_position.direction_to(player.global_position), Dano * (0.70 if eclipse else 0.66), Color(1.0, 0.34, 0.12) if eclipse else Color(1.0, 0.74, 0.18), 1.12 if eclipse else 1.28, 0.36, 38.0 if eclipse else 32.0, true, 0.10 if eclipse else 0.0, Dano * 0.23, 2.7)


func lancar_prominencias(quantidade: int) -> void:
	tempo_ataque = maxf(tempo_ataque, 2.35)
	var base := global_position.direction_to(player.global_position).angle() if is_instance_valid(player) else 0.0
	for indice in quantidade:
		var proj := ProjetilAstralCena.new() as ProjetilAstral
		get_tree().current_scene.add_child(proj)
		var lateral := -1.0 if indice % 2 == 0 else 1.0
		var angulo := base + (float(indice) - quantidade * 0.5) * 0.14
		proj.configurar(global_position, Vector2.from_angle(angulo), Dano * 0.25, 250.0, Color(1.0, 0.43, 0.08), ProjetilAstral.Tipo.FOGO, lateral * 0.62, self, false, Dano * 0.16, 2.4)


func criar_corona(quantidade: int, alternar_sentido: bool) -> void:
	tempo_ataque = maxf(tempo_ataque, 2.4 + quantidade * 0.32)
	for indice in quantidade:
		var onda := PerigoAstralCena.new() as PerigoAstral
		get_tree().current_scene.add_child(onda)
		var contrair := alternar_sentido and indice % 2 == 1
		var inicio := 720.0 if contrair else 40.0
		var fim := 40.0 if contrair else 720.0
		onda.configurar_onda(global_position, Dano * 0.38, obter_cor_fase(), inicio, fim, 1.22 + indice * 0.22, randf_range(-PI, PI), 0.64)


func criar_manchas_solares(quantidade: int) -> void:
	tempo_ataque = maxf(tempo_ataque, 4.0)
	for indice in quantidade:
		var orbe := OrbeAstralCena.new() as OrbeAstral
		get_tree().current_scene.add_child(orbe)
		orbe.configurar(self, TAU * indice / quantidade, Dano * 0.27)


func criar_reflexos_astrais(frenesi: bool) -> void:
	tempo_ataque = maxf(tempo_ataque, 2.75)
	var origens := [Vector2(155.0, 110.0), Vector2(805.0, 430.0)]
	var quantidade := 6 if frenesi else 4
	for origem in origens:
		var direcao_base = origem.direction_to(player.global_position) if is_instance_valid(player) else Vector2.RIGHT
		for indice in quantidade:
			var proj := ProjetilAstralCena.new() as ProjetilAstral
			get_tree().current_scene.add_child(proj)
			var desloc := (indice - (quantidade - 1) * 0.5) * 0.18
			proj.configurar(origem, direcao_base.rotated(desloc), Dano * 0.27, 275.0, Color(0.88, 0.38, 1.0), ProjetilAstral.Tipo.CORONA, desloc * 0.16, self)


func iniciar_totalidade(frenesi: bool) -> void:
	tempo_ataque = maxf(tempo_ataque, 5.35)
	criar_umbra(4.3, Dano * 0.23, 0.34 if frenesi else 0.24)
	criar_chuva_meteoros(4 if frenesi else 3, Color(0.8, 0.32, 1.0), Dano * 0.36)
	criar_raio_totalidade_atrasado(fase_atual, 1.25)


func criar_raio_totalidade_atrasado(fase_esperada: int, atraso: float) -> void:
	await get_tree().create_timer(atraso).timeout
	if morto or fase_atual != fase_esperada or estado == Estado.TRANSICAO:
		return
	criar_raio_solar(true)


func iniciar_transicao(proxima_fase: int) -> void:
	token_transicao += 1
	token_acao += 1
	estado = Estado.TRANSICAO
	velocity = Vector2.ZERO
	limpar_ataques_astrais()
	curar_player_na_transicao()
	if proxima_fase == Fase.SOL:
		_transicao_para_sol(token_transicao)
	else:
		iniciar_cinematica_eclipse(token_transicao)


func _transicao_para_sol(token: int) -> void:
	progresso_fusao = 0.0
	await get_tree().create_timer(1.65).timeout
	if morto or token != token_transicao:
		return
	concluir_transicao_para_sol()


func concluir_transicao_para_sol() -> void:
	token_transicao += 1
	fase_atual = Fase.SOL
	VidaMaxima = vidas_fases[1]
	Vida = VidaMaxima
	Velocidade = 118.0
	atualizar_colisao(53.0)
	estado = Estado.MOVENDO
	tempo_ataque = 1.35
	ultimo_ataque = -1
	fase_alterada.emit(fase_atual)
	subtitulo_alterado.emit(obter_subtitulo_boss())
	vida_alterada.emit(Vida, VidaMaxima)
	queue_redraw()


func iniciar_cinematica_eclipse(token: int) -> void:
	progresso_fusao = 0.0
	proteger_player(true)
	var movimento := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	movimento.tween_property(self, "global_position", CENTRO_FUSAO, 0.85)
	await movimento.finished
	if morto or token != token_transicao:
		return
	global_position = CENTRO_FUSAO
	criar_overlay_transicao()
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.set_parallel(true)
	tween.tween_property(self, "progresso_fusao", 1.0, 3.25)
	if is_instance_valid(material_transicao):
		tween.tween_method(atualizar_progresso_shader, 0.0, 1.0, 3.25)
		tween.tween_method(atualizar_escuridao_shader, 0.0, 0.88, 2.5)
	var tween_silhueta := create_tween()
	tween_silhueta.tween_interval(2.12)
	tween_silhueta.tween_method(atualizar_silhueta_shader, 0.0, 1.0, 0.95)
	await get_tree().create_timer(3.35).timeout
	if morto or token != token_transicao:
		return
	Global.vibrar_controle(0.95, 1.0, 0.38)
	EfeitoCombateCena.criar(get_tree().current_scene, global_position, EfeitoCombate.Tipo.AVISO, Color(1.0, 0.45, 0.13), 2.4)
	await get_tree().create_timer(1.0).timeout
	if morto or token != token_transicao:
		return
	concluir_transicao_para_eclipse()


func concluir_transicao_para_eclipse() -> void:
	token_transicao += 1
	fase_atual = Fase.ECLIPSE
	VidaMaxima = vidas_fases[2]
	Vida = VidaMaxima
	Velocidade = 128.0
	atualizar_colisao(58.0)
	estado = Estado.MOVENDO
	tempo_ataque = 1.15
	ultimo_ataque = -1
	proteger_player(false)
	remover_overlay_transicao_gradual()
	fase_alterada.emit(fase_atual)
	subtitulo_alterado.emit(obter_subtitulo_boss())
	vida_alterada.emit(Vida, VidaMaxima)
	queue_redraw()


func curar_player_na_transicao() -> void:
	if not is_instance_valid(player) or not player.has_method("curar"):
		return
	var vida_maxima = player.get("VIDA_MAXIMA")
	if vida_maxima != null:
		player.curar(float(vida_maxima) * 0.10)


func proteger_player(ativar: bool) -> void:
	if not is_instance_valid(player):
		return
	if ativar:
		invulnerabilidade_anterior = bool(player.get("invulneravel_por_habilidade"))
		player.set("invulneravel_por_habilidade", true)
	else:
		player.set("invulneravel_por_habilidade", invulnerabilidade_anterior)


func criar_overlay_transicao() -> void:
	remover_overlay_transicao()
	overlay_transicao = CanvasLayer.new()
	overlay_transicao.layer = 70
	get_tree().current_scene.add_child(overlay_transicao)
	var tela := ColorRect.new()
	tela.mouse_filter = Control.MOUSE_FILTER_IGNORE
	material_transicao = ShaderMaterial.new()
	material_transicao.shader = SHADER_TRANSICAO
	material_transicao.set_shader_parameter("centro", Vector2(0.5, 188.0 / 540.0))
	tela.material = material_transicao
	overlay_transicao.add_child(tela)
	tela.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	atualizar_progresso_shader(0.0)
	atualizar_escuridao_shader(0.0)
	atualizar_silhueta_shader(0.0)


func atualizar_progresso_shader(valor: float) -> void:
	if is_instance_valid(material_transicao):
		material_transicao.set_shader_parameter("progresso", valor)


func atualizar_escuridao_shader(valor: float) -> void:
	if is_instance_valid(material_transicao):
		material_transicao.set_shader_parameter("escuridao", valor)


func atualizar_silhueta_shader(valor: float) -> void:
	if is_instance_valid(material_transicao):
		material_transicao.set_shader_parameter("silhueta", valor)


func remover_overlay_transicao_gradual() -> void:
	if not is_instance_valid(overlay_transicao):
		return
	var camada := overlay_transicao
	var tela := camada.get_child(0) as ColorRect
	var tween := create_tween()
	if is_instance_valid(tela):
		tween.tween_property(tela, "modulate:a", 0.0, 0.7)
	tween.tween_callback(camada.queue_free)
	overlay_transicao = null
	material_transicao = null


func remover_overlay_transicao() -> void:
	if is_instance_valid(overlay_transicao):
		overlay_transicao.queue_free()
	overlay_transicao = null
	material_transicao = null


func limpar_ataques_astrais() -> void:
	for grupo in [
		&"projetil_astral", &"raio_astral", &"perigo_astral",
		&"mancha_solar", &"campo_gravitacional"
	]:
		for node in get_tree().get_nodes_in_group(grupo):
			if is_instance_valid(node):
				node.queue_free()


func atualizar_colisao(raio: float) -> void:
	var forma := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if not is_instance_valid(forma):
		return
	var circulo := forma.shape as CircleShape2D
	if is_instance_valid(circulo):
		circulo.radius = raio


func morrer() -> void:
	if Vida > 0.0:
		return
	limpar_ataques_astrais()
	proteger_player(false)
	remover_overlay_transicao()
	super.morrer()


func _exit_tree() -> void:
	limpar_ataques_astrais()
	if fase_atual == Fase.ECLIPSE or estado == Estado.TRANSICAO:
		proteger_player(false)
	remover_overlay_transicao()


func _draw() -> void:
	if estado == Estado.TRANSICAO and Vida <= 0.0:
		if fase_atual == Fase.SOL:
			desenhar_fusao()
		else:
			desenhar_corpo_lua()
	else:
		match fase_atual:
			Fase.LUA:
				desenhar_corpo_lua()
			Fase.SOL:
				desenhar_corpo_sol()
			_:
				desenhar_corpo_eclipse()
	if estado == Estado.AVISANDO:
		var aviso := Color(1.0, 0.32, 0.08, 0.82)
		draw_dashed_line(Vector2.ZERO, direcao_investida * 850.0, aviso, 3.0, 14.0, true)


func desenhar_corpo_lua(posicao: Vector2 = Vector2.ZERO, escala: float = 1.0) -> void:
	var pulso := 1.0 + sin(Time.get_ticks_msec() * 0.0028) * 0.018
	draw_circle(posicao, 58.0 * escala * pulso, Color(0.46, 0.62, 1.0, 0.13))
	draw_circle(posicao, 46.0 * escala, Color(0.70, 0.79, 0.94))
	draw_circle(posicao + Vector2(16.0, -3.0) * escala, 43.0 * escala, Color(0.035, 0.05, 0.13))
	draw_arc(posicao, 47.0 * escala, 0.0, TAU, 52, Color(0.68, 0.84, 1.0), 3.0 * escala, true)
	for cratera in [Vector2(-18, -12), Vector2(-23, 16), Vector2(-7, 26)]:
		draw_circle(posicao + cratera * escala, 5.0 * escala, Color(0.38, 0.45, 0.62, 0.65))


func desenhar_corpo_sol(posicao: Vector2 = Vector2.ZERO, escala: float = 1.0) -> void:
	var tempo := Time.get_ticks_msec() * 0.001
	for indice in 16:
		var angulo := TAU * indice / 16.0 + tempo * 0.18
		var tamanho := 66.0 + sin(tempo * 2.1 + indice) * 7.0
		draw_line(posicao + Vector2.from_angle(angulo) * 51.0 * escala, posicao + Vector2.from_angle(angulo) * tamanho * escala, Color(1.0, 0.39, 0.08, 0.68), 4.0 * escala, true)
	draw_circle(posicao, 64.0 * escala, Color(1.0, 0.38, 0.05, 0.13))
	draw_circle(posicao, 52.0 * escala, Color(1.0, 0.52, 0.08))
	draw_circle(posicao, 39.0 * escala, Color(1.0, 0.83, 0.24))
	draw_circle(posicao - Vector2(10.0, 8.0) * escala, 9.0 * escala, Color(0.58, 0.12, 0.035, 0.65))
	draw_arc(posicao, 53.0 * escala, 0.0, TAU, 56, Color(1.0, 0.93, 0.48), 3.0 * escala, true)


func desenhar_corpo_eclipse(posicao: Vector2 = Vector2.ZERO, escala: float = 1.0) -> void:
	var tempo := Time.get_ticks_msec() * 0.001
	for indice in 22:
		var angulo := TAU * indice / 22.0 - tempo * 0.23
		var tamanho := 76.0 + sin(tempo * 2.8 + indice * 1.7) * 9.0
		draw_line(posicao + Vector2.from_angle(angulo) * 55.0 * escala, posicao + Vector2.from_angle(angulo) * tamanho * escala, Color(1.0, 0.31, 0.08, 0.72), 4.0 * escala, true)
	draw_circle(posicao, 72.0 * escala, Color(0.75, 0.25, 1.0, 0.13))
	draw_circle(posicao, 59.0 * escala, Color(1.0, 0.48, 0.08))
	draw_circle(posicao, 53.0 * escala, Color(0.008, 0.012, 0.035))
	draw_arc(posicao, 55.0 * escala, 0.0, TAU, 64, Color(1.0, 0.74, 0.23), 4.0 * escala, true)
	draw_arc(posicao, 48.0 * escala, -2.6, 0.75, 40, Color(0.48, 0.63, 1.0, 0.72), 2.0 * escala, true)


func desenhar_fusao() -> void:
	var distancia := lerpf(135.0, 0.0, progresso_fusao)
	var escala := lerpf(0.88, 1.0, progresso_fusao)
	if progresso_fusao < 0.80:
		desenhar_corpo_lua(Vector2(-distancia, 0.0), escala)
		desenhar_corpo_sol(Vector2(distancia, 0.0), escala)
	else:
		var alpha := clampf((progresso_fusao - 0.80) / 0.20, 0.0, 1.0)
		draw_circle(Vector2.ZERO, 58.0, Color(0.002, 0.004, 0.014, alpha))
		draw_arc(Vector2.ZERO, 59.0, -PI, 0.0, 40, Color(1.0, 0.34, 0.08, alpha), 5.0, true)
		draw_arc(Vector2.ZERO, 59.0, 0.0, PI, 40, Color(0.72, 0.38, 1.0, alpha), 5.0, true)
