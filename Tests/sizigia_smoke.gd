extends Node


class JogadorTeste extends CharacterBody2D:
	var nivel_atual := 20
	var vivo := true
	var vida := 100.0
	var VIDA_MAXIMA := 100.0
	var protegido_por_sizigia := false
	var dano_recebido := 0.0
	var queimadura_recebida := 0.0

	func _ready() -> void:
		add_to_group("player")

	func tomar_dano(valor: float, _origem_dano := Vector2.INF) -> void:
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
	var golpes := boss.golpes
	golpes.iniciar(golpes.Golpe.MARE)
	var direcao := boss.global_position.angle_to_point(jogador.global_position)
	verificar(golpes.livre(direcao, 0.0) and golpes.livre(direcao, 0.16), "as ondas não preservaram a passagem")
	var vida_inicial := jogador.vida
	for i in 280:
		golpes.avancar(1.0 / 60.0)
	verificar(is_equal_approx(jogador.vida, vida_inicial), "o corredor verde causou dano")
	golpes.encerrar()
	golpes.iniciar(golpes.Golpe.CRATERAS)
	for i in 135:
		golpes.avancar(1.0 / 60.0)
	verificar(golpes.pontos.size() == 3 and jogador.vida < vida_inicial, "crateras não marcaram e atingiram o alvo")
	golpes.encerrar()
	var vida_lua := boss.Vida
	boss.tomarDano(vida_lua + 999.0)
	verificar(boss.fase_atual == BossSizigiaEterna.Fase.LUA, "o dano excedente atravessou a primeira barra")
	verificar(boss.estado == BossSizigiaEterna.Estado.TRANSICAO, "a Lua não iniciou a transição")

	boss.concluir_transicao_para_sol()
	verificar(boss.fase_atual == BossSizigiaEterna.Fase.SOL, "a segunda fase não é o Sol")
	verificar(boss.visual_fase.texture == boss.TEXTURA_SOL, "o Sol 5 pontudo não foi aplicado ao boss")
	verificar(is_equal_approx(boss.Vida, boss.obter_vida_maxima_atual()), "o Sol não recebeu uma barra cheia independente")
	boss.global_position = Vector2(180, 265)
	jogador.global_position = Vector2(830, 265)
	golpes.iniciar(golpes.Golpe.INVESTIDA)
	var inicio := boss.global_position
	for i in 115:
		await get_tree().physics_frame
	var percurso := boss.global_position.distance_to(inicio)
	verificar(percurso > 420 and percurso < 475, "investida percorreu apenas %.1f px" % percurso)
	verificar(golpes.exposto(), "faltou a recuperação da investida")
	golpes.iniciar(golpes.Golpe.ROUBO)
	var vida_sol := boss.Vida
	boss.tomarDano(12)
	verificar(golpes.energia == 12 and boss.Vida == vida_sol, "absorção não contabilizou o dano")
	golpes.iniciar(golpes.Golpe.MANCHAS)
	golpes.orbes[1].tomarDano(3)
	verificar(golpes.mascara_orbes == 5, "destruir a mancha não abriu a rota")
	boss.iniciar_transicao(BossSizigiaEterna.Fase.ECLIPSE)
	verificar(jogador.protegido_por_sizigia, "a cinemática não protegeu o jogador")
	boss.concluir_transicao_para_eclipse()
	verificar(boss.fase_atual == BossSizigiaEterna.Fase.ECLIPSE, "a terceira fase não é o Eclipse")
	verificar(boss.visual_fase.texture == boss.TEXTURA_ECLIPSE, "o Eclipse 01 não foi aplicado ao boss")
	verificar(not jogador.protegido_por_sizigia, "a proteção da cinemática não terminou")
	verificar(is_equal_approx(boss.Vida, boss.obter_vida_maxima_atual()), "o Eclipse não recebeu sua barra independente")
	golpes.iniciar(golpes.Golpe.TOTALIDADE)
	for i in 340:
		golpes.avancar(1.0 / 60.0)
	verificar(golpes.exposto() and boss.multiplicador_dano_recebido == 1.45, "núcleo não abriu depois do combo")
	golpes.encerrar()
	boss.Vida = boss.VidaMaxima * 0.35
	golpes.escolher()
	verificar(golpes.tipo == golpes.Golpe.ABSOLUTO and golpes.abrigos.size() > 0, "faltou o abrigo do Eclipse Absoluto")

	var mortes := [0]
	boss.morreu.connect(func(_alvo: InimigoBase) -> void: mortes[0] += 1)
	boss.tomarDano(boss.Vida + 1.0)
	verificar(mortes[0] == 1, "o Eclipse final não concluiu a luta")

	for audio in find_children("*", "AudioStreamPlayer2D", true, false):
		audio.stop()
		audio.stream = null
	for audio in find_children("*", "AudioStreamPlayer", true, false):
		audio.stop()
		audio.stream = null
	await get_tree().create_timer(0.25, true, false, true).timeout
	if falhas.is_empty():
		print("TESTE OK: Sizígia Eterna, três barras e arsenal astral")
		get_tree().quit(0)
	else:
		print("TESTE FALHOU: %d problema(s) na Sizígia Eterna" % falhas.size())
		get_tree().quit(1)
