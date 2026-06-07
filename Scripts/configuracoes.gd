extends Control

var mira_mouse = Global.mira_mouse
var volume_som = Global.volume_som
var volume_musica = Global.volume_musica

@onready var ctrl_volume_som: HScrollBar = $configs_box/HBoxContainer/ctrl_volume_som
@onready var ctrl_volume_musica: HScrollBar = $configs_box/HBoxContainer2/ctrl_volume_musica
@onready var mouse_teclado: CheckButton = $configs_box/mouse_teclado
@onready var debug_text: Label = $Debug_text


func _ready() -> void:
	carregar_configuracoes()
	if get_tree().paused:
		get_tree().paused = false

func _process(_delta: float) -> void:
	debug_text.text = "Volume Musica: {vol_mus} \n Volume Som: {vol_som} \n Usar Mouse: {mouse}\n".format({
			"vol_mus" : snapped(Global.volume_musica,0.1),
			"vol_som" : snapped(Global.volume_som,0.1),
			"mouse" : Global.mira_mouse
		})
	var musicbus = AudioServer.get_bus_index("Music")
	var soundbus = AudioServer.get_bus_index("Sound") 
	AudioServer.set_bus_volume_db(musicbus,Global.volume_musica)
	AudioServer.set_bus_volume_db(soundbus,Global.volume_som)

func _on_mouse_teclado_toggled(toggled_on: bool) -> void:
	mira_mouse = toggled_on
	salvar_configuracoes()

func _on_voltar_pressed() -> void:
	salvar_configuracoes()
	
	get_tree().change_scene_to_file("res://Rooms/TelaInicial.tscn")

func carregar_configuracoes():
	mira_mouse = Global.mira_mouse
	volume_som = Global.volume_som
	volume_musica = Global.volume_musica
	
	ctrl_volume_musica.value = volume_musica
	ctrl_volume_som.value = volume_som
	mouse_teclado.button_pressed = mira_mouse
	
	
func _on_ctrl_volume_som_value_changed(value: float) -> void:
	volume_som = value
	salvar_configuracoes()

func _on_ctrl_volume_musica_value_changed(value: float) -> void:
	volume_musica = value
	salvar_configuracoes()

func salvar_configuracoes():
	Global.mira_mouse = mira_mouse
	Global.volume_som = volume_som 
	Global.volume_musica = volume_musica
