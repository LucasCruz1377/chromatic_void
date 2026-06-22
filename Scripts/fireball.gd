extends Area2D

const SPEED = 1000
var dmg : int
var tempo_vida = 5 * 60
func _physics_process(delta: float) -> void:
	tempo_vida -= 1
	if tempo_vida <= 0:
		queue_free()
	position += transform.x * SPEED * delta

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("tomar_dano"):
		body.tomar_dano(dmg)
		body.velocity *= 0.1
	queue_free()
func _on_visible_on_screen_notifier_3d_screen_exited() -> void:
	queue_free()
