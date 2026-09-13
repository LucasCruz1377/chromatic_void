extends Control
class_name BossIntroPortrait

## Retratos vetoriais leves usados somente na apresentação dos bosses.
## Não instancia o boss real, não duplica materiais e não cria texturas de viewport.
var boss_id: StringName = &"pet0"
var cor_tema: Color = Color(0.48, 0.95, 1.0)
var tempo := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func configurar(id: StringName, cor: Color) -> void:
	boss_id = id
	cor_tema = cor
	queue_redraw()


static func nome_do_boss(id: StringName) -> String:
	match id:
		&"pet0":
			return "PET-0"
		&"constelacao_amparo":
			return "CONSTELAÇÃO DO AMPARO"
		&"no_ametista":
			return "NÓ DE AMETISTA"
		&"flor_equinocio":
			return "CAOS PRIMAVERIL"
		&"eclipse_colheita":
			return "SIZÍGIA ETERNA"
		_:
			return "ANOMALIA DO VAZIO"


func _process(delta: float) -> void:
	tempo += delta
	queue_redraw()


func _draw() -> void:
	if size.x < 2.0 or size.y < 2.0:
		return
	var escala := minf(size.x / 280.0, size.y / 230.0)
	var pulso := 1.0 + sin(tempo * 3.2) * 0.025
	draw_set_transform(size * 0.5, sin(tempo * 1.7) * 0.018, Vector2.ONE * escala * pulso)
	match boss_id:
		&"pet0":
			_desenhar_pet0()
		&"constelacao_amparo":
			_desenhar_constelacao()
		&"no_ametista":
			_desenhar_ametista()
		&"flor_equinocio":
			_desenhar_flor()
		&"eclipse_colheita":
			_desenhar_sizigia()
		_:
			_desenhar_constelacao()


func _desenhar_pet0() -> void:
	var contorno := Color(0.015, 0.07, 0.10, 1.0)
	var corpo := PackedVector2Array([
		Vector2(-106, -48), Vector2(-84, -62), Vector2(44, -62),
		Vector2(72, -43), Vector2(91, -31), Vector2(91, 31),
		Vector2(72, 43), Vector2(44, 62), Vector2(-84, 62),
		Vector2(-106, 48),
	])
	draw_colored_polygon(corpo, contorno)
	var interior := PackedVector2Array([
		Vector2(-96, -38), Vector2(-78, -50), Vector2(39, -50),
		Vector2(63, -34), Vector2(80, -25), Vector2(80, 25),
		Vector2(63, 34), Vector2(39, 50), Vector2(-78, 50),
		Vector2(-96, 38),
	])
	draw_colored_polygon(interior, Color(0.20, 0.82, 1.0, 0.94))
	draw_colored_polygon(PackedVector2Array([
		Vector2(75, -32), Vector2(115, -27), Vector2(115, 27), Vector2(75, 32)
	]), Color(0.35, 0.95, 1.0))
	draw_colored_polygon(PackedVector2Array([
		Vector2(108, -32), Vector2(132, -32), Vector2(139, -22),
		Vector2(139, 22), Vector2(132, 32), Vector2(108, 32)
	]), Color(1.0, 0.20, 0.14))
	draw_rect(Rect2(-20, -51, 47, 102), Color(1.0, 0.78, 0.12), true)
	draw_line(Vector2(-72, -34), Vector2(42, -34), Color(0.86, 1.0, 1.0), 5.0, true)


func _desenhar_constelacao() -> void:
	var centro := Color(0.16, 0.09, 0.015)
	var dourado := Color(1.0, 0.76, 0.17)
	var ciano := Color(0.35, 0.95, 1.0)
	var pontos := PackedVector2Array()
	for indice in range(6):
		pontos.append(Vector2.from_angle(tempo * 0.45 + indice * TAU / 6.0) * 47.0)
	draw_colored_polygon(pontos, centro)
	draw_circle(Vector2.ZERO, 28.0, Color(ciano, 0.58))
	draw_circle(Vector2.ZERO, 14.0, Color.WHITE)
	var satelites := PackedVector2Array()
	for indice in range(3):
		satelites.append(Vector2.from_angle(-tempo * 0.34 + indice * TAU / 3.0) * 94.0)
	for indice in range(3):
		draw_line(satelites[indice], satelites[(indice + 1) % 3], Color(dourado, 0.58), 4.0, true)
	for ponto in satelites:
		draw_circle(ponto, 18.0, dourado)
		draw_arc(ponto, 27.0, -2.1, 2.1, 24, ciano, 5.0, true)
		draw_circle(ponto, 6.0, Color.WHITE)


func _desenhar_ametista() -> void:
	var roxo := Color(0.78, 0.36, 1.0)
	var rosa := Color(1.0, 0.28, 0.68)
	var cristal := PackedVector2Array([
		Vector2(0, -61), Vector2(42, 0), Vector2(0, 69), Vector2(-42, 0)
	])
	draw_colored_polygon(cristal, rosa)
	draw_polyline(PackedVector2Array([
		cristal[0], cristal[1], cristal[2], cristal[3], cristal[0]
	]), Color.WHITE, 4.0, true)
	for indice in range(4):
		var angulo := tempo * (0.32 if indice % 2 == 0 else -0.32) + indice * TAU / 4.0
		var ponto := Vector2.from_angle(angulo) * 103.0
		draw_line(Vector2.ZERO, ponto, Color(roxo, 0.82), 12.0, true)
		draw_line(Vector2.ZERO, ponto, Color(rosa, 0.72), 4.0, true)
		draw_circle(ponto, 17.0, roxo)
		draw_circle(ponto, 6.0, Color.WHITE)
	draw_arc(Vector2.ZERO, 79.0, tempo * 0.3, tempo * 0.3 + 4.8, 48, Color(roxo, 0.72), 6.0, true)


func _desenhar_flor() -> void:
	var verde := Color(0.20, 0.62, 0.18)
	var petala := Color(0.94, 0.28, 0.65)
	var miolo := Color(1.0, 0.78, 0.16)
	for indice in range(6):
		var angulo := tempo * 0.18 + indice * TAU / 6.0
		var centro_petala := Vector2.from_angle(angulo) * 64.0
		draw_set_transform_matrix(Transform2D(angulo + PI * 0.5, centro_petala))
		draw_colored_polygon(PackedVector2Array([
			Vector2(0, -46), Vector2(27, -5), Vector2(18, 31),
			Vector2(0, 43), Vector2(-18, 31), Vector2(-27, -5)
		]), petala)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for indice in range(12):
		var angulo := indice * TAU / 12.0
		draw_line(Vector2.from_angle(angulo) * 89.0, Vector2.from_angle(angulo + 0.10) * 113.0, verde, 7.0, true)
	draw_circle(Vector2.ZERO, 43.0, verde)
	draw_circle(Vector2.ZERO, 31.0, miolo)
	draw_circle(Vector2(-9, -10), 8.0, Color(1.0, 1.0, 0.76))


func _desenhar_sizigia() -> void:
	var dourado := Color(1.0, 0.62, 0.12)
	var lunar := Color(0.60, 0.74, 1.0)
	var eclipse := Color(0.06, 0.025, 0.11)
	for raio in [109.0, 98.0, 88.0]:
		draw_arc(Vector2.ZERO, raio, -2.45, 2.45, 72, Color(dourado, 0.36), 5.0, true)
	draw_circle(Vector2(-22, 0), 77.0, dourado)
	draw_circle(Vector2(20, 0), 78.0, eclipse)
	draw_arc(Vector2.ZERO, 82.0, 0.0, TAU, 72, lunar, 5.0, true)
	draw_circle(Vector2.ZERO, 18.0, Color(0.98, 0.92, 1.0))
	for indice in range(8):
		var angulo := tempo * 0.22 + indice * TAU / 8.0
		var inicio := Vector2.from_angle(angulo) * 116.0
		var fim := Vector2.from_angle(angulo) * 137.0
		draw_line(inicio, fim, Color(lunar, 0.70), 4.0, true)
