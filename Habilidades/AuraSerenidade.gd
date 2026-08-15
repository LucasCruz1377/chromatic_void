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

