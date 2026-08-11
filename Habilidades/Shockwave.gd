extends Habilidade
class_name HabilidadeShockwave

@export var RaioOnda : float = 50
@export var VelocidadeOnda : float = 5
@export var DanoOnda : float = 10
@export var OndaCena : PackedScene 

func activate(_player):
	var Onda = OndaCena.instantiate()
	
	Onda.Dano = DanoOnda
	Onda.Raio = RaioOnda
	Onda.Velocidade = VelocidadeOnda
	
	_player.get_tree().current_scene().add_child(Onda)
	
		
