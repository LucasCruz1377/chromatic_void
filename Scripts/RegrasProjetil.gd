extends RefCounted
## Regras puras de geometria e dano de projeteis; sem acesso a cena ou rede.

static func padrao_multitiro(indice: int, quantidade: int, dispersao_graus: float, convergente: bool) -> Vector2:
	if quantidade <= 1:
		return Vector2.ZERO
	var centro := float(indice) - float(quantidade - 1) * 0.5
	var separacao_lateral := 14.0 if quantidade == 2 else 9.0
	var lateral := centro * separacao_lateral
	var angular := 0.0
	if quantidade == 3:
		angular = deg_to_rad(centro * 7.0)
	elif quantidade >= 4:
		angular = lerpf(-deg_to_rad(dispersao_graus) * 0.5, deg_to_rad(dispersao_graus) * 0.5, float(indice) / float(quantidade - 1))
	if convergente:
		angular = atan2(-lateral, 300.0)
	return Vector2(angular, lateral)


static func multiplicar_dano(base: float, fatores: Array[float]) -> float:
	var resultado := base
	for fator in fatores:
		resultado *= fator
	return resultado
