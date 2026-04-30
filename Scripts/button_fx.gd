extends Node

class_name ButtonsEffectsModule

@export var ease_type : Tween.EaseType
@export var transit_type : Tween.TransitionType
@export var anim_duration : float = 0.07
@export var color_trans : float = 0.3
@export var scale_amount : Vector2 = Vector2(1.4,1.4)
@export var dist : int = 30
@export var color1 : Color = Color(1, 1, 1, 1)
@export var color2 : Color = Color(0.973, 1.0, 0.0, 1.0)
@onready var button : Button = get_parent()

var tween : Tween

func _ready() -> void:
	button.offset_left = 0
	button.modulate = color1 
	button.mouse_entered.connect(_on_mouse_hovered.bind(true))
	button.mouse_exited.connect(_on_mouse_hovered.bind(false))
	button.pressed.connect(_on_button_pressed)

func _on_mouse_hovered(hovered : bool):
	reset_tween()
	
	if tween == null:
		return
		
	tween.tween_property(button, "offset_left", dist if hovered else 0, anim_duration)
	tween.tween_property(button, "modulate", color2 if hovered else color1, color_trans)
	
func reset_tween():

	
	if tween and tween.is_valid():
		tween.kill()
	
	tween = create_tween().set_ease(ease_type).set_trans(transit_type).set_parallel(true)

func _on_button_pressed():
	# mata qualquer tween ativo (hover)
	if tween and tween.is_valid():
		tween.kill()
	
