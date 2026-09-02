extends Node


class JogadorTeste extends CharacterBody2D:
	var nivel_atual := 20
	var vivo := true
	var vida := 100.0
	var VIDA_MAXIMA := 100.0
	var invulneravel_por_habilidade := false
	var dano_recebido := 0.0
	var queimadura_recebida := 0.0

	func _ready() -> void:
		add_to_group("player")

	func tomar_dano(valor: float) -> void:
		dano_recebido += valor
		vida = maxf(vida - valor, 0.0)

	func aplicar_queimadura(valor: float, _duracao: float) -> void:
		queimadura_recebida = maxf(queimadura_recebida, valor)

	func curar(valor: float) -> void:
		vida = minf(vida + valor, VIDA_MAXIMA)


var falhas: Array[String] = []


func verificar(condicao: bool, mensagem: String) -> void:
	if not condicao:
		falhas.append(mensagem)
		push_error("TESTE SIZÍGIA: " + mensagem)


func _ready() -> void:
	var jogador := JogadorTeste.new()
	add_child(jogador)
	jogador.global_position = Vector2(260.0, 270.0)
	await get_tree().process_frame

	var cena := load("res://Entities/BossEclipseColheita.tscn") as PackedScene
	verificar(cena != null, "a cena do boss não carregou")
	if cena == null:
		get_tree().quit(1)
		return
	var boss := cena.instantiate() as BossSizigiaEterna
	add_child(boss)
	boss.global_position = Vector2(700.0, 270.0)
	await get_tree().process_frame

	verificar(boss.fase_atual == BossSizigiaEterna.Fase.LUA, "a luta não começou na Lua")
	verificar(boss.visual_fase.texture == boss.TEXTURA_LUA, "a Lua 2 não foi aplicada ao boss")
	verificar(boss.obter_vida_maxima_atual() >= 330.0, "a vida da Lua está abaixo da meta")
	verificar(
		boss.CENTRO_FUSAO == Vector2(480.0, 188.0),
		"a fusão não está posicionada acima do centro da arena"
	)
	boss.ativar_mare_gravitacional()
	verificar(
		get_tree().get_nodes_in_group("campo_gravitacional").size() == 1,
		"a maré gravitacional não criou um indicador visível"
	)
	verificar(boss.tempo_ataque >= 4.4, "a maré permite sobreposição precoce de ataques")
	boss.limpar_ataques_astrais()
	await get_tree().process_frame
	boss.criar_chuva_meteoros(1, Color(0.52, 0.68, 1.0), 10.0)
	await get_tree().process_frame
	var perigos_meteoro := get_tree().get_nodes_in_group("perigo_astral")
	verificar(perigos_meteoro.size() == 1, "a chuva não criou o meteoro marcado")
	if perigos_meteoro.size() == 1:
		var meteoro := perigos_meteoro[0] as PerigoAstral
		verificar(is_instance_valid(meteoro.meteoro_visual), "o SVG do meteoro não apareceu durante a queda")
	boss.limpar_ataques_astrais()
	await get_tree().process_frame
	var vida_lua := boss.Vida
	boss.tomarDano(vida_lua + 999.0)
	verificar(boss.fase_atual == BossSizigiaEterna.Fase.LUA, "o dano excedente atravessou a primeira barra")
	verificar(boss.estado == BossSizigiaEterna.Estado.TRANSICAO, "a Lua não iniciou a transição")

	boss.concluir_transicao_para_sol()
	verificar(boss.fase_atual == BossSizigiaEterna.Fase.SOL, "a segunda fase não é o Sol")
	verificar(boss.visual_fase.texture == boss.TEXTURA_SOL, "o Sol 5 pontudo não foi aplicado ao boss")
	verificar(is_equal_approx(boss.Vida, boss.obter_vida_maxima_atual()), "o Sol não recebeu uma barra cheia independente")
	boss.lancar_crescentes(3, 0.2, false, false)
	verificar(get_tree().get_nodes_in_group("projetil_astral").size() == 3, "os crescentes lunares não foram criados")
	boss.limpar_ataques_astrais()
	await get_tree().process_frame
	boss.criar_raio_solar(false)
	verificar(get_tree().get_nodes_in_group("raio_astral").size() == 1, "o raio solar não foi criado")
	var raios := get_tree().get_nodes_in_group("raio_astral")
	if raios.size() == 1:
		var raio := raios[0] as RaioAstral
		verificar(raio.tempo_aviso >= 2.0, "o raio solar não oferece carga suficiente")
		verificar(raio.tempo_ativo <= 0.10, "o disparo do raio não é instantâneo")
	boss.limpar_ataques_astrais()
	await get_tree().process_frame

	boss.iniciar_transicao(BossSizigiaEterna.Fase.ECLIPSE)
	verificar(jogador.invulneravel_por_habilidade, "a cinemática não protegeu o jogador")
	boss.concluir_transicao_para_eclipse()
	verificar(boss.fase_atual == BossSizigiaEterna.Fase.ECLIPSE, "a terceira fase não é o Eclipse")
	verificar(boss.visual_fase.texture == boss.TEXTURA_ECLIPSE, "o Eclipse 01 não foi aplicado ao boss")
	verificar(not jogador.invulneravel_por_habilidade, "a proteção da cinemática não terminou")
	verificar(is_equal_approx(boss.Vida, boss.obter_vida_maxima_atual()), "o Eclipse não recebeu sua barra independente")
	boss.criar_corona(2, true)
	verificar(get_tree().get_nodes_in_group("perigo_astral").size() == 2, "a fratura da corona não foi criada")
	boss.limpar_ataques_astrais()
	await get_tree().process_frame

	var mortes := [0]
	boss.morreu.connect(func(_alvo: InimigoBase) -> void: mortes[0] += 1)
	boss.tomarDano(boss.Vida + 1.0)
	verificar(mortes[0] == 1, "o Eclipse final não concluiu a luta")

	if falhas.is_empty():
		print("TESTE OK: Sizígia Eterna, três barras e arsenal astral")
		get_tree().quit(0)
	else:
		print("TESTE FALHOU: %d problema(s) na Sizígia Eterna" % falhas.size())
		get_tree().quit(1)
