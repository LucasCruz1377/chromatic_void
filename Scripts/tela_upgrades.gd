extends Control


const TAMANHO_NO := Vector2(170, 68)


@export var cena_carta: PackedScene
@export var qtd_cartas: int = 3

@onready var container_cartas: Control = $ContainerCartas

var player: Player
var botoes: Dictionary = {}
var titulo_pontos: Label
var detalhes: Label
var botao_continuar: Button
var time_scale_anterior := 1.0
var mouse_mode_anterior := Input.MOUSE_MODE_HIDDEN


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	container_cartas.hide()
	construir_interface()
	visible = false
	call_deferred("conectar_player")


func conectar_player() -> void:
	player = get_tree().get_first_node_in_group("player") as Player
	if not is_instance_valid(player):
		push_warning("A árvore de habilidades não encontrou o Player.")
		return

	if not player.subiuDeNivel.is_connected(_on_player_subiu_de_nivel):
		player.subiuDeNivel.connect(_on_player_subiu_de_nivel)


func construir_interface() -> void:
	var titulo := Label.new()
	titulo.position = Vector2(24, 14)
	titulo.size = Vector2(470, 42)
	titulo.text = "MATRIZ DE EVOLUÇÃO"
	titulo.add_theme_font_size_override("font_size", 26)
	titulo.add_theme_color_override("font_color", Color(0.55, 0.95, 1.0))
	add_child(titulo)

	titulo_pontos = Label.new()
	titulo_pontos.position = Vector2(500, 18)
	titulo_pontos.size = Vector2(260, 34)
	titulo_pontos.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	titulo_pontos.add_theme_font_size_override("font_size", 18)
	titulo_pontos.add_theme_color_override("font_color", Color(1.0, 0.86, 0.32))
	add_child(titulo_pontos)

	botao_continuar = Button.new()
	botao_continuar.position = Vector2(790, 13)
	botao_continuar.size = Vector2(145, 38)
	botao_continuar.text = "CONTINUAR"
	botao_continuar.pressed.connect(fechar_arvore)
	add_child(botao_continuar)

	for id in SkillTreeData.ORDEM:
		criar_botao_no(id)

	detalhes = Label.new()
	detalhes.position = Vector2(28, 462)
	detalhes.size = Vector2(904, 62)
	detalhes.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	detalhes.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detalhes.add_theme_font_size_override("font_size", 14)
	detalhes.add_theme_color_override("font_color", Color(0.78, 0.84, 0.94))
	add_child(detalhes)

	var dica := Label.new()
	dica.position = Vector2(28, 438)
	dica.size = Vector2(500, 24)
	dica.text = "Passe o mouse para ver detalhes. Nós brilhantes podem ser evoluídos."
	dica.add_theme_font_size_override("font_size", 11)
	dica.add_theme_color_override("font_color", Color(0.45, 0.55, 0.72))
	add_child(dica)


func criar_botao_no(id: StringName) -> void:
	var dados := SkillTreeData.obter_dados(id)
	var botao := Button.new()
	botao.name = str(id)
	botao.position = Vector2(dados["posicao"]) - TAMANHO_NO * 0.5
	botao.size = TAMANHO_NO
	botao.clip_text = true
	botao.add_theme_font_size_override("font_size", 12)
	botao.pressed.connect(_on_no_pressed.bind(id))
	botao.mouse_entered.connect(_mostrar_detalhes.bind(id))

	var caminho_icone := str(dados.get("icone", ""))
	if not caminho_icone.is_empty() and ResourceLoader.exists(caminho_icone):
		botao.icon = load(caminho_icone) as Texture2D
		botao.icon_max_width = 28

	add_child(botao)
	botoes[id] = botao


func _on_player_subiu_de_nivel() -> void:
	call_deferred("abrir_arvore")


func abrir_arvore() -> void:
	if not is_instance_valid(player):
		conectar_player()
	if not is_instance_valid(player):
		return

	if not visible:
		time_scale_anterior = Engine.time_scale
		mouse_mode_anterior = Input.mouse_mode

	visible = true
	Engine.time_scale = 0.0
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	atualizar_interface()


func fechar_arvore() -> void:
	if not visible:
		return

	visible = false
	Engine.time_scale = maxf(time_scale_anterior, 0.01)
	Input.set_mouse_mode(mouse_mode_anterior)


func esta_aberta() -> bool:
	return visible


func atualizar_interface() -> void:
	if not is_instance_valid(player):
		return

	titulo_pontos.text = "PONTOS: %d" % player.pontos_skill

	for id in SkillTreeData.ORDEM:
		var botao := botoes[id] as Button
		var dados := SkillTreeData.obter_dados(id)
		var nivel := SkillTreeData.obter_nivel(id, player.niveis_skill)
		var max_nivel := int(dados.get("max_nivel", 1))
		var requisitos_ok := SkillTreeData.requisitos_cumpridos(id, player.niveis_skill)
		var pode_comprar := player.pontos_skill > 0 and SkillTreeData.pode_comprar(
			id,
			player.niveis_skill
		)

		botao.text = "%s\n%d/%d" % [dados["nome"], nivel, max_nivel]
		botao.disabled = not pode_comprar

		var cor := Color(0.11, 0.13, 0.2)
		var borda := Color(0.24, 0.28, 0.4)
		if nivel >= max_nivel:
			cor = Color(0.18, 0.42, 0.36)
			borda = Color(0.45, 1.0, 0.72)
		elif nivel > 0:
			cor = Color(0.16, 0.3, 0.42)
			borda = Color(0.38, 0.85, 1.0)
		elif requisitos_ok:
			cor = Color(0.16, 0.2, 0.34)
			borda = Color(0.75, 0.78, 1.0)

		botao.add_theme_stylebox_override("normal", criar_estilo(cor, borda))
		botao.add_theme_stylebox_override(
			"hover",
			criar_estilo(cor.lightened(0.12), borda.lightened(0.12))
		)
		botao.add_theme_stylebox_override(
			"pressed",
			criar_estilo(cor.darkened(0.08), Color.WHITE)
		)
		botao.add_theme_stylebox_override(
			"disabled",
			criar_estilo(cor.darkened(0.35), borda.darkened(0.45))
		)

	botao_continuar.text = "CONTINUAR" if player.pontos_skill == 0 else "ADIAR PONTO"
	queue_redraw()


func criar_estilo(cor: Color, borda: Color) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = cor
	estilo.border_color = borda
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(11)
	estilo.content_margin_left = 8
	estilo.content_margin_right = 8
	return estilo


func _on_no_pressed(id: StringName) -> void:
	if not is_instance_valid(player):
		return
	if not player.comprar_upgrade_skill(id):
		atualizar_interface()
		return

	atualizar_interface()
	_mostrar_detalhes(id)
	if player.pontos_skill <= 0:
		fechar_arvore()


func _mostrar_detalhes(id: StringName) -> void:
	if not is_instance_valid(player):
		return

	var dados := SkillTreeData.obter_dados(id)
	var nivel := SkillTreeData.obter_nivel(id, player.niveis_skill)
	var max_nivel := int(dados.get("max_nivel", 1))
	detalhes.text = "%s  [%d/%d]\n%s  %s" % [
		dados["nome"],
		nivel,
		max_nivel,
		dados["descricao"],
		SkillTreeData.texto_requisitos(id, player.niveis_skill)
	]


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.008, 0.012, 0.035, 0.97))

	if not is_instance_valid(player):
		return

	for id in SkillTreeData.ORDEM:
		var dados := SkillTreeData.obter_dados(id)
		var destino := Vector2(dados["posicao"])
		var requisitos: Dictionary = dados.get("requisitos", {})

		for requisito in requisitos:
			var origem := Vector2(SkillTreeData.obter_dados(requisito)["posicao"])
			var ativo := (
				SkillTreeData.obter_nivel(requisito, player.niveis_skill)
				>= int(requisitos[requisito])
			)
			var cor := Color(0.24, 0.28, 0.4, 0.8)
			if ativo:
				cor = Color(0.35, 0.9, 1.0, 0.95)
			draw_line(origem, destino, cor, 3.0, true)
