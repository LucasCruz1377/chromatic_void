extends Control
class_name CristalMoedaIcone


@export var cor_base := Color(0.72, 0.30, 1.08, 1.0)


func _ready() -> void:
	custom_minimum_size = Vector2(18, 24)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	queue_redraw()


func _draw() -> void:
	var largura := size.x
	var altura := size.y
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(largura * 0.50, altura * 0.10),
			Vector2(largura * 0.82, altura * 0.50),
			Vector2(largura * 0.50, altura * 0.90),
			Vector2(largura * 0.18, altura * 0.50),
		]),
		cor_base
	)
