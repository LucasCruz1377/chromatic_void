extends Node

var falhas: Array[String] = []

class Alvo extends CharacterBody2D:
	var acertos := 0
	func tomarDano(_valor: float) -> void:
		acertos += 1


func verificar(condicao: bool, mensagem: String) -> void:
	if not condicao:
		falhas.append(mensagem)
		push_error(mensagem)


func _ready() -> void:
	var projetil := (load("res://Entities/fireball.tscn") as PackedScene).instantiate() as Area2D
	add_child(projetil)
	projetil.set_physics_process(false)
	projetil.configurar_id_disparo_rede("2:regressao", true)
	projetil.aplicar_estado_visual_rede(Vector2(200, 100), 0.0, Vector2.ONE, true, Color.WHITE, 2)
	projetil.aplicar_estado_visual_rede(Vector2.ZERO, PI, Vector2.ONE, false, Color.RED, 1)
	verificar(projetil.position == Vector2(200, 100) and projetil.visible, "pacote antigo fez o disparo retroceder")
	projetil.estilo_monthly = &"perielio_ray"
	projetil.aplicar_estado_visual_rede(Vector2.ZERO, PI, Vector2.ONE, true, Color.RED, 3)
	verificar(projetil.position == Vector2(200, 100) and projetil.cor_monthly == Color.RED, "pacote deslocou o feixe do cano ou perdeu a cor")
	projetil.configurar_estilo_monthly(&"harvest_boomerang", Color.WHITE, {})
	projetil.monitoring = false
	var alvo := Alvo.new()
	add_child(alvo)
	for i in 100:
		projetil._atingir_alvos_sobrepostos_bumerangue()
		projetil._atingir_com_bumerangue(alvo)
	verificar(alvo.acertos == 0, "bumerangue visual causou dano")
	projetil.configurar_id_disparo_rede("", false)
	# Um tiro real tambem pode ter monitoring desligado durante transicoes.
	projetil._atingir_alvos_sobrepostos_bumerangue()
	projetil.monitoring = true
	projetil._atingir_com_bumerangue(alvo)
	verificar(alvo.acertos == 1, "bumerangue real perdeu dano unico por alvo na ida")
	projetil.bumerangue_retornando = true
	projetil._atingir_com_bumerangue(alvo)
	verificar(alvo.acertos == 2, "bumerangue real perdeu o acerto de retorno")
	projetil._atingir_com_bumerangue(alvo)
	verificar(alvo.acertos == 2, "bumerangue repetiu dano na mesma fase")
	projetil.queue_free()
	alvo.queue_free()
	var arena := load("res://Scripts/battle_area.gd").new() as Node2D
	# Reproduz o callback atrasado sem uma MultiplayerAPI vinculada a arvore.
	arena.call("_encaminhar_fim_disparo", {"id_disparo": "2:encerrado"})
	arena.call("finalizar_disparo_rede", "2:encerrado")
	arena.free()
	await get_tree().process_frame
	print("TESTE %s: bumerangue visual, dano de ida/retorno e callbacks fora da arvore" % ("OK" if falhas.is_empty() else "FALHOU"))
	get_tree().quit(0 if falhas.is_empty() else 1)
