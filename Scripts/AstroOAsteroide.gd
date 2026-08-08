extends Control

@onready var texto_label: RichTextLabel = $DialogoAstro
@onready var som_digito: AudioStreamPlayer2D = $VozAstro
@onready var timer_proxima: Timer = $Timer

@export var velocidade_escrita: float = 0.03
@export var tempo_espera_frase: float = 5.0

# ============================================================
# DIÁLOGOS
# ============================================================

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

var curiosidades: Array[String] = [
	"T_CURIOSIDADE1",
	"T_CURIOSIDADE2",
	"T_CURIOSIDADE3",
	"T_CURIOSIDADE4",
	"T_CURIOSIDADE5",
	"T_CURIOSIDADE6"
]


# ============================================================
# ESTADO
# ============================================================

var indice_dialogo := 0
var escrevendo := false

var tween_texto: Tween

# Pode ser:
# "apresentacao"
# "tutorial"
# "curiosidade"
var modo := "curiosidade"

var tutorial_terminado := false


# ============================================================
# READY
# ============================================================

func _ready() -> void:

	timer_proxima.wait_time = tempo_espera_frase

	texto_label.visible = false


# ============================================================
# FALAR
# ============================================================

func falar(texto: String) -> void:

	if tween_texto:
		tween_texto.kill()

	texto_label.visible = true
	texto_label.text = texto
	texto_label.visible_ratio = 0

	escrevendo = true

	tween_texto = create_tween()

	tween_texto.tween_property(
		texto_label,
		"visible_ratio",
		1.0,
		texto.length() * velocidade_escrita
	)

	tween_texto.finished.connect(_terminou_de_escrever)


func _terminou_de_escrever() -> void:

	escrevendo = false


# ============================================================
# APRESENTAÇÃO NA TELA INICIAL
# ============================================================

func apresentar() -> void:

	modo = "apresentacao"

	falar(apresentacao[0])


# ============================================================
# INICIAR TUTORIAL
# ============================================================

func iniciar_tutorial(player: Player) -> void:

	modo = "tutorial"

	indice_dialogo = 0
	tutorial_terminado = false

	# Bloqueia o jogador sem pausar a árvore.
	player.BloquearControle()
	player.BloquearGiro()

	falar(dialogo_inicial[indice_dialogo])


# ============================================================
# PRÓXIMA FALA
# ============================================================

func proxima_fala() -> void:

	if modo == "tutorial":

		indice_dialogo += 1

		if indice_dialogo < dialogo_inicial.size():

			falar(dialogo_inicial[indice_dialogo])

		else:

			finalizar_tutorial()


# ============================================================
# FINALIZAR TUTORIAL
# ============================================================

func finalizar_tutorial() -> void:
	
	tutorial_terminado = true

	GerenciadorDeSave.salvar({"tutorialconcluido" : true})
	texto_label.visible = false

	var player = get_tree().get_first_node_in_group("player")

	if player:

		player.DesbloquearControle()
		player.DesbloquearGiro()

	modo = "curiosidade"


# ============================================================
# CURIOSIDADE
# ============================================================

func iniciar_curiosidades() -> void:

	modo = "curiosidade"

	timer_proxima.start()


func falar_curiosidade() -> void:

	if modo != "curiosidade":
		return

	falar(curiosidades.pick_random())

	timer_proxima.start()


# ============================================================
# TIMER
# ============================================================

func _on_timer_timeout() -> void:

	if modo == "curiosidade":

		falar_curiosidade()


# ============================================================
# INPUT
# ============================================================

func _process(_delta: float) -> void:

	if Input.is_action_just_pressed("atirar"):

		# Se ainda está escrevendo,
		# completa a frase imediatamente.
		if escrevendo:

			if tween_texto:
				tween_texto.kill()

			texto_label.visible_ratio = 1.0
			escrevendo = false

		# Se terminou de escrever,
		# avança o tutorial.
		elif modo == "tutorial":

			proxima_fala()
