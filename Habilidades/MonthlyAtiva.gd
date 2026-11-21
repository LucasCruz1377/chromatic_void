extends Habilidade
class_name HabilidadeMonthly


@export var efeito_id: StringName = &""
@export var cor_efeito: Color = Color.WHITE
@export_range(0.2, 3.0, 0.05) var potencia: float = 1.0

var nivel_upgrade_1 := 0
var nivel_upgrade_2 := 0
var nivel_upgrade_3 := 0
var nivel_upgrade_4 := 0


func em_uso() -> bool:
	if super():
		return true
	if not is_instance_valid(piloto_ativacao):
		return false
	match efeito_id:
		&"renascimento": return piloto_ativacao.semente_renascimento_ativa
		&"parry": return piloto_ativacao.janela_parry > 0.0
		&"imaginacao": return piloto_ativacao.tempo_poder_monthly > 0.0
		&"determinacao": return piloto_ativacao.tempo_escudo_habilidade > 0.0
		&"natureza": return piloto_ativacao.sequencia_natureza_ativa
	return false


func executar(player) -> void:
	if is_instance_valid(player) and player.has_method("aplicar_poder_monthly"):
		var configuracao := _config_rework()
		configuracao["semente_visual"] = randi()
		player.call("aplicar_poder_monthly", efeito_id, cor_efeito, potencia, configuracao)


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
				"limite_raizes": 3 + mini(nivel_upgrade_4, 2),
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
				&"ovo_cura": criar_carta_upgrade("GEMA RESTAURADORA", "O resultado de cura recupera mais vida.", icone, cor_efeito, Nome, 3, [&"cura"]),
				&"ovo_drone_dano": criar_carta_upgrade("PINTINHO ARMADO", "Seu ajudante causa mais dano.", icone, cor_efeito, Nome, 3, [&"dano"]),
				&"ovo_drone_duracao": criar_carta_upgrade("CASCA RESISTENTE", "Seu ajudante permanece por mais tempo.", icone, cor_efeito, Nome, 3, [&"duracao"]),
			}
		&"florescimento":
			return {
				&"flor_velocidade": criar_carta_upgrade("VINHAS VORAZES", "Suas flores criam vinhas mais rápido.", icone, cor_efeito, Nome, 3, [&"cadencia"]),
				&"flor_sementes": criar_carta_upgrade("SEMENTES EXPLOSIVAS", "Flores destruídas espalham pétalas perfurantes.", icone, cor_efeito, Nome, 1, [&"projeteis"]),
				&"flor_duracao": criar_carta_upgrade("PRIMAVERA LONGA", "Sua habilidade infecta inimigos por mais tempo.", icone, cor_efeito, Nome, 3, [&"duracao"]),
				&"flor_raizes": criar_carta_upgrade("JARDIM PROFUNDO", "Mais raízes podem ficar ativas ao mesmo tempo.", icone, cor_efeito, Nome, 2, [&"quantidade"]),
			}
		&"tempestade":
			return {
				&"tempestade_dano": criar_carta_upgrade("FOLHAS CORTANTES", "As folhas da sua tempestade causam mais dano.", icone, cor_efeito, Nome, 3, [&"dano"]),
				&"tempestade_duracao": criar_carta_upgrade("FRENTE VERDE", "Sua tempestade dura mais tempo.", icone, cor_efeito, Nome, 3, [&"duracao"]),
				&"tempestade_perfuracao": criar_carta_upgrade("VENTO PENETRANTE", "Suas folhas atravessam mais inimigos.", icone, cor_efeito, Nome, 3, [&"penetracao"]),
			}
	return {}


func aplicar_upgrade_especifico(id: StringName, _nivel: int) -> bool:
	if id in [&"ovo_cura", &"flor_velocidade", &"tempestade_dano"]:
		nivel_upgrade_1 += 1
	elif id in [&"ovo_drone_dano", &"flor_sementes", &"tempestade_duracao"]:
		nivel_upgrade_2 += 1
	elif id in [&"ovo_drone_duracao", &"flor_duracao", &"tempestade_perfuracao"]:
		nivel_upgrade_3 += 1
	elif id == &"flor_raizes":
		nivel_upgrade_4 += 1
	else:
		return false
	return true


func reiniciar_estado() -> void:
	super()
	nivel_upgrade_1 = 0
	nivel_upgrade_2 = 0
	nivel_upgrade_3 = 0
	nivel_upgrade_4 = 0
