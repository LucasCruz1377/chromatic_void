extends Control

@export var cena_carta : PackedScene
@onready var container = $ContainerCartas
@export var qtd_cartas : int = 3

func _ready():
	var player = get_tree().get_first_node_in_group("player")
	player.subiuDeNivel.connect(_on_player_subiu_de_nivel)
	print("player obtido")
	

func _on_player_subiu_de_nivel():
	var upgrades = sortear_upgrades(3)
	mostrar_cartas(qtd_cartas)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
func sortear_upgrades(qtd : int) -> Array:
	var tipos = Upgrades.Tipo.keys()
	tipos.shuffle()
	return tipos.slice(0, qtd)
	
func mostrar_cartas(upgrades):
	for tipo in upgrades:
		var carta = cena_carta.instantiate()
		container.add_child(carta)
		
		var dados = Upgrades.DADOS[tipo]
		carta.configurar_carta(
			tipo,
			dados["nome"],
			dados["descrição"]
		)
		
		carta.clicou.connect(_on_carta_clicada)
	
	
func _on_carta_clicada(tipo):
	print("escolheu upgrade de:  ", tipo)
	for i in get_children():
		i.queue_free()
