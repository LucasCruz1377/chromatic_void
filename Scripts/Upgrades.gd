extends RefCounted
class_name Upgrades

enum Tipo{
	CADENCIA,
	VIDA,
	DANO,
	VELOCIDADE
}

static var DADOS = {
	Tipo.CADENCIA: {
		"nome" : "Cadencia do Tiro",
		"descrição" : "sua arma é melhorada e você atirara mais rápido"
	},
	
	Tipo.VIDA: {
		"nome" : "Blindagem",
		"descrição" : "sua vida é aumentada em 10%"
	},
	
	Tipo.DANO: {
		"nome" : "Melhoria de dano",
		"descrição" : "sua arma é melhorada e você causa mais dano"
	},

	Tipo.VELOCIDADE: {
		"nome" : " Melhoria dos motores",
		"descrição" : "sua velocidade passa a ser maior"
	},
}
