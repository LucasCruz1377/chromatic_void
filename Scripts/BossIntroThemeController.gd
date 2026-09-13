extends Node
class_name BossIntroThemeController

const SONS: Dictionary = {
	&"pet0": "res://sounds/Bosses/snd_intro_pet.wav",
	&"constelacao_amparo": "res://sounds/Bosses/snd_intro_boss2.wav",
	&"no_ametista": "res://sounds/Bosses/snd_intro_ametista.wav",
	&"flor_equinocio": "res://sounds/Bosses/snd_intro_flor.wav",
	&"eclipse_colheita": "res://sounds/Bosses/snd_intro_sizigia.wav",
}

const CORES: Dictionary = {
	&"pet0": Color(0.08, 0.30, 0.42, 0.94),
	&"constelacao_amparo": Color(0.08, 0.18, 0.48, 0.94),
	&"no_ametista": Color(0.24, 0.07, 0.38, 0.94),
	&"flor_equinocio": Color(0.13, 0.34, 0.12, 0.94),
	&"eclipse_colheita": Color(0.30, 0.08, 0.34, 0.94),
}

var intro_processada: CanvasLayer
var audio_intro: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	audio_intro = AudioStreamPlayer.new()
	audio_intro.name = "AudioIntroBoss"
	add_child(audio_intro)


func _process(_delta: float) -> void:
	var batalha := get_parent()
	if not is_instance_valid(batalha):
		return
	var intro := batalha.get_node_or_null("IntroBoss") as CanvasLayer
	if not is_instance_valid(intro) or intro == intro_processada:
		return
	intro_processada = intro
	var id := StringName(batalha.get("boss_atual_id"))
	_aplicar_cor(intro, id)
	_tocar_som(id)


func _aplicar_cor(intro: CanvasLayer, id: StringName) -> void:
	var raiz := intro.get_child(0) if intro.get_child_count() > 0 else null
	if not raiz is Control:
		return
	var fundo: ColorRect
	for filho in raiz.get_children():
		if filho is ColorRect:
			fundo = filho as ColorRect
			break
	if is_instance_valid(fundo):
		fundo.color = CORES.get(id, Color(0.06, 0.08, 0.16, 0.94))


func _tocar_som(id: StringName) -> void:
	var caminho := String(SONS.get(id, ""))
	if caminho.is_empty() or not ResourceLoader.exists(caminho):
		return
	var fluxo := load(caminho) as AudioStream
	if not is_instance_valid(fluxo):
		return
	audio_intro.stop()
	audio_intro.stream = fluxo
	audio_intro.play()
