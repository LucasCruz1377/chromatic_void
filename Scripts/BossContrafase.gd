extends BossMensal
class_name BossContrafase

const JANELA_ENTRE_SOLOS := 5.0

@onready var partitura: PartituraContrafase = $Palco/Partitura
@onready var silhueta: CollisionPolygon2D = $Silhueta
var volta := 0
var camada_solida := 0
var mascara_solida := 0


func _ready() -> void:
	super._ready()
	camada_solida = collision_layer
	mascara_solida = collision_mask
	tempo_ataque = 3.0
	partitura.fim_da_frase.connect(_retornar)


func Mover(delta: float) -> void:
	angulo_visual += delta
	if partitura.ativa:
		velocity = Vector2.ZERO
		return
	rotation = -0.30 + 0.10 * sin(angulo_visual * 1.8)
	velocity = velocity.move_toward(Vector2.ZERO, delta * 160.0)
	if is_instance_valid(player):
		tempo_ataque -= delta
		if tempo_ataque <= 0.0:
			iniciar_partitura()


func iniciar_partitura() -> void:
	if morto or partitura.ativa or (Rede.modo_multiplayer and not multiplayer.is_server()):
		return
	volta += 1
	velocity = Vector2.ZERO
	partitura.iniciar(volta, global_position, Dano * 0.38, 0.0)
	_definir_corpo(false)
	_enviar_estado_defesas_rede()


func _retornar() -> void:
	if Rede.modo_multiplayer and not multiplayer.is_server():
		return
	partitura.encerrar()
	_definir_corpo(true)
	tempo_ataque = JANELA_ENTRE_SOLOS
	_enviar_estado_defesas_rede()


func _definir_corpo(presente: bool) -> void:
	visible = presente
	if presente and not is_in_group(&"inimigo"):
		add_to_group(&"inimigo")
	elif not presente and is_in_group(&"inimigo"):
		remove_from_group(&"inimigo")
	collision_layer = camada_solida if presente else 0
	collision_mask = mascara_solida if presente else 0
	silhueta.set_deferred("disabled", not presente)


func _mover_para_presente_misterioso(delta: float) -> bool:
	return false if partitura.ativa else super._mover_para_presente_misterioso(delta)


func tomarDano(valor: float) -> void:
	if not partitura.ativa:
		super.tomarDano(valor)


func receber_eco_laco(valor: float) -> void:
	if not partitura.ativa:
		super.receber_eco_laco(valor)


func ao_colidir_com_player(alvo: Node) -> void:
	if not partitura.ativa:
		super.ao_colidir_com_player(alvo)


# O solo tem somente um ataque, inclusive quando cruza os limiares de vida.
func atualizar_fase() -> void:
	pass


func obter_cor_feedback() -> Color:
	return cor_principal


func _capturar_estado_defesas_rede() -> Dictionary:
	return {
		"volta": volta, "solo": partitura.ativa, "tempo": partitura.tempo,
		"origem": partitura.origem, "dano": partitura.dano,
	}


func _aplicar_estado_defesas_rede(dados: Dictionary) -> void:
	if not dados.has("solo"):
		return
	var nova_volta := int(dados["volta"])
	if bool(dados["solo"]):
		var instante := float(dados["tempo"])
		if not partitura.ativa or nova_volta != volta:
			volta = nova_volta
			partitura.iniciar(volta, dados["origem"], float(dados["dano"]), instante)
			_definir_corpo(false)
		else:
			partitura.corrigir_tempo(instante)
	elif partitura.ativa:
		partitura.encerrar()
		_definir_corpo(true)
