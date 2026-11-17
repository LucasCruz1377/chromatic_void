extends Control
class_name UpgradeCardNova


signal escolhido(id: StringName)

# Hexagono com pontas verticais e lados verticais compartilhados na fileira.
const TAMANHO_CARD := Vector2(176, 204)
const COR_BORDA_NEUTRA := Color(0.38, 0.39, 0.57)

class BotaoHexagonal extends Button:
	func _has_point(ponto: Vector2) -> bool:
		return Geometry2D.is_point_in_polygon(ponto, UpgradeCardNova.vertices_hexagono(size))


var upgrade_id: StringName
var cor_destaque := Color.WHITE
var selecionado := false
var botao: Button
var icone: TextureRect
var _em_foco := false


func configurar(
	id: StringName,
	dados: Dictionary,
	_nivel_atual: int = 0,
	_texto_requisitos: String = ""
) -> void:
	upgrade_id = id
	cor_destaque = Color(dados.get("cor", Color.WHITE))
	custom_minimum_size = TAMANHO_CARD
	size = TAMANHO_CARD
	size_flags_horizontal = Control.SIZE_FILL
	size_flags_vertical = Control.SIZE_FILL
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	icone = TextureRect.new()
	icone.name = "IconeMelhoria"
	icone.position = (TAMANHO_CARD - Vector2(100, 100)) * 0.5
	icone.size = Vector2(100, 100)
	icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icone.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	icone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var caminho_icone := str(dados.get("icone", ""))
	if not caminho_icone.is_empty() and ResourceLoader.exists(caminho_icone):
		icone.texture = load(caminho_icone) as Texture2D
	add_child(icone)

	botao = BotaoHexagonal.new()
	botao.name = "SelecionarMelhoria"
	botao.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	botao.flat = true
	botao.focus_mode = Control.FOCUS_ALL
	botao.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for estado in ["normal", "hover", "pressed", "focus", "disabled"]:
		botao.add_theme_stylebox_override(estado, StyleBoxEmpty.new())
	botao.pressed.connect(_on_pressed)
	botao.mouse_entered.connect(_atualizar_foco)
	botao.mouse_exited.connect(_atualizar_foco)
	botao.focus_entered.connect(_atualizar_foco)
	botao.focus_exited.connect(_atualizar_foco)
	add_child(botao)
	resized.connect(queue_redraw)


static func vertices_hexagono(tamanho: Vector2) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(tamanho.x * 0.5, 0),
		Vector2(tamanho.x, tamanho.y * 0.25),
		Vector2(tamanho.x, tamanho.y * 0.75),
		Vector2(tamanho.x * 0.5, tamanho.y),
		Vector2(0, tamanho.y * 0.75),
		Vector2(0, tamanho.y * 0.25),
	])


func definir_selecionado(valor: bool) -> void:
	selecionado = valor
	# A borda selecionada fica acima da borda neutra no lado compartilhado.
	z_index = 1 if selecionado else 0
	queue_redraw()


func _draw() -> void:
	var pontos := vertices_hexagono(size)
	var fundo := Color(0.012, 0.018, 0.045, 0.98)
	if selecionado:
		fundo = fundo.lerp(Color(cor_destaque, 0.98), 0.065)
	draw_colored_polygon(pontos, fundo)
	pontos.append(pontos[0])
	if selecionado:
		draw_polyline(pontos, Color(cor_destaque, 0.04), 16.0, true)
		draw_polyline(pontos, Color(cor_destaque, 0.08), 10.0, true)
		draw_polyline(pontos, Color(cor_destaque, 0.18), 6.0, true)
	draw_polyline(
		pontos,
		cor_destaque if selecionado else COR_BORDA_NEUTRA.lightened(0.2 if _em_foco else 0.0),
		3.0 if selecionado else 1.8,
		true
	)


func _on_pressed() -> void:
	escolhido.emit(upgrade_id)


func _atualizar_foco() -> void:
	_em_foco = botao.has_focus() or botao.is_hovered()
	queue_redraw()
