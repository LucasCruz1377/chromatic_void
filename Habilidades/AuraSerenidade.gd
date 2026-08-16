extends Habilidade
class_name HabilidadeAuraSerenidade


@export_category("Aura da Serenidade")
@export var duracao: float = 5.0
@export_range(0.0, 1.0, 0.05) var multiplicador_dano: float = 0.55
@export var regeneracao_por_segundo: float = 5.0

var ativa := false
var tempo_restante := 0.0
var multiplicador_anterior := 1.0


func pode_ativar(player) -> bool:
	return super(player) and not ativa


func executar(player) -> void:
	ativa = true
	tempo_restante = duracao
	multiplicador_anterior = player.multiplicador_dano_recebido
	player.multiplicador_dano_recebido = multiplicador_anterior * multiplicador_dano
	player.IniciarHabilidade(false)
	player.modulate = Color(0.9, 1.0, 1.0, 1.0)


func atualizar(player, delta: float) -> void:
	if not ativa:
		return
	if not is_instance_valid(player):
		ativa = false
		return
	player.curar(regeneracao_por_segundo * delta)
	tempo_restante -= delta
	if tempo_restante <= 0.0:
		finalizar(player)


func finalizar(player) -> void:
	if not ativa:
		return
	ativa = false
	tempo_restante = 0.0
	if is_instance_valid(player):
		player.multiplicador_dano_recebido = multiplicador_anterior
		player.modulate = Color.WHITE
		player.EncerrarHabilidade()


func ao_desequipar(player) -> void:
	finalizar(player)


func reiniciar_estado() -> void:
	super()
	ativa = false
	tempo_restante = 0.0
	multiplicador_anterior = 1.0


func obter_upgrades_especificos() -> Dictionary:
	var icone := "res://Habilidades/Icones/aura_serenidade.svg"
	var cor := Color(0.72, 0.94, 1.0)
	return {
		&"aura_regeneracao": criar_carta_upgrade("RESPIRAÇÃO SERENA", "+1,5 de regeneração por segundo.", icone, cor, Nome, 3, [&"cura"]),
		&"aura_duracao": criar_carta_upgrade("PAUSA CONSCIENTE", "+1 segundo de duração.", icone, cor, Nome, 3, [&"duracao"]),
		&"aura_resistencia": criar_carta_upgrade("MENTE PROTEGIDA", "Recebe mais 7% de redução de dano.", icone, cor, Nome, 3, [&"defesa"]),
	}


func aplicar_upgrade_especifico(id: StringName, _nivel: int) -> bool:
	match id:
		&"aura_regeneracao": regeneracao_por_segundo += 1.5
		&"aura_duracao": duracao += 1.0
		&"aura_resistencia": multiplicador_dano = maxf(multiplicador_dano - 0.07, 0.25)
		_: return false
	return true
