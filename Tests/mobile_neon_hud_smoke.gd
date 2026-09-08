extends Node


var falhas: Array[String] = []


func verificar(condicao: bool, mensagem: String) -> void:
	if not condicao:
		falhas.append(mensagem)
		push_error("MOBILE/NEON/HUD: " + mensagem)


func _ready() -> void:
	testar_neon()
	testar_laser()
	testar_flor()
	await testar_interface()
	if falhas.is_empty():
		print("TESTE OK: neon por renderer, HUD multirresolução, toque, laser e vinhas")
	get_tree().quit(0 if falhas.is_empty() else 1)


func testar_neon() -> void:
	var neon_anterior: float = Global.neon
	var bloom_anterior: float = Global.bloom
	Global.neon = 1.0
	Global.bloom = 0.12
	var ambiente := Environment.new()
	Global.configurar_glow(ambiente, &"gl_compatibility")
	verificar(ambiente.glow_enabled, "o glow ficou desligado no OpenGL")
	verificar(ambiente.glow_hdr_threshold < 1.0, "o glow em SDR exige pixels HDR inexistentes")
	verificar(is_equal_approx(ambiente.glow_bloom, 0.12), "o bloom foi reduzido silenciosamente no mobile")
	verificar(is_equal_approx(ambiente.glow_intensity, 1.0), "a intensidade foi limitada")
	Global.configurar_glow(ambiente, &"mobile")
	verificar(is_equal_approx(ambiente.glow_intensity, 1.5), "faltou compensação do renderer Mobile")
	Global.neon = 0.0
	Global.bloom = 0.0
	Global.configurar_glow(ambiente, &"gl_compatibility")
	verificar(not ambiente.glow_enabled, "os sliders não conseguem desligar o efeito")
	Global.neon = neon_anterior
	Global.bloom = bloom_anterior


func testar_laser() -> void:
	var alvo := Node2D.new()
	var origem := Node2D.new()
	add_child(alvo)
	add_child(origem)
	alvo.position = Vector2(0.0, 200.0)
	var laser := FaixaEnergiaBoss.criar(self, {
		"movimento": FaixaEnergiaBoss.Movimento.RASTREADORA,
		"aviso": 0.88, "antecedencia_trava": 0.5,
		"alvo": alvo, "dono": origem, "acompanha_origem": true,
	})
	laser.set_process(false)
	laser.tempo = 0.2
	laser._atualizar_geometria(0.2)
	verificar(absf(laser.angulo) > 0.1, "o laser não rastreou durante o início do aviso")
	laser.tempo = 0.38
	laser._atualizar_geometria(0.18)
	verificar(laser.mira_travada, "a mira não travou 0,5 segundo antes do disparo")
	var a: Vector2 = laser.ponto_a
	var b: Vector2 = laser.ponto_b
	alvo.position = Vector2(-200.0, -200.0)
	origem.position = Vector2(100.0, 100.0)
	for instante in [0.6, 0.87, 0.89, 1.05]:
		laser.tempo = instante
		laser._atualizar_geometria(0.2)
		verificar(laser.ponto_a.is_equal_approx(a) and laser.ponto_b.is_equal_approx(b), "a linha travada continuou seguindo o alvo ou satélite")
	laser.free()
	alvo.free()
	origem.free()


func testar_flor() -> void:
	var flor := BossCaosPrimaveril.new()
	seed(20260908)
	for fase in [1, 2, 3]:
		flor.fase = fase
		var total_vinhas := 0
		var intervalo := 100
		for _i in 2000:
			var ataque: int = flor.sortear_proximo_ataque()
			if ataque == BossCaosPrimaveril.Ataque.DANCA_CAULES:
				total_vinhas += 1
				verificar(intervalo >= 3, "as vinhas não respeitaram os três ataques de intervalo")
				intervalo = 0
			else:
				intervalo += 1
			flor.ultimo_ataque = ataque
		if fase == 1:
			verificar(total_vinhas == 0, "a flor usou vinhas na primeira fase")
		else:
			verificar(total_vinhas > 0 and total_vinhas < 350, "as vinhas sumiram ou continuam frequentes demais")
	flor.free()
	randomize()


func testar_interface() -> void:
	var cena := load("res://Rooms/Battle_area.tscn") as PackedScene
	var batalha := cena.instantiate() as Node2D
	add_child(batalha)
	await get_tree().process_frame
	var gui := batalha.get_node("GUI")
	var vida := batalha.get_node("GUI/Barra_vida") as TextureProgressBar
	var xp := batalha.get_node("GUI/Barra_xp") as TextureProgressBar
	var icone := batalha.get_node("GUI/DisplaySkill") as TextureRect
	# Inclui telas pequenas, ultrawide, tablet e uma troca de orientação.
	for tamanho in [Vector2(640, 360), Vector2(960, 540), Vector2(1280, 540), Vector2(1170, 540), Vector2(960, 720), Vector2(540, 960)]:
		gui._aplicar_layout_hud(tamanho)
		for proporcao in [0.0, 0.37, 1.0]:
			vida.value = vida.max_value * proporcao
			xp.value = xp.max_value * proporcao
			for barra in [vida, xp]:
				verificar(is_equal_approx(barra.position.x + barra.size.x * 0.5, tamanho.x * 0.5), "barra fora do centro em %s" % tamanho)
				verificar(barra.position.x >= 0.0 and barra.get_rect().end.x <= tamanho.x, "textura impediu barra de encolher")
			verificar(vida.size.x == xp.size.x and vida.position.x == xp.position.x, "barras com larguras ou margens diferentes")
		verificar(is_equal_approx(icone.position.x + icone.size.x * 0.5, tamanho.x * 0.5), "ícone fora do centro")
		verificar(icone.size.is_equal_approx(Vector2(64, 64)) and is_zero_approx(icone.rotation), "ícone deformado")
	gui._ajustar_hud_responsivo()
	var centro_real := batalha.get_viewport().get_visible_rect().size.x * 0.5
	verificar(is_equal_approx(icone.get_global_rect().get_center().x, centro_real), "HUD usa coordenadas da câmera")
	var controles := ControlesMobile.new()
	batalha.add_child(controles)
	controles.configurar(batalha, batalha.get_node("Player"), true)
	controles.definir_analogico_para_teste(Vector2.RIGHT)
	controles.pressionar_acao_para_teste(&"atirar")
	controles._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	verificar(not Global.controle_toque_ativo and not Input.is_action_pressed("atirar"), "comandos ficaram presos ao minimizar o jogo")
	if Global.dispositivo_mobile():
		Global.definir_cursor_interface(true)
		var aim := batalha.get_node("GUI/aim") as Node2D
		verificar(not aim.visible, "mobile ainda exibe aim.tscn")
		# O DisplayServer headless ignora mouse_mode; só existe ponteiro num display real.
		if DisplayServer.get_name() != "headless":
			verificar(Input.mouse_mode == Input.MOUSE_MODE_HIDDEN, "mobile ainda exibe cursor nativo")
	for audio in batalha.find_children("*", "AudioStreamPlayer2D", true, false):
		(audio as AudioStreamPlayer2D).stop()
	batalha.queue_free()
	await get_tree().process_frame
