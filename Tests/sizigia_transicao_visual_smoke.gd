extends Node


class JogadorCinematica extends CharacterBody2D:
	var nivel_atual := 20
	var VIDA_MAXIMA := 100.0
	var vida := 100.0
	var invulneravel_por_habilidade := false

	func _ready() -> void:
		add_to_group("player")

	func curar(valor: float) -> void:
		vida = minf(vida + valor, VIDA_MAXIMA)


var falhas: Array[String] = []


func verificar(condicao: bool, mensagem: String) -> void:
	if not condicao:
		falhas.append(mensagem)
		push_error("TESTE TRANSIÇÃO SIZÍGIA: " + mensagem)


func _ready() -> void:
	var escala_tempo_anterior := Engine.time_scale
	Engine.time_scale = 18.0

	var jogador := JogadorCinematica.new()
	add_child(jogador)
	jogador.global_position = Vector2(230.0, 270.0)

	var cena := load("res://Entities/BossEclipseColheita.tscn") as PackedScene
	verificar(cena != null, "a cena da Sizígia não carregou")
	if cena == null:
		Engine.time_scale = escala_tempo_anterior
		get_tree().quit(1)
		return
	var boss := cena.instantiate() as BossSizigiaEterna
	add_child(boss)
	boss.global_position = Vector2(710.0, 210.0)
	await get_tree().process_frame

	verificar(is_instance_valid(boss.visual_lua_transicao), "falta o visual independente da Lua")
	verificar(is_instance_valid(boss.visual_sol_transicao), "falta o visual independente do Sol")
	verificar(is_instance_valid(boss.visual_eclipse_transicao), "falta o visual independente do Eclipse")

	# A primeira troca deve esconder o corpo principal e separar a saída da Lua
	# da entrada do Sol.
	boss.iniciar_transicao(BossSizigiaEterna.Fase.SOL)
	verificar(not boss.visual_fase.visible, "a Lua principal não foi escondida ao sair")
	verificar(boss.visual_lua_transicao.visible, "a Lua não ganhou uma saída própria")
	verificar(boss.visual_sol_transicao.visible, "o Sol não foi preparado fora da tela")
	verificar(
		boss.visual_sol_transicao.global_position.x > 960.0,
		"o Sol deveria começar a entrada além da borda direita"
	)
	boss.concluir_transicao_para_sol()
	verificar(boss.visual_fase.texture == boss.TEXTURA_SOL, "o sprite novo do Sol não foi restaurado")

	# Executa a cinemática completa acelerada. Ela só pode liberar o combate
	# depois do encontro, fusão, piscar no escuro e onda de refração.
	boss.iniciar_transicao(BossSizigiaEterna.Fase.ECLIPSE)
	verificar(boss.estado == BossSizigiaEterna.Estado.TRANSICAO, "o Sol não parou para a fusão")
	verificar(boss.visual_lua_transicao.visible, "a Lua anterior não retornou para a fusão")
	verificar(boss.visual_sol_transicao.visible, "o Sol sumiu antes de encontrar a Lua")

	var limite_quadros := 600
	var houve_brecha_visual := false
	var detalhe_brecha := ""
	var eclipse_neon_durante_transicao := false
	while (
		limite_quadros > 0
		and (
			boss.fase_atual != BossSizigiaEterna.Fase.ECLIPSE
			or boss.estado != BossSizigiaEterna.Estado.MOVENDO
		)
	):
		var lua_visivel := (
			is_instance_valid(boss.visual_lua_transicao)
			and boss.visual_lua_transicao.visible
			and boss.visual_lua_transicao.modulate.a > 0.01
		)
		var sol_visivel := (
			is_instance_valid(boss.visual_sol_transicao)
			and boss.visual_sol_transicao.visible
			and boss.visual_sol_transicao.modulate.a > 0.01
		)
		var eclipse_transicao_visivel := (
			is_instance_valid(boss.visual_eclipse_transicao)
			and boss.visual_eclipse_transicao.visible
			and boss.visual_eclipse_transicao.modulate.a > 0.01
		)
		var eclipse_final_visivel := (
			boss.visual_fase.visible
			and boss.visual_fase.modulate.a > 0.01
		)
		if not (lua_visivel or sol_visivel or eclipse_transicao_visivel or eclipse_final_visivel):
			houve_brecha_visual = true
			if detalhe_brecha.is_empty():
				detalhe_brecha = (
					"quadro=%d fase=%d estado=%d overlay=%s lua=%s sol=%s eclipse=%s final=%s"
					% [
						600 - limite_quadros,
						boss.fase_atual,
						boss.estado,
						is_instance_valid(boss.overlay_transicao),
						boss.visual_lua_transicao.visible,
						boss.visual_sol_transicao.visible,
						boss.visual_eclipse_transicao.visible,
						boss.visual_fase.visible,
					]
				)
		if (
			eclipse_transicao_visivel
			and boss.visual_eclipse_transicao.self_modulate.r >= 1.8
		):
			eclipse_neon_durante_transicao = true
		limite_quadros -= 1
		await get_tree().process_frame

	verificar(limite_quadros > 0, "a cinemática não terminou dentro do tempo esperado")
	verificar(
		not houve_brecha_visual,
		"Sol, Lua e Eclipse sumiram juntos durante a fusão: " + detalhe_brecha
	)
	verificar(
		eclipse_neon_durante_transicao,
		"o Eclipse só recebeu neon depois da onda de choque"
	)
	verificar(boss.fase_atual == BossSizigiaEterna.Fase.ECLIPSE, "a união não formou o Eclipse")
	verificar(boss.visual_fase.visible, "o Eclipse real não apareceu na volta da tela")
	verificar(boss.visual_fase.texture == boss.TEXTURA_ECLIPSE, "o Eclipse final usa a textura errada")
	verificar(not jogador.invulneravel_por_habilidade, "a batalha não devolveu o controle ao jogador")
	verificar(not is_instance_valid(boss.overlay_transicao), "o shader da cinemática permaneceu na tela")

	Engine.time_scale = escala_tempo_anterior
	if falhas.is_empty():
		print("TESTE OK: saída, entrada, fusão, eclipse e onda de choque")
		get_tree().quit(0)
	else:
		print("TESTE FALHOU: %d problema(s) na transição visual" % falhas.size())
		get_tree().quit(1)
