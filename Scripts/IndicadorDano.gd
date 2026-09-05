extends Node2D
class_name IndicadorDano


const DURACAO := 0.68

var valor := 0.0
var cor := Color.WHITE
var critico := false
var tempo := 0.0
var velocidade := Vector2.ZERO
var label: Label


static func criar(
	pai: Node, posicao_global: Vector2, dano: float,
	cor_efeito: Color = Color.WHITE, eh_critico: bool = false
) -> IndicadorDano:
	if not is_instance_valid(pai) or dano <= 0.0:
		return null
	var indicador := IndicadorDano.new()
	indicador.valor = dano
	indicador.cor = cor_efeito
	indicador.critico = eh_critico
	indicador.velocidade = Vector2(randf_range(-18.0, 18.0), -72.0 if eh_critico else -58.0)
	pai.add_child(indicador)
	indicador.global_position = posicao_global + Vector2(randf_range(-8.0, 8.0), -16.0)
	indicador.z_index = 110
	return indicador


func _ready() -> void:
	label = Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = Vector2(-45.0, -18.0)
	label.size = Vector2(90.0, 36.0)
	label.text = _formatar_valor(valor)
	label.add_theme_font_size_override("font_size", 22 if critico else 17)
	label.add_theme_color_override("font_color", Color(1.2, 1.2, 1.2, 1.0))
	label.add_theme_color_override("font_outline_color", Color(cor.r, cor.g, cor.b, 0.95))
	label.add_theme_constant_override("outline_size", 5 if critico else 3)
	if ResourceLoader.exists("res://Fonts/Stereohead.otf"):
		label.add_theme_font_override("font", load("res://Fonts/Stereohead.otf") as Font)
	add_child(label)
	scale = Vector2.ONE * 0.45


func _process(delta: float) -> void:
	tempo += delta
	global_position += velocidade * delta
	velocidade = velocidade.lerp(Vector2(0.0, -24.0), clampf(delta * 4.0, 0.0, 1.0))
	var progresso := clampf(tempo / DURACAO, 0.0, 1.0)
	var entrada := minf(progresso / 0.16, 1.0)
	var saida := clampf((1.0 - progresso) / 0.34, 0.0, 1.0)
	scale = Vector2.ONE * lerpf(0.45, 1.12 if critico else 1.0, entrada)
	modulate.a = saida
	if tempo >= DURACAO:
		queue_free()


func _formatar_valor(dano: float) -> String:
	if absf(dano - roundf(dano)) < 0.05:
		return str(roundi(dano))
	return "%.1f" % dano
