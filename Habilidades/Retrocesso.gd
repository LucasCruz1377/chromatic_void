extends Habilidade
class_name HabilidadeRetrocesso

var memoria = []
var recordando = false
@export var intervalomemorias : float = 0
@export var max_memoria : int = 60


func activate(player):
	if recordando:
		return
	
	player.BloquearGiro()
	player.BloquearControle()
	recordando = true
	player.velocity = Vector2.ZERO
	rewind(player)

func update(player,delta):
	
	if !recordando:
		if memoria.size() >= max_memoria:
			memoria.pop_front()
		memoria.append({"posicao" : player.global_position , "rotacao" : player.rotation , "vida" : player.vida})
	
func rewind(player):
	
	if memoria.is_empty():
		recordando = false
		return
		
	player.IniciarHabilidade()
	for save in range(memoria.size() - 1,-1,-1):
		while player.get_tree().paused and player.vivo :
			await player.get_tree().process_frame
		
		player.global_position = memoria[save]["posicao"]
		player.rotation = memoria[save]["rotacao"]
		
		player.vida = memoria[save]["vida"] if memoria[save]["vida"] > player.vida else player.vida
		
		await player.get_tree().create_timer(intervalomemorias).timeout
	player.EncerrarHabilidade()
	memoria.clear()
	recordando = false
	player.DesbloquearGiro()
	player.DesbloquearControle()
