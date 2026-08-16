extends Control


const VERSAO_LOJA := 3
const HABILIDADE_INICIAL := "res://Habilidades/habilidadeRetrocesso.tres"
const CristalIcone = preload("res://Scripts/CristalMoedaIcone.gd")

const CATALOGO := [
	{
		"caminho": "res://Habilidades/habilidadeRetrocesso.tres",
		"preco": 0,
		"cor": Color(0.76, 0.30, 1.0, 1.0),
		"raridade": "FEV • ROXO",
		"stats": [3, 4, 3]
	},
	{
		"caminho": "res://Habilidades/habilidadeHiperdash.tres",
		"preco": 2200,
		"cor": Color(0.10, 0.86, 1.0, 1.0),
		"raridade": "MAI • AMARELO",
		"stats": [4, 2, 4]
	},
	{
		"caminho": "res://Habilidades/habilidadeAuraSerenidade.tres",
		"preco": 3000,
		"cor": Color(0.35, 1.0, 0.76, 1.0),
		"raridade": "JAN • BRANCO",
		"stats": [2, 5, 2]
	},
	{
		"caminho": "res://Habilidades/habilidadeFocoAbsoluto.tres",
		"preco": 3600,
		"cor": Color(0.35, 0.58, 1.0, 1.0),
		"raridade": "ABR • AZUL",
		"stats": [3, 3, 3]
	},
	{
		"caminho": "res://Habilidades/habilidadeShockwave.tres",
		"preco": 4500,
		"cor": Color(0.22, 0.82, 1.0, 1.0),
		"raridade": "MAR • ÁGUA",
		"stats": [5, 2, 2]
	},
	{
		"caminho": "res://Habilidades/habilidadeFrenesiCarnavalesco.tres",
		"preco": 5200,
		"cor": Color(1.0, 0.24, 0.76, 1.0),
		"raridade": "FEV • CARNAVAL",
		"stats": [4, 4, 2]
	},
	{
		"caminho": "res://Habilidades/habilidadeEscudoProtetor.tres",
		"preco": 4800,
		"cor": Color(0.72, 0.42, 1.0, 1.0),
		"raridade": "MAR • LILÁS",
		"stats": [1, 4, 3]
	},
	{
		"caminho": "res://Habilidades/habilidadeAbracoMaterno.tres",
		"preco": 4400,
		"cor": Color(1.0, 0.38, 0.62, 1.0),
		"raridade": "MAI • CUIDADO",
		"stats": [2, 4, 2]
	},
	{
		"caminho": "res://Habilidades/habilidadeTransfusao.tres",
		"preco": 6000,
		"cor": Color(1.0, 0.08, 0.22, 1.0),
		"raridade": "JUN • VERMELHO",
		"stats": [5, 1, 3]
	},
	{
		"caminho": "res://Habilidades/habilidadeFogueiraArdente.tres",
		"preco": 5600,
		"cor": Color(1.0, 0.48, 0.10, 1.0),
		"raridade": "JUN • FESTA JUNINA",
		"stats": [4, 5, 2]
	}
]

const CATEGORIAS := ["HABILIDADES", "ARMAS", "NAVE", "UPGRADES"]
const ITENS_FUTUROS := {
	1: ["CANHÃO PRISMÁTICO", "RAJADA DUPLA", "LANÇA-FRAGMENTOS", "RAIO CONTÍNUO"],
	2: ["CASCO LEVE", "NÚCLEO REFORÇADO", "MOTOR VETORIAL", "ASAS DE ÍON"],
	3: ["BLINDAGEM", "RECARGA", "COLETA MAGNÉTICA", "PROPULSÃO"]
}

var habilidades: Array[Habilidade] = []
var dados_habilidades: Array[Dictionary] = []
var desbloqueadas: Array[String] = []
var caminho_equipado := HABILIDADE_INICIAL
var indice_selecionado := 0
var categoria_atual := 0
var fonte: Font

var saldo_label: Label
var botao_adicionar: Button
var botoes_categorias: Array[Button] = []
var grade: GridContainer
var paineis_cartoes: Array[PanelContainer] = []
var painel_detalhes: PanelContainer
var detalhe_icone: TextureRect
var detalhe_nome: Label
var detalhe_tipo: Label
var detalhe_descricao: Label
var detalhe_contexto: Label
var detalhe_recarga: Label
var detalhe_stats: VBoxContainer
var detalhe_preco: Label
var botao_acao: Button
var mensagem: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	if ResourceLoader.exists("res://Fonts/Stereohead.otf"):
		fonte = load("res://Fonts/Stereohead.otf") as Font

	carregar_catalogo()
	carregar_estado()
	construir_interface()
	Global.cristais_alterados.connect(_on_cristais_alterados)
	atualizar_saldo()
	selecionar_categoria(0)
	call_deferred("_focar_primeiro_item")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_voltar_pressed()


func carregar_catalogo() -> void:
	habilidades.clear()
	dados_habilidades.clear()
	for dados in CATALOGO:
		var caminho := str(dados["caminho"])
		if not ResourceLoader.exists(caminho):
			push_warning("Habilidade não encontrada na loja: " + caminho)
			continue
		var recurso := load(caminho)
		if recurso is Habilidade:
			habilidades.append(recurso)
			dados_habilidades.append(dados)


func carregar_estado() -> void:
	var dados := GerenciadorDeSave.carregar()
	var versao := int(dados.get("versao_loja", 0))

	desbloqueadas.clear()
	if versao >= 2:
		var salvas = dados.get("habilidades_desbloqueadas", [HABILIDADE_INICIAL])
		if salvas is Array:
			for valor in salvas:
				if valor is String and valor not in desbloqueadas:
					desbloqueadas.append(valor)

	if HABILIDADE_INICIAL not in desbloqueadas:
		desbloqueadas.append(HABILIDADE_INICIAL)

	caminho_equipado = str(dados.get("habilidade_equipada", HABILIDADE_INICIAL))
	if (
		not Global.modo_desenvolvedor
		and caminho_equipado not in desbloqueadas
	):
		caminho_equipado = HABILIDADE_INICIAL

	if versao < 2:
		caminho_equipado = HABILIDADE_INICIAL
		salvar_estado()
	elif versao < VERSAO_LOJA:
		# Migra o catálogo sem apagar compras nem trocar a habilidade equipada.
		salvar_estado()


func salvar_estado() -> void:
	GerenciadorDeSave.salvar({
		"versao_loja": VERSAO_LOJA,
		"habilidades_desbloqueadas": desbloqueadas,
		"habilidade_equipada": caminho_equipado,
		"cristais": Global.cristais
	})


func construir_interface() -> void:
	var margem := MarginContainer.new()
	margem.name = "InterfaceLoja"
	margem.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margem.add_theme_constant_override("margin_left", 22)
	margem.add_theme_constant_override("margin_top", 14)
	margem.add_theme_constant_override("margin_right", 22)
	margem.add_theme_constant_override("margin_bottom", 14)
	add_child(margem)

	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 8)
	margem.add_child(coluna)

	construir_cabecalho(coluna)
	construir_categorias(coluna)
	construir_conteudo(coluna)

	mensagem = Label.new()
	mensagem.custom_minimum_size = Vector2(0, 22)
	mensagem.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mensagem.add_theme_color_override("font_color", Color(0.48, 0.62, 0.78))
	aplicar_fonte(mensagem, 11)
	coluna.add_child(mensagem)

	if Global.modo_desenvolvedor:
		mensagem.text = "MODO DESENVOLVEDOR • CATÁLOGO LIBERADO • + adiciona moeda de teste"


func construir_cabecalho(pai: VBoxContainer) -> void:
	var cabecalho := HBoxContainer.new()
	cabecalho.custom_minimum_size = Vector2(0, 54)
	cabecalho.add_theme_constant_override("separation", 14)
	pai.add_child(cabecalho)

	var voltar := Button.new()
	voltar.custom_minimum_size = Vector2(142, 46)
	voltar.text = "<  VOLTAR"
	voltar.focus_mode = Control.FOCUS_ALL
	estilizar_botao(voltar, Color(0.03, 0.05, 0.11), Color(0.28, 0.45, 0.78))
	aplicar_fonte(voltar, 15)
	voltar.pressed.connect(_on_voltar_pressed)
	cabecalho.add_child(voltar)

	var titulo_box := VBoxContainer.new()
	titulo_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titulo_box.alignment = BoxContainer.ALIGNMENT_CENTER
	cabecalho.add_child(titulo_box)

	var titulo := Label.new()
	titulo.text = "LOJA"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_color_override("font_color", Color(0.76, 0.38, 1.0))
	aplicar_fonte(titulo, 34)
	titulo_box.add_child(titulo)

	var subtitulo := Label.new()
	subtitulo.text = "TERMINAL CROMÁTICO"
	subtitulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitulo.add_theme_color_override("font_color", Color(0.28, 0.86, 1.0))
	aplicar_fonte(subtitulo, 10)
	titulo_box.add_child(subtitulo)

	var saldo_painel := PanelContainer.new()
	saldo_painel.custom_minimum_size = Vector2(176, 46)
	saldo_painel.add_theme_stylebox_override(
		"panel",
		criar_estilo(Color(0.025, 0.035, 0.085), Color(0.34, 0.40, 0.78), 10, 1)
	)
	cabecalho.add_child(saldo_painel)

	var saldo_box := HBoxContainer.new()
	saldo_box.alignment = BoxContainer.ALIGNMENT_CENTER
	saldo_box.add_theme_constant_override("separation", 8)
	saldo_painel.add_child(saldo_box)

	var icone = CristalIcone.new()
	icone.custom_minimum_size = Vector2(16, 22)
	saldo_box.add_child(icone)

	saldo_label = Label.new()
	saldo_label.custom_minimum_size = Vector2(82, 0)
	saldo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	saldo_label.add_theme_color_override("font_color", Color(0.90, 0.92, 1.0))
	aplicar_fonte(saldo_label, 17)
	saldo_box.add_child(saldo_label)

	botao_adicionar = Button.new()
	botao_adicionar.custom_minimum_size = Vector2(32, 32)
	botao_adicionar.text = "+"
	botao_adicionar.disabled = not Global.modo_desenvolvedor
	botao_adicionar.tooltip_text = "DEV: adicionar 1.000 cristais"
	estilizar_botao(
		botao_adicionar,
		Color(0.06, 0.06, 0.14),
		Color(0.38, 0.32, 0.75)
	)
	botao_adicionar.pressed.connect(_on_adicionar_cristais_pressed)
	saldo_box.add_child(botao_adicionar)


func construir_categorias(pai: VBoxContainer) -> void:
	var painel := PanelContainer.new()
	painel.custom_minimum_size = Vector2(0, 46)
	painel.add_theme_stylebox_override(
		"panel",
		criar_estilo(Color(0.018, 0.025, 0.064), Color(0.13, 0.20, 0.38), 8, 1)
	)
	pai.add_child(painel)

	var linha := HBoxContainer.new()
	linha.alignment = BoxContainer.ALIGNMENT_CENTER
	linha.add_theme_constant_override("separation", 4)
	painel.add_child(linha)

	var cores := [
		Color(0.18, 0.86, 1.0),
		Color(1.0, 0.32, 0.56),
		Color(0.30, 0.80, 1.0),
		Color(0.68, 0.38, 1.0)
	]
	for indice in CATEGORIAS.size():
		var botao := Button.new()
		botao.custom_minimum_size = Vector2(208, 42)
		botao.text = CATEGORIAS[indice]
		botao.focus_mode = Control.FOCUS_ALL
		botao.set_meta("cor_categoria", cores[indice])
		botao.pressed.connect(selecionar_categoria.bind(indice))
		aplicar_fonte(botao, 13)
		linha.add_child(botao)
		botoes_categorias.append(botao)


func construir_conteudo(pai: VBoxContainer) -> void:
	var conteudo := HBoxContainer.new()
	conteudo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	conteudo.add_theme_constant_override("separation", 12)
	pai.add_child(conteudo)

	var esquerda := VBoxContainer.new()
	esquerda.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	esquerda.add_theme_constant_override("separation", 8)
	conteudo.add_child(esquerda)

	# Esta moldura interrompe a propagação do tamanho mínimo da grade.
	# Assim, o surgimento da barra de rolagem nunca alarga o painel da loja.
	var moldura_rolagem := Control.new()
	moldura_rolagem.custom_minimum_size = Vector2.ZERO
	moldura_rolagem.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	moldura_rolagem.size_flags_vertical = Control.SIZE_EXPAND_FILL
	moldura_rolagem.clip_contents = true
	esquerda.add_child(moldura_rolagem)

	var rolagem := ScrollContainer.new()
	rolagem.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rolagem.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rolagem.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rolagem.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rolagem.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	moldura_rolagem.add_child(rolagem)

	grade = GridContainer.new()
	grade.columns = 3
	grade.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grade.add_theme_constant_override("h_separation", 8)
	grade.add_theme_constant_override("v_separation", 8)
	rolagem.add_child(grade)

	var dica := Label.new()
	dica.text = "Selecione um módulo para ver detalhes • Compras ficam salvas"
	dica.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dica.add_theme_color_override("font_color", Color(0.40, 0.50, 0.68))
	aplicar_fonte(dica, 9)
	esquerda.add_child(dica)

	painel_detalhes = PanelContainer.new()
	painel_detalhes.custom_minimum_size = Vector2(278, 0)
	painel_detalhes.add_theme_stylebox_override(
		"panel",
		criar_estilo(Color(0.018, 0.027, 0.068), Color(0.26, 0.46, 0.78), 12, 2, 8)
	)
	conteudo.add_child(painel_detalhes)

	var margem := MarginContainer.new()
	margem.add_theme_constant_override("margin_left", 16)
	margem.add_theme_constant_override("margin_top", 12)
	margem.add_theme_constant_override("margin_right", 16)
	margem.add_theme_constant_override("margin_bottom", 12)
	painel_detalhes.add_child(margem)

	# O texto Monthly Colors pode ser longo, mas fica confinado ao painel.
	var moldura_detalhes := Control.new()
	moldura_detalhes.custom_minimum_size = Vector2.ZERO
	moldura_detalhes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	moldura_detalhes.size_flags_vertical = Control.SIZE_EXPAND_FILL
	moldura_detalhes.clip_contents = true
	margem.add_child(moldura_detalhes)

	var rolagem_detalhes := ScrollContainer.new()
	rolagem_detalhes.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rolagem_detalhes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rolagem_detalhes.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rolagem_detalhes.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rolagem_detalhes.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	moldura_detalhes.add_child(rolagem_detalhes)

	var coluna := VBoxContainer.new()
	coluna.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	coluna.add_theme_constant_override("separation", 5)
	rolagem_detalhes.add_child(coluna)

	detalhe_tipo = Label.new()
	detalhe_tipo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	aplicar_fonte(detalhe_tipo, 10)
	coluna.add_child(detalhe_tipo)

	detalhe_nome = Label.new()
	detalhe_nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detalhe_nome.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detalhe_nome.add_theme_color_override("font_color", Color(0.58, 0.94, 1.0))
	aplicar_fonte(detalhe_nome, 20)
	coluna.add_child(detalhe_nome)

	detalhe_icone = TextureRect.new()
	detalhe_icone.custom_minimum_size = Vector2(78, 78)
	detalhe_icone.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	detalhe_icone.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	detalhe_icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	var linha_icone := HBoxContainer.new()
	linha_icone.alignment = BoxContainer.ALIGNMENT_CENTER
	linha_icone.add_theme_constant_override("separation", 9)
	coluna.add_child(linha_icone)
	linha_icone.add_child(detalhe_icone)

	detalhe_contexto = Label.new()
	detalhe_contexto.custom_minimum_size = Vector2(150, 78)
	detalhe_contexto.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	detalhe_contexto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detalhe_contexto.add_theme_color_override("font_color", Color(0.70, 0.82, 1.0))
	aplicar_fonte(detalhe_contexto, 8)
	linha_icone.add_child(detalhe_contexto)

	detalhe_descricao = Label.new()
	detalhe_descricao.custom_minimum_size = Vector2(0, 72)
	detalhe_descricao.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	detalhe_descricao.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detalhe_descricao.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detalhe_descricao.add_theme_color_override("font_color", Color(0.72, 0.76, 0.88))
	aplicar_fonte(detalhe_descricao, 11)
	coluna.add_child(detalhe_descricao)

	detalhe_recarga = Label.new()
	detalhe_recarga.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detalhe_recarga.add_theme_color_override("font_color", Color(0.42, 0.82, 1.0))
	aplicar_fonte(detalhe_recarga, 10)
	coluna.add_child(detalhe_recarga)

	detalhe_stats = VBoxContainer.new()
	detalhe_stats.add_theme_constant_override("separation", 4)
	coluna.add_child(detalhe_stats)

	var preco_box := HBoxContainer.new()
	preco_box.alignment = BoxContainer.ALIGNMENT_CENTER
	preco_box.add_theme_constant_override("separation", 7)
	coluna.add_child(preco_box)

	var moeda = CristalIcone.new()
	moeda.custom_minimum_size = Vector2(14, 19)
	preco_box.add_child(moeda)

	detalhe_preco = Label.new()
	detalhe_preco.add_theme_color_override("font_color", Color(0.75, 0.70, 1.0))
	aplicar_fonte(detalhe_preco, 16)
	preco_box.add_child(detalhe_preco)

	botao_acao = Button.new()
	botao_acao.custom_minimum_size = Vector2(0, 38)
	botao_acao.focus_mode = Control.FOCUS_ALL
	estilizar_botao(
		botao_acao,
		Color(0.05, 0.18, 0.26),
		Color(0.24, 0.86, 1.0)
	)
	aplicar_fonte(botao_acao, 15)
	botao_acao.pressed.connect(_on_acao_pressed)
	coluna.add_child(botao_acao)


func selecionar_categoria(indice: int) -> void:
	categoria_atual = indice
	indice_selecionado = 0
	atualizar_botoes_categorias()
	if categoria_atual == 0:
		reconstruir_grade_habilidades()
		atualizar_detalhes()
	else:
		reconstruir_grade_futura()
		atualizar_detalhes_futuros()
	call_deferred("_focar_primeiro_item")


func atualizar_botoes_categorias() -> void:
	for indice in botoes_categorias.size():
		var botao := botoes_categorias[indice]
		var cor: Color = botao.get_meta("cor_categoria")
		if indice == categoria_atual:
			botao.add_theme_stylebox_override(
				"normal",
				criar_estilo(Color(0.04, 0.08, 0.16), cor, 8, 2)
			)
			botao.add_theme_color_override("font_color", cor)
		else:
			botao.add_theme_stylebox_override(
				"normal",
				criar_estilo(Color(0.018, 0.025, 0.064), Color(0.10, 0.16, 0.30), 8, 1)
			)
			botao.add_theme_color_override("font_color", Color(0.52, 0.60, 0.75))


func limpar_grade() -> void:
	paineis_cartoes.clear()
	for filho in grade.get_children():
		grade.remove_child(filho)
		filho.queue_free()


func reconstruir_grade_habilidades() -> void:
	limpar_grade()
	for indice in habilidades.size():
		criar_cartao_habilidade(indice)
	atualizar_destaques_cartoes()


func criar_cartao_habilidade(indice: int) -> void:
	var habilidade := habilidades[indice]
	var dados: Dictionary = dados_habilidades[indice]
	var caminho := habilidade.resource_path
	var cor: Color = dados["cor"]

	var wrapper := Control.new()
	wrapper.custom_minimum_size = Vector2(198, 162)
	grade.add_child(wrapper)

	var painel := PanelContainer.new()
	painel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wrapper.add_child(painel)
	paineis_cartoes.append(painel)

	var margem := MarginContainer.new()
	margem.add_theme_constant_override("margin_left", 10)
	margem.add_theme_constant_override("margin_top", 9)
	margem.add_theme_constant_override("margin_right", 10)
	margem.add_theme_constant_override("margin_bottom", 9)
	painel.add_child(margem)

	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 4)
	margem.add_child(coluna)

	var tipo := Label.new()
	tipo.text = str(dados["raridade"])
	tipo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tipo.add_theme_color_override("font_color", cor)
	aplicar_fonte(tipo, 8)
	coluna.add_child(tipo)

	var icone := TextureRect.new()
	icone.custom_minimum_size = Vector2(68, 68)
	icone.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icone.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icone.texture = habilidade.Icone
	icone.self_modulate = cor.lightened(0.12)
	coluna.add_child(icone)

	var nome := Label.new()
	nome.text = habilidade.Nome.to_upper()
	nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nome.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	nome.add_theme_color_override("font_color", Color(0.88, 0.91, 1.0))
	aplicar_fonte(nome, 10)
	coluna.add_child(nome)

	var estado := Label.new()
	estado.text = texto_estado_cartao(caminho, int(dados["preco"]))
	estado.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	estado.add_theme_color_override(
		"font_color",
		Color(0.45, 1.0, 0.72)
		if esta_liberada(caminho)
		else Color(0.70, 0.64, 1.0)
	)
	aplicar_fonte(estado, 9)
	coluna.add_child(estado)

	var botao := Button.new()
	botao.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	botao.flat = true
	botao.focus_mode = Control.FOCUS_ALL
	botao.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	botao.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	botao.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	botao.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	botao.add_theme_stylebox_override(
		"focus",
		criar_estilo(Color(0, 0, 0, 0), cor, 10, 2)
	)
	botao.pressed.connect(selecionar_habilidade.bind(indice))
	botao.focus_entered.connect(selecionar_habilidade.bind(indice))
	wrapper.add_child(botao)


func selecionar_habilidade(indice: int) -> void:
	if categoria_atual != 0 or indice < 0 or indice >= habilidades.size():
		return
	indice_selecionado = indice
	atualizar_destaques_cartoes()
	atualizar_detalhes()


func atualizar_destaques_cartoes() -> void:
	for indice in paineis_cartoes.size():
		var dados: Dictionary = dados_habilidades[indice]
		var cor: Color = dados["cor"]
		paineis_cartoes[indice].add_theme_stylebox_override(
			"panel",
			criar_estilo(
				Color(0.025, 0.034, 0.075, 0.98),
				cor if indice == indice_selecionado else Color(0.10, 0.15, 0.29),
				11,
				2 if indice == indice_selecionado else 1,
				8 if indice == indice_selecionado else 0
			)
		)


func atualizar_detalhes() -> void:
	if habilidades.is_empty():
		atualizar_detalhes_futuros()
		return

	var habilidade := habilidades[indice_selecionado]
	var dados: Dictionary = dados_habilidades[indice_selecionado]
	var caminho := habilidade.resource_path
	var preco := int(dados["preco"])
	var cor: Color = dados["cor"]

	detalhe_tipo.text = str(dados["raridade"])
	detalhe_tipo.add_theme_color_override("font_color", cor)
	detalhe_nome.text = habilidade.Nome.to_upper()
	detalhe_icone.texture = habilidade.Icone
	detalhe_icone.self_modulate = cor.lightened(0.10)
	var contexto := habilidade.MonthlyColorsContexto.strip_edges()
	var selo := habilidade.MonthlyColorsSelo.strip_edges()
	detalhe_contexto.visible = not contexto.is_empty() or not selo.is_empty()
	detalhe_contexto.text = (
		"MONTHLY COLORS\n%s\n%s" % [selo, contexto]
		if detalhe_contexto.visible
		else ""
	)
	detalhe_descricao.text = habilidade.Descricao
	detalhe_recarga.text = "RECARGA  %.1f s" % habilidade.Cooldown
	detalhe_preco.text = "GRÁTIS" if preco == 0 else formatar_numero(preco)
	reconstruir_stats(dados["stats"], cor)

	if caminho == caminho_equipado:
		botao_acao.text = "EQUIPADA"
		botao_acao.disabled = true
	elif esta_liberada(caminho):
		botao_acao.text = "EQUIPAR"
		botao_acao.disabled = false
	elif Global.pode_gastar_cristais(preco):
		botao_acao.text = "COMPRAR"
		botao_acao.disabled = false
	else:
		botao_acao.text = "SALDO INSUFICIENTE"
		botao_acao.disabled = true


func reconstruir_stats(valores: Array, cor: Color) -> void:
	for filho in detalhe_stats.get_children():
		detalhe_stats.remove_child(filho)
		filho.queue_free()

	var nomes := ["POTÊNCIA", "DURAÇÃO", "RECARGA"]
	for indice in nomes.size():
		var linha := HBoxContainer.new()
		linha.add_theme_constant_override("separation", 4)
		detalhe_stats.add_child(linha)

		var rotulo := Label.new()
		rotulo.custom_minimum_size = Vector2(82, 0)
		rotulo.text = nomes[indice]
		rotulo.add_theme_color_override("font_color", Color(0.58, 0.65, 0.80))
		aplicar_fonte(rotulo, 8)
		linha.add_child(rotulo)

		for bloco in range(5):
			var indicador := ColorRect.new()
			indicador.custom_minimum_size = Vector2(22, 8)
			indicador.color = (
				cor
				if bloco < int(valores[indice])
				else Color(0.08, 0.11, 0.21)
			)
			linha.add_child(indicador)


func reconstruir_grade_futura() -> void:
	limpar_grade()
	var nomes: Array = ITENS_FUTUROS.get(categoria_atual, [])
	for nome_item in nomes:
		var painel := PanelContainer.new()
		painel.custom_minimum_size = Vector2(198, 162)
		painel.add_theme_stylebox_override(
			"panel",
			criar_estilo(Color(0.02, 0.028, 0.062), Color(0.10, 0.16, 0.28), 11, 1)
		)
		grade.add_child(painel)

		var coluna := VBoxContainer.new()
		coluna.alignment = BoxContainer.ALIGNMENT_CENTER
		painel.add_child(coluna)

		var simbolo := Label.new()
		simbolo.text = "◇"
		simbolo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		simbolo.add_theme_color_override("font_color", Color(0.32, 0.45, 0.68))
		aplicar_fonte(simbolo, 34)
		coluna.add_child(simbolo)

		var nome := Label.new()
		nome.text = str(nome_item)
		nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nome.add_theme_color_override("font_color", Color(0.48, 0.56, 0.72))
		aplicar_fonte(nome, 10)
		coluna.add_child(nome)

		var estado := Label.new()
		estado.text = "EM DESENVOLVIMENTO"
		estado.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		estado.add_theme_color_override("font_color", Color(0.34, 0.40, 0.56))
		aplicar_fonte(estado, 8)
		coluna.add_child(estado)


func atualizar_detalhes_futuros() -> void:
	detalhe_tipo.text = CATEGORIAS[categoria_atual] if categoria_atual < CATEGORIAS.size() else ""
	detalhe_tipo.add_theme_color_override("font_color", Color(0.48, 0.60, 0.82))
	detalhe_nome.text = "MÓDULOS EM PREPARAÇÃO"
	detalhe_icone.texture = null
	detalhe_contexto.visible = false
	detalhe_contexto.text = ""
	detalhe_descricao.text = "Esta categoria já possui a estrutura visual pronta para receber novos itens em versões futuras."
	detalhe_recarga.text = ""
	detalhe_preco.text = "---"
	reconstruir_stats([0, 0, 0], Color(0.2, 0.3, 0.5))
	botao_acao.text = "EM BREVE"
	botao_acao.disabled = true


func _on_acao_pressed() -> void:
	if categoria_atual != 0 or habilidades.is_empty():
		return

	var habilidade := habilidades[indice_selecionado]
	var dados: Dictionary = dados_habilidades[indice_selecionado]
	var caminho := habilidade.resource_path
	var preco := int(dados["preco"])

	if caminho not in desbloqueadas and not Global.modo_desenvolvedor:
		if not Global.gastar_cristais(preco):
			mensagem.text = "CRISTAIS INSUFICIENTES"
			Global.vibrar_controle(0.10, 0.35, 0.14)
			return
		desbloqueadas.append(caminho)
		mensagem.text = "%s DESBLOQUEADA" % habilidade.Nome.to_upper()
	elif Global.modo_desenvolvedor and caminho not in desbloqueadas:
		mensagem.text = "EQUIPADA PELO MODO DESENVOLVEDOR"

	caminho_equipado = caminho
	salvar_estado()
	Global.vibrar_controle(0.18, 0.32, 0.12)
	reconstruir_grade_habilidades()
	atualizar_detalhes()


func esta_liberada(caminho: String) -> bool:
	return Global.modo_desenvolvedor or caminho in desbloqueadas


func texto_estado_cartao(caminho: String, preco: int) -> String:
	if caminho == caminho_equipado:
		return "EQUIPADA"
	if caminho in desbloqueadas:
		return "LIBERADA"
	if Global.modo_desenvolvedor:
		return "DEV LIBERADA"
	return "GRÁTIS" if preco == 0 else "◆  " + formatar_numero(preco)


func atualizar_saldo() -> void:
	if saldo_label:
		saldo_label.text = formatar_numero(Global.cristais)


func _on_cristais_alterados(_total: int, _alteracao: int) -> void:
	atualizar_saldo()
	if categoria_atual == 0:
		atualizar_detalhes()


func _on_adicionar_cristais_pressed() -> void:
	if not Global.modo_desenvolvedor:
		return
	Global.adicionar_cristais(1000, true)
	mensagem.text = "+1.000 CRISTAIS DE TESTE"


func _focar_primeiro_item() -> void:
	if categoria_atual == 0 and grade.get_child_count() > 0:
		var primeiro := grade.get_child(0)
		var botoes := primeiro.find_children("*", "Button", true, false)
		if not botoes.is_empty():
			botoes[0].grab_focus()
			return
	botoes_categorias[categoria_atual].grab_focus()


func _on_voltar_pressed() -> void:
	Global.salvar_economia()
	get_tree().change_scene_to_file("res://Rooms/TelaInicial.tscn")


func formatar_numero(valor: int) -> String:
	var texto := str(maxi(valor, 0))
	var resultado := ""
	var contador := 0
	for indice in range(texto.length() - 1, -1, -1):
		if contador > 0 and contador % 3 == 0:
			resultado = "." + resultado
		resultado = texto[indice] + resultado
		contador += 1
	return resultado


func aplicar_fonte(controle: Control, tamanho: int) -> void:
	if fonte:
		controle.add_theme_font_override("font", fonte)
	controle.add_theme_font_size_override("font_size", tamanho)


func estilizar_botao(botao: Button, fundo: Color, borda: Color) -> void:
	botao.add_theme_stylebox_override("normal", criar_estilo(fundo, borda, 8, 1))
	botao.add_theme_stylebox_override(
		"hover",
		criar_estilo(fundo.lightened(0.08), borda.lightened(0.20), 8, 2)
	)
	botao.add_theme_stylebox_override(
		"pressed",
		criar_estilo(fundo.darkened(0.06), borda, 8, 2)
	)
	botao.add_theme_stylebox_override(
		"focus",
		criar_estilo(fundo.lightened(0.05), Color(0.72, 0.90, 1.0), 8, 2)
	)


func criar_estilo(
	fundo: Color,
	borda: Color,
	raio := 8,
	espessura := 1,
	sombra := 0
) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = fundo
	estilo.border_color = borda
	estilo.set_border_width_all(espessura)
	estilo.set_corner_radius_all(raio)
	estilo.content_margin_left = 8.0
	estilo.content_margin_right = 8.0
	estilo.content_margin_top = 5.0
	estilo.content_margin_bottom = 5.0
	if sombra > 0:
		estilo.shadow_color = Color(borda.r, borda.g, borda.b, 0.20)
		estilo.shadow_size = sombra
	return estilo
