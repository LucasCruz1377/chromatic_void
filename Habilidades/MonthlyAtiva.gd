extends Habilidade
class_name HabilidadeMonthly


@export var efeito_id: StringName = &""
@export var cor_efeito: Color = Color.WHITE
@export_range(0.2, 3.0, 0.05) var potencia: float = 1.0

var nivel_upgrade_1 := 0
var nivel_upgrade_2 := 0
var nivel_upgrade_3 := 0


func executar(player) -> void:
	if is_instance_valid(player) and player.has_method("aplicar_poder_monthly"):
		player.call("aplicar_poder_monthly", efeito_id, cor_efeito, potencia, _config_rework())


func _config_rework() -> Dictionary:
	match efeito_id:
		&"ovo":
			return {
				"cura": 22.0 + 8.0 * nivel_upgrade_1,
				"dano_drone": 0.8 + 0.25 * nivel_upgrade_2,
				"duracao_drone": 6.5 + 1.5 * nivel_upgrade_3,
			}
		&"florescimento":
			return {
				"intervalo": 0.54 * pow(0.82, nivel_upgrade_1),
				"projeteis_explosao": nivel_upgrade_2 > 0,
				"duracao": 3.0 + 0.75 * nivel_upgrade_3,
			}
		&"tempestade":
			return {
				"dano": 5.0 + 1.25 * nivel_upgrade_1,
				"duracao": 7.0 + 1.0 * nivel_upgrade_2,
				"perfuracao": nivel_upgrade_3,
			}
	return {}


func obter_upgrades_especificos() -> Dictionary:
	var icone := String(Icone.resource_path) if Icone else ""
	match efeito_id:
		&"ovo":
			return {
				&"ovo_cura": criar_carta_upgrade("GEMA RESTAURADORA", "+8 de cura no resultado restaurador.", icone, cor_efeito, Nome, 3, [&"cura"]),
				&"ovo_drone_dano": criar_carta_upgrade("PINTINHO ARMADO", "+25% de dano do ajudante.", icone, cor_efeito, Nome, 3, [&"dano"]),
				&"ovo_drone_duracao": criar_carta_upgrade("CASCA RESISTENTE", "+1,5 segundo de duração do ajudante.", icone, cor_efeito, Nome, 3, [&"duracao"]),
			}
		&"florescimento":
			return {
				&"flor_velocidade": criar_carta_upgrade("VINHAS VORAZES", "Cria vinhas 18% mais rápido quando há alvos.", icone, cor_efeito, Nome, 3, [&"cadencia"]),
				&"flor_sementes": criar_carta_upgrade("SEMENTES EXPLOSIVAS", "Flores destruídas espalham seis pétalas perfurantes.", icone, cor_efeito, Nome, 1, [&"projeteis"]),
				&"flor_duracao": criar_carta_upgrade("PRIMAVERA LONGA", "+0,75 segundo infectando inimigos próximos.", icone, cor_efeito, Nome, 3, [&"duracao"]),
			}
		&"tempestade":
			return {
				&"tempestade_dano": criar_carta_upgrade("FOLHAS CORTANTES", "+1,25 de dano por folha.", icone, cor_efeito, Nome, 3, [&"dano"]),
				&"tempestade_duracao": criar_carta_upgrade("FRENTE VERDE", "+1 segundo de chuva diagonal.", icone, cor_efeito, Nome, 3, [&"duracao"]),
				&"tempestade_perfuracao": criar_carta_upgrade("VENTO PENETRANTE", "Cada folha atravessa mais um inimigo.", icone, cor_efeito, Nome, 3, [&"penetracao"]),
			}
	return {}


func aplicar_upgrade_especifico(id: StringName, _nivel: int) -> bool:
	if id in [&"ovo_cura", &"flor_velocidade", &"tempestade_dano"]:
		nivel_upgrade_1 += 1
	elif id in [&"ovo_drone_dano", &"flor_sementes", &"tempestade_duracao"]:
		nivel_upgrade_2 += 1
	elif id in [&"ovo_drone_duracao", &"flor_duracao", &"tempestade_perfuracao"]:
		nivel_upgrade_3 += 1
	else:
		return false
	return true


func reiniciar_estado() -> void:
	super()
	nivel_upgrade_1 = 0
	nivel_upgrade_2 = 0
	nivel_upgrade_3 = 0
