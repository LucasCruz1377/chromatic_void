extends Habilidade
class_name HabilidadeRetrocesso

var memoria = []
var recordando = false
var max_memoria : int = 60


func activate(player):

# o que deve acontecer a todo momento para funcionar
func update(player,delta): 
	if recordando
