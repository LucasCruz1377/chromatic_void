extends Node


var setor_atual: StringName = &"vazio_inicial"
var falhas: Array[String] = []
var objetos: Array[Node] = []


func verificar(condicao: bool, mensagem: String) -> void:
	if not condicao:
		falhas.append(mensagem)
		push_error("MELHORIA 0.7.4: " + mensagem)


func _ready() -> void:
	testar_curva_xp_e_dano()
	testar_conquista_modelo_o()
	testar_modelos_spectrum_e_fspeed()
	testar_feedback_vinculos()
	await testar_limites_hud_e_musica()
	await finalizar()


func testar_curva_xp_e_dano() -> void:
	var xp_inicio := InimigoBase.calcular_fator_xp_combo(1, 0)
	var xp_combo_20 := InimigoBase.calcular_fator_xp_combo(20, 0)
	var xp_pos_pet0 := InimigoBase.calcular_fator_xp_combo(10, 1)
	var xp_final := InimigoBase.calcular_fator_xp_combo(200, 4)
	verificar(xp_inicio > 1.0 and xp_inicio < 1.03, "o primeiro abate recebeu bônus excessivo")
	verificar(is_equal_approx(xp_combo_20, 1.10), "combo 20x não concede exatamente 10% de XP")
	verificar(xp_pos_pet0 > xp_inicio, "o combo não melhorou o XP após o PET-0")
	verificar(xp_final > xp_pos_pet0 and xp_final < 2.25, "a curva de XP não cresce de forma moderada")

	setor_atual = &"no_ametista"
	var inimigo := InimigoBase.new()
	inimigo.VidaMaxima = 100.0
	inimigo.Dano = 10.0
	add_child(inimigo)
	verificar(is_equal_approx(inimigo.Dano, 14.8), "o dano pós-PET-0 não escalou 24% por setor")
	var intervalo := inimigo.calcular_intervalo_ataque(2.8)
	verificar(intervalo < 2.8 and intervalo >= 0.5, "o intervalo de ataque não acelerou com piso de 0,5 s")
	inimigo.free()

	var fita := InimigoSetorial.new()
	fita.estilo = InimigoSetorial.Estilo.FITA_VIOLETA
	fita.Velocidade = 100.0
	add_child(fita)
	verificar(fita.Velocidade > 140.0, "a Fita Violeta não recebeu velocidade extra para cruzar o mapa")
	verificar(fita.intervalo_acao >= 0.5, "a cadência setorial atravessou o piso de 0,5 s")
	fita.free()
	setor_atual = &"vazio_inicial"


func testar_conquista_modelo_o() -> void:
	var modelo := MonthlyCatalog.encontrar(&"c07_modelo_o")
	verificar(StringName(modelo.get("requer_conquista", &"")) == &"sinal_da_estrela", "o Modelo O não exige a conquista secreta")
	verificar(int(modelo.get("preco", 0)) > 0, "o Modelo O virou recompensa gratuita")
	verificar(bool(Global.CONQUISTAS.get(&"sinal_da_estrela", {}).get("secreta", false)), "a conquista do Modelo O não é secreta")

	var anteriores := Global.conquistas_desbloqueadas.duplicate()
	Global.conquistas_desbloqueadas.erase(&"sinal_da_estrela")
	var loja := preload("res://Scripts/shopcontroler.gd").new()
	verificar(not loja.requisito_compra_atendido(modelo), "o Modelo O pode ser comprado antes da conquista")
	Global.conquistas_desbloqueadas.append(&"sinal_da_estrela")
	verificar(loja.requisito_compra_atendido(modelo), "o preço não é liberado depois da conquista")
	loja.free()
	Global.conquistas_desbloqueadas.assign(anteriores)


func testar_modelos_spectrum_e_fspeed() -> void:
	var spectrum := MonthlyCatalog.encontrar(&"c08_modelo_spectrum")
	var fspeed := MonthlyCatalog.encontrar(&"c09_modelo_fspeed")
	verificar(StringName(spectrum.get("requer_conquista", &"")) == &"combo_213_spectrum", "Spectrum não exige combo 300x")
	verificar(StringName(fspeed.get("requer_conquista", &"")) == &"pontos_75000000_fspeed", "Fspeed não exige 75M de pontos")
	verificar(int(Global.CONQUISTAS[&"combo_213_spectrum"]["meta"]) == 213, "meta do Spectrum não é 213x")
	verificar(int(Global.CONQUISTAS[&"pontos_75000000_fspeed"]["meta"]) == 75000000, "meta do Fspeed não é 75M")
	verificar(&"c22_rastro_spectrum" in Global.CONQUISTAS[&"combo_213_spectrum"]["recompensas"], "Spectrum não libera seu rastro")
	verificar(&"c23_rastro_fspeed" in Global.CONQUISTAS[&"pontos_75000000_fspeed"]["recompensas"], "Fspeed não libera seu rastro")


func testar_feedback_vinculos() -> void:
	var inimigo := InimigoSetorial.new()
	inimigo.estilo = InimigoSetorial.Estilo.CENTELHA_GUIA
	verificar("ESCUDO" in inimigo.obter_descricao_vinculo(), "o raio dourado não explica que concede escudo")
	inimigo.estilo = InimigoSetorial.Estilo.ELO_DOURADO
	verificar("DANO COMPARTILHADO" in inimigo.obter_descricao_vinculo(), "o Elo não explica o dano compartilhado")
	inimigo.free()


func testar_limites_hud_e_musica() -> void:
	var cena := load("res://Rooms/Battle_area.tscn") as PackedScene
	var batalha := cena.instantiate() as Node2D
	get_tree().root.add_child.call_deferred(batalha)
	objetos.append(batalha)
	await get_tree().process_frame
	await get_tree().process_frame
	batalha.tutorial_ativo = false
	batalha.player.nivel_atual = 1
	verificar(batalha.calcular_limite_inimigos() >= 2, "o limite inicial ficou abaixo de dois")
	for inimigo in get_tree().get_nodes_in_group("inimigo"):
		if not inimigo.is_in_group("boss") and not inimigo.is_in_group("asteroide_bonus"):
			inimigo.queue_free()
	await get_tree().process_frame
	batalha.garantir_minimo_inimigos()
	await get_tree().process_frame
	verificar(batalha.contar_inimigos_regulares() >= 2, "a arena não recompôs o mínimo de dois inimigos")
	verificar(batalha.contar_inimigos_regulares() <= 10, "a recomposição ultrapassou dez inimigos")
	batalha.player.nivel_atual = 999
	verificar(batalha.calcular_limite_inimigos() == 10, "o limite máximo ultrapassa dez")

	var gui := batalha.get_node("GUI")
	gui._ajustar_hud_responsivo()
	var centro := Global.obter_centro_area_visivel().x
	var vida := batalha.get_node("GUI/Barra_vida") as TextureProgressBar
	var xp := batalha.get_node("GUI/Barra_xp") as TextureProgressBar
	verificar(is_equal_approx(vida.position.x + vida.size.x * 0.5, centro), "a vida não está centralizada horizontalmente")
	verificar(is_equal_approx(xp.position.x + xp.size.x * 0.5, centro), "o XP não está centralizado horizontalmente")

	for id in [&"constelacao_amparo", &"no_ametista"]:
		batalha.aplicar_musica_boss(id)
		verificar(is_instance_valid(batalha.tocarmusica.stream), "boss novo ficou sem música: %s" % id)


func finalizar() -> void:
	for objeto in objetos:
		if is_instance_valid(objeto):
			for audio in objeto.find_children("*", "AudioStreamPlayer", true, false):
				(audio as AudioStreamPlayer).stop()
			for audio2d in objeto.find_children("*", "AudioStreamPlayer2D", true, false):
				(audio2d as AudioStreamPlayer2D).stop()
			objeto.free()
	objetos.clear()
	await get_tree().process_frame
	await get_tree().process_frame
	if falhas.is_empty():
		print("TESTE OK: HUD, mobile/iOS, desempenho, progressão, música e Modelo O")
	get_tree().quit(0 if falhas.is_empty() else 1)
