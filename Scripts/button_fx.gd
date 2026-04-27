extends Node

class_name ButtonsEffectsModule

@export var ease_type : Tween.EaseType
@export var transit_type : Tween.TransitionType
@export var anim_duration : float = 0.07
@export var color_trans : float = 0.3
@export var dist : int = 60
@export var color1 : Color = Color(1.0, 1.0, 1.0, 1.0)
@export var color2 : Color = Color(0.973, 1.0, 0.0, 1.0)
@onready var button : Button = get_parent()

var tween : Tween

func _ready() -> void:
	
	button.modulate = color1
	
	button.mouse_entered.connect(_on_mouse_hovered.bind(true))
	button.mouse_exited.connect(_on_mouse_hovered.bind(false))
	

func _on_mouse_hovered(hovered : bool):
	reset_tween()
	tween.tween_property(button, "offset_left", dist if hovered else 0, anim_duration)
	tween.tween_property(button, "modulate", color2 if hovered else color1, color_trans)
	
func reset_tween():
	if tween:
		tween.kill()
	tween = get_tree().create_tween().set_ease(ease_type).set_trans(transit_type).set_parallel(true)
