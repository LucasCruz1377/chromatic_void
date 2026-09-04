extends Habilidade
class_name HabilidadeMonthly


@export var efeito_id: StringName = &""
@export var cor_efeito: Color = Color.WHITE
@export_range(0.2, 3.0, 0.05) var potencia: float = 1.0


func executar(player) -> void:
	if is_instance_valid(player) and player.has_method("aplicar_poder_monthly"):
		player.call("aplicar_poder_monthly", efeito_id, cor_efeito, potencia)
