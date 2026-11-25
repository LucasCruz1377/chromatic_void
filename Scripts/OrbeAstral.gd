extends CharacterBody2D
class_name OrbeAstral

var indice: int
var vida := 3.0
var morto := false

func _ready() -> void:
	collision_layer = 4
	collision_mask = 0
	add_to_group("inimigo")
	add_to_group("mancha_solar")
	var forma := CollisionShape2D.new()
	var circulo := CircleShape2D.new()
	circulo.radius = 15
	forma.shape = circulo
	add_child(forma)

func tomarDano(valor: float) -> void:
	if not visible or morto or valor <= 0:
		return
	if Rede.modo_multiplayer and not multiplayer.is_server():
		var combate := get_parent() as SizigiaFinalController
		combate.solicitar_impacto_mancha.rpc_id(1, combate.serie, indice, minf(valor, vida))
		return
	vida -= maxf(valor, 0)
	if vida <= 0:
		morto = true
		var combate := get_parent()
		combate.mascara_orbes &= ~(1 << indice)
		combate.atualizar_orbes()

func _draw() -> void:
	var carga := clampf(get_parent().tempo / 3.2, 0, 1)
	var pulso := sin(carga * carga * TAU * 5.0) * 0.5 + 0.5
	draw_circle(Vector2.ZERO, 19 + pulso * 6, Color(1, 0.45, 0.1, 0.12 + carga * 0.16))
	draw_circle(Vector2.ZERO, 15, Color("#482235"))
	draw_arc(Vector2.ZERO, 15, 0, TAU, 28, Color("#ffbd53"), 3, true)
	draw_circle(Vector2(-4,-3), 4, Color("#ffdfa3"))
