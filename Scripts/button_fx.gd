class_name ButtonsEffectsModule

extends Node

@export var ease_type: Tween.EaseType
@export var transit_type: Tween.TransitionType
@export var anim_duration: float = 0.07
@export var color_trans: float = 0.3
@export var scale_amount: Vector2 = Vector2(1.4, 1.4)
@export var dist: int = 30
@export var color1: Color = Color(1, 1, 1, 1)
@export var color2: Color = Color(0.973, 1.0, 0.0, 1.0)

var tween: Tween
var mouse_sobre := false
var tem_foco := false
var destacado := false

@onready var button: Button = get_parent()


func _ready() -> void:
	# Algumas cenas antigas possuem dois módulos no mesmo botão. Somente o
	# último (a configuração específica da cena) deve controlar a animação.
	for irmao in button.get_children():
		if (
			irmao != self
			and irmao.get_script() == get_script()
			and irmao.get_index() > get_index()
		):
			return

	tween = null
	button.offset_left = 0
	button.modulate = color1
	button.pivot_offset = button.size / 2

	if not button.mouse_entered.is_connected(_on_mouse_hovered.bind(true)):
		button.mouse_entered.connect(_on_mouse_hovered.bind(true))

	if not button.mouse_exited.is_connected(_on_mouse_hovered.bind(false)):
		button.mouse_exited.connect(_on_mouse_hovered.bind(false))

	if not button.focus_entered.is_connected(_on_focus_changed.bind(true)):
		button.focus_entered.connect(_on_focus_changed.bind(true))

	if not button.focus_exited.is_connected(_on_focus_changed.bind(false)):
		button.focus_exited.connect(_on_focus_changed.bind(false))

	if not button.pressed.is_connected(_on_button_pressed):
		button.pressed.connect(_on_button_pressed)


func _on_mouse_hovered(hovered: bool) -> void:
	mouse_sobre = hovered
	_atualizar_destaque()


func _on_focus_changed(focado: bool) -> void:
	tem_foco = focado
	_atualizar_destaque()


func _atualizar_destaque() -> void:
	var novo_estado := mouse_sobre or tem_foco
	if novo_estado == destacado:
		return
	destacado = novo_estado
	reset_tween()

	if tween == null:
		return

	tween.tween_property(button, "offset_left", dist if destacado else 0, anim_duration)
	tween.tween_property(button, "modulate", color2 if destacado else color1, color_trans)
	tween.tween_property(button, "scale", scale_amount if destacado else Vector2.ONE, anim_duration)


func reset_tween() -> void:
	if tween:
		tween.kill()
		tween = null

	tween = create_tween().set_ease(ease_type).set_trans(transit_type).set_parallel(true)


func _on_button_pressed() -> void:
	if tween:
		tween.kill()
		tween = null
