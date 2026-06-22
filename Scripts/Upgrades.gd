extends RefCounted
class_name Upgrades

enum Tipo{
	CADENCIA,
	VIDA,
	DANO,
	VELOCIDADE,
	AGILIDADE
}

static var DADOS = {
	Tipo.CADENCIA: {
		"nome" : "Cadencia do Tiro",
		"descrição" : "sua arma é melhorada e você atirara mais rápido \n -0,01 pontos de cadência"
	},
	
	Tipo.VIDA: {
		"nome" : "Blindagem",
		"descrição" : "A sua nave é consertada e a blindagem é trocada por uma melhor \n +10% de vida máxima"
	},
	
	Tipo.DANO: {
		"nome" : "Melhoria de dano",
		"descrição" : "sua arma é melhorada e você causa mais dano \n +1 de Dano"
	},

	Tipo.VELOCIDADE: {
		"nome" : " Melhoria dos motores",
		"descrição" : "sua velocidade passa a ser maior \n +10% de velocidade máxima"
	},
	Tipo.AGILIDADE: {
		"nome" : " Melhoria dos flaps",
		"descrição" : "Sua nave se torna mais ágil e aerodinamica \n +10% velocidade de virada"
	},
}
