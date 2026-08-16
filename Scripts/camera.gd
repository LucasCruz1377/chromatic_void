extends Camera2D


@export var ShakeMax := 100.0
@export var ShakeFade := 10.0

var ForcaShake := 0.0


func shake(magnitude := 25.0) -> void:
	var intensidade := clampf(Global.tremor_tela, 0.0, 1.0)
	ForcaShake = minf(ForcaShake + magnitude * intensidade, ShakeMax * intensidade)


func _process(delta: float) -> void:
	ForcaShake = move_toward(ForcaShake, 0.0, ShakeFade * delta)

	if ForcaShake > 0.0 and Global.tremor_tela > 0.0:
		offset = Vector2(
			randf_range(-ForcaShake, ForcaShake),
			randf_range(-ForcaShake, ForcaShake)
		)
	else:
		offset = Vector2.ZERO

