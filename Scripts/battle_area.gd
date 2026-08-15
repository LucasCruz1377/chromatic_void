extends Node2D


const INIMIGO_SEGUIDOR := preload("res://Entities/InimigoSeguidor.tscn")
const INIMIGO_MELEE := preload("res://Entities/InimigoMelee.tscn")
const INIMIGO_INVESTIDA := preload("res://Entities/InimigoInvestida.tscn")
const INIMIGO_TANQUE := preload("res://Entities/InimigoTanque.tscn")
const INIMIGO_ATIRADOR := preload("res://Entities/InimigoAtirador.tscn")
const BOSS_PET0 := preload("res://Entities/BossPet0.tscn")

const TIMER_MAX := 3.0
const TIMER_MIN := 0.5
const MAX_ENEMIES := 30
const MAX_ENEMIES_BASE := 8


@export_category("Boss PET-0")
@export var ativar_boss_pet0: bool = true
@export var nivel_boss_pet0: int = 10
@export var testar_boss_ao_iniciar: bool = false

@onready var contpontos: Label = $GUI/Pontos
@onready var player: CharacterBody2D = $Player
@onready var caixa_gameover: VBoxContainer = $"GUI/caixa gameover"
@onready var tocarmusica: AudioStreamPlayer2D = $tocarmusica
@onready var astro = $GUI/Astro

var pontos: float = 0.0
var timer: float = TIMER_MAX
var tutorial_ativo: bool = false
var game_over: bool = false

var boss_invocado: bool = false
var boss_derrotado: bool = false
var boss_ativo: BossPet0
var boss_hud: VBoxContainer
var boss_nome: Label
var boss_vida: ProgressBar
var boss_reciclagem_texto: Label
var boss_reciclagem: ProgressBar


func _ready() -> void:
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

	Global.Pontos = 0
	Global.Combo = 0
	pontos = 0.0
	timer = TIMER_MAX
	game_over = false
	caixa_gameover.visible = false

	if not tocarmusica.playing:
		tocarmusica.play()

	var dados := GerenciadorDeSave.carregar()
	var tutorial_concluido = dados.get("tutorialconcluido", false) == true

	if not tutorial_concluido:
		tutorial_ativo = true
		limpar_inimigos_sem_recompensa()
		astro.call_deferred("iniciar_tutorial", player)
	else:
		tutorial_ativo = false
		if is_instance_valid(astro):
			astro.queue_free()

		if testar_boss_ao_iniciar:
			call_deferred("invocar_boss_pet0")


func _process(delta: float) -> void:
	if game_over:
		return

	atualizar_pontos(delta)

	if get_tree().get_nodes_in_group("player").is_empty():
		game_over = true
		caixa_gameover.visible = true
		return

	if tutorial_ativo:
		return

	if deve_invocar_boss():
		invocar_boss_pet0()
		return

	if is_instance_valid(boss_ativo):
		return

	timer -= delta
	if timer <= 0.0:
		spawnar_enemy()
		timer = calcular_tempo_spawn()


func atualizar_pontos(delta: float) -> void:
	var pontos_alvo: float = Global.Pontos
	if pontos < pontos_alvo:
		pontos = move_toward(
			pontos,
			pontos_alvo,
			20.0 * maxi(Global.Combo, 1) * delta
		)
	contpontos.text = str(int(pontos)).pad_zeros(8)


func finalizar_tutorial() -> void:
	if not tutorial_ativo:
		return
	tutorial_ativo = false
	timer = TIMER_MAX
	print("BATTLE AREA: TUTORIAL TERMINOU")


func calcular_tempo_spawn() -> float:
	if not is_instance_valid(player):
		return TIMER_MAX

	var reducao := floori(player.nivel_atual / 5.0) * 0.15
	return clampf(TIMER_MAX - reducao, TIMER_MIN, TIMER_MAX)


func spawnar_enemy() -> void:
	if tutorial_ativo or not is_instance_valid(player) or is_instance_valid(boss_ativo):
		return

	var spawners := get_tree().get_nodes_in_group("spawners")
	if spawners.is_empty():
		return

	var inimigos := get_tree().get_nodes_in_group("inimigo")
	if inimigos.size() >= calcular_limite_inimigos():
		return

	var cena_escolhida := escolher_tipo_inimigo(player.nivel_atual)
	var inimigo := cena_escolhida.instantiate() as Node2D
	if not inimigo:
		return
	var spawner := spawners.pick_random() as Node2D
	if not spawner:
		inimigo.queue_free()
		return
	add_child(inimigo)
	inimigo.global_position = spawner.global_position


func escolher_tipo_inimigo(nivel: int) -> PackedScene:
	# Repetições funcionam como pesos: o Seguidor continua sendo o mais comum.
	var opcoes: Array[PackedScene] = [INIMIGO_SEGUIDOR, INIMIGO_SEGUIDOR]

	if nivel >= 2:
		opcoes.append(INIMIGO_MELEE)
	if nivel >= 3:
		opcoes.append(INIMIGO_INVESTIDA)
	if nivel >= 4:
		opcoes.append(INIMIGO_TANQUE)
	if nivel >= 5:
		opcoes.append(INIMIGO_ATIRADOR)
	if nivel >= 7:
		opcoes.append(INIMIGO_ATIRADOR)
		opcoes.append(INIMIGO_INVESTIDA)

	return opcoes.pick_random()


func calcular_limite_inimigos() -> int:
	if not is_instance_valid(player):
		return MAX_ENEMIES_BASE

	var limite := MAX_ENEMIES_BASE + floori(player.nivel_atual / 3.0)
	return clampi(limite, MAX_ENEMIES_BASE, MAX_ENEMIES)


func deve_invocar_boss() -> bool:
	return (
		ativar_boss_pet0
		and not boss_invocado
		and not boss_derrotado
		and is_instance_valid(player)
		and player.nivel_atual >= nivel_boss_pet0
	)


func invocar_boss_pet0() -> void:
	boss_invocado = true
	limpar_inimigos_sem_recompensa()

	boss_ativo = BOSS_PET0.instantiate() as BossPet0
	add_child(boss_ativo)

	var posicao_boss := Vector2(760.0, 270.0)
	if is_instance_valid(player) and player.global_position.distance_to(posicao_boss) < 220.0:
		posicao_boss = Vector2(200.0, 270.0)
	boss_ativo.global_position = posicao_boss

	criar_hud_boss()
	boss_ativo.vida_alterada.connect(_on_boss_vida_alterada)
	boss_ativo.fase_alterada.connect(_on_boss_fase_alterada)
	boss_ativo.reciclagem_alterada.connect(_on_boss_reciclagem_alterada)
	boss_ativo.morreu.connect(_on_boss_morreu)

	_on_boss_vida_alterada(boss_ativo.Vida, boss_ativo.obter_vida_maxima_atual())
	_on_boss_fase_alterada(boss_ativo.fase)
	_on_boss_reciclagem_alterada(
		boss_ativo.reciclagem_atual,
		boss_ativo.meta_reciclagem
	)


func limpar_inimigos_sem_recompensa() -> void:
	for inimigo in get_tree().get_nodes_in_group("inimigo"):
		if is_instance_valid(inimigo):
			inimigo.queue_free()

	for projetil in get_tree().get_nodes_in_group("projetil_inimigo"):
		if is_instance_valid(projetil):
			projetil.queue_free()


func criar_hud_boss() -> void:
	if is_instance_valid(boss_hud):
		boss_hud.queue_free()

	boss_hud = VBoxContainer.new()
	boss_hud.name = "HUD_BossPet0"
	boss_hud.position = Vector2(260.0, 66.0)
	boss_hud.size = Vector2(440.0, 88.0)
	boss_hud.add_theme_constant_override("separation", 3)
	$GUI.add_child(boss_hud)

	boss_nome = Label.new()
	boss_nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_nome.add_theme_color_override("font_color", Color(0.35, 1.0, 0.65, 1.0))
	boss_nome.add_theme_font_size_override("font_size", 17)
	boss_hud.add_child(boss_nome)

	boss_vida = ProgressBar.new()
	boss_vida.custom_minimum_size = Vector2(440.0, 18.0)
	boss_vida.show_percentage = false
	boss_vida.modulate = Color(0.25, 1.0, 0.62, 1.0)
	boss_hud.add_child(boss_vida)

	boss_reciclagem_texto = Label.new()
	boss_reciclagem_texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_reciclagem_texto.add_theme_font_size_override("font_size", 12)
	boss_hud.add_child(boss_reciclagem_texto)

	boss_reciclagem = ProgressBar.new()
	boss_reciclagem.custom_minimum_size = Vector2(440.0, 10.0)
	boss_reciclagem.show_percentage = false
	boss_reciclagem.modulate = Color(1.0, 0.82, 0.18, 1.0)
	boss_hud.add_child(boss_reciclagem)


func _on_boss_vida_alterada(atual: float, maxima: float) -> void:
	if not is_instance_valid(boss_vida):
		return
	boss_vida.max_value = maxima
	boss_vida.value = atual


func _on_boss_fase_alterada(fase: int) -> void:
	if is_instance_valid(boss_nome):
		boss_nome.text = "PET-0: O RESÍDUO ETERNO — FASE %d" % fase


func _on_boss_reciclagem_alterada(atual: int, meta: int) -> void:
	if not is_instance_valid(boss_reciclagem):
		return

	boss_reciclagem.max_value = meta
	boss_reciclagem.value = atual
	if atual >= meta:
		boss_reciclagem_texto.text = "RÓTULO RECICLADO — NÚCLEO EXPOSTO!"
	else:
		boss_reciclagem_texto.text = "RECICLE OS FRAGMENTOS: %d/%d" % [atual, meta]


func _on_boss_morreu(_inimigo: InimigoBase) -> void:
	boss_derrotado = true
	boss_ativo = null
	timer = TIMER_MAX

	if is_instance_valid(boss_nome):
		boss_nome.text = "PET-0 RECICLADO!"
	if is_instance_valid(boss_reciclagem_texto):
		boss_reciclagem_texto.text = "DIA DA MÃE TERRA — 22 DE ABRIL"

	if is_instance_valid(boss_hud):
		var tween := create_tween()
		tween.tween_interval(1.5)
		tween.tween_property(boss_hud, "modulate:a", 0.0, 0.5)
		tween.tween_callback(boss_hud.queue_free)


func fadeout_tutorial() -> void:
	# Mantida porque a animação antiga da cena ainda chama este método.
	pass
