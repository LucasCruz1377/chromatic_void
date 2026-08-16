extends Node2D


@onready var transition: AnimationPlayer = $transition
@onready var som: AudioStreamPlayer2D = $som
@onready var botao_loja: Button = $CanvasLayer/CaixaMenu2/Shop
@onready var botao_iniciar: Button = $CanvasLayer/CaixaMenu2/Start


func _ready() -> void:
	$Astro.apresentar()
	Global.aplicar_configuracoes()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	Global.dispositivo_alterado.connect(_on_dispositivo_alterado)
	if Global.ultimo_dispositivo == &"controle":
		botao_iniciar.call_deferred("grab_focus")

	if not botao_loja.pressed.is_connected(_on_shop_pressed):
		botao_loja.pressed.connect(_on_shop_pressed)


func _process(_delta: float) -> void:
	if get_tree().paused:
		get_tree().paused = false


func _on_start_pressed() -> void:
	Global.primeira_vez_jogando = false
	click_som()
	transition.play("fade_in")
	await transition.animation_finished
	get_tree().change_scene_to_file("res://Rooms/Battle_area.tscn")


func _on_shop_pressed() -> void:
	click_som()
	transition.play("fade_in")
	await transition.animation_finished
	get_tree().change_scene_to_file("res://Rooms/Loja.tscn")


func _on_options_pressed() -> void:
	transition.play("fade_in")
	click_som()
	await transition.animation_finished
	get_tree().change_scene_to_file("res://Rooms/configuracoes.tscn")


func _on_exit_pressed() -> void:
	click_som()
	await get_tree().create_timer(0.5).timeout
	get_tree().quit()


func click_som() -> void:
	som.play()


func _on_dispositivo_alterado(tipo: StringName) -> void:
	if tipo == &"controle":
		botao_iniciar.grab_focus()


func _on_button_pressed() -> void:
	GerenciadorDeSave.deletar_save()
	print("SAVE APAGADO: o tutorial será exibido ao iniciar a batalha novamente.")
