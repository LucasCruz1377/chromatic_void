extends CharacterBody2D
class_name InimigoBase


@export_group("Configuração")
@export var VidaMaxima: float = 100.0
@export var Dano: float = 2.0
@export var ValorXP: float = 1.0
@export var Velocidade: float = 30.0
@export var usa_wrap: bool = true

var Vida: float = 0.0
var tempo_atordoado: float = 0.0

@onready var player = get_tree().get_first_node_in_group("player")


func atualizar_estados(delta: float) -> void:
	if tempo_atordoado > 0.0:
		tempo_atordoado = maxf(tempo_atordoado - delta, 0.0)


func aplicar_atordoamento(duracao: float) -> void:
	tempo_atordoado = maxf(tempo_atordoado, duracao)


func esta_atordoado() -> bool:
	return tempo_atordoado > 0.0


func Mover(_delta: float) -> void:
	pass


func tomarDano(_valor: float) -> void:
	pass


func morrer() -> void:
	pass
