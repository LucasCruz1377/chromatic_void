extends RefCounted
class_name UpgradeData


# Catálogo central dos mods. Para personalizar a tela, altere aqui:
# nome, descrição, ícone, cor, raridade, níveis, peso e requisitos.
const DADOS: Dictionary = {
	&"dano_calibrado": {
		"nome": "DANO CALIBRADO",
		"descricao": "+0,45 de dano base por nível.",
		"icone": "res://Assets/UpgradeDano.png",
		"categoria": "ARMA",
		"raridade": "COMUM",
		"cor": Color(1.0, 0.35, 0.28),
		"max_nivel": 5,
		"peso": 1.2,
		"requisitos": {},
		"tags": [&"arma", &"dano"]
	},
	&"cadencia": {
		"nome": "CÂMARA ACELERADA",
		"descricao": "+10% de cadência por nível.",
		"icone": "res://Assets/UpgradeCadencia.png",
		"categoria": "ARMA",
		"raridade": "COMUM",
		"cor": Color(1.0, 0.72, 0.2),
		"max_nivel": 5,
		"peso": 1.1,
		"requisitos": {},
		"tags": [&"arma", &"cadencia"]
	},
	&"blindagem": {
		"nome": "BLINDAGEM VIVA",
		"descricao": "+12% de vida máxima e recupera a vida adicionada.",
		"icone": "res://Assets/UpgradeVida.png",
		"categoria": "CASCO",
		"raridade": "COMUM",
		"cor": Color(0.35, 1.0, 0.58),
		"max_nivel": 5,
		"peso": 0.9,
		"requisitos": {},
		"tags": [&"casco", &"vida"]
	},
	&"propulsao": {
		"nome": "PROPULSÃO VETORIAL",
		"descricao": "+10% de aceleração e velocidade máxima.",
		"icone": "res://Assets/UpgradeVelocidade.png",
		"categoria": "MOBILIDADE",
		"raridade": "COMUM",
		"cor": Color(0.3, 0.86, 1.0),
		"max_nivel": 5,
		"peso": 0.9,
		"requisitos": {},
		"tags": [&"movimento"]
	},
	&"tiro_duplo": {
		"nome": "TIRO DUPLO",
		"descricao": "Dispara 2 projéteis com pequena abertura. Cada projétil causa 78% do dano.",
		"icone": "res://Assets/UpgradeDano.png",
		"categoria": "PROJÉTIL",
		"raridade": "INCOMUM",
		"cor": Color(1.0, 0.38, 0.7),
		"max_nivel": 1,
		"peso": 1.0,
		"requisitos": {},
		"tags": [&"projetil", &"multitiro"]
	},
	&"tiro_triplo": {
		"nome": "FORMAÇÃO TRIDENTE",
		"descricao": "Transforma o tiro duplo em 3 projéteis e amplia levemente o arco.",
		"icone": "res://Assets/UpgradeDano.png",
		"categoria": "PROJÉTIL",
		"raridade": "RARA",
		"cor": Color(0.82, 0.38, 1.0),
		"max_nivel": 1,
		"peso": 0.72,
		"requisitos": {&"tiro_duplo": 1},
		"tags": [&"projetil", &"multitiro"]
	},
	&"leque_prismatico": {
		"nome": "LEQUE PRISMÁTICO",
		"descricao": "+1 projétil e +8° de dispersão por nível.",
		"icone": "res://Assets/UpgradeDano.png",
		"categoria": "PROJÉTIL",
		"raridade": "RARA",
		"cor": Color(0.65, 0.3, 1.0),
		"max_nivel": 2,
		"peso": 0.6,
		"requisitos": {&"tiro_triplo": 1},
		"tags": [&"projetil", &"multitiro"]
	},
	&"calibre_pesado": {
		"nome": "CALIBRE PESADO",
		"descricao": "+24% de dano e +18% de tamanho, mas -8% de velocidade do projétil.",
		"icone": "res://Assets/UpgradeDano.png",
		"categoria": "PROJÉTIL",
		"raridade": "INCOMUM",
		"cor": Color(1.0, 0.5, 0.22),
		"max_nivel": 3,
		"peso": 0.9,
		"requisitos": {},
		"tags": [&"projetil", &"dano", &"pesado"]
	},
	&"perfuracao": {
		"nome": "PONTA PERFURANTE",
		"descricao": "O projétil atravessa +1 inimigo por nível.",
		"icone": "res://Assets/UpgradeDano.png",
		"categoria": "PROJÉTIL",
		"raridade": "INCOMUM",
		"cor": Color(1.0, 0.64, 0.2),
		"max_nivel": 3,
		"peso": 0.72,
		"requisitos": {&"calibre_pesado": 1},
		"tags": [&"projetil", &"pesado"]
	},
	&"fragmentacao": {
		"nome": "FRAGMENTAÇÃO",
		"descricao": "Ao atingir um inimigo, gera +2 estilhaços por nível.",
		"icone": "res://Assets/UpgradeDano.png",
		"categoria": "PROJÉTIL",
		"raridade": "RARA",
		"cor": Color(1.0, 0.24, 0.45),
		"max_nivel": 2,
		"peso": 0.48,
		"requisitos": {&"perfuracao": 1, &"tiro_duplo": 1},
		"tags": [&"projetil", &"multitiro", &"pesado"]
	},
	&"mira_gravitacional": {
		"nome": "MIRA GRAVITACIONAL",
		"descricao": "Projéteis corrigem a trajetória em direção ao inimigo mais próximo.",
		"icone": "res://Assets/UpgradeAgilidade.png",
		"categoria": "PROJÉTIL",
		"raridade": "RARA",
		"cor": Color(0.42, 0.72, 1.0),
		"max_nivel": 3,
		"peso": 0.62,
		"requisitos": {&"propulsao": 1},
		"tags": [&"projetil", &"movimento", &"homing"]
	},
	&"ricochete": {
		"nome": "RICOCHETE DE BORDA",
		"descricao": "Projéteis rebatem nas bordas da arena +1 vez por nível.",
		"icone": "res://Assets/UpgradeAgilidade.png",
		"categoria": "PROJÉTIL",
		"raridade": "INCOMUM",
		"cor": Color(0.28, 1.0, 0.92),
		"max_nivel": 2,
		"peso": 0.68,
		"requisitos": {&"propulsao": 1},
		"tags": [&"projetil", &"movimento"]
	},
	&"fluxo_habilidade": {
		"nome": "FLUXO DA HABILIDADE",
		"descricao": "A habilidade equipada recarrega 10% mais rápido por nível.",
		"icone": "res://Assets/UpgradeCadencia.png",
		"categoria": "HABILIDADE",
		"raridade": "COMUM",
		"cor": Color(0.35, 0.72, 1.0),
		"max_nivel": 4,
		"peso": 1.0,
		"requisitos": {},
		"tags": [&"habilidade", &"cooldown"]
	},
	&"overdrive_habilidade": {
		"nome": "RESSONÂNCIA ARMADA",
		"descricao": "Usar a habilidade sobrecarrega a arma: +25% de dano e cadência temporariamente.",
		"icone": "res://Assets/UpgradeCadencia.png",
		"categoria": "HABILIDADE + ARMA",
		"raridade": "RARA",
		"cor": Color(0.25, 0.82, 1.0),
		"max_nivel": 3,
		"peso": 0.7,
		"requisitos": {&"fluxo_habilidade": 1},
		"tags": [&"habilidade", &"arma", &"sinergia"]
	},
	&"conversor_impacto": {
		"nome": "CONVERSOR DE IMPACTO",
		"descricao": "Cada acerto reduz a recarga atual da habilidade em 0,06 s.",
		"icone": "res://Assets/UpgradeCadencia.png",
		"categoria": "HABILIDADE + PROJÉTIL",
		"raridade": "INCOMUM",
		"cor": Color(0.24, 0.92, 1.0),
		"max_nivel": 3,
		"peso": 0.78,
		"requisitos": {&"fluxo_habilidade": 1},
		"tags": [&"habilidade", &"projetil", &"sinergia"]
	},
	&"nova_ativacao": {
		"nome": "NOVA DE ATIVAÇÃO",
		"descricao": "Ao usar a habilidade, dispara uma explosão circular de projéteis.",
		"icone": "res://Assets/UpgradeDano.png",
		"categoria": "SUPERMOD",
		"raridade": "SUPERMOD",
		"cor": Color(0.95, 0.38, 1.0),
		"max_nivel": 2,
		"peso": 0.34,
		"requisitos": {&"fluxo_habilidade": 2, &"tiro_duplo": 1},
		"tags": [&"habilidade", &"projetil", &"sinergia"]
	},
	&"escudo_fase": {
		"nome": "ESCUDO DE FASE",
		"descricao": "Usar a habilidade concede 0,35 s de invulnerabilidade por nível.",
		"icone": "res://Assets/UpgradeVida.png",
		"categoria": "HABILIDADE + CASCO",
		"raridade": "RARA",
		"cor": Color(0.35, 1.0, 0.8),
		"max_nivel": 2,
		"peso": 0.58,
		"requisitos": {&"fluxo_habilidade": 1, &"blindagem": 1},
		"tags": [&"habilidade", &"casco", &"sinergia"]
	},
	&"tempestade_prismatica": {
		"nome": "TEMPESTADE PRISMÁTICA",
		"descricao": "SUPERMOD: +2 projéteis, arco maior e +15% de cadência.",
		"icone": "res://Assets/UpgradeDano.png",
		"categoria": "SUPERMOD",
		"raridade": "SUPERMOD",
		"cor": Color(1.0, 0.25, 0.82),
		"max_nivel": 1,
		"peso": 0.28,
		"requisitos": {&"leque_prismatico": 1, &"cadencia": 3},
		"tags": [&"projetil", &"multitiro", &"cadencia"]
	},
	&"singularidade": {
		"nome": "SINGULARIDADE GUIADA",
		"descricao": "SUPERMOD: projéteis enormes, perfurantes e fortemente teleguiados.",
		"icone": "res://Assets/UpgradeDano.png",
		"categoria": "SUPERMOD",
		"raridade": "SUPERMOD",
		"cor": Color(0.45, 0.35, 1.0),
		"max_nivel": 1,
		"peso": 0.25,
		"requisitos": {&"calibre_pesado": 2, &"mira_gravitacional": 2},
		"tags": [&"projetil", &"pesado", &"homing"]
	},
	&"reator_sincronizado": {
		"nome": "REATOR SINCRONIZADO",
		"descricao": "SUPERMOD: a Nova dispara mais projéteis e o overdrive dura o dobro.",
		"icone": "res://Assets/UpgradeCadencia.png",
		"categoria": "SUPERMOD",
		"raridade": "SUPERMOD",
		"cor": Color(0.25, 0.95, 1.0),
		"max_nivel": 1,
		"peso": 0.22,
		"requisitos": {&"overdrive_habilidade": 2, &"nova_ativacao": 1},
		"tags": [&"habilidade", &"projetil", &"sinergia"]
	}
}


static func obter(id: StringName) -> Dictionary:
	var dados: Dictionary = DADOS.get(id, {})
	return dados


static func nivel(id: StringName, niveis: Dictionary) -> int:
	return int(niveis.get(id, 0))


static func requisitos_cumpridos(id: StringName, niveis: Dictionary) -> bool:
	var dados := obter(id)
	var requisitos: Dictionary = dados.get("requisitos", {})
	for requisito in requisitos:
		if nivel(requisito, niveis) < int(requisitos[requisito]):
			return false
	return true


static func disponivel(id: StringName, niveis: Dictionary) -> bool:
	var dados := obter(id)
	if dados.is_empty():
		return false
	return (
		nivel(id, niveis) < int(dados.get("max_nivel", 1))
		and requisitos_cumpridos(id, niveis)
	)


static func texto_requisitos(id: StringName, niveis: Dictionary) -> String:
	var requisitos: Dictionary = obter(id).get("requisitos", {})
	if requisitos.is_empty():
		return "SEM PRÉ-REQUISITOS"

	var partes: Array[String] = []
	for requisito in requisitos:
		var nome := str(obter(requisito).get("nome", requisito))
		partes.append("%s %d/%d" % [
			nome,
			nivel(requisito, niveis),
			int(requisitos[requisito])
		])
	return "REQUER: " + "  •  ".join(partes)


static func sortear(niveis: Dictionary, quantidade := 3) -> Array[StringName]:
	var candidatos: Array[StringName] = []
	for id in DADOS:
		if disponivel(id, niveis):
			candidatos.append(id)

	var resultado: Array[StringName] = []
	_adicionar_de_categoria(resultado, candidatos, niveis, &"projetil")
	_adicionar_de_categoria(resultado, candidatos, niveis, &"habilidade")

	while resultado.size() < quantidade and not candidatos.is_empty():
		var escolhido := _sortear_ponderado(candidatos, niveis)
		resultado.append(escolhido)
		candidatos.erase(escolhido)

	resultado.shuffle()
	return resultado


static func _adicionar_de_categoria(
	resultado: Array[StringName],
	candidatos: Array[StringName],
	niveis: Dictionary,
	tag: StringName
) -> void:
	var filtrados: Array[StringName] = []
	for id in candidatos:
		var tags: Array = obter(id).get("tags", [])
		if tag in tags:
			filtrados.append(id)

	if filtrados.is_empty():
		return

	var escolhido := _sortear_ponderado(filtrados, niveis)
	resultado.append(escolhido)
	candidatos.erase(escolhido)


static func _sortear_ponderado(
	candidatos: Array[StringName],
	niveis: Dictionary
) -> StringName:
	var peso_total := 0.0
	for id in candidatos:
		peso_total += _peso_com_sinergia(id, niveis)

	var alvo := randf() * maxf(peso_total, 0.01)
	var acumulado := 0.0
	for id in candidatos:
		acumulado += _peso_com_sinergia(id, niveis)
		if alvo <= acumulado:
			return id

	return candidatos.back()


static func _peso_com_sinergia(id: StringName, niveis: Dictionary) -> float:
	var dados := obter(id)
	var peso := float(dados.get("peso", 1.0))
	var tags: Array = dados.get("tags", [])

	for adquirido in niveis:
		var nivel_adquirido := int(niveis[adquirido])
		if nivel_adquirido <= 0:
			continue
		var tags_adquiridas: Array = obter(adquirido).get("tags", [])
		for tag in tags:
			if tag in tags_adquiridas:
				peso += 0.16 * nivel_adquirido

	return maxf(peso, 0.05)
