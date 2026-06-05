extends Area2D

const SPEED = 1000
var dmg = 1

func _physics_process(delta: float) -> void:
	position += transform.x * SPEED * delta

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("tomar_dano"):
		body.tomar_dano(dmg)
		body.velocity *= 0.2
	queue_free()
func _on_visible_on_screen_notifier_3d_screen_exited() -> void:
	queue_free()
