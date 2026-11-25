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
	boss.configurar_dificuldade(5)
	verificar(is_equal_approx(boss.obter_vida_maxima_atual(), 3936.0), "vida da Lua no quinto setor")
	var dano_lua := boss.Dano
	var golpes := boss.golpes
	golpes.iniciar(golpes.Golpe.MARE)
	var direcao := boss.global_position.angle_to_point(jogador.global_position)
	verificar(golpes.livre(direcao, 0.0) and golpes.livre(direcao, 0.16), "as ondas não preservaram a passagem")
	var vida_inicial := jogador.vida
	for i in 280:
		golpes.avancar(1.0 / 60.0)
	verificar(is_equal_approx(jogador.vida, vida_inicial), "o corredor verde causou dano")
	golpes.encerrar()
	golpes.iniciar(golpes.Golpe.METEOROS)
	var sala := Global.obter_retangulo_area_visivel()
	var primeira_mira := golpes.pontos[0]
	verificar(primeira_mira == jogador.global_position and golpes.pontos.size() == 4, "a primeira leva não mirou o piloto")
	golpes.avancar(0.50)
	verificar(jogador.vida == vida_inicial, "o aviso causou dano antes do impacto")
	var limite: float = golpes.especial.raios[0]
	jogador.global_position = golpes.pontos[0] + Vector2.RIGHT * (limite + 1)
	golpes.avancar(golpes.instante_impacto(0) - golpes.tempo + 0.01)
	verificar(jogador.vida == vida_inicial, "meteoro causou dano fora do círculo")
	limite = golpes.especial.raios[1]
	jogador.global_position = golpes.pontos[1] + Vector2.RIGHT * (limite - 1)
	golpes.avancar(golpes.instante_impacto(1) - golpes.tempo + 0.01)
	verificar(jogador.vida < vida_inicial, "meteoro não atingiu o interior do círculo")
	verificar(golpes.pontos[0] == primeira_mira and golpes.pontos[4] != primeira_mira, "o alvo se moveu com o aviso já visível")
	var vida_apos := jogador.vida
	golpes.avancar(0.03)
	verificar(jogador.vida == vida_apos, "uma explosão aplicou dano duas vezes")
	for i in 108:
		golpes.avancar(1.0 / 60.0)
	var setores := {}
	for i in golpes.pontos.size():
		if i % 4 != 0:
			var celula := Vector2i((golpes.pontos[i] - sala.position) / sala.size * Vector2(3, 4))
			setores[celula] = true
	verificar(golpes.pontos.size() == 16 and setores.size() == 12, "a chuva deixou setores sem cobertura")
	golpes.encerrar()
	var nave := preload("res://Entities/player.tscn").instantiate() as Player
	add_child(nave)
	jogador.remove_from_group("player")
	golpes.iniciar(golpes.Golpe.SOMBRA)
	var sombra := golpes.sombra
	verificar(is_equal_approx(sombra.vida, boss.VidaMaxima * 0.2), "vida inicial da sombra")
	var nascendo := sombra.global_position
	sombra._physics_process(0.45)
	sombra.tomarDano(5)
	verificar(sombra.collision_layer == 0 and sombra.vida == sombra.vida_maxima and sombra.disparos == 0, "a silhueta em formação entrou em combate")
	verificar(sombra.casco.modulate.a > 0 and sombra.casco.modulate.a < 1, "a invocação não revelou o casco gradualmente")
	sombra._physics_process(0.51)
	verificar(sombra.collision_layer == 4 and sombra.global_position == nascendo, "a invocação não materializou o colisor junto da nave")
	sombra.tomarDano(5)
	var restante := sombra.vida
	golpes.iniciar(golpes.Golpe.CRESCENTES)
	golpes.iniciar(golpes.Golpe.SOMBRA)
	verificar(sombra == golpes.sombra and sombra.vida == restante, "reiniciar ataque duplicou ou curou a sombra")
	nave.global_position = Vector2(400, 300)
	nave.velocity = Vector2(0, 220)
	for i in 36:
		sombra._physics_process(1.0 / 60.0)
	var mira_travada := sombra.mira
	var rumo := Vector2.from_angle(mira_travada)
	verificar(sombra.global_position.distance_to(nascendo) >= 75.0, "a sombra não flanqueou o piloto")
	verificar(absf(angle_difference(mira_travada, sombra.global_position.angle_to_point(nave.global_position))) > 0.07, "a mira não antecipou o deslocamento lateral")
	nave.global_position += Vector2(0, -70)
	nave.velocity = Vector2.ZERO
	for i in 18:
		sombra._physics_process(1.0 / 60.0)
	verificar(sombra.disparos == 1 and is_equal_approx(sombra.eixo_tiro, mira_travada), "a primeira salva corrigiu a mira depois do aviso")
	for i in 82:
		sombra._physics_process(1.0 / 60.0)
	verificar(sombra.disparos == 2 and sombra.duracao_ciclo() == sombra.CICLO_LONGO, "a sombra não manteve a cadência independente")
	for i in sombra.BRACOS:
		var radial := sombra.ponta(i, 0.3) - sombra.origem_tiro
		var seguinte := sombra.ponta((i + 1) % sombra.BRACOS, 0.3) - sombra.origem_tiro
		verificar(radial.rotated(PI / 2).is_equal_approx(seguinte), "a salva perdeu a simetria de 90 graus")
	nave.remove_from_group("player")
	nave.queue_free()
	jogador.add_to_group("player")
	# A mesma ponta desenhada só causa dano ao cruzar o piloto, uma vez por dardo.
	var idade := sombra.idade_tiro
	rumo = Vector2.from_angle(sombra.eixo_tiro)
	jogador.global_position = sombra.ponta(0, idade + 0.02) + rumo.orthogonal() * 15
	var dano_antes := jogador.dano_recebido
	sombra._physics_process(0.02)
	verificar(jogador.dano_recebido == dano_antes, "tiro da sombra acertou fora da trajetória")
	jogador.global_position = sombra.ponta(0, sombra.idade_tiro + 0.01)
	sombra._physics_process(0.02)
	sombra._physics_process(0.01)
	verificar(is_equal_approx(jogador.dano_recebido - dano_antes, boss.Dano * sombra.FATOR_DANO), "o dardo não aplicou exatamente um impacto")
	var vida_lua := boss.Vida
	boss.tomarDano(vida_lua + 999.0)
	verificar(boss.fase_atual == BossSizigiaEterna.Fase.LUA, "o dano excedente atravessou a primeira barra")
	verificar(boss.estado == BossSizigiaEterna.Estado.TRANSICAO, "a Lua não iniciou a transição")

	var tempo_congelado := sombra.tempo
	sombra._physics_process(0.6)
	sombra.tomarDano(2)
	verificar(sombra.tempo == tempo_congelado and sombra.vida == restante, "a sombra continuou atacando ou recebendo dano na cinemática")
	boss.concluir_transicao_para_sol()
	verificar(is_instance_valid(sombra) and sombra.vida == restante, "a mudança de fase removeu a sombra")
	sombra.tomarDano(restante)
	verificar(sombra.morto and golpes.snapshot_sombra().is_empty(), "a morte não removeu a sombra e sua salva")
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
	verificar(is_equal_approx(boss.Dano, dano_lua * 1.15), "dano do Sol fora da curva")
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
	verificar(is_equal_approx(boss.Dano, dano_lua * 1.35), "dano da Eclipse fora da curva")
	var vida_eclipse := boss.Vida
	boss.Vida = boss.VidaMaxima * 0.24
	golpes.iniciar(golpes.Golpe.METEOROS)
	for leva in 5:
		golpes.avancar(1.2) # Um quadro atrasado não deve encurtar os avisos seguintes.
		var ultimo := golpes.pontos.size() - 4
		verificar(is_equal_approx(golpes.instante_impacto(ultimo) - golpes.tempo, 0.93), "aviso da Eclipse foi encurtado")
	verificar(golpes.pontos.size() == 24, "faltou a sexta leva da Eclipse")
	golpes.encerrar()
	boss.Vida = vida_eclipse
	golpes.iniciar(golpes.Golpe.TOTALIDADE)
	var centro: Vector2 = golpes.especial.centro
	var eixo_inicial := centro.angle_to_point(jogador.global_position)
	verificar(golpes.ANEIS_ECLIPSE == 10 and golpes.lacunas.size() == 1, "contagem de anéis ou frestas solo")
	var raio_teste := 180.0
	var meio_vao := 2.0 * golpes.raio_piloto(jogador)
	for i in golpes.ANEIS_ECLIPSE:
		var desvio := golpes.desvio_anel(i)
		if i == 0:
			verificar(absf(desvio) >= deg_to_rad(15), "primeira fresta apontou para o piloto")
		else:
			var passo := absf(desvio - golpes.desvio_anel(i - 1))
			verificar(passo >= deg_to_rad(15) and passo <= deg_to_rad(30), "giro do corredor fora da faixa")
		var instante := golpes.PRIMEIRO_ANEL + i * golpes.INTERVALO_ANEIS + raio_teste / golpes.VELOCIDADE_ANEL
		var rumo_fresta := Vector2.from_angle(eixo_inicial + desvio)
		# Anéis pares cruzam pelo centro da fresta. Ímpares acertam a parede ao lado.
		jogador.global_position = centro + rumo_fresta * raio_teste
		if i % 2 == 1:
			jogador.global_position += rumo_fresta.orthogonal() * (meio_vao + 3.0)
		while golpes.tempo < instante + 0.08:
			golpes.avancar(1.0 / 60.0)
		var chave := Vector2i(300 + i, jogador.get_multiplayer_authority())
		verificar(golpes.impactos.has(chave) == (i % 2 == 1), "colisão da passagem no anel %d" % i)
	verificar(not golpes.exposto(), "o núcleo abriu antes do último anel sair")
	var fim_aneis := golpes.fim_dos_aneis()
	while golpes.tempo < fim_aneis + 0.05:
		golpes.avancar(1.0 / 60.0)
	verificar(golpes.exposto() and boss.multiplicador_dano_recebido == 1.45, "núcleo não abriu depois do combo")
	golpes.encerrar()
	boss.Vida = boss.VidaMaxima * 0.35
	golpes.escolher()
	verificar(golpes.tipo == golpes.Golpe.ABSOLUTO and golpes.abrigos.size() > 0, "faltou o abrigo do Eclipse Absoluto")

	await testar_clone(boss, jogador)
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

func testar_clone(boss: BossSizigiaEterna, alvo_teste: Node2D) -> void:
	boss.golpes.encerrar()
	alvo_teste.remove_from_group("player")
	var nave := preload("res://Entities/player.tscn").instantiate() as Player
	add_child(nave)
	nave.set_process(false)
	nave.set_physics_process(false)
	boss.set_physics_process(false)
	var golpes := boss.golpes
	nave.global_position = Vector2(935, 220)
	nave.rotation = 3.05
	golpes.registrar_trajetorias(0.1)
	nave.global_position = Vector2(16, 225)
	nave.rotation = -3.02
	golpes.registrar_trajetorias(0.1)
	nave.cooldown = 30.0 # Grava o botão mesmo quando a arma equipada não pode disparar.
	Input.action_press("atirar")
	nave.atualizar_combate(0.01)
	nave.global_position = Vector2(38, 235)
	for i in 60:
		golpes.registrar_trajetorias(1.0 / 60.0)
	Input.action_release("atirar")
	nave.atualizar_combate(0.01)
	for i in 24:
		golpes.registrar_trajetorias(1.0 / 60.0)
	golpes.iniciar(golpes.Golpe.ABSOLUTO)
	var tiros: PackedFloat32Array = golpes.especial.tiros
	verificar(tiros.size() == 3, "um segundo de gatilho segurado deve gerar três disparos")
	verificar(golpes.pose_em(0.05).x > 900 and golpes.pose_em(0.15).x < 40, "o clone atravessou o centro durante o wrap")
	if tiros.size() < 3:
		return
	for i in range(1, tiros.size()):
		verificar(absf(tiros[i] - tiros[i - 1] - 1.0 / 3.0) < 0.001, "a cadência divergiu de três disparos por segundo")
	var tiro := tiros[0]
	var pose := golpes.pose_em(tiro)
	var boca: Vector2 = golpes.especial.modelo.boca
	nave.global_position = Vector2(pose.x, pose.y) + boca.rotated(pose.z) + Vector2.from_angle(pose.z) * 32
	golpes.avancar(golpes.MATERIALIZACAO + tiro - 0.02)
	var chave := Vector2i(200, nave.get_multiplayer_authority())
	verificar(not golpes.impactos.has(chave), "dardo atingiu antes de ser disparado")
	for i in 8:
		golpes.avancar(1.0 / 60.0)
	verificar(golpes.impactos.has(chave), "o dardo visível não atingiu a nave")
	golpes.encerrar()
	golpes.registrar_trajetorias(3.2)
	golpes.iniciar(golpes.Golpe.ABSOLUTO)
	verificar(golpes.especial.tiros.is_empty(), "a gravação silenciosa inventou um disparo")
	golpes.encerrar()
	if DisplayServer.get_name() != "headless":
		await comparar_pixels_do_clone(nave)
	nave.queue_free()


func comparar_pixels_do_clone(nave: Player) -> void:
	var tela := SubViewport.new()
	tela.size = Vector2i(192, 96)
	tela.world_2d = World2D.new()
	tela.transparent_bg = true
	tela.use_hdr_2d = get_viewport().use_hdr_2d
	tela.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(tela)
	for id in [&"c04_dardo", &"c07_modelo_o", &"c08_modelo_spectrum", &"c09_modelo_fspeed"]:
		nave.modelo_visual_nave = id
		nave.cor_visual_nave = &"c12_rosa"
		nave.aplicar_personalizacao_nave()
		var original := Node2D.new()
		tela.add_child(original)
		original.position = Vector2(48, 48)
		original.scale = nave.global_scale
		var sprite: Sprite2D = nave.sprites_modelos_exclusivos.get(id, nave.sprite_modelo_o)
		if sprite.visible:
			original.add_child(sprite.duplicate(0))
		else:
			for parte in [nave.corpo_visual, nave.detalhe_visual]:
				original.add_child(parte.duplicate(0))
		var copia := CloneLunar.new()
		tela.add_child(copia)
		copia.position = Vector2(144, 48)
		copia.configurar(CloneLunar.capturar(nave))
		await RenderingServer.frame_post_draw
		var imagem := tela.get_texture().get_image()
		var opacos := 0
		var invertidos := 0
		var silhueta_errada := 0
		for y in 96:
			for x in 96:
				var a := imagem.get_pixel(x, y)
				var b := imagem.get_pixel(x + 96, y)
				if tela.use_hdr_2d and RenderingServer.get_current_rendering_method() != "gl_compatibility":
					a = a.linear_to_srgb()
					b = b.linear_to_srgb()
				a = a.clamp()
				if absf(a.a - b.a) > 0.12:
					silhueta_errada += 1
				if a.a < 0.97:
					continue
				opacos += 1
				if maxf(absf(a.r + b.r - 1), maxf(absf(a.g + b.g - 1), absf(a.b + b.b - 1))) < 0.09:
					invertidos += 1
		verificar(opacos > 12 and invertidos >= opacos * 0.94 and silhueta_errada < 6,
			"casco %s: %d/%d pixels invertidos e %d fora da silhueta" % [id, invertidos, opacos, silhueta_errada])
		original.free()
		copia.free()
	tela.queue_free()
