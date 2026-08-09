extends Node2D


# ============================================================
# NODES
# ============================================================

@onready var contpontos: Label = $GUI/Pontos
@onready var player: CharacterBody2D = $Player

@onready var caixa_gameover: VBoxContainer = \
	$"GUI/caixa gameover"

@onready var tocarmusica: AudioStreamPlayer2D = \
	$tocarmusica

@onready var display_skill = $GUI/DisplaySkill
@onready var astro = $GUI/Astro


# ============================================================
# CENAS
# ============================================================

const ENEMY = preload(
	"res://Entities/InimigoSeguidor.tscn"
)


# ============================================================
# CONFIGURAÇÕES
# ============================================================

const TIMER_MAX := 3.0
const TIMER_MIN := 0.5

const MAX_ENEMIES := 30
const MAX_ENEMIES_BASE := 8


# ============================================================
# VARIÁVEIS
# ============================================================

var pontos: float = 0.0
var timer: float = TIMER_MAX

var tutorial_ativo := false
var game_over := false


# ============================================================
# READY
# ============================================================

func _ready() -> void:
	get_tree().paused = false

	Input.set_mouse_mode(
		Input.MOUSE_MODE_HIDDEN
	)

	Global.Pontos = 0
	Global.Combo = 0

	pontos = 0.0
	timer = TIMER_MAX

	game_over = false

	caixa_gameover.visible = false


	if not tocarmusica.playing:
		tocarmusica.play()


	# ========================================================
	# SAVE
	# ========================================================

	var dados := GerenciadorDeSave.carregar()

	var tutorial_concluido = \
		dados.get(
			"tutorialconcluido",
			false
		) == true


	# ========================================================
	# PRIMEIRA VEZ: MOSTRA E INICIA O TUTORIAL
	# ========================================================

	if not tutorial_concluido:
		tutorial_ativo = true

		# Não deixa inimigos ativos enquanto o Astro explica o jogo.
		for node in get_tree().get_nodes_in_group("inimigo"):
			node.queue_free()

		# O Astro começa invisível no próprio _ready().
		# Chamamos de forma adiada para garantir que toda a cena já terminou
		# de carregar antes de iniciar a primeira fala.
		astro.call_deferred("iniciar_tutorial", player)


	# ========================================================
	# TUTORIAL JÁ FOI VISTO: REMOVE O ASTRO IMEDIATAMENTE
	# ========================================================

	else:
		tutorial_ativo = false

		if is_instance_valid(astro):
			astro.queue_free()


# ============================================================
# PROCESS
# ============================================================

func _process(delta: float) -> void:
	if game_over:
		return


	# ========================================================
	# PONTOS
	# ========================================================

	var pontos_alvo = Global.Pontos

	if pontos < pontos_alvo:

		pontos = move_toward(
			pontos,
			pontos_alvo,
			20.0 * max(
				Global.Combo,
				1
			) * delta
		)


	contpontos.text = str(
		int(pontos)
	).pad_zeros(8)


	# ========================================================
	# GAME OVER
	# ========================================================

	var players = get_tree().get_nodes_in_group(
		"player"
	)

	if players.is_empty():

		game_over = true

		caixa_gameover.visible = true

		return


	# ========================================================
	# TUTORIAL
	# ========================================================

	if tutorial_ativo:
		return


	# ========================================================
	# SPAWN
	# ========================================================

	timer -= delta

	if timer <= 0.0:

		spawnar_enemy()

		timer = calcular_tempo_spawn()


# ============================================================
# FINALIZAR TUTORIAL
# ============================================================

func finalizar_tutorial() -> void:
	if not tutorial_ativo:
		return

	tutorial_ativo = false

	timer = TIMER_MAX

	print(
		"BATTLE AREA: TUTORIAL TERMINOU"
	)


# ============================================================
# TEMPO DO SPAWN
# ============================================================

func calcular_tempo_spawn() -> float:
	if not is_instance_valid(player):
		return TIMER_MAX


	var reducao := floori(
		player.nivel_atual / 5.0
	) * 0.15


	return clamp(
		TIMER_MAX - reducao,
		TIMER_MIN,
		TIMER_MAX
	)


# ============================================================
# SPAWN
# ============================================================

func spawnar_enemy() -> void:
	if tutorial_ativo:
		return


	if not is_instance_valid(player):
		return


	var spawners = get_tree().get_nodes_in_group(
		"spawners"
	)


	if spawners.is_empty():
		return


	# IMPORTANTE:
	# Seu InimigoSeguidor está no grupo "inimigo".
	var inimigos = get_tree().get_nodes_in_group(
		"inimigo"
	)


	var limite := calcular_limite_inimigos()


	if inimigos.size() >= limite:
		return


	var inimigo = ENEMY.instantiate()

	var spawner = spawners.pick_random()


	add_child(inimigo)

	inimigo.global_position = \
		spawner.global_position


# ============================================================
# LIMITE DOS INIMIGOS
# ============================================================

func calcular_limite_inimigos() -> int:
	if not is_instance_valid(player):
		return MAX_ENEMIES_BASE


	var limite := \
		MAX_ENEMIES_BASE + floori(
			player.nivel_atual / 3.0
		)


	return clamp(
		limite,
		MAX_ENEMIES_BASE,
		MAX_ENEMIES
	)


# ============================================================
# COMPATIBILIDADE COM SUA ANIMAÇÃO ANTIGA
# ============================================================

func fadeout_tutorial() -> void:
	# Seu AnimationPlayer ainda chama essa função.
	#
	# Antes ela tentava iniciar:
	#
	# tutorial_fadeout
	#
	# Essa animação não existe mais.
	#
	# Não precisamos dela atualmente,
	# mas manter esta função evita erro.
	pass
