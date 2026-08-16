extends PanelContainer
class_name UpgradeCardNova


signal escolhido(id: StringName)

var upgrade_id: StringName
var cor_destaque := Color.WHITE
var botao: Button


func configurar(
	id: StringName,
	dados: Dictionary,
	nivel_atual: int,
	texto_requisitos: String
) -> void:
	upgrade_id = id
	cor_destaque = Color(dados.get("cor", Color.WHITE))
	custom_minimum_size = Vector2(252, 332)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_STOP
	pivot_offset = custom_minimum_size * 0.5

	add_theme_stylebox_override("panel", criar_estilo_painel())
	criar_poligonos_decorativos()

	var margem := MarginContainer.new()
	margem.add_theme_constant_override("margin_left", 18)
	margem.add_theme_constant_override("margin_top", 16)
	margem.add_theme_constant_override("margin_right", 18)
	margem.add_theme_constant_override("margin_bottom", 16)
	margem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margem)

	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 8)
	coluna.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margem.add_child(coluna)

	var topo := HBoxContainer.new()
	topo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coluna.add_child(topo)

	var categoria := Label.new()
	categoria.text = str(dados.get("categoria", "MOD"))
	categoria.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	categoria.add_theme_font_size_override("font_size", 11)
	categoria.add_theme_color_override("font_color", cor_destaque)
	categoria.mouse_filter = Control.MOUSE_FILTER_IGNORE
	topo.add_child(categoria)

	var raridade := Label.new()
	raridade.text = str(dados.get("raridade", "COMUM"))
	raridade.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	raridade.add_theme_font_size_override("font_size", 10)
	raridade.add_theme_color_override("font_color", cor_destaque.lightened(0.18))
	raridade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	topo.add_child(raridade)

	var icone := TextureRect.new()
	icone.custom_minimum_size = Vector2(82, 82)
	icone.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icone.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icone.self_modulate = cor_destaque.lightened(0.15)
	icone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var caminho_icone := str(dados.get("icone", ""))
	if not caminho_icone.is_empty() and ResourceLoader.exists(caminho_icone):
		icone.texture = load(caminho_icone) as Texture2D
	coluna.add_child(icone)

	var nome := Label.new()
	nome.text = str(dados.get("nome", id))
	nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nome.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nome.add_theme_font_size_override("font_size", 18)
	nome.add_theme_color_override("font_color", Color(0.95, 0.97, 1.0))
	nome.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coluna.add_child(nome)

	var nivel := Label.new()
	var max_nivel := int(dados.get("max_nivel", 1))
	nivel.text = "NÍVEL %d  →  %d/%d" % [nivel_atual, nivel_atual + 1, max_nivel]
	nivel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nivel.add_theme_font_size_override("font_size", 11)
	nivel.add_theme_color_override("font_color", cor_destaque)
	nivel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coluna.add_child(nivel)

	var descricao := Label.new()
	descricao.text = str(dados.get("descricao", ""))
	descricao.custom_minimum_size = Vector2(0, 70)
	descricao.size_flags_vertical = Control.SIZE_EXPAND_FILL
	descricao.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	descricao.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	descricao.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	descricao.add_theme_font_size_override("font_size", 13)
	descricao.add_theme_color_override("font_color", Color(0.76, 0.8, 0.9))
	descricao.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coluna.add_child(descricao)

	var requisitos := Label.new()
	requisitos.text = texto_requisitos
	requisitos.custom_minimum_size = Vector2(0, 32)
	requisitos.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	requisitos.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	requisitos.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	requisitos.add_theme_font_size_override("font_size", 9)
	requisitos.add_theme_color_override("font_color", Color(0.46, 0.55, 0.7))
	requisitos.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coluna.add_child(requisitos)

	botao = Button.new()
	botao.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	botao.flat = true
	botao.focus_mode = Control.FOCUS_ALL
	botao.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	botao.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	botao.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	botao.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	botao.pressed.connect(_on_pressed)
	botao.mouse_entered.connect(_on_mouse_entered)
	botao.mouse_exited.connect(_on_mouse_exited)
	botao.focus_entered.connect(_on_mouse_entered)
	botao.focus_exited.connect(_on_mouse_exited)
	add_child(botao)


func criar_estilo_painel() -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.025, 0.035, 0.075, 0.98)
	estilo.border_color = cor_destaque.darkened(0.08)
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(16)
	estilo.shadow_color = Color(cor_destaque.r, cor_destaque.g, cor_destaque.b, 0.22)
	estilo.shadow_size = 10
	return estilo


func criar_poligonos_decorativos() -> void:
	var canto_superior := Polygon2D.new()
	canto_superior.polygon = PackedVector2Array([
		Vector2(0, 0), Vector2(72, 0), Vector2(0, 72)
	])
	canto_superior.color = Color(cor_destaque.r, cor_destaque.g, cor_destaque.b, 0.13)
	add_child(canto_superior)

	var losango := Polygon2D.new()
	losango.position = Vector2(226, 302)
	losango.polygon = PackedVector2Array([
		Vector2(0, -18), Vector2(18, 0), Vector2(0, 18), Vector2(-18, 0)
	])
	losango.color = Color(cor_destaque.r, cor_destaque.g, cor_destaque.b, 0.28)
	add_child(losango)


func _on_pressed() -> void:
	escolhido.emit(upgrade_id)


func _on_mouse_entered() -> void:
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.035, 1.035), 0.12)
	self_modulate = cor_destaque.lightened(0.08)


func _on_mouse_exited() -> void:
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.12)
	self_modulate = Color.WHITE
