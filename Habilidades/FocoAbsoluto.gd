extends Habilidade
class_name HabilidadeFocoAbsoluto


@export_category("Foco Absoluto")
@export_range(0.1, 1.0, 0.05) var escala_tempo: float = 0.35
@export var duracao_real: float = 2.5

var ativo := false
var instante_final_ms := 0
var escala_anterior := 1.0
var movimento_anterior := 1.0


func pode_ativar(player) -> bool:
	return super(player) and not ativo


func executar(player) -> void:
	ativo = true
	escala_anterior = Engine.time_scale
	movimento_anterior = player.multiplicador_velocidade_habilidade
	instante_final_ms = Time.get_ticks_msec() + int(duracao_real * 1000.0)

	Engine.time_scale = escala_tempo
	player.multiplicador_velocidade_habilidade = movimento_anterior / escala_tempo
	player.IniciarHabilidade(false)
	player.modulate = Color(0.65, 0.9, 1.0, 1.0)


func atualizar(player, _delta: float) -> void:
	if not ativo:
		return

	if not is_instance_valid(player):
		Engine.time_scale = escala_anterior
		ativo = false
		return

	if Time.get_ticks_msec() >= instante_final_ms:
		finalizar(player)


func finalizar(player) -> void:
	if not ativo:
		return

	ativo = false
	Engine.time_scale = escala_anterior

	if is_instance_valid(player):
		player.multiplicador_velocidade_habilidade = movimento_anterior
		player.modulate = Color.WHITE
		player.EncerrarHabilidade()


func ao_desequipar(player) -> void:
	finalizar(player)


func reiniciar_estado() -> void:
	super()
	ativo = false
	instante_final_ms = 0
	escala_anterior = 1.0
	movimento_anterior = 1.0

