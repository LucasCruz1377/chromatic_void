extends Node2D
class_name LimiteArenaCoop


var area_comum := Rect2()
var area_local := Rect2()
var resolucoes_diferentes := false


func configurar(nova_area: Rect2, nova_area_local: Rect2, diferentes: bool) -> void:
	area_comum = nova_area
	area_local = nova_area_local
	resolucoes_diferentes = diferentes
	z_index = 80
	queue_redraw()


func _draw() -> void:
	if not resolucoes_diferentes or area_comum.size.x <= 0.0 or area_comum.size.y <= 0.0:
		return
	var sombra := Color(0.01, 0.025, 0.075, 0.48)
	if area_local.position.y < area_comum.position.y:
		draw_rect(Rect2(area_local.position, Vector2(area_local.size.x, area_comum.position.y - area_local.position.y)), sombra)
	if area_comum.end.y < area_local.end.y:
		draw_rect(Rect2(Vector2(area_local.position.x, area_comum.end.y), Vector2(area_local.size.x, area_local.end.y - area_comum.end.y)), sombra)
	if area_local.position.x < area_comum.position.x:
		draw_rect(Rect2(Vector2(area_local.position.x, area_comum.position.y), Vector2(area_comum.position.x - area_local.position.x, area_comum.size.y)), sombra)
	if area_comum.end.x < area_local.end.x:
		draw_rect(Rect2(Vector2(area_comum.end.x, area_comum.position.y), Vector2(area_local.end.x - area_comum.end.x, area_comum.size.y)), sombra)
	var cor := Color(0.28, 0.94, 1.0, 0.92)
	draw_rect(area_comum, Color.TRANSPARENT, false, 3.0, true)
	for deslocamento in [0.0, 4.0]:
		var borda := area_comum.grow(-deslocamento)
		var brilho := cor
		brilho.a = 0.92 if deslocamento == 0.0 else 0.28
		draw_rect(borda, brilho, false, 2.0 if deslocamento == 0.0 else 5.0, true)
