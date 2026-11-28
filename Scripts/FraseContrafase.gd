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
const PASSAGEM := Vector2(5.8, 7.1)
const RAIO_NAVE := 13.5
# Degraus da melodia: sobe em pares, segura o topo e volta pelo outro lado.
const LINHAS := [0, 0, 1, 1, 2, 2, 3, 4, 4, 3, 3, 2, 2, 1, 1, 0]
# Graus diatônicos desde ré4, em semitons relativos à amostra de mi4.
const SEMITONS: Array[int] = [-2, 0, 1, 3, 5, 7, 8, 10, 12, 13, 15]


func _init(fase: int) -> void:
	janela = [Vector2(1, 2), Vector2(0.75, 1.5), Vector2(0.5, 1)][fase - 1]
	entrada = janela.y + 0.35
	duracao = 12.0
	travessia = [1.35, 1.10, 0.86][fase - 1]
	var passos: int = [28, 36, 44][fase - 1]
	# Reserva a travessia da última nota e a animação de retorno no mesmo relógio.
	batida = (duracao - entrada - travessia - 0.45) / (0.5 * (passos - 1))
	var i := 0
	while i < passos:
		var grau := float(LINHAS[i % LINHAS.size()] * 2)
		var articulacao := Articulacao.RETA
		if fase == 3 and i % 16 == 5:
			articulacao = Articulacao.BEND
		elif fase >= 2 and i % 8 == 2:
			articulacao = Articulacao.VIBRATO
		var sustentada := articulacao == Articulacao.BEND
		var nota := Vector4(i * 0.5, grau, 1.0 if sustentada else 0.5, articulacao)
		var chegada := inicio(nota.x)
		if chegada >= PASSAGEM.y or chegada + travessia + cauda(nota) <= PASSAGEM.x:
			if i % 8 == 0:
				# Acordes retos ocupam apenas um lado. A outra metade recebe a resposta.
				var lado := 0 if (i / 8) % 2 == 0 else 8
				var sentido := 1 if lado == 0 else -1
				var vozes := 3 if fase >= 2 and i % 16 == 8 else 2
				for j in vozes:
					notas.append(Vector4(nota.x, lado + sentido * j * 2, 0.5, Articulacao.RETA))
			else:
				notas.append(nota)
		i += 2 if sustentada else 1
	if fase == 2:
		graves = [5.0, 13.0]
	elif fase == 3:
		graves = [2.0, 5.0, 8.0, 15.0, 17.0, 20.0]


static func escala_nota(area: Rect2) -> float:
	var distancia := y_do_grau(area, 0) - y_do_grau(area, 2)
	return clampf(distancia / 33.0, 1.35, 4.0)


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
	var margem := 18.0 * escala_nota(area)
	var x := lerpf(area.end.x + margem, area.position.x - margem, idade / travessia)
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
