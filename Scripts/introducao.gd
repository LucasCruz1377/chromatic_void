extends Node2D

@onready var animation_player = $AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_anything_pressed():
		animation_player.play("fade")
		
func iniciar():
	get_tree().change_scene_to_file("res://Rooms/TelaInicial.tscn")
