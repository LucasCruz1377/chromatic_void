extends Node2D

const LASER = preload("res://FX/ContrafaseRaio.gdshader")
const CORES := [
	Color("#ff4e6e"),
	Color("#ff9f47"),
	Color("#73ceff"),
	Color("#c28aff"),
	Color("#7df1a4"),
]
const MARFIM := Color("#fff0d0")
const ROSA := Color("#f780bd")
var duelo
var raios: Array[Line2D] = []
var materiais: Array[ShaderMaterial] = []
var pista: AudioStreamPlayer
var acorde: AudioStreamPlayer
var ultimo_passo := -1


func configurar(controlador: Node2D) -> void:
	duelo = controlador
	z_index = 1
	add_to_group(&"visual_boss_local")
	for i in 3:
		_criar_raio()
	pista = _criar_audio(preload("res://sounds/Bosses/contrafase_corda.wav"))
	acorde = _criar_audio(preload("res://sounds/Bosses/contrafase_bumbo.wav"))
	hide()


func _criar_audio(som: AudioStream) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.bus = &"SFX" if AudioServer.get_bus_index(&"SFX") >= 0 else &"Master"
	player.stream = som
	player.volume_db = -11.0
	add_child(player)
	return player


func _criar_raio() -> void:
	var linha := Line2D.new()
	var material_raio := ShaderMaterial.new()
	material_raio.shader = LASER
	material_raio.set_shader_parameter("tinta", CORES[0])
	linha.material = material_raio
	linha.width = 18
	linha.antialiased = true
	linha.texture_mode = Line2D.LINE_TEXTURE_STRETCH
	linha.add_point(Vector2.ZERO)
	linha.add_point(Vector2.UP)
	linha.add_to_group(&"visual_boss_local")
	add_child(linha)
	linha.hide()
	raios.append(linha)
	materiais.append(material_raio)


func exibir() -> void:
	ultimo_passo = -1
	show()
	queue_redraw()


func recolher() -> void:
	for linha in raios:
		linha.hide()
	pista.stop()
	acorde.stop()
	hide()


func atualizar() -> void:
	if duelo.golpe == duelo.Golpe.FEIXE:
		_atualizar_raios()
		_sonorizar_feixe()
	else:
		_sonorizar_acorde()
	queue_redraw()


func _atualizar_raios() -> void:
	var regra: int = duelo.etapa_cor()
	var tinta: Color = CORES[regra]
	var intensidade := 1.0 if duelo.feixe_ativo() else 0.48
	if duelo.antecipando_cor():
		var progresso: float = (duelo.tempo_da_cor() - duelo.periodo_cor() + duelo.AVISO_COR) / duelo.AVISO_COR
		intensidade -= 0.18 * sin(PI * progresso)
	for i in raios.size():
		var linha := raios[i]
		linha.visible = i < duelo.fase_inicial
		if not linha.visible:
			continue
		linha.set_point_position(0, to_local(duelo.origem_raio(i)))
		linha.set_point_position(1, to_local(duelo.fim_raio(i)))
		linha.width = duelo.MEIA_LARGURA * 3.6 if duelo.feixe_ativo() else 6.0
		var material_raio := materiais[i]
		material_raio.set_shader_parameter("relogio", duelo.tempo)
		material_raio.set_shader_parameter("tinta", tinta)
		material_raio.set_shader_parameter("intensidade", intensidade)


func _sonorizar_feixe() -> void:
	if duelo.tempo < duelo.PRELUDIO:
		return
	var passo: int = duelo.etapa_cor()
	if passo == ultimo_passo:
		return
	ultimo_passo = passo
	pista.pitch_scale = [0.8, 0.94, 1.12, 1.26, 1.49][passo]
	pista.play()


func _sonorizar_acorde() -> void:
	var passo := mini(5, floori(duelo.tempo))
	if passo == ultimo_passo:
		return
	ultimo_passo = passo
	if passo == 5:
		acorde.volume_db = -5.0
		acorde.play()
		pista.pitch_scale = 0.73
	else:
		pista.pitch_scale = 0.88 + passo * 0.08
	pista.play()


func _draw() -> void:
	if not is_instance_valid(duelo):
		return
	match duelo.golpe:
		duelo.Golpe.ACORDE:
			_desenhar_acorde()
		duelo.Golpe.FEIXE:
			_desenhar_feixe()


func _desenhar_acorde() -> void:
	var centro: Vector2 = duelo.PONTA
	if duelo.tempo < duelo.CARGA:
		_desenhar_carga(centro)
	else:
		_desenhar_onda(centro)


func _desenhar_carga(centro: Vector2) -> void:
	var progresso := clampf(duelo.tempo / duelo.CARGA, 0, 1)
	var travado: bool = duelo.tempo >= duelo.TRAVA_MIRA
	var tinta := MARFIM if travado else ROSA
	var angulo: float = duelo.MEIO_LEQUE
	var frente := Vector2.UP
	for sinal: float in [-1.0, 1.0]:
		var limite := frente.rotated(sinal * angulo)
		draw_dashed_line(centro, centro + limite * duelo.alcance_onda, Color(tinta, 0.32), 1.6, 14)
	for i in 5:
		var inicio := -PI * 0.5 + TAU * i / 5.0
		var cor := tinta if progresso * 5.0 >= i + 1 else Color(tinta, 0.25)
		draw_arc(centro, 15, inicio, inicio + TAU / 5.0 - 0.12, 12, cor, 2.5, true)
	var pulso := fposmod(duelo.tempo * (1.0 + progresso), 1.0)
	var raio := lerpf(44.0, 9.0, pulso)
	draw_arc(centro, raio, -PI / 2 - angulo, -PI / 2 + angulo, 32, Color(tinta, pulso), 2.0, true)
	draw_circle(centro, 2.0 + 4.0 * progresso, tinta)


func _desenhar_onda(centro: Vector2) -> void:
	var frente: float = duelo.raio_onda(duelo.tempo)
	var angulo: float = duelo.MEIO_LEQUE
	for i in 3:
		var raio := frente - i * 9.0
		if raio <= 1.0:
			continue
		var tinta := MARFIM if i == 0 else Color(ROSA, 0.58 / i)
		draw_arc(centro, raio, -PI / 2 - angulo, -PI / 2 + angulo, 72, tinta, 4.5 - i, true)


func _desenhar_feixe() -> void:
	var regra: int = duelo.etapa_cor()
	var ponta: Vector2 = duelo.PONTA
	var tinta: Color = CORES[regra]
	draw_circle(ponta, 8.0, Color(tinta, 0.4))
	draw_circle(ponta, 3.0, MARFIM)
	draw_set_transform(Vector2.ZERO, -global_rotation, Vector2.ONE)
	if regra == duelo.Regra.VERDE:
		var area := Global.obter_retangulo_area_visivel()
		var esquerda := Vector2(area.position.x - global_position.x, 0)
		var direita := Vector2(area.end.x - global_position.x, 0)
		draw_dashed_line(esquerda, direita, Color(tinta, 0.52), 1.2, 12)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
