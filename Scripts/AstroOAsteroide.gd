extends Control

@onready var texto_label: RichTextLabel = $DialogoAstro
@onready var som_digito: AudioStreamPlayer2D = $VozAstro
@onready var timer_proxima: Timer = $Timer

@export var velocidade_escrita: float = 0.03

var apresentacao: Array[String] = [
	"Olá! Eu sou o Astro."
]

var dialogo_inicial: Array[String] = [
	"Olá! Eu sou o Astro.",
	"Vou te ensinar o básico sobre o jogo.",
	"O jogo ainda está em desenvolvimento, então podem existir alguns erros.",
	"Para acelerar use W e para frear use S.",
	"Para virar a nave, use o mouse. Nas configurações você pode mudar para usar apenas o teclado.",
	"Para atirar, use o botão esquerdo do mouse ou a tecla [color=yellow]F[/color].",
	"Pressione Espaço para usar sua habilidade especial."
]

var indice_dialogo: int = 0
var escrevendo: bool = false
var tutorial_ativo: bool = false
var tutorial_terminado: bool = false
var tween_texto: Tween
var jogador: Player


func _ready() -> void:
	# O Astro só deve aparecer quando Battle_area mandar iniciar o tutorial.
	visible = false
	texto_label.visible = false
	set_process_input(false)


func apresentar() -> void:
	# Usado apenas na TelaInicial. Não marca tutorial como concluído.
	visible = true
	texto_label.visible = true
	set_process_input(false)
	falar(apresentacao[0])


func iniciar_tutorial(player: Player) -> void:
	if tutorial_ativo or tutorial_terminado:
		return

	print("ASTRO: INICIANDO TUTORIAL")

	jogador = player
	indice_dialogo = 0
	tutorial_ativo = true
	tutorial_terminado = false

	visible = true
	texto_label.visible = true
	set_process_input(true)

	if is_instance_valid(jogador):
		jogador.BloquearControle()
		jogador.BloquearGiro()

	# Garante que o primeiro texto seja mostrado já no começo do tutorial.
	falar(dialogo_inicial[indice_dialogo])


func falar(texto: String) -> void:
	if tween_texto and tween_texto.is_valid():
		tween_texto.kill()

	visible = true
	texto_label.visible = true
	texto_label.text = texto
	texto_label.visible_characters = 0

	escrevendo = true

	var total_caracteres: int = texto_label.get_parsed_text().length()

	for i in range(total_caracteres + 1):
		# Caso outra fala tenha interrompido essa.
		if not escrevendo:
			return

		texto_label.visible_characters = i

		# Toca o som a cada caractere.
		if i > 0 and som_digito.stream:
			som_digito.pitch_scale = randf_range(0.95, 1.05)
			som_digito.play()

		await get_tree().create_timer(velocidade_escrita).timeout

	escrevendo = false
	_on_fala_terminou()


func _on_fala_terminou() -> void:
	escrevendo = false


func completar_fala() -> void:
	if not escrevendo:
		return

	if tween_texto and tween_texto.is_valid():
		tween_texto.kill()

	texto_label.visible_ratio = 1.0
	escrevendo = false


func proxima_fala() -> void:
	if not tutorial_ativo:
		return

	indice_dialogo += 1

	if indice_dialogo < dialogo_inicial.size():
		falar(dialogo_inicial[indice_dialogo])
	else:
		terminar_tutorial()


func terminar_tutorial() -> void:
	if tutorial_terminado:
		return

	print("ASTRO: TUTORIAL TERMINADO")

	tutorial_ativo = false
	tutorial_terminado = true
	set_process_input(false)

	if tween_texto and tween_texto.is_valid():
		tween_texto.kill()

	escrevendo = false

	# Marca permanentemente que o tutorial já foi visto.
	GerenciadorDeSave.salvar({
		"tutorialconcluido": true
	})

	# Libera completamente o jogador.
	if is_instance_valid(jogador):
		jogador.DesbloquearControle()
		jogador.DesbloquearGiro()

	# A Battle Area volta a rodar spawn e gameplay normal.
	var area_batalha := get_tree().current_scene
	if area_batalha and area_batalha.has_method("finalizar_tutorial"):
		area_batalha.finalizar_tutorial()

	# O Astro existe apenas para o tutorial.
	queue_free()


func _input(event: InputEvent) -> void:
	if not tutorial_ativo:
		return

	var avancar := false

	# Clique esquerdo.
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			avancar = true

	# F também pode avançar porque já é um dos controles ensinados no tutorial.
	if event.is_action_pressed("atirar"):
		avancar = true

	if not avancar:
		return

	get_viewport().set_input_as_handled()

	# Um clique completa a frase; o próximo passa para a seguinte.
	if escrevendo:
		completar_fala()
	else:
		proxima_fala()
