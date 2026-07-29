extends Control

@onready var h_box_container: HBoxContainer = $HBoxContainer

var itematual = 1
var tween : Tween
var itemsAVenda : Array

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			itematual += 1
			if itematual > itemsAVenda.size() - 1:
				itematual = 0
			mover()
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			itematual -= 1 
			if itematual < 0:
				itematual = itemsAVenda.size() - 1
			mover()
func _ready() -> void:
	itemsAVenda = h_box_container.get_children()

func mover():
	tween = create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)

	tween.tween_property(h_box_container, "global_position", Vector2(-itemsAVenda[itematual].position.x + 175,60.0), 0.9)
	

func _on_left_pressed() -> void:
	itematual -= 1
	
	if itematual < 0:
		itematual = itemsAVenda.size() - 1
	mover()

func _on_right_pressed() -> void:
	itematual += 1
	if itematual > itemsAVenda.size():
		itematual = 0
	
	mover()
