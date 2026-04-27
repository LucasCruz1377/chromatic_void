extends Area2D

const SPEED = 1000
var dmg = 2
func _physics_process(delta: float) -> void:
	position += transform.x * SPEED * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") or body.is_in_group("parede"):
		if body.is_in_group("enemies"):
			body.hp -= dmg
			queue_free()
		else:
			queue_free()

func _on_visible_on_screen_notifier_3d_screen_exited() -> void:
	queue_free()
