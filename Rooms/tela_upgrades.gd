extends Control

@export var cena_carta : PackedScene
@onready var container = $ContainerCartas
@export var qtd_cartas : int = 3

@onready var player = get_tree().get_first_node_in_group("player")

func _ready():
	player.subiuDeNivel.connect(_on_player_subiu_de_nivel)
	print("player obtido")
	

func _on_player_subiu_de_nivel():
	var upgrades = sortear_upgrades(3)
	mostrar_cartas(upgrades)
	
func sortear_upgrades(qtd : int) -> Array:
	var tipos = Upgrades.Tipo.values()
	tipos.shuffle()
	return tipos.slice(0, qtd)
	
func mostrar_cartas(upgrades):
	Engine.time_scale = 0.1
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
	player.receber_upgrade(tipo)
	Engine.time_scale = 1
	for i in container.get_children():
		i.queue_free()
