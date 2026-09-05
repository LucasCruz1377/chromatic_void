extends Camera2D


@export var ShakeMax := 100.0
@export var ShakeFade := 10.0
@export var ShakeComumMax := 3.5
@export var ShakeForteMax := 18.0

var ForcaShake := 0.0


func shake(magnitude := 25.0, forte := false) -> void:
	var intensidade := clampf(Global.tremor_tela, 0.0, 1.0)
	var limite := ShakeForteMax if forte else ShakeComumMax
	limite = minf(limite, ShakeMax)
	var alvo := minf(maxf(magnitude, 0.0), limite) * intensidade
	# Usa o maior tremor vigente em vez de somar impactos. Rajadas, fragmentos e
	# mortes simultâneas deixam de transformar um toque leve em terremoto.
	ForcaShake = maxf(ForcaShake, alvo)


func _process(delta: float) -> void:
	ForcaShake = move_toward(ForcaShake, 0.0, ShakeFade * delta)

	if ForcaShake > 0.0 and Global.tremor_tela > 0.0:
		offset = Vector2(
			randf_range(-ForcaShake, ForcaShake),
			randf_range(-ForcaShake, ForcaShake)
		)
	else:
		offset = Vector2.ZERO
