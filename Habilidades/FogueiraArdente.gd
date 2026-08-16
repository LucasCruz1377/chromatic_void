extends Habilidade
class_name HabilidadeFogueiraArdente


const FOGUEIRA := preload("res://Habilidades/FogueiraZona.gd")

@export_category("Fogueira Ardente")
@export var duracao: float = 8.0
@export var raio: float = 95.0
@export var dano_por_segundo: float = 3.5


func executar(player) -> void:
	var fogueira := FOGUEIRA.new() as FogueiraZona
	fogueira.configurar(
		player.global_position,
		duracao,
		raio,
		dano_por_segundo
	)
	player.get_tree().current_scene.add_child(fogueira)


func obter_upgrades_especificos() -> Dictionary:
	var icone := "res://Habilidades/Icones/fogueira_ardente.svg"
	var cor := Color(1.0, 0.58, 0.12)
	return {
		&"fogueira_dano": criar_carta_upgrade("BRASA VIVA", "+1 de dano por segundo.", icone, cor, Nome, 3, [&"dano"]),
		&"fogueira_duracao": criar_carta_upgrade("FOGO ALIMENTADO", "+1,5 segundo de duração.", icone, cor, Nome, 3, [&"duracao"]),
		&"fogueira_alcance": criar_carta_upgrade("RODA DA FOGUEIRA", "+18 de raio da zona ardente.", icone, cor, Nome, 3, [&"alcance"]),
	}


func aplicar_upgrade_especifico(id: StringName, _nivel: int) -> bool:
	match id:
		&"fogueira_dano": dano_por_segundo += 1.0
		&"fogueira_duracao": duracao += 1.5
		&"fogueira_alcance": raio += 18.0
		_: return false
	return true
