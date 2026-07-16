extends Camera2D

@export var ShakeMax := 100.0
@export var ShakeFade : float = 10.0

var ForcaShake := 0.0

func shake(magnitude := 25.0):
	ForcaShake = min(ForcaShake + magnitude, ShakeMax)
	
func _process(delta):
	print("Força Tremer:",str(ForcaShake))
	ForcaShake = move_toward(ForcaShake, 0.0, ShakeFade * delta)
	
	if ForcaShake > 0.0:
		offset = Vector2(
			randf_range(-ForcaShake, ForcaShake),
			randf_range(-ForcaShake, ForcaShake)
		)
	else:
		offset = Vector2.ZERO
