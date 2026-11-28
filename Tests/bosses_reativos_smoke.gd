extends Node

var falhas: Array[String] = []


func checar(condicao: bool, mensagem: String) -> void:
	if condicao:
		return
	falhas.append(mensagem)
	push_error("BOSSES REATIVOS: " + mensagem)


func _ready() -> void:
	var batalha := (load("res://Rooms/Battle_area.tscn") as PackedScene).instantiate()
	get_tree().root.add_child.call_deferred(batalha)
	await get_tree().process_frame
	get_tree().current_scene = batalha
	await get_tree().process_frame
	batalha.tutorial_ativo = false

	var constelacao := (load("res://Entities/BossConstelacaoAmparo.tscn") as PackedScene).instantiate()
	batalha.add_child(constelacao)
	constelacao.global_position = Vector2(430.0, 250.0)
	constelacao.player = batalha.player
	constelacao.fase = 3
	for ataque in range(4):
		constelacao.executar_ataque(ataque)
	checar(constelacao.poderes_executados == 4, "Constelação não executou os quatro poderes")
	for _indice in range(3):
		constelacao.tomarDano(999.0)
	checar(constelacao.exposto, "Constelação não expôs o núcleo após perder os satélites")
	checar(constelacao.reacoes_executadas >= 3, "Constelação não reagiu à quebra dos satélites")

	await get_tree().process_frame
	var movimentos := {}
	var ondas := 0
	for perigo in get_tree().get_nodes_in_group("perigo_boss_dinamico"):
		if perigo is FaixaEnergiaBoss:
			movimentos[int(perigo.movimento)] = true
		elif perigo is OndaAnelarBoss:
			ondas += 1
	checar(movimentos.has(FaixaEnergiaBoss.Movimento.RASTREADORA), "faltou faixa que rastreia antes de travar")
	checar(movimentos.has(FaixaEnergiaBoss.Movimento.LIGACAO), "faltou ligação dinâmica dos satélites")
	checar(ondas >= 5, "faltaram ondas anelares de reação e transição")

	for perigo in get_tree().get_nodes_in_group("perigo_boss_dinamico"):
		perigo.queue_free()
	constelacao.queue_free()
	await get_tree().process_frame
	for audio in batalha.find_children("*", "AudioStreamPlayer", true, false):
		(audio as AudioStreamPlayer).stop()
	for audio in batalha.find_children("*", "AudioStreamPlayer2D", true, false):
		(audio as AudioStreamPlayer2D).stop()
	batalha.queue_free()
	await get_tree().process_frame
	await get_tree().create_timer(0.25, true, false, true).timeout

	if falhas.is_empty():
		print("TESTE OK: Constelação, satélites e ondas de reação")
		get_tree().quit(0)
	else:
		get_tree().quit(1)

