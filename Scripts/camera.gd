extends Camera2D


@export var ShakeMax := 100.0
@export var ShakeFade := 10.0
@export var ShakeComumMax := 3.5
@export var ShakeForteMax := 18.0

var ForcaShake := 0.0
var alvo_seguido: Node2D
var limites_arena := Rect2(Vector2.ZERO, Global.TAMANHO_BASE_JOGO)
var tamanho_visivel := Global.TAMANHO_BASE_JOGO

func configurar_alvo(
	novo_alvo: Node2D, nova_area: Rect2, novo_tamanho_visivel: Vector2
) -> void:
	alvo_seguido = novo_alvo
	limites_arena = nova_area
	tamanho_visivel = novo_tamanho_visivel
	_atualizar_posicao_alvo(1.0, true)


func shake(magnitude := 25.0, forte := false) -> void:
	var intensidade := clampf(Global.tremor_tela, 0.0, 1.0)
	var limite := ShakeForteMax if forte else ShakeComumMax
	limite = minf(limite, ShakeMax)
	var alvo := minf(maxf(magnitude, 0.0), limite) * intensidade
	# Usa o maior tremor vigente em vez de somar impactos. Rajadas, fragmentos e
	# mortes simultâneas deixam de transformar um toque leve em terremoto.
	ForcaShake = maxf(ForcaShake, alvo)


func _process(delta: float) -> void:
	_atualizar_posicao_alvo(delta)
	ForcaShake = move_toward(ForcaShake, 0.0, ShakeFade * delta)

	if ForcaShake > 0.0 and Global.tremor_tela > 0.0:
		offset = Vector2(
			randf_range(-ForcaShake, ForcaShake),
			randf_range(-ForcaShake, ForcaShake)
		)
	else:
		offset = Vector2.ZERO


func _atualizar_posicao_alvo(delta: float, imediato := false) -> void:
	if not is_instance_valid(alvo_seguido):
		return
	var metade := tamanho_visivel * 0.5
	var destino := alvo_seguido.global_position
	if limites_arena.size.x > tamanho_visivel.x:
		destino.x = clampf(destino.x, limites_arena.position.x + metade.x, limites_arena.end.x - metade.x)
	else:
		destino.x = limites_arena.get_center().x
	if limites_arena.size.y > tamanho_visivel.y:
		destino.y = clampf(destino.y, limites_arena.position.y + metade.y, limites_arena.end.y - metade.y)
	else:
		destino.y = limites_arena.get_center().y
	if imediato or global_position.distance_to(destino) > tamanho_visivel.length() * 0.65:
		global_position = destino
	else:
		global_position = global_position.lerp(destino, 1.0 - exp(-7.5 * delta))
