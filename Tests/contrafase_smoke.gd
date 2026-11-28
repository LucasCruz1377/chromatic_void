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
		checar(is_equal_approx(part.duracao, 12.0), "solo fora da duração esperada")
		print("Solo fase %d: %.2f s, %d notas" % [etapa, part.duracao, part.notas.size()])
		var ultima := part.notas[-1]
		checar(is_equal_approx(part.inicio(ultima.x) + part.travessia + part.cauda(ultima) + 0.45, 12.0), "última nota fora do solo")
		var acordes := {}
		for evento in part.notas:
			var t := part.inicio(evento.x)
			checar(t >= Frase.PASSAGEM.y or t + part.travessia + part.cauda(evento) <= Frase.PASSAGEM.x, "nota ou cauda invadiu a passagem")
			var cordas: Array = acordes.get(evento.x, [])
			checar(evento.y not in cordas, "acorde sobreposto")
			cordas.append(evento.y)
			acordes[evento.x] = cordas
			checar(fmod(evento.y, 2.0) == 0 and evento.y >= 0 and evento.y <= 8, "nota fora da linha")
			checar(part.aviso(evento) >= part.janela.x and part.aviso(evento) <= part.janela.y, "aviso fora da janela")
			checar(etapa >= 2 or evento.w == Frase.Articulacao.RETA, "articulação prematura")
			checar(etapa == 3 or evento.w != Frase.Articulacao.BEND, "bend prematuro")
		var maior := 0
		for cordas: Array in acordes.values():
			maior = maxi(maior, cordas.size())
		checar(maior == (2 if etapa == 1 else 3), "faltou acorde da fase")
		for grave in part.graves:
			var t := part.inicio(grave)
			checar(t + 0.22 <= Frase.PASSAGEM.x or t >= Frase.PASSAGEM.y, "grave invadiu a passagem")
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

	var nota := palco.frase.notas[6]
	var a := palco.frase.ponto(palco.area, nota, 0.1, 1)
	var b := palco.frase.ponto(palco.area, nota, 0.45, 1)
	checar(b.x < a.x and b.y < a.y, "o bend perdeu o sentido")
	var vibrato := palco.frase.notas[3]
	var linha := Frase.grau_base(vibrato, 1)
	checar(Frase.altura(vibrato, 0.135, 1) > linha and Frase.altura(vibrato, 0.405, 1) < linha, "vibrato sem oscilação")
	var idade := 0.7
	palco.tempo = palco.frase.inicio(nota.x) + idade
	nave.global_position = palco.frase.ponto(palco.area, nota, idade - 0.2, 1)
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
	testar_duelo(chefe, nave)
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


func testar_duelo(chefe: BossContrafase, nave: Player) -> void:
	var duelo = chefe.duelo
	var regra = duelo.Regra
	checar(duelo.vulneravel(regra.VERMELHO, 0, false, 0, 0), "vermelho deveria atingir")
	checar(duelo.vulneravel(regra.LARANJA, 0, false, 0, 0), "laranja deixou nave parada passar")
	checar(not duelo.vulneravel(regra.LARANJA, 40, false, 0, 0), "laranja atingiu em movimento")
	checar(not duelo.vulneravel(regra.AZUL, 24, false, 0, 0), "azul atingiu no limite seguro")
	checar(duelo.vulneravel(regra.AZUL, 25, false, 0, 0), "azul ignorou velocidade")
	checar(duelo.vulneravel(regra.ROXO, 0, true, 0, 0), "roxo ignorou carga")
	checar(not duelo.vulneravel(regra.ROXO, 0, false, 0, 0), "roxo atingiu na recarga")
	checar(duelo.vulneravel(regra.VERDE, 0, false, 49, 50), "verde ignorou altura")
	checar(not duelo.vulneravel(regra.VERDE, 0, false, 50, 50), "verde atingiu na altura do boss")
	chefe.global_position = Vector2(350, 270)
	nave.global_position = Vector2(570, 270)
	duelo.iniciar(duelo.Golpe.ACORDE, 1, nave.global_position)
	nave.invencibilidade = false
	nave.vida = nave.VIDA_MAXIMA
	duelo._physics_process(4.99)
	checar(nave.stun_acorde == 0, "acorde atingiu durante a carga")
	duelo._physics_process(0.2)
	checar(nave.stun_acorde == 4.0, "impacto deixou de atordoar por quatro segundos")
	duelo.concluir()
	nave.stun_acorde = 0.0
	for fase in range(1, 4):
		var centro := Global.obter_retangulo_area_visivel().get_center()
		var partida := centro + Vector2(-120, 80)
		chefe.global_position = partida
		duelo.iniciar(duelo.Golpe.FEIXE, fase, nave.global_position)
		duelo._physics_process(0.5)
		checar(chefe.global_position.is_equal_approx(partida.lerp(centro, 0.5)) and not duelo.feixe_ativo(), "aproximação ao centro")
		duelo._physics_process(0.5)
		checar(chefe.global_position.is_equal_approx(centro), "feixe fora do centro")
		checar(is_equal_approx(rad_to_deg(duelo.velocidade_angular()), 90 + 30 * (fase - 1)), "giro por fase")
		checar(duelo.origem_raio(0).is_equal_approx(chefe.to_global(Vector2(0, -66))), "ponta desalinhada")
		for i in range(1, fase):
			var esperado: Vector2 = duelo.direcao_raio(0).rotated(TAU * i / fase)
			checar(esperado.is_equal_approx(duelo.direcao_raio(i)), "raios assimétricos")
		var tinta_original: Color = chefe.get_node("Guitarra").self_modulate
		checar(is_equal_approx(duelo.velocidade_angular() * duelo.periodo_cor(), TAU), "troca antes da volta completa")
		for cor in 5:
			if cor > 0:
				duelo.tempo = duelo.PRELUDIO + cor * duelo.periodo_cor() - 0.001
				checar(duelo.etapa_cor() == cor - 1, "cor antecipada")
			duelo.tempo = duelo.PRELUDIO + cor * duelo.periodo_cor()
			checar(duelo.etapa_cor() == cor and not duelo.feixe_ativo(), "troca de cor sem tolerância")
			duelo._physics_process(0.3)
			checar(duelo.feixe_ativo() and duelo.etapa_cor() == cor, "ordem ou duração das cores")
			for i in fase:
				checar(duelo.visual.materiais[i].get_shader_parameter("tinta") == duelo.visual.CORES[cor], "raio com cor errada")
			checar(chefe.get_node("Guitarra").self_modulate == tinta_original, "cor aplicada ao sprite")
		duelo.concluir()
