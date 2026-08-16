extends Habilidade
class_name HabilidadeFrenesiCarnavalesco


const RASTRO := preload("res://Habilidades/RastroCarnaval.gd")

@export_category("Frenesi Carnavalesco")
@export var duracao: float = 5.5
@export var multiplicador_velocidade: float = 1.45
@export var multiplicador_ataque: float = 1.35
@export var multiplicador_cadencia: float = 0.72
@export var intervalo_rastro: float = 0.16
@export var dano_rastro: float = 0.45
@export var raio_rastro: float = 30.0

var ativa := false
var tempo_restante := 0.0
var tempo_rastro := 0.0
var alvo: Node
var modulacao_anterior := Color.WHITE
var indice_cor := 0
var cores := [
	Color(1.0, 0.20, 0.74, 0.82),
	Color(0.20, 0.92, 1.0, 0.82),
	Color(1.0, 0.78, 0.14, 0.82),
	Color(0.64, 0.32, 1.0, 0.82),
]


func pode_ativar(player) -> bool:
	return super(player) and not ativa


func executar(player) -> void:
	ativa = true
	alvo = player
	tempo_restante = duracao
	tempo_rastro = 0.0
	modulacao_anterior = player.modulate
	player.multiplicador_velocidade_habilidade *= multiplicador_velocidade
	player.multiplicador_dano_habilidade *= multiplicador_ataque
	player.multiplicador_cadencia_habilidade *= multiplicador_cadencia
	player.modulate = Color(1.0, 0.72, 1.0, 1.0)


func atualizar(player, delta: float) -> void:
	if not ativa:
		return
	if not is_instance_valid(player):
		ativa = false
		alvo = null
		return

	tempo_restante -= delta
	tempo_rastro -= delta
	if tempo_rastro <= 0.0:
		tempo_rastro = intervalo_rastro
		criar_rastro(player)

	if tempo_restante <= 0.0:
		finalizar(player)


func criar_rastro(player) -> void:
	var rastro := RASTRO.new() as RastroCarnaval
	rastro.configurar(
		player.global_position,
		dano_rastro * player.dano,
		cores[indice_cor % cores.size()],
		raio_rastro
	)
	player.get_tree().current_scene.add_child(rastro)
	indice_cor += 1


func finalizar(player) -> void:
	if not ativa:
		return
	ativa = false
	tempo_restante = 0.0

	if is_instance_valid(player):
		player.multiplicador_velocidade_habilidade /= multiplicador_velocidade
		player.multiplicador_dano_habilidade /= multiplicador_ataque
		player.multiplicador_cadencia_habilidade /= multiplicador_cadencia
		player.modulate = modulacao_anterior
	alvo = null


func ao_desequipar(player) -> void:
	finalizar(player)


func reiniciar_estado() -> void:
	super()
	ativa = false
	tempo_restante = 0.0
	tempo_rastro = 0.0
	alvo = null
	indice_cor = 0


func obter_upgrades_especificos() -> Dictionary:
	var icone := "res://Habilidades/Icones/frenesi_carnavalesco.svg"
	var cor := Color(1.0, 0.25, 0.78)
	return {
		&"frenesi_potencia": criar_carta_upgrade("RITMO INTENSO", "+12% de ataque e +0,18 de dano dos rastros.", icone, cor, Nome, 3, [&"dano"]),
		&"frenesi_duracao": criar_carta_upgrade("BLOCO SEM FIM", "+1 segundo de duração.", icone, cor, Nome, 3, [&"duracao"]),
		&"frenesi_alcance": criar_carta_upgrade("PASSARELA NEON", "+8 de raio para os rastros de dano.", icone, cor, Nome, 3, [&"alcance"]),
	}


func aplicar_upgrade_especifico(id: StringName, _nivel: int) -> bool:
	match id:
		&"frenesi_potencia":
			multiplicador_ataque += 0.12
			dano_rastro += 0.18
		&"frenesi_duracao":
			duracao += 1.0
		&"frenesi_alcance":
			raio_rastro += 8.0
		_:
			return false
	return true
