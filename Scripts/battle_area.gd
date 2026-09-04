extends Node2D


const DadosSetores = preload("res://Scripts/SectorData.gd")
const PainelDesenvolvedorCena = preload("res://Scripts/PainelDesenvolvedor.gd")
const ControlesMobileCena = preload("res://Scripts/ControlesMobile.gd")

const INIMIGOS: Dictionary = {
	&"seguidor": preload("res://Entities/InimigoSeguidor.tscn"),
	&"melee": preload("res://Entities/InimigoMelee.tscn"),
	&"investida": preload("res://Entities/InimigoInvestida.tscn"),
	&"tanque": preload("res://Entities/InimigoTanque.tscn"),
	&"atirador": preload("res://Entities/InimigoAtirador.tscn"),
}

const BOSSES: Dictionary = {
	&"pet0": preload("res://Entities/BossPet0.tscn"),
	&"flor_equinocio": preload("res://Entities/BossFlorEquinocio.tscn"),
	&"eclipse_colheita": preload("res://Entities/BossEclipseColheita.tscn"),
	&"sentinela_dourada": preload("res://Entities/BossSentinelaDourada.tscn"),
	&"ruptura_lilas": preload("res://Entities/BossRupturaLilas.tscn"),
}

const ASTEROIDE_BONUS := preload("res://Entities/AsteroideBonus.tscn")
const TIMER_MAX := 2.4
const TIMER_MIN := 0.72
const MAX_ENEMIES := 26
const MAX_ENEMIES_BASE := 5
const INTERVALO_BOSS := 10
# Construído em duas partes porque a faixa é adicionada pelo autor ao projeto e
# não faz parte dos pacotes de código. O caminho final continua sendo
# res://sounds/OST/LotusDance.mp3.
const CAMINHO_LOTUS_DANCE := "res:/" + "/sounds/OST/LotusDance.mp3"

@export_category("Asteroides bônus")
@export_range(8.0, 90.0, 1.0) var intervalo_asteroide_min: float = 18.0
@export_range(8.0, 120.0, 1.0) var intervalo_asteroide_max: float = 32.0
@export_range(0.0, 1.0, 0.05) var chance_asteroide: float = 0.65
@export_range(0, 4, 1) var max_asteroides: int = 2

@export_category("Setores e bosses")
@export var ativar_bosses: bool = true
@export var testar_boss_ao_iniciar: bool = false

@onready var contpontos: Label = $GUI/Pontos
@onready var player: CharacterBody2D = $Player
@onready var caixa_gameover: VBoxContainer = $"GUI/caixa gameover"
@onready var tocarmusica: AudioStreamPlayer2D = $tocarmusica
@onready var astro = $GUI/Astro
@onready var fundo_original: CanvasItem = $espaco
@onready var tela_upgrades: Control = $GUI/TelaUpgrades

var pontos: float = 0.0
var timer: float = TIMER_MAX
var tutorial_ativo: bool = false
var game_over: bool = false
var tempo_asteroide: float = 0.0

# A partida sempre começa aqui. Não existe tela de escolha antes do PET-0.
var setor_atual: StringName = &"vazio_inicial"
var setores_concluidos: Array[StringName] = []
var proximo_nivel_boss: int = INTERVALO_BOSS
var escolha_setor_ativa: bool = false
var camada_escolha: CanvasLayer
var fundo_setor: ColorRect
var rotulo_setor: Label

var boss_ativo: InimigoBase
var boss_atual_id: StringName = &""
var boss_hud: VBoxContainer
var boss_nome: Label
var boss_vida: ProgressBar
var boss_detalhe_texto: Label
var boss_detalhe: ProgressBar
var spawns_pausados_desenvolvedor := false
var boss_em_teste := false
var painel_desenvolvedor: PainelDesenvolvedor
var controles_mobile: ControlesMobile
var musica_partida_padrao: AudioStream
var musica_boss_ativa := false


func _ready() -> void:
	get_tree().paused = false
	Global.definir_emulacao_mouse_mobile(false)
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	Global.Pontos = 0
	Global.Combo = 0
	pontos = 0.0
	timer = TIMER_MAX
	game_over = false
	tempo_asteroide = randf_range(intervalo_asteroide_min, intervalo_asteroide_max)
	caixa_gameover.visible = false
	if tela_upgrades.has_signal("estado_alterado"):
		tela_upgrades.connect("estado_alterado", _on_menu_upgrades_estado_alterado)
	criar_visual_setor()
	aplicar_setor(&"vazio_inicial")
	if Global.modo_desenvolvedor:
		painel_desenvolvedor = PainelDesenvolvedorCena.new()
		painel_desenvolvedor.name = "PainelDesenvolvedor"
		add_child(painel_desenvolvedor)
		painel_desenvolvedor.configurar(self, player)
	if Global.deve_exibir_controles_toque():
		controles_mobile = ControlesMobileCena.new()
		controles_mobile.name = "ControlesMobile"
		add_child(controles_mobile)
		controles_mobile.configurar(self, player)

	musica_partida_padrao = tocarmusica.stream
	if not tocarmusica.playing:
		tocarmusica.play()

	var dados: Dictionary = GerenciadorDeSave.carregar()
	var tutorial_concluido: bool = dados.get("tutorialconcluido", false) == true
	if not tutorial_concluido:
		tutorial_ativo = true
		limpar_inimigos_sem_recompensa()
		astro.call_deferred("iniciar_tutorial", player)
	else:
		tutorial_ativo = false
		if is_instance_valid(astro):
			astro.queue_free()

	if testar_boss_ao_iniciar:
		proximo_nivel_boss = 1


func _exit_tree() -> void:
	Global.salvar_conquistas()
	Global.limpar_controle_toque()
	Global.definir_emulacao_mouse_mobile(true)


func _process(delta: float) -> void:
	if game_over or escolha_setor_ativa:
		return
	atualizar_pontos(delta)
	if get_tree().get_nodes_in_group("player").is_empty():
		game_over = true
		Global.definir_emulacao_mouse_mobile(true)
		caixa_gameover.visible = true
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		return
	if tutorial_ativo:
		return
	if spawns_pausados_desenvolvedor:
		return

	processar_asteroides(delta)
	if deve_invocar_boss():
		invocar_boss_do_setor()
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
	var reducao := floori(maxi(player.nivel_atual - 1, 0) / 3.0) * 0.12
	return clampf(TIMER_MAX - reducao, TIMER_MIN, TIMER_MAX)


func spawnar_enemy() -> void:
	if tutorial_ativo or not is_instance_valid(player) or is_instance_valid(boss_ativo):
		return
	var spawners := get_tree().get_nodes_in_group("spawners")
	if spawners.is_empty():
		return
	if get_tree().get_nodes_in_group("inimigo").size() >= calcular_limite_inimigos():
		return

	var cena_escolhida := escolher_tipo_inimigo(player.nivel_atual)
	var inimigo := cena_escolhida.instantiate() as Node2D
	var spawner := spawners.pick_random() as Node2D
	if not is_instance_valid(inimigo) or not is_instance_valid(spawner):
		if is_instance_valid(inimigo):
			inimigo.queue_free()
		return
	add_child(inimigo)
	inimigo.global_position = spawner.global_position


func escolher_tipo_inimigo(nivel: int) -> PackedScene:
	# O setor inicial ensina uma ameaça por vez. Inimigos simples aparecem em
	# maior frequência para a primeira evolução chegar cedo sem lotar a arena.
	if setor_atual == &"vazio_inicial":
		var opcoes_originais: Array[PackedScene] = [
			INIMIGOS[&"seguidor"],
			INIMIGOS[&"seguidor"],
			INIMIGOS[&"seguidor"]
		]
		if nivel >= 3:
			opcoes_originais.append(INIMIGOS[&"melee"])
		if nivel >= 5:
			opcoes_originais.append(INIMIGOS[&"investida"])
		if nivel >= 6:
			opcoes_originais.append(INIMIGOS[&"atirador"])
		if nivel >= 7:
			opcoes_originais.append(INIMIGOS[&"tanque"])
		if nivel >= 8:
			opcoes_originais.append(INIMIGOS[&"atirador"])
			opcoes_originais.append(INIMIGOS[&"investida"])
		return opcoes_originais.pick_random()

	var composicao: Array = DadosSetores.obter(setor_atual).get("inimigos", [])
	if composicao.is_empty():
		return INIMIGOS[&"seguidor"]
	var peso_total := 0.0
	for entrada in composicao:
		peso_total += float(entrada[1])
	var alvo := randf() * peso_total
	for entrada in composicao:
		alvo -= float(entrada[1])
		if alvo <= 0.0:
			return INIMIGOS.get(StringName(entrada[0]), INIMIGOS[&"seguidor"])
	return INIMIGOS[&"seguidor"]


func calcular_limite_inimigos() -> int:
	if not is_instance_valid(player):
		return MAX_ENEMIES_BASE
	var limite := MAX_ENEMIES_BASE + floori(maxi(player.nivel_atual - 1, 0) / 3.0)
	return clampi(limite, MAX_ENEMIES_BASE, MAX_ENEMIES)


func processar_asteroides(delta: float) -> void:
	tempo_asteroide -= delta
	if tempo_asteroide > 0.0:
		return
	tempo_asteroide = randf_range(intervalo_asteroide_min, intervalo_asteroide_max)
	if max_asteroides <= 0 or randf() > chance_asteroide:
		return
	if get_tree().get_nodes_in_group("asteroide_bonus").size() < max_asteroides:
		spawnar_asteroide_bonus()


func spawnar_asteroide_bonus() -> void:
	if not is_instance_valid(player):
		return
	var spawners := get_tree().get_nodes_in_group("spawners")
	if spawners.is_empty():
		return
	var spawner := spawners.pick_random() as Node2D
	var asteroide := ASTEROIDE_BONUS.instantiate() as InimigoBase
	if not is_instance_valid(asteroide) or not is_instance_valid(spawner):
		return
	add_child(asteroide)
	asteroide.global_position = spawner.global_position
	if asteroide.has_method("configurar_movimento"):
		var destino := Vector2(480.0, 270.0) + Vector2(
			randf_range(-180.0, 180.0),
			randf_range(-110.0, 110.0)
		)
		asteroide.configurar_movimento(destino)


func deve_invocar_boss() -> bool:
	return (
		ativar_bosses
		and setor_atual not in setores_concluidos
		and is_instance_valid(player)
		and not is_instance_valid(boss_ativo)
		and player.nivel_atual >= proximo_nivel_boss
	)


func invocar_boss_do_setor() -> void:
	if is_instance_valid(boss_ativo) or setor_atual in setores_concluidos:
		return
	limpar_inimigos_sem_recompensa()
	var dados_setor := DadosSetores.obter(setor_atual)
	_criar_boss(
		StringName(dados_setor.get("boss", &"pet0")),
		setores_concluidos.size() + 1,
		false
	)


func invocar_boss_teste(id: StringName) -> void:
	if not Global.modo_desenvolvedor or not BOSSES.has(id):
		return
	limpar_arena_teste()
	_criar_boss(id, 1, true)


func _criar_boss(id: StringName, dificuldade: int, em_teste: bool) -> void:
	boss_atual_id = id
	boss_em_teste = em_teste
	var cena: PackedScene = BOSSES.get(boss_atual_id, BOSSES[&"pet0"])
	boss_ativo = cena.instantiate() as InimigoBase
	if not is_instance_valid(boss_ativo):
		boss_em_teste = false
		push_error("Não foi possível criar o boss %s." % boss_atual_id)
		return
	add_child(boss_ativo)
	var posicao_boss := Vector2(760.0, 270.0)
	if player.global_position.distance_to(posicao_boss) < 220.0:
		posicao_boss = Vector2(200.0, 270.0)
	boss_ativo.global_position = posicao_boss
	if boss_ativo.has_method("configurar_dificuldade"):
		boss_ativo.call("configurar_dificuldade", dificuldade)
	aplicar_musica_boss(id)

	criar_hud_boss()
	boss_ativo.vida_alterada.connect(_on_boss_vida_alterada)
	if boss_ativo.has_signal("fase_alterada"):
		boss_ativo.connect("fase_alterada", _on_boss_fase_alterada)
	if boss_ativo.has_signal("subtitulo_alterado"):
		boss_ativo.connect("subtitulo_alterado", _on_boss_subtitulo_alterado)
	if boss_ativo.has_signal("reciclagem_alterada"):
		boss_ativo.connect("reciclagem_alterada", _on_boss_reciclagem_alterada)
	boss_ativo.morreu.connect(_on_boss_morreu)
	_on_boss_vida_alterada(boss_ativo.Vida, boss_ativo.obter_vida_maxima_atual())
	_on_boss_fase_alterada(1)
	if boss_ativo.has_method("obter_subtitulo_boss"):
		_on_boss_subtitulo_alterado(str(boss_ativo.call("obter_subtitulo_boss")))
	if boss_atual_id == &"pet0":
		var pet0 := boss_ativo as BossPet0
		_on_boss_reciclagem_alterada(pet0.reciclagem_atual, pet0.meta_reciclagem)


func limpar_inimigos_sem_recompensa() -> void:
	for inimigo in get_tree().get_nodes_in_group("inimigo"):
		if is_instance_valid(inimigo):
			inimigo.queue_free()
	for grupo in [&"projetil_inimigo", &"residuo_pet0", &"minion_pet0"]:
		for node in get_tree().get_nodes_in_group(grupo):
			if is_instance_valid(node):
				node.queue_free()


func limpar_arena_teste() -> void:
	if not Global.modo_desenvolvedor:
		return
	limpar_inimigos_sem_recompensa()
	boss_ativo = null
	boss_em_teste = false
	if is_instance_valid(boss_hud):
		boss_hud.queue_free()
	boss_hud = null
	timer = TIMER_MAX
	restaurar_musica_partida()


func aplicar_musica_boss(id: StringName) -> void:
	if id != &"flor_equinocio":
		restaurar_musica_partida()
		return
	if not ResourceLoader.exists(CAMINHO_LOTUS_DANCE):
		return
	var faixa := load(CAMINHO_LOTUS_DANCE) as AudioStream
	if not is_instance_valid(faixa):
		return
	if faixa is AudioStreamMP3:
		(faixa as AudioStreamMP3).loop = true
	tocarmusica.stop()
	tocarmusica.stream = faixa
	tocarmusica.play()
	musica_boss_ativa = true


func restaurar_musica_partida() -> void:
	if not musica_boss_ativa or not is_instance_valid(tocarmusica):
		return
	tocarmusica.stop()
	tocarmusica.stream = musica_partida_padrao
	if is_instance_valid(musica_partida_padrao):
		tocarmusica.play()
	musica_boss_ativa = false


func alternar_spawns_teste() -> bool:
	if not Global.modo_desenvolvedor:
		return false
	spawns_pausados_desenvolvedor = not spawns_pausados_desenvolvedor
	return spawns_pausados_desenvolvedor


func spawns_teste_estao_pausados() -> bool:
	return spawns_pausados_desenvolvedor


func pode_abrir_painel_desenvolvedor() -> bool:
	return (
		Global.modo_desenvolvedor
		and not game_over
		and not tutorial_ativo
		and not escolha_setor_ativa
		and is_instance_valid(player)
		and player.vivo
		and player.vida > 0.0
		and not player.UsandoHabilidade
		and not (
			tela_upgrades.has_method("esta_aberta")
			and bool(tela_upgrades.call("esta_aberta"))
		)
	)


func criar_hud_boss() -> void:
	if is_instance_valid(boss_hud):
		boss_hud.queue_free()
	var dados_setor := DadosSetores.obter(setor_atual)
	var cor: Color = dados_setor.get("cor_destaque", Color.WHITE)
	boss_hud = VBoxContainer.new()
	boss_hud.name = "HUD_Boss"
	boss_hud.position = Vector2(260.0, 66.0)
	boss_hud.size = Vector2(440.0, 88.0)
	boss_hud.add_theme_constant_override("separation", 3)
	$GUI.add_child(boss_hud)
	boss_hud.visible = not (
		tela_upgrades.has_method("esta_aberta")
		and bool(tela_upgrades.call("esta_aberta"))
	)

	boss_nome = Label.new()
	boss_nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_nome.add_theme_color_override("font_color", cor)
	boss_nome.add_theme_font_size_override("font_size", 17)
	boss_hud.add_child(boss_nome)
	boss_vida = ProgressBar.new()
	boss_vida.custom_minimum_size = Vector2(440.0, 18.0)
	boss_vida.show_percentage = false
	boss_vida.modulate = cor
	boss_hud.add_child(boss_vida)
	boss_detalhe_texto = Label.new()
	boss_detalhe_texto.text = str(dados_setor.get("subtitulo", ""))
	boss_detalhe_texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_detalhe_texto.add_theme_font_size_override("font_size", 11)
	boss_hud.add_child(boss_detalhe_texto)
	boss_detalhe = ProgressBar.new()
	boss_detalhe.custom_minimum_size = Vector2(440.0, 10.0)
	boss_detalhe.show_percentage = false
	boss_detalhe.visible = boss_atual_id == &"pet0"
	boss_detalhe.modulate = Color(1.0, 0.82, 0.18, 1.0)
	boss_hud.add_child(boss_detalhe)


func _on_menu_upgrades_estado_alterado(aberto: bool) -> void:
	if is_instance_valid(boss_hud):
		boss_hud.visible = not aberto


func _on_boss_vida_alterada(atual: float, maxima: float) -> void:
	if is_instance_valid(boss_vida):
		boss_vida.max_value = maxima
		boss_vida.value = atual


func _on_boss_fase_alterada(fase: int) -> void:
	if not is_instance_valid(boss_nome):
		return
	var nome := "PET-0: O RESÍDUO ETERNO"
	if is_instance_valid(boss_ativo) and boss_ativo.has_method("obter_nome_boss"):
		nome = str(boss_ativo.call("obter_nome_boss"))
	boss_nome.text = "%s — FASE %d" % [nome, fase]
	if is_instance_valid(boss_vida) and is_instance_valid(boss_ativo) and boss_ativo.has_method("obter_cor_fase"):
		boss_vida.modulate = boss_ativo.call("obter_cor_fase")


func _on_boss_subtitulo_alterado(texto: String) -> void:
	if is_instance_valid(boss_detalhe_texto):
		boss_detalhe_texto.text = texto


func _on_boss_reciclagem_alterada(atual: int, meta: int) -> void:
	if not is_instance_valid(boss_detalhe):
		return
	boss_detalhe.visible = true
	boss_detalhe.max_value = meta
	boss_detalhe.value = atual
	boss_detalhe_texto.text = (
		"RÓTULO RECICLADO — NÚCLEO EXPOSTO!"
		if atual >= meta
		else "RECICLE OS FRAGMENTOS: %d/%d" % [atual, meta]
	)


func _on_boss_morreu(_inimigo: InimigoBase) -> void:
	restaurar_musica_partida()
	if boss_em_teste:
		boss_em_teste = false
		boss_ativo = null
		timer = TIMER_MAX
		if is_instance_valid(boss_nome):
			boss_nome.text = "TESTE CONCLUÍDO"
		if is_instance_valid(boss_detalhe_texto):
			boss_detalhe_texto.text = "PROGRESSÃO DA PARTIDA PRESERVADA"
		if is_instance_valid(boss_hud):
			var tween_teste := create_tween()
			tween_teste.tween_interval(0.65)
			tween_teste.tween_property(boss_hud, "modulate:a", 0.0, 0.25)
			tween_teste.tween_callback(boss_hud.queue_free)
		return
	Global.registrar_boss_derrotado(boss_atual_id)
	if setor_atual not in setores_concluidos:
		setores_concluidos.append(setor_atual)
	boss_ativo = null
	proximo_nivel_boss += INTERVALO_BOSS
	timer = TIMER_MAX
	if is_instance_valid(boss_nome):
		boss_nome.text = "SETOR CONCLUÍDO"
	if is_instance_valid(boss_detalhe_texto):
		boss_detalhe_texto.text = str(DadosSetores.obter(setor_atual).get("nome", ""))
	if is_instance_valid(boss_hud):
		var tween := create_tween()
		tween.tween_interval(0.9)
		tween.tween_property(boss_hud, "modulate:a", 0.0, 0.35)
		tween.tween_callback(boss_hud.queue_free)
	await get_tree().create_timer(1.1).timeout
	if game_over:
		return
	var opcoes := DadosSetores.sortear_opcoes(setores_concluidos, setor_atual, 2)
	if opcoes.is_empty():
		mostrar_vitoria()
	else:
		mostrar_escolha_setor(opcoes)


func criar_visual_setor() -> void:
	var camada := CanvasLayer.new()
	camada.layer = -100
	add_child(camada)
	fundo_setor = ColorRect.new()
	fundo_setor.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fundo_setor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fundo_setor.visible = false
	camada.add_child(fundo_setor)
	rotulo_setor = Label.new()
	rotulo_setor.position = Vector2(24.0, 76.0)
	rotulo_setor.add_theme_font_size_override("font_size", 11)
	rotulo_setor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$GUI.add_child(rotulo_setor)


func aplicar_setor(id: StringName) -> void:
	setor_atual = id
	var dados := DadosSetores.obter(id)
	var usar_original := bool(dados.get("usar_fundo_original", false))
	fundo_original.visible = usar_original
	fundo_setor.visible = not usar_original
	rotulo_setor.visible = not usar_original
	fundo_setor.color = dados.get("cor_fundo", Color(0.004, 0.006, 0.022))
	rotulo_setor.text = "%s  •  PRÓXIMO BOSS: LVL %d" % [
		dados.get("nome", "SETOR"), proximo_nivel_boss
	]
	var cor: Color = dados.get("cor_destaque", Color.WHITE)
	cor.a = 0.76
	rotulo_setor.add_theme_color_override("font_color", cor)
	timer = 0.8


func mostrar_escolha_setor(opcoes: Array[StringName]) -> void:
	var linha := iniciar_painel_escolha(
		"ESCOLHA O PRÓXIMO SETOR",
		"O primeiro setor foi concluído. A próxima escolha define inimigos, paleta e boss."
	)
	for id in opcoes:
		var dados := DadosSetores.obter(id)
		var botao := criar_cartao_setor(linha, dados)
		botao.pressed.connect(_on_setor_escolhido.bind(id))
	focar_primeiro_botao(linha)


func iniciar_painel_escolha(titulo: String, subtitulo: String) -> HBoxContainer:
	escolha_setor_ativa = true
	get_tree().paused = true
	Global.definir_emulacao_mouse_mobile(true)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	camada_escolha = CanvasLayer.new()
	camada_escolha.layer = 80
	camada_escolha.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(camada_escolha)
	var fundo := ColorRect.new()
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fundo.color = Color(0.004, 0.006, 0.020, 0.94)
	camada_escolha.add_child(fundo)
	var coluna := VBoxContainer.new()
	coluna.set_anchors_preset(Control.PRESET_CENTER)
	coluna.position = Vector2(-390.0, -180.0)
	coluna.size = Vector2(780.0, 360.0)
	coluna.add_theme_constant_override("separation", 12)
	fundo.add_child(coluna)
	var titulo_label := Label.new()
	titulo_label.text = titulo
	titulo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo_label.add_theme_font_size_override("font_size", 25)
	titulo_label.add_theme_color_override("font_color", Color(0.68, 0.94, 1.0))
	coluna.add_child(titulo_label)
	var subtitulo_label := Label.new()
	subtitulo_label.text = subtitulo
	subtitulo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitulo_label.add_theme_font_size_override("font_size", 11)
	subtitulo_label.add_theme_color_override("font_color", Color(0.58, 0.66, 0.80))
	coluna.add_child(subtitulo_label)
	var linha := HBoxContainer.new()
	linha.custom_minimum_size = Vector2(780.0, 278.0)
	linha.alignment = BoxContainer.ALIGNMENT_CENTER
	linha.add_theme_constant_override("separation", 18)
	coluna.add_child(linha)
	return linha


func criar_cartao_setor(pai: HBoxContainer, dados: Dictionary) -> Button:
	var cor: Color = dados.get("cor_destaque", Color.WHITE)
	var botao := Button.new()
	botao.custom_minimum_size = Vector2(300.0, 260.0)
	botao.text = "%s\n\n%s\n\n%s" % [
		dados.get("nome", "SETOR"),
		dados.get("subtitulo", ""),
		dados.get("descricao", "")
	]
	botao.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	botao.add_theme_font_size_override("font_size", 13)
	botao.add_theme_color_override("font_color", Color(0.84, 0.90, 1.0))
	botao.add_theme_color_override("font_hover_color", cor)
	botao.add_theme_color_override("font_focus_color", cor)
	for estado in [&"normal", &"hover", &"pressed", &"focus"]:
		var estilo := StyleBoxFlat.new()
		estilo.bg_color = Color(0.018, 0.027, 0.070, 0.96)
		if estado != &"normal":
			estilo.bg_color = Color(0.035, 0.052, 0.12, 1.0)
		estilo.border_color = Color(cor, 0.48) if estado == &"normal" else cor
		estilo.set_border_width_all(2)
		estilo.set_corner_radius_all(12)
		estilo.content_margin_left = 18.0
		estilo.content_margin_right = 18.0
		estilo.content_margin_top = 20.0
		estilo.content_margin_bottom = 20.0
		botao.add_theme_stylebox_override(estado, estilo)
	pai.add_child(botao)
	return botao


func focar_primeiro_botao(linha: HBoxContainer) -> void:
	for child in linha.get_children():
		if child is Button:
			(child as Button).call_deferred("grab_focus")
			return


func _on_setor_escolhido(id: StringName) -> void:
	encerrar_escolha_setor()
	aplicar_setor(id)


func encerrar_escolha_setor() -> void:
	escolha_setor_ativa = false
	get_tree().paused = false
	Global.definir_emulacao_mouse_mobile(false)
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	if is_instance_valid(camada_escolha):
		camada_escolha.queue_free()
	camada_escolha = null


func mostrar_vitoria() -> void:
	game_over = true
	Global.registrar_jogo_zerado()
	var linha := iniciar_painel_escolha(
		"CICLO DE SETORES CONCLUÍDO",
		"Todos os cinco bosses foram derrotados sem repetir setores."
	)
	var botao := criar_cartao_setor(linha, {
		"nome": "VOLTAR AO MENU",
		"subtitulo": "PONTUAÇÃO %s" % str(int(Global.Pontos)).pad_zeros(8),
		"descricao": "A tentativa foi concluída.",
		"cor_destaque": Color(0.42, 1.0, 0.68)
	})
	botao.pressed.connect(_on_vitoria_menu)
	botao.call_deferred("grab_focus")


func _on_vitoria_menu() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene_to_file("res://Rooms/TelaInicial.tscn")


func fadeout_tutorial() -> void:
	# Mantida porque a animação antiga da cena ainda chama este método.
	pass
