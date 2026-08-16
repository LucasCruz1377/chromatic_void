extends RefCounted
class_name SkillTreeData


const ID_DANO: StringName = &"dano_calibrado"
const ID_CADENCIA: StringName = &"cadencia_estavel"
const ID_SOBRECARGA: StringName = &"sobrecarga_cromatica"
const ID_PROPULSAO: StringName = &"propulsao_vetorial"
const ID_GIROSCOPIO: StringName = &"giroscopio_quantico"
const ID_IMPACTO: StringName = &"impacto_cinetico"
const ID_BLINDAGEM: StringName = &"blindagem_reforcada"
const ID_RESILIENCIA: StringName = &"revestimento_adaptativo"
const ID_ESCUDO: StringName = &"escudo_adaptativo"
const ID_FLUXO: StringName = &"fluxo_temporal"
const ID_RECICLAGEM: StringName = &"reciclagem_vital"
const ID_SIMBIOSE: StringName = &"simbiose_energetica"
const ID_PRISMA: StringName = &"nucleo_prismatico"


# As posições representam o centro de cada botão dentro da tela 960 x 540.
# Você pode trocar nomes, descrições, ícones, posições, níveis e requisitos aqui.
const DADOS: Dictionary = {
	ID_DANO: {
		"nome": "DANO CALIBRADO",
		"descricao": "+0,4 de dano por nível.",
		"icone": "res://Assets/UpgradeDano.png",
		"posicao": Vector2(105, 105),
		"max_nivel": 3,
		"requisitos": {}
	},
	ID_CADENCIA: {
		"nome": "CADÊNCIA ESTÁVEL",
		"descricao": "Tiros e habilidade recarregam 10% mais rápido por nível.",
		"icone": "res://Assets/UpgradeCadencia.png",
		"posicao": Vector2(320, 105),
		"max_nivel": 3,
		"requisitos": {ID_DANO: 1}
	},
	ID_SOBRECARGA: {
		"nome": "SOBRECARGA CROMÁTICA",
		"descricao": "SINERGIA: +35% de dano e +15% de cadência, mas -10% de vida máxima.",
		"icone": "res://Assets/UpgradeDano.png",
		"posicao": Vector2(545, 105),
		"max_nivel": 1,
		"requisitos": {ID_DANO: 2, ID_CADENCIA: 2}
	},
	ID_PROPULSAO: {
		"nome": "PROPULSÃO VETORIAL",
		"descricao": "+10% de aceleração e velocidade máxima por nível.",
		"icone": "res://Assets/UpgradeVelocidade.png",
		"posicao": Vector2(105, 205),
		"max_nivel": 3,
		"requisitos": {}
	},
	ID_GIROSCOPIO: {
		"nome": "GIROSCÓPIO QUÂNTICO",
		"descricao": "+12% de agilidade para virar por nível.",
		"icone": "res://Assets/UpgradeAgilidade.png",
		"posicao": Vector2(320, 205),
		"max_nivel": 3,
		"requisitos": {ID_PROPULSAO: 1}
	},
	ID_IMPACTO: {
		"nome": "IMPACTO CINÉTICO",
		"descricao": "SINERGIA: seu dano aumenta em até 50% conforme a velocidade da nave.",
		"icone": "res://Assets/UpgradeVelocidade.png",
		"posicao": Vector2(545, 205),
		"max_nivel": 1,
		"requisitos": {ID_PROPULSAO: 2, ID_DANO: 1}
	},
	ID_BLINDAGEM: {
		"nome": "BLINDAGEM REFORÇADA",
		"descricao": "+12% de vida máxima e cura imediata por nível.",
		"icone": "res://Assets/UpgradeVida.png",
		"posicao": Vector2(105, 305),
		"max_nivel": 3,
		"requisitos": {}
	},
	ID_RESILIENCIA: {
		"nome": "REVESTIMENTO ADAPTATIVO",
		"descricao": "Reduz o dano recebido em 7% por nível.",
		"icone": "res://Assets/UpgradeVida.png",
		"posicao": Vector2(320, 305),
		"max_nivel": 3,
		"requisitos": {ID_BLINDAGEM: 1}
	},
	ID_ESCUDO: {
		"nome": "ESCUDO ADAPTATIVO",
		"descricao": "SINERGIA: -15% de dano recebido e +0,35 s de invencibilidade após ser atingido.",
		"icone": "res://Assets/UpgradeVida.png",
		"posicao": Vector2(545, 305),
		"max_nivel": 1,
		"requisitos": {ID_RESILIENCIA: 2, ID_GIROSCOPIO: 1}
	},
	ID_FLUXO: {
		"nome": "FLUXO TEMPORAL",
		"descricao": "A habilidade equipada recarrega 10% mais rápido por nível.",
		"icone": "res://Assets/UpgradeCadencia.png",
		"posicao": Vector2(105, 405),
		"max_nivel": 3,
		"requisitos": {}
	},
	ID_RECICLAGEM: {
		"nome": "RECICLAGEM VITAL",
		"descricao": "Recupera 4% da vida máxima ao subir de nível, por nível deste upgrade.",
		"icone": "res://Assets/UpgradeVida.png",
		"posicao": Vector2(320, 405),
		"max_nivel": 3,
		"requisitos": {ID_FLUXO: 1}
	},
	ID_SIMBIOSE: {
		"nome": "SIMBIOSE ENERGÉTICA",
		"descricao": "SINERGIA: ativar sua habilidade cura 3% da vida máxima.",
		"icone": "res://Assets/UpgradeCadencia.png",
		"posicao": Vector2(545, 405),
		"max_nivel": 1,
		"requisitos": {ID_RECICLAGEM: 2, ID_BLINDAGEM: 1}
	},
	ID_PRISMA: {
		"nome": "NÚCLEO PRISMÁTICO",
		"descricao": "SUPERMOD: +20% de dano, +10% de velocidade e +15% de vida máxima.",
		"icone": "res://Assets/UpgradeDano.png",
		"posicao": Vector2(805, 255),
		"max_nivel": 1,
		"requisitos": {
			ID_SOBRECARGA: 1,
			ID_IMPACTO: 1,
			ID_ESCUDO: 1,
			ID_SIMBIOSE: 1
		}
	}
}


const ORDEM: Array[StringName] = [
	ID_DANO,
	ID_CADENCIA,
	ID_SOBRECARGA,
	ID_PROPULSAO,
	ID_GIROSCOPIO,
	ID_IMPACTO,
	ID_BLINDAGEM,
	ID_RESILIENCIA,
	ID_ESCUDO,
	ID_FLUXO,
	ID_RECICLAGEM,
	ID_SIMBIOSE,
	ID_PRISMA
]


static func obter_dados(id: StringName) -> Dictionary:
	return DADOS.get(id, {})


static func obter_nivel(id: StringName, niveis: Dictionary) -> int:
	return int(niveis.get(id, 0))


static func requisitos_cumpridos(id: StringName, niveis: Dictionary) -> bool:
	var dados := obter_dados(id)
	if dados.is_empty():
		return false

	var requisitos: Dictionary = dados.get("requisitos", {})
	for requisito in requisitos:
		if obter_nivel(requisito, niveis) < int(requisitos[requisito]):
			return false
	return true


static func pode_comprar(id: StringName, niveis: Dictionary) -> bool:
	var dados := obter_dados(id)
	if dados.is_empty():
		return false

	var nivel := obter_nivel(id, niveis)
	var max_nivel := int(dados.get("max_nivel", 1))
	return nivel < max_nivel and requisitos_cumpridos(id, niveis)


static func texto_requisitos(id: StringName, niveis: Dictionary) -> String:
	var dados := obter_dados(id)
	var requisitos: Dictionary = dados.get("requisitos", {})
	if requisitos.is_empty():
		return "Disponível desde o início."

	var partes: Array[String] = []
	for requisito in requisitos:
		var dados_requisito := obter_dados(requisito)
		var nome := str(dados_requisito.get("nome", requisito))
		var necessario := int(requisitos[requisito])
		var atual := obter_nivel(requisito, niveis)
		partes.append("%s %d/%d" % [nome, atual, necessario])
	return "Requer: " + ", ".join(partes)
