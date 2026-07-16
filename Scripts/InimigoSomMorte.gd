extends GPUParticles2D

@onready var som: AudioStreamPlayer2D = $som

func _ready() -> void:
	som.play()
	await get_tree().create_timer(2).timeout
	queue_free()

	
