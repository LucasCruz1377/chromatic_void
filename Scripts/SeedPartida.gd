extends RefCounted
class_name SeedPartida

# Seeds numericas reproduziveis, independentes do RNG global usado por FX.
# Dominio separa sorteios (spawns, asteroides, melhorias e futuros eventos).
const LIMITE := 999999999
const MODULO := 2147483647


static func gerar() -> int:
	var fonte := RandomNumberGenerator.new()
	fonte.randomize()
	return fonte.randi_range(1, LIMITE)


static func validar(valor: int) -> int:
	return clampi(valor, 1, LIMITE)


static func derivar(base: int, dominio: int, indice: int = 0, jogador: int = 0) -> int:
	var resultado := int(base) % MODULO
	for valor in [dominio, indice, jogador]:
		resultado = posmod(resultado * 48271 + posmod(int(valor), MODULO), MODULO)
	return maxi(resultado, 1)


static func criar_rng(base: int, dominio: int, indice: int = 0, jogador: int = 0) -> RandomNumberGenerator:
	var fonte := RandomNumberGenerator.new()
	fonte.seed = derivar(base, dominio, indice, jogador)
	return fonte
