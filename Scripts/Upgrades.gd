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
		"nome" : "UPG_N_FR",
		"descrição" : "UPG_D_FR"
	},
	
	Tipo.VIDA: {
		"nome" : "UPG_N_HP",
		"descrição" : "UPG_D_HP"
	},
	
	Tipo.DANO: {
		"nome" : "UPG_N_DMG",
		"descrição" : "UPG_D_DMG"
	},

	Tipo.VELOCIDADE: {
		"nome" : "UPG_N_SPD",
		"descrição" : "UPG_D_SPD"
	},
	Tipo.AGILIDADE: {
		"nome" : "UPG_N_AGL",
		"descrição" : "UPG_D_AGL"
	}
}
