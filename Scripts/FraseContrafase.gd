extends RefCounted

## Batida, grau na pauta (zero = mi da primeira linha), duração e articulação.
enum Articulacao { RETA, BEND, VIBRATO }
const BATIDA := 60.0 / 120.0
const ENTRADA := 1.3
const AVISO := 0.68
const TRAVESSIA := 1.55
const DURACAO := ENTRADA + 16.0 * BATIDA + TRAVESSIA + 0.45
const RAIO_NAVE := 13.5
const NOTAS: Array[Vector4] = [
	Vector4(0, 0, 0.5, Articulacao.RETA), Vector4(0.5, 0, 0.5, Articulacao.RETA),
	Vector4(1, 4, 1, Articulacao.RETA), Vector4(2, 1, 0.5, Articulacao.RETA),
	Vector4(2.5, 3, 0.5, Articulacao.RETA), Vector4(3, 5, 1, Articulacao.BEND),
	Vector4(4, 7, 0.5, Articulacao.RETA), Vector4(4.5, 6, 0.5, Articulacao.RETA),
	Vector4(5, 4, 1, Articulacao.VIBRATO), Vector4(6.5, -1, 0.5, Articulacao.RETA),
	Vector4(7, 0, 1, Articulacao.RETA), Vector4(8, 9, 0.5, Articulacao.RETA),
	Vector4(8.5, 7, 0.5, Articulacao.RETA), Vector4(9, 6, 1, Articulacao.BEND),
	Vector4(10, 3, 0.5, Articulacao.RETA), Vector4(10.5, 1, 0.5, Articulacao.RETA),
	Vector4(11, 0, 1.5, Articulacao.VIBRATO), Vector4(13, 8, 0.5, Articulacao.RETA),
	Vector4(13.5, 6, 0.5, Articulacao.RETA), Vector4(14, 2, 2, Articulacao.BEND),
]
const GRAVES: Array[float] = [2.0, 6.0, 12.5, 15.0]
# Graus diatônicos desde ré4, em semitons relativos à amostra de mi4.
const SEMITONS: Array[int] = [-2, 0, 1, 3, 5, 7, 8, 10, 12, 13, 15]


static func inicio(batida: float) -> float:
	return ENTRADA + batida * BATIDA


static func grau_base(nota: Vector4, volta: int) -> float:
	return nota.y if volta % 2 == 1 else 8.0 - nota.y


static func altura(nota: Vector4, idade: float, volta: int) -> float:
	var grau := grau_base(nota, volta)
	match int(nota.w):
		Articulacao.BEND:
			return grau + (2.0 if grau <= 7.0 else -2.0) * smoothstep(0.07, 0.45, idade)
		Articulacao.VIBRATO:
			return grau + sin(idade * TAU / 0.54) * smoothstep(0.0, 0.10, idade) * 0.95
	return grau


static func pitch(grau: float) -> float:
	var indice := clampf(grau + 1.0, 0.0, SEMITONS.size() - 1.0)
	var inteiro := floori(indice)
	var tom := lerpf(SEMITONS[inteiro], SEMITONS[mini(inteiro + 1, SEMITONS.size() - 1)], indice - inteiro)
	return pow(2.0, tom / 12.0)


static func fundo_caixa(area: Rect2) -> float:
	return clampf(area.size.y * 0.095, 32.0, 72.0)


static func y_do_grau(area: Rect2, grau: float) -> float:
	var margem := fundo_caixa(area) + RAIO_NAVE + 8.0
	return area.get_center().y + (4.0 - grau) * (area.size.y - 2.0 * margem) / 10.0


static func ponto(area: Rect2, nota: Vector4, idade: float, volta: int) -> Vector2:
	var x := lerpf(area.end.x + 18.0, area.position.x - 18.0, idade / TRAVESSIA)
	return Vector2(x, y_do_grau(area, altura(nota, idade, volta)))


static func cauda(nota: Vector4) -> float:
	return nota.z * BATIDA if nota.z >= 1.0 else 0.0


## A cauda percorre o mesmo caminho que a cabeça. Para colisão incluímos o
## deslocamento do último tick, inclusive quando o projétil é uma nota curta.
static func trecho(area: Rect2, nota: Vector4, idade: float, volta: int, passo := 0.0) -> PackedVector2Array:
	var pontos := PackedVector2Array()
	var de := maxf(0.0, idade - cauda(nota) - passo)
	var ate := minf(idade, TRAVESSIA)
	if ate < de:
		return pontos
	var n := maxi(1, ceili((ate - de) / 0.035))
	for i in n + 1:
		pontos.append(ponto(area, nota, lerpf(de, ate, float(i) / n), volta))
	return pontos
