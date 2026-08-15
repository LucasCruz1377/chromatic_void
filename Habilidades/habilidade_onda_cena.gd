@tool
extends Area2D

@onready var area_deteccao = $AreaDeteccao

@export var Raio : float:
	set(valorraio):
		Raio = valorraio
		force_update_transform()
@export var Velocidade : float
@export var Dano : float

func _process(delta):
	area_deteccao.shape.radius = Raio
