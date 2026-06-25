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
		"descrição" : "UPG_D_FR",
		"icone": "res://Assets/UpgradeCadencia.png"
	},
	
	Tipo.VIDA: {
		"nome" : "UPG_N_HP",
		"descrição" : "UPG_D_HP",
		"icone": "res://Assets/UpgradeVida.png"
	},
	
	Tipo.DANO: {
		"nome" : "UPG_N_DMG",
		"descrição" : "UPG_D_DMG",
		"icone": "res://Assets/UpgradeDano.png"
	},

	Tipo.VELOCIDADE: {
		"nome" : "UPG_N_SPD",
		"descrição" : "UPG_D_SPD",
		"icone": "res://Assets/UpgradeVelocidade.png"
	},
	Tipo.AGILIDADE: {
		"nome" : "UPG_N_AGL",
		"descrição" : "UPG_D_AGL",
		"icone": "res://Assets/UpgradeAgilidade.png"
	}
}
