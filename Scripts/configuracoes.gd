extends Control

var mira_mouse = Global.mira_mouse
var volume_som = Global.volume_som
var volume_musica = Global.volume_musica

@onready var ctrl_volume_som: HScrollBar = $configs_box/HBoxContainer/ctrl_volume_som
@onready var ctrl_volume_musica: HScrollBar = $configs_box/HBoxContainer2/ctrl_volume_musica


func _ready() -> void:
	carregar_configuracoes()
	if get_tree().paused:
		get_tree().paused = false

func _on_mouse_teclado_toggled(toggled_on: bool) -> void:
	if toggled_on:
		print("usar mouse")
		mira_mouse = true	
	if !toggled_on:
		print("usar teclado")
		mira_mouse = false

func _on_voltar_pressed() -> void:
	salvar_configuracoes()
	
	get_tree().change_scene_to_file("res://Rooms/TelaInicial.tscn")

func carregar_configuracoes():
	mira_mouse = Global.mira_mouse
	volume_som = Global.volume_som
	volume_musica = Global.volume_musica
	ctrl_volume_musica.value = volume_musica
	ctrl_volume_som.value = volume_som
	
func _on_ctrl_volume_som_value_changed(value: float) -> void:
	volume_som = value
	print("som: " + str(volume_som))

func _on_ctrl_volume_musica_value_changed(value: float) -> void:
	volume_musica = value
	print("Musica: " + str(volume_musica))

func salvar_configuracoes():
	Global.mira_mouse = mira_mouse 
	Global.volume_som = volume_som 
	Global.volume_musica = volume_musica
