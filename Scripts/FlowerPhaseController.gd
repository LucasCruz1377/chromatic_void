extends Node
class_name FlowerPhaseController

const ESTADO_MOVENDO := 0
const ATAQUE_DANCA_CAULES := 2

var boss: Node
var fase_anterior := 1
var dancas_na_fase := 0
var ataques_comuns := 0
var ultimo_ataque_observado := -1


func _ready() -> void:
	boss = get_parent()
	fase_anterior = int(boss.get("fase"))
	_desativar_sorteio_extra()


func _process(_delta: float) -> void:
	if not is_instance_valid(boss) or bool(boss.get("morto")):
		return
	var fase := int(boss.get("fase"))
	if fase != fase_anterior:
		fase_anterior = fase
		dancas_na_fase = 0
		ataques_comuns = 0
		ultimo_ataque_observado = int(boss.get("ultimo_ataque"))
	_desativar_sorteio_extra()
	if fase < 2:
		return
	var ataque_atual := int(boss.get("ultimo_ataque"))
	if ataque_atual != ultimo_ataque_observado:
		ultimo_ataque_observado = ataque_atual
		if ataque_atual != ATAQUE_DANCA_CAULES:
			ataques_comuns += 1
	if (
		dancas_na_fase < 2
		and ataques_comuns >= 2
		and int(boss.get("estado")) == ESTADO_MOVENDO
	):
		dancas_na_fase += 1
		ataques_comuns = 0
		boss.set("ultimo_ataque", ATAQUE_DANCA_CAULES)
		boss.call("iniciar_danca_caules")


func _desativar_sorteio_extra() -> void:
	# O script original só sorteia a dança quando o contador chega a três.
	# Mantê-lo negativo deixa este controlador garantir exatamente duas por fase.
	if int(boss.get("ataques_desde_vinhas")) > -900:
		boss.set("ataques_desde_vinhas", -1000)
