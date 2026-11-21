extends GPUParticles2D

func _ready() -> void:
	await get_tree().create_timer(2, false).timeout
	queue_free()
