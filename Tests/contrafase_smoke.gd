extends Node

const Frase = preload("res://Scripts/FraseContrafase.gd")
var falhas: Array[String] = []


func checar(ok: bool, detalhe: String) -> void:
	if not ok:
		falhas.append(detalhe)
		push_error(detalhe)


func _ready() -> void:
	var arena := preload("res://Rooms/Battle_area.tscn").instantiate()
	get_tree().root.add_child.call_deferred(arena)
	await get_tree().process_frame
	get_tree().current_scene = arena
	await get_tree().process_frame
	arena.tutorial_ativo = false
	arena.spawns_pausados_desenvolvedor = true
	arena._criar_boss(&"contrafase", 3, true)
	var chefe := arena.boss_ativo as BossContrafase
	var palco := chefe.partitura
	var nave := arena.player as Player
	var volume: float = arena.tocarmusica.volume_db
	for etapa in range(1, 4):
		var part := Frase.new(etapa)
		for evento in part.notas:
			checar(fmod(evento.y, 2.0) == 0 and evento.y >= 0 and evento.y <= 8, "nota fora da linha")
			checar(part.aviso(evento) >= part.janela.x and part.aviso(evento) <= part.janela.y, "aviso fora da janela")
			checar(etapa >= 2 or evento.w == Frase.Articulacao.RETA, "articulação prematura")
			checar(etapa == 3 or evento.w != Frase.Articulacao.BEND, "bend prematuro")
	chefe.Vida = chefe.obter_vida_maxima_atual() * 0.60
	chefe.atualizar_fase()
	checar(chefe.fase == 2, "fase intermediária ausente")
	chefe.Vida = chefe.obter_vida_maxima_atual() * 0.30
	chefe.iniciar_partitura()
	checar(chefe.fase == 3, "fase final ausente")
	await get_tree().physics_frame
	await get_tree().physics_frame
	checar(palco.is_visible_in_tree() and not chefe.visible, "a pauta precisa permanecer visível sem a guitarra")
	checar(not chefe.is_in_group(&"inimigo") and chefe.silhueta.disabled, "colisão ou mira ativa durante o teleporte")
	var vida := chefe.Vida
	chefe.tomarDano(70.0)
	chefe.receber_eco_laco(70.0)
	checar(is_equal_approx(vida, chefe.Vida), "chefe invisível recebeu dano")
	get_tree().paused = true
	var antes := palco.tempo
	await get_tree().create_timer(0.08, true).timeout
	checar(is_equal_approx(palco.tempo, antes), "a pauta avançou na pausa")
	get_tree().paused = false

	var nota := palco.frase.notas[5]
	var a := palco.frase.ponto(palco.area, nota, 0.1, 1)
	var b := palco.frase.ponto(palco.area, nota, 0.45, 1)
	checar(b.x < a.x and b.y < a.y, "o bend perdeu o sentido")
	var vibrato := palco.frase.notas[8]
	var linha := Frase.grau_base(vibrato, 1)
	checar(Frase.altura(vibrato, 0.135, 1) > linha and Frase.altura(vibrato, 0.405, 1) < linha, "vibrato sem oscilação")
	var idade := 0.7
	palco.tempo = palco.frase.inicio(nota.x) + idade
	nave.global_position = palco.frase.ponto(palco.area, nota, idade - 0.25, 1)
	nave.invencibilidade = false
	var hp := nave.vida
	palco._testar_colisoes(1.0 / 60)
	checar(nave.vida < hp, "a cauda desenhada não atingiu a nave")
	hp = nave.vida
	nave.invencibilidade = false
	palco._testar_colisoes(1.0 / 60)
	checar(is_equal_approx(nave.vida, hp), "uma nota sustentada atingiu duas vezes a mesma nave")

	var limites := palco.limites_nave()
	nave.global_position = Vector2(limites.end.x + 60, limites.get_center().y)
	nave.velocity = Vector2(325, 75)
	nave.atualizar_limites(1.0 / 60)
	checar(is_equal_approx(nave.global_position.x, limites.end.x) and is_equal_approx(nave.velocity.y, 75), "o vento inverteu a borda ou removeu a velocidade tangencial")
	palco.tempo = palco.frase.duracao - 0.001
	palco._physics_process(1.0 / 60)
	await get_tree().physics_frame
	await get_tree().physics_frame
	checar(chefe.visible and not chefe.silhueta.disabled and not palco.ativa, "o retorno não recuperou a janela de dano")
	chefe.tomarDano(1)
	checar(chefe.Vida < vida and is_equal_approx(volume, arena.tocarmusica.volume_db), "dano ou música não restaurados")
	nave.global_position.x = palco.area.end.x + 4
	nave.atualizar_limites()
	checar(is_equal_approx(nave.global_position.x, palco.area.position.x + 4), "wrap não voltou depois do solo")
	chefe.iniciar_partitura()
	arena.limpar_inimigos_sem_recompensa()
	await get_tree().process_frame
	await get_tree().process_frame
	checar(get_tree().get_first_node_in_group(&"partitura_ativa") == null and is_equal_approx(volume, arena.tocarmusica.volume_db), "bordas ou música sobreviveram à remoção do chefe")
	arena.queue_free()
	await get_tree().process_frame
	await get_tree().create_timer(0.25).timeout
	if falhas.is_empty():
		print("TESTE OK: Contrafase, partitura, dano, pausa, bordas e retorno")
	get_tree().quit(0 if falhas.is_empty() else 1)
