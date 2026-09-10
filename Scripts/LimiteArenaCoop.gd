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
	set_process(diferentes)
	if diferentes:
		_process(0.0)


func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_2d()
	if is_instance_valid(camera):
		position = camera.global_position - Global.TAMANHO_BASE_JOGO * 0.5


func _draw() -> void:
	if not resolucoes_diferentes or area_comum.size.x <= 0.0 or area_comum.size.y <= 0.0:
		return
	# Letterbox puro: nenhuma camada translúcida sobre a partida e nenhuma
	# moldura neon. Só a área extra do dispositivo maior fica preta.
	var sombra := Color(0.0, 0.0, 0.0, 1.0)
	if area_local.position.y < area_comum.position.y:
		draw_rect(Rect2(area_local.position, Vector2(area_local.size.x, area_comum.position.y - area_local.position.y)), sombra)
	if area_comum.end.y < area_local.end.y:
		draw_rect(Rect2(Vector2(area_local.position.x, area_comum.end.y), Vector2(area_local.size.x, area_local.end.y - area_comum.end.y)), sombra)
	if area_local.position.x < area_comum.position.x:
		draw_rect(Rect2(Vector2(area_local.position.x, area_comum.position.y), Vector2(area_comum.position.x - area_local.position.x, area_comum.size.y)), sombra)
	if area_comum.end.x < area_local.end.x:
		draw_rect(Rect2(Vector2(area_comum.end.x, area_comum.position.y), Vector2(area_local.end.x - area_comum.end.x, area_comum.size.y)), sombra)
