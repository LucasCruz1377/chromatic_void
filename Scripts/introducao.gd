extends Node2D

const TEMPO_PARA_PULAR := 2.0
const CENA_MENU := "res://Rooms/TelaInicial.tscn"

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var aviso_pular: Label = $caixapular/AvisoPular
@onready var progresso_pular: ProgressBar = $caixapular/ProgressoPular

var pode_pular := false
var segurando := false
var tempo_segurando := 0.0
var dedo_ativo := -1
var saida_iniciada := false


func _ready() -> void:
	var dados: Dictionary = GerenciadorDeSave.carregar()

	# tutorialconcluido atende a quem já jogava antes da criação
	# do campo ja_iniciou_partida.
	pode_pular = bool(dados.get("ja_iniciou_jogo", false))

	aviso_pular.visible = pode_pular
	progresso_pular.visible = pode_pular
	progresso_pular.min_value = 0.0
	progresso_pular.max_value = TEMPO_PARA_PULAR
	progresso_pular.value = 0.0

	# A cena já tem Intro configurada como autoplay.
	# Não é necessário iniciar a animação outra vez aqui.


func _input(event: InputEvent) -> void:
	if not pode_pular or saida_iniciada:
		return

	if event is InputEventScreenTouch:
		var toque := event as InputEventScreenTouch

		if toque.pressed and dedo_ativo == -1:
			dedo_ativo = toque.index
			segurando = true
		elif not toque.pressed and toque.index == dedo_ativo:
			dedo_ativo = -1
			_cancelar_segurar()

	elif event is InputEventMouseButton and not OS.has_feature("mobile"):
		var mouse := event as InputEventMouseButton

		if mouse.button_index == MOUSE_BUTTON_LEFT:
			if mouse.pressed:
				segurando = true
			else:
				_cancelar_segurar()


func _process(delta: float) -> void:
	if not segurando or saida_iniciada:
		return

	tempo_segurando += delta
	progresso_pular.value = minf(tempo_segurando, TEMPO_PARA_PULAR)

	if tempo_segurando >= TEMPO_PARA_PULAR:
		saida_iniciada = true
		segurando = false
		animation_player.play("fade")


func _cancelar_segurar() -> void:
	segurando = false
	tempo_segurando = 0.0
	progresso_pular.value = 0.0


func iniciar() -> void:
	get_tree().change_scene_to_file(CENA_MENU)
