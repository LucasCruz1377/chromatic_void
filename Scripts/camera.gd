extends Camera2D

@export var ShakeMax := 10.0
@export var ShakeFade : float = 10.0
var _ForcaShake : float = 0.0

func Shake() -> void:
	_ForcaShake = ShakeMax
	
func _process(delta):
	if _ForcaShake > 0:
		_ForcaShake = lerp(_ForcaShake, 0.0, ShakeFade * delta)
		offset = Vector2(randf_range(-_ForcaShake,_ForcaShake),randf_range(-_ForcaShake,_ForcaShake))
