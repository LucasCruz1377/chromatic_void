extends Node

class_name ButtonsEffectsModule

var ease_type : Tween.EaseType
var transit_type : Tween.TransitionType
var anim_duration : float = 0.07
var color_trans : float = 0.3
var scale_amount : Vector2 = Vector2(1.4,1.4)
var pos2 : Vector2 = Vector2(30,0)
var color1 : Color = Color(1.0, 1.0, 1.0, 1.0)
var color2 : Color = Color(0.973, 1.0, 0.0, 1.0)
@onready var button : Button = get_parent()

var tween : Tween

func _ready() -> void:
	button.mouse_entered.connect(_on_mouse_hovered.bind(true))
	button.mouse_exited.connect(_on_mouse_hovered.bind(false))
	

func _on_mouse_hovered(hovered : bool):
	reset_tween()
	tween.tween_property(button, "position", pos2 if hovered else Vector2.ZERO, anim_duration)
	tween.tween_property(button, "modulate", color2 if hovered else color1, color_trans)
	
	
func reset_tween():
	if tween:
		tween.kill()
	tween = get_tree().create_tween().set_ease(ease_type).set_trans(transit_type).set_parallel(true)
