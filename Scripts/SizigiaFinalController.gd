extends Node
class_name SizigiaFinalController

const SOM_ECLIPSE := preload("res://sounds/Bosses/snd_intro_sizigia.wav")
const INTERVALO_AMOSTRA := 0.10
const DURACAO_MEMORIA := 3.0
const ESTADO_MOVENDO := 0
const ESTADO_TRANSICAO := 4

var boss: Node2D
var historico: Array[Vector2] = []
var tempo_amostra := 0.0
var tempo_mecanica := 7.0
var fase_anterior := 0
var mecanica_ativa := false
var eclipse_absoluto_usado := false
var roubo_luz_ativo := false
var disparos_absorvidos := 0
var vida_anterior := 0.0
var dano_janela := 0.0
var tempo_janela_dano := 0.0
var audio_eclipse: AudioStreamPlayer


func _ready() -> void:
	boss = get_parent() as Node2D
	audio_eclipse = AudioStreamPlayer.new()
	audio_eclipse.stream = SOM_ECLIPSE
	add_child(audio_eclipse)
	if boss.has_signal("vida_alterada"):
		boss.connect("vida_alterada", _ao_alterar_vida)
	fase_anterior = int(boss.get("fase_atual"))
	vida_anterior = float(boss.get("Vida"))


func _process(delta: float) -> void:
	if not is_instance_valid(boss) or bool(boss.get("morto")):
		return
	var fase := int(boss.get("fase_atual"))
	if fase != fase_anterior:
		fase_anterior = fase
		if fase == 3:
			audio_eclipse.play()
	if not _tem_autoridade():
		return
	_registrar_memoria(delta)
	tempo_janela_dano = maxf(tempo_janela_dano - delta, 0.0)
	if tempo_janela_dano <= 0.0:
		dano_janela = 0.0
		tempo_janela_dano = 2.0
	if fase == 3 and not eclipse_absoluto_usado:
		var vida := float(boss.get("Vida"))
		var maxima := maxf(float(boss.call("obter_vida_maxima_atual")), 1.0)
		if vida <= maxima * 0.35:
			eclipse_absoluto_usado = true
			_iniciar_eclipse_absoluto()
			return
	if mecanica_ativa or int(boss.get("estado")) != ESTADO_MOVENDO:
		return
	tempo_mecanica -= delta
	if tempo_mecanica <= 0.0:
		_escolher_reacao(fase)


func _tem_autoridade() -> bool:
	return not multiplayer.has_multiplayer_peer() or multiplayer.is_server()


func _players_vivos() -> Array[Node]:
	var resultado: Array[Node] = []
	for alvo in get_tree().get_nodes_in_group("player"):
		if not is_instance_valid(alvo) or not alvo is Node2D:
			continue
		if alvo.has_method("esta_vivo") and not bool(alvo.call("esta_vivo")):
			continue
		resultado.append(alvo)
	return resultado


func _player_referencia() -> Node2D:
	var players := _players_vivos()
	return players[0] as Node2D if not players.is_empty() else null


func _registrar_memoria(delta: float) -> void:
	tempo_amostra -= delta
	if tempo_amostra > 0.0:
		return
	tempo_amostra = INTERVALO_AMOSTRA
	var alvo := _player_referencia()
	if not is_instance_valid(alvo):
		return
	historico.append(alvo.global_position)
	var maximo := int(DURACAO_MEMORIA / INTERVALO_AMOSTRA)
	while historico.size() > maximo:
		historico.pop_front()


func _ao_alterar_vida(nova_vida: float, _maxima: float) -> void:
	var perda := maxf(vida_anterior - nova_vida, 0.0)
	if roubo_luz_ativo:
		disparos_absorvidos += 1
	dano_janela += perda
	vida_anterior = nova_vida


func _escolher_reacao(fase: int) -> void:
	mecanica_ativa = true
	boss.set("estado", ESTADO_TRANSICAO)
	boss.set("velocity", Vector2.ZERO)
	if dano_janela >= 45.0:
		_iniciar_ocultacao(false)
	elif fase == 1:
		_iniciar_sombra_passado()
	elif fase == 2:
		_iniciar_roubo_luz()
	else:
		var alvo := _player_referencia()
		if is_instance_valid(alvo) and alvo.velocity.length() < 35.0:
			_iniciar_ocultacao(false)
		elif randf() < 0.5:
			_iniciar_sombra_passado()
		else:
			_iniciar_roubo_luz()


func _encerrar_mecanica(proximo_intervalo := 8.5) -> void:
	if not is_instance_valid(boss) or bool(boss.get("morto")):
		return
	boss.set("estado", ESTADO_MOVENDO)
	boss.set("tempo_ataque", maxf(float(boss.get("tempo_ataque")), 1.4))
	mecanica_ativa = false
	tempo_mecanica = proximo_intervalo + randf_range(0.0, 2.0)


func _iniciar_sombra_passado() -> void:
	if historico.size() < 8:
		_encerrar_mecanica(4.0)
		return
	var caminho := PackedVector2Array(historico)
	if multiplayer.has_multiplayer_peer():
		_mostrar_sombra.rpc(caminho)
	_mostrar_sombra(caminho)
	await get_tree().create_timer(1.10).timeout
	if not _boss_valido():
		return
	var passos := caminho.size()
	for indice in passos:
		var posicao := caminho[indice]
		for alvo in _players_vivos():
			if (alvo as Node2D).global_position.distance_to(posicao) <= 34.0:
				alvo.call("tomar_dano", float(boss.get("Dano")) * 0.22)
		await get_tree().create_timer(maxf(1.55 / float(passos), 0.035)).timeout
	_encerrar_mecanica()


@rpc("authority", "call_remote", "reliable")
func _mostrar_sombra(caminho: PackedVector2Array) -> void:
	var cena := get_tree().current_scene
	if not is_instance_valid(cena):
		return
	var linha := Line2D.new()
	linha.name = "MemoriaEscuraSizigia"
	linha.add_to_group("mecanica_sizigia")
	linha.points = caminho
	linha.width = 11.0
	linha.default_color = Color(0.35, 0.08, 0.50, 0.18)
	linha.z_index = 2
	cena.add_child(linha)
	var sombra := Polygon2D.new()
	sombra.polygon = PackedVector2Array([
		Vector2(22, 0), Vector2(-15, -13), Vector2(-8, 0), Vector2(-15, 13)
	])
	sombra.color = Color(0.08, 0.01, 0.12, 0.78)
	sombra.z_index = 4
	cena.add_child(sombra)
	sombra.global_position = caminho[0]
	var aviso := linha.create_tween()
	aviso.tween_property(linha, "default_color:a", 0.76, 1.10)
	await aviso.finished
	if not is_instance_valid(sombra):
		return
	var replay := sombra.create_tween()
	for ponto in caminho:
		replay.tween_property(sombra, "global_position", ponto, maxf(1.55 / float(caminho.size()), 0.035))
	replay.parallel().tween_property(linha, "default_color:a", 0.0, 1.55)
	await replay.finished
	if is_instance_valid(linha):
		linha.queue_free()
	if is_instance_valid(sombra):
		sombra.queue_free()


func _iniciar_roubo_luz() -> void:
	roubo_luz_ativo = true
	disparos_absorvidos = 0
	boss.set("multiplicador_dano_recebido", 0.0)
	if multiplayer.has_multiplayer_peer():
		_mostrar_roubo_luz.rpc()
	_mostrar_roubo_luz()
	await get_tree().create_timer(2.15).timeout
	if not _boss_valido():
		return
	roubo_luz_ativo = false
	boss.set("multiplicador_dano_recebido", 1.0)
	var ondas := clampi(1 + int(float(disparos_absorvidos) / 5.0), 1, 3)
	if boss.has_method("criar_corona"):
		boss.call("criar_corona", ondas, true)
	_encerrar_mecanica(7.5)


@rpc("authority", "call_remote", "reliable")
func _mostrar_roubo_luz() -> void:
	var halo := Line2D.new()
	halo.name = "CoroaInvertida"
	halo.add_to_group("mecanica_sizigia")
	halo.width = 8.0
	halo.default_color = Color(1.0, 0.72, 0.12, 0.92)
	var pontos := PackedVector2Array()
	for i in 49:
		pontos.append(Vector2.from_angle(TAU * float(i) / 48.0) * 92.0)
	halo.points = pontos
	boss.add_child(halo)
	var tween := halo.create_tween().set_loops(4)
	tween.tween_property(halo, "scale", Vector2(1.12, 1.12), 0.27)
	tween.tween_property(halo, "scale", Vector2.ONE, 0.27)
	await tween.finished
	if is_instance_valid(halo):
		halo.queue_free()


func _iniciar_ocultacao(suprema: bool) -> void:
	var retangulo := Global.obter_retangulo_area_visivel()
	var y := retangulo.position.y + retangulo.size.y * 0.72
	var abrigos := PackedVector2Array([
		Vector2(retangulo.position.x + retangulo.size.x * 0.28, y),
		Vector2(retangulo.position.x + retangulo.size.x * 0.72, y),
	])
	var aviso := 1.40 if not suprema else 1.85
	if multiplayer.has_multiplayer_peer():
		_mostrar_ocultacao.rpc(abrigos, aviso, suprema)
	_mostrar_ocultacao(abrigos, aviso, suprema)
	await get_tree().create_timer(aviso).timeout
	if not _boss_valido():
		return
	boss.set("gravidade_tempo", 0.0)
	for alvo in _players_vivos():
		var seguro := false
		for abrigo in abrigos:
			if (alvo as Node2D).global_position.distance_to(abrigo) <= 82.0:
				seguro = true
				break
		if not seguro:
			alvo.call("tomar_dano", float(boss.get("Dano")) * (0.95 if suprema else 0.72))
	await get_tree().create_timer(0.45).timeout
	if not _boss_valido():
		return
	boss.set("multiplicador_dano_recebido", 1.45)
	boss.set("estado", ESTADO_MOVENDO)
	await get_tree().create_timer(2.20).timeout
	if not _boss_valido():
		return
	boss.set("multiplicador_dano_recebido", 1.0)
	_encerrar_mecanica(9.5)


@rpc("authority", "call_remote", "reliable")
func _mostrar_ocultacao(abrigos: PackedVector2Array, aviso: float, suprema: bool) -> void:
	var cena := get_tree().current_scene
	for posicao in abrigos:
		var circulo := Line2D.new()
		circulo.add_to_group("mecanica_sizigia")
		circulo.width = 5.0
		circulo.default_color = Color(0.90, 0.95, 1.0, 0.94)
		var pontos := PackedVector2Array()
		for i in 49:
			pontos.append(posicao + Vector2.from_angle(TAU * float(i) / 48.0) * 82.0)
		circulo.points = pontos
		cena.add_child(circulo)
		var pulso := circulo.create_tween().set_loops(3)
		pulso.tween_property(circulo, "default_color:a", 0.30, aviso / 6.0)
		pulso.tween_property(circulo, "default_color:a", 1.0, aviso / 6.0)
		circulo.create_tween().tween_callback(circulo.queue_free).set_delay(aviso + 0.55)
	var camada := CanvasLayer.new()
	camada.layer = 88
	camada.add_to_group("mecanica_sizigia")
	cena.add_child(camada)
	var flash := ColorRect.new()
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.color = Color(1.0, 0.82, 0.22, 0.0) if not suprema else Color(1.0, 0.95, 0.76, 0.0)
	camada.add_child(flash)
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var tween := flash.create_tween()
	tween.tween_property(flash, "color:a", 0.95, aviso)
	tween.tween_property(flash, "color:a", 0.0, 0.48)
	tween.tween_callback(camada.queue_free)


func _iniciar_eclipse_absoluto() -> void:
	mecanica_ativa = true
	boss.set("estado", ESTADO_TRANSICAO)
	boss.set("velocity", Vector2.ZERO)
	boss.set("gravidade_tempo", 0.0)
	if boss.has_method("limpar_ataques_astrais"):
		boss.call("limpar_ataques_astrais")
	if multiplayer.has_multiplayer_peer():
		_tocar_eclipse.rpc()
	_tocar_eclipse()
	if boss.has_signal("subtitulo_alterado"):
		boss.emit_signal("subtitulo_alterado", "ECLIPSE ABSOLUTO — REPITA O PASSADO E BUSQUE A SOMBRA")
	await get_tree().create_timer(0.55).timeout
	if not _boss_valido():
		return
	await _eclipse_memoria()
	if not _boss_valido():
		return
	_iniciar_ocultacao(true)


func _eclipse_memoria() -> void:
	if historico.size() < 8:
		await get_tree().create_timer(0.4).timeout
		return
	var caminho := PackedVector2Array(historico)
	if multiplayer.has_multiplayer_peer():
		_mostrar_sombra.rpc(caminho)
	_mostrar_sombra(caminho)
	await get_tree().create_timer(2.75).timeout


@rpc("authority", "call_remote", "reliable")
func _tocar_eclipse() -> void:
	audio_eclipse.stop()
	audio_eclipse.play()


func _boss_valido() -> bool:
	return is_instance_valid(boss) and not bool(boss.get("morto"))


func _exit_tree() -> void:
	for node in get_tree().get_nodes_in_group("mecanica_sizigia"):
		if is_instance_valid(node):
			node.queue_free()
