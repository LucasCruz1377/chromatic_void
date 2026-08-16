extends Habilidade
class_name HabilidadeEscudoProtetor


@export_category("Escudo Protetor")
@export var resistencia_escudo: float = 48.0
@export var duracao: float = 7.0


func executar(player) -> void:
	player.ativar_escudo(
		resistencia_escudo,
		duracao,
		Color(0.72, 0.42, 1.0, 0.86)
	)


func obter_upgrades_especificos() -> Dictionary:
	var icone := "res://Habilidades/Icones/escudo_protetor.svg"
	var cor := Color(0.72, 0.42, 1.0)
	return {
		&"escudo_resistencia": criar_carta_upgrade("BARREIRA REFORÇADA", "+15 de resistência do escudo.", icone, cor, Nome, 3, [&"defesa"]),
		&"escudo_duracao": criar_carta_upgrade("PREVENÇÃO CONTÍNUA", "+1,2 segundo de duração.", icone, cor, Nome, 3, [&"duracao"]),
		&"escudo_recarga": criar_carta_upgrade("RESPOSTA PREVENTIVA", "Recarga 12% mais rápida.", icone, cor, Nome, 3, [&"cooldown"]),
	}


func aplicar_upgrade_especifico(id: StringName, _nivel: int) -> bool:
	match id:
		&"escudo_resistencia": resistencia_escudo += 15.0
		&"escudo_duracao": duracao += 1.2
		&"escudo_recarga": reduzir_cooldown(0.88)
		_: return false
	return true
