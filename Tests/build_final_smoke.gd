extends Node

var falhas := 0


func conferir(valor: bool, mensagem: String) -> void:
	if not valor:
		falhas += 1
		push_error(mensagem)


func _ready() -> void:
	var arena := preload("res://Rooms/Battle_area.tscn").instantiate()
	get_tree().root.add_child.call_deferred(arena)
	await get_tree().process_frame
	get_tree().current_scene = arena
	var piloto: Player = arena.player
	piloto.modelo_visual_nave = &"c04_dardo"
	piloto.arma_monthly = &"a06_feixe_perielio"
	piloto.HabilidadeEquipada = preload("res://Habilidades/monthly_p14.tres")
	piloto.mutacao_habilidade = &"u12_noite_congelada"
	piloto.modulo_nave = &"n05_reserva_solidaria"
	piloto.niveis_upgrades = {&"cadencia": 2, &"perielio_potencia": 1}
	arena._apresentar_vitoria(12345)
	var final := arena.camada_escolha.get_node("FinalDoCiclo") as Node2D
	final.set_process(false)
	var rolagem := final.get_node("RolagemBuild") as ScrollContainer
	var build := rolagem.get_node("Build")
	var nomes := [
		MonthlyCatalog.encontrar(piloto.modelo_visual_nave).nome,
		MonthlyCatalog.encontrar(piloto.arma_monthly).nome,
		piloto.HabilidadeEquipada.Nome.to_upper(),
		MonthlyCatalog.encontrar(piloto.mutacao_habilidade).nome,
		MonthlyCatalog.encontrar(piloto.modulo_nave).nome,
		UpgradeData.obter(&"cadencia").nome,
		UpgradeData.obter(&"perielio_potencia").nome,
	]
	conferir(build.itens.size() == nomes.size(), "quantidade de itens da build")
	for i in nomes.size():
		conferir(build.itens[i].nome == nomes[i] and build.itens[i].icone is Texture2D, "equipamento ou melhoria fora de ordem: %d" % i)
	conferir(build.itens[5].nivel == 2, "melhoria repetida perdeu nível")
	conferir(build.origem_celula(1) - build.origem_celula(0) == Vector2(36, 0), "encaixe horizontal")
	conferir(build.origem_celula(5) - build.origem_celula(0) == Vector2(18, 31.5), "encaixe diagonal")
	conferir(not rolagem.visible, "build apareceu durante a cutscene")
	final.inicio_ms = Time.get_ticks_msec() - 20000
	final._process(0.0)
	conferir(rolagem.visible and final.voltar.visible, "build ou botão ausente nos resultados")
	conferir(final.cor_fundo == ProjectSettings.get_setting("rendering/environment/defaults/default_clear_color"), "cor do fundo")
	for id in UpgradeData.DADOS:
		piloto.niveis_upgrades[id] = 1
	for i in range(85):
		piloto.niveis_upgrades["melhoria_teste_%d" % i] = 1
	build.capturar(piloto)
	await get_tree().process_frame
	await get_tree().process_frame
	rolagem.scroll_vertical = 9999
	conferir(rolagem.scroll_vertical > 0 and build.origem_celula(build.itens.size() - 1).y + build.CELULA.y <= rolagem.scroll_vertical + rolagem.size.y, "última melhoria fora do alcance da rolagem")
	conferir(build.itens.size() == piloto.niveis_upgrades.size() + 5, "build extensa truncada")
	piloto.arma_monthly = &""
	piloto.HabilidadeEquipada = null
	piloto.mutacao_habilidade = &""
	piloto.modulo_nave = &""
	piloto.niveis_upgrades.clear()
	build.capturar(piloto)
	conferir(build.itens.size() == 5 and build.itens[1].nome == "ARMA PADRÃO", "equipamento padrão")
	conferir(build.itens[3].icone == null and build.itens[4].icone == null, "slot vazio mostrou equipamento")
	arena.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().paused = false
	if falhas == 0:
		print("TESTE OK: colmeia, equipamentos e melhorias no final do ciclo")
	get_tree().quit(1 if falhas else 0)
