extends RefCounted

## Batida, grau na pauta (zero = mi da primeira linha), duração e articulação.
enum Articulacao { RETA, BEND, VIBRATO }
var batida: float
var entrada: float
var travessia: float
var duracao: float
var janela: Vector2
var notas: Array[Vector4] = []
var graves: Array[float] = []
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
# Graus diatônicos desde ré4, em semitons relativos à amostra de mi4.
const SEMITONS: Array[int] = [-2, 0, 1, 3, 5, 7, 8, 10, 12, 13, 15]


func _init(fase: int) -> void:
	janela = [Vector2(1, 2), Vector2(0.75, 1.5), Vector2(0.5, 1)][fase - 1]
	entrada = janela.y + 0.35
	batida = 60.0 / [112.0, 128.0, 156.0][fase - 1]
	travessia = [1.95, 1.55, 1.15][fase - 1]
	var blocos := fase + 1
	for bloco in blocos:
		var inicio_bloco := bloco * 16.0
		for original in NOTAS:
			if fase == 1 and original.x != floorf(original.x) and bloco == 0:
				continue
			var nota := original
			nota.x += inicio_bloco
			var linha := clampi(roundi(nota.y / 2.0), 0, 4)
			if bloco % 2 == 1:
				linha = 4 - linha
			if bloco >= 2:
				linha = (linha + 1) % 5
			nota.y = linha * 2
			if fase == 1 or (fase == 2 and nota.w == Articulacao.BEND):
				nota.w = Articulacao.RETA
			notas.append(nota)
		if fase == 2:
			graves.append(inicio_bloco + 6.0)
		elif fase == 3:
			for pulso: float in [2.0, 6.0, 9.0, 15.0]:
				graves.append(inicio_bloco + pulso)
	if fase == 3:
		# Resposta final em colcheias seguida de um bend sustentado.
		for i in 4:
			notas.append(Vector4(64.0 + i * 0.5, i * 2, 0.5, Articulacao.RETA))
		notas.append(Vector4(66, 8, 2, Articulacao.BEND))
	var ultima := notas[-1]
	duracao = inicio(ultima.x) + cauda(ultima) + travessia + 0.45


func aviso(nota: Vector4) -> float:
	return lerpf(janela.x, janela.y, fmod(nota.x * 2.0, 5.0) / 4.0)


func inicio(pulso: float) -> float:
	return entrada + pulso * batida


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


func ponto(area: Rect2, nota: Vector4, idade: float, volta: int) -> Vector2:
	var x := lerpf(area.end.x + 18.0, area.position.x - 18.0, idade / travessia)
	return Vector2(x, y_do_grau(area, altura(nota, idade, volta)))


func cauda(nota: Vector4) -> float:
	return nota.z * batida if nota.z >= 1.0 else 0.0


## A cauda percorre o mesmo caminho que a cabeça. Para colisão incluímos o
## deslocamento do último tick, inclusive quando o projétil é uma nota curta.
func trecho(area: Rect2, nota: Vector4, idade: float, volta: int, passo := 0.0) -> PackedVector2Array:
	var pontos := PackedVector2Array()
	var de := maxf(0.0, idade - cauda(nota) - passo)
	var ate := minf(idade, travessia)
	if ate < de:
		return pontos
	var n := maxi(1, ceili((ate - de) / 0.035))
	for i in n + 1:
		pontos.append(ponto(area, nota, lerpf(de, ate, float(i) / n), volta))
	return pontos
