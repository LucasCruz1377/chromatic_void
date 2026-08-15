extends Node2D


var tempo: float = 0.0
var duracao: float = 1.8


func _ready() -> void:
	queue_redraw()


func _process(delta: float) -> void:
	tempo += delta
	rotation += delta * 2.2
	scale = Vector2.ONE * (0.45 + minf(tempo / 0.45, 1.0) * 0.75)
	modulate.a = clampf(1.0 - maxf(tempo - 1.0, 0.0) / 0.8, 0.0, 1.0)

	if tempo >= duracao:
		queue_free()


func _draw() -> void:
	var cor := Color(0.25, 1.0, 0.5, 1.0)
	var pontos := PackedVector2Array(
		[
			Vector2(0, -36),
			Vector2(32, 20),
			Vector2(-32, 20),
			Vector2(0, -36),
		]
	)
	draw_polyline(pontos, cor, 7.0, true)
	draw_colored_polygon(
		PackedVector2Array([Vector2(0, -36), Vector2(13, -22), Vector2(-8, -20)]),
		cor
	)
	draw_colored_polygon(
		PackedVector2Array([Vector2(32, 20), Vector2(13, 16), Vector2(23, 2)]),
		cor
	)
	draw_colored_polygon(
		PackedVector2Array([Vector2(-32, 20), Vector2(-24, 2), Vector2(-13, 16)]),
		cor
	)
