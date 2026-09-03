extends RefCounted
class_name UpgradeData


# Chance de uma rodada oferecer exatamente uma carta da habilidade equipada.
# Mantém as cartas específicas presentes sem dominar todas as ofertas.
const CHANCE_UPGRADE_HABILIDADE_ESPECIFICA := 0.42

const TIPO_BASICA: StringName = &"basica"
const TIPO_ESTRUTURAL: StringName = &"estrutural"
const TIPO_SINERGIA: StringName = &"sinergia"
const TIPO_SUPERMOD: StringName = &"supermod"

const SLOT_ESTILO_TIRO: StringName = &"estilo_tiro"
const SLOT_SUPERMOD: StringName = &"supermod"


# Catálogo central dos mods. Para personalizar a tela, altere aqui:
# nome, descrição, ícone, cor, raridade, níveis, peso e requisitos.
const DADOS: Dictionary = {
	&"dano_calibrado": {
		"nome": "DANO CALIBRADO",
		"descricao": "Aumenta o dano em +25%, +18%, +14%, +10% e +8%. Forte cedo, controlado depois.",
		"icone": "res://Assets/UpgradeDano.png",
		"categoria": "ARMA",
		"raridade": "COMUM",
		"cor": Color(1.0, 0.35, 0.28),
		"max_nivel": 5,
		"peso": 1.2,
		"tipo": TIPO_BASICA,
		"requisitos": {},
		"tags": [&"arma", &"dano"]
	},
	&"cadencia": {
		"nome": "CÂMARA ACELERADA",
		"descricao": "Aumenta muito a cadência nos primeiros níveis, com retornos decrescentes.",
		"icone": "res://Assets/UpgradeCadencia.png",
		"categoria": "ARMA",
		"raridade": "COMUM",
		"cor": Color(1.0, 0.72, 0.2),
		"max_nivel": 5,
		"peso": 1.1,
		"tipo": TIPO_BASICA,
		"requisitos": {},
		"tags": [&"arma", &"cadencia"]
	},
	&"blindagem": {
		"nome": "BLINDAGEM VIVA",
		"descricao": "Aumenta bastante a vida máxima e recupera somente a vida adicionada.",
		"icone": "res://Assets/UpgradeVida.png",
		"categoria": "CASCO",
		"raridade": "COMUM",
		"cor": Color(0.35, 1.0, 0.58),
		"max_nivel": 5,
		"peso": 0.9,
		"tipo": TIPO_BASICA,
		"requisitos": {},
		"tags": [&"casco", &"vida"]
	},
	&"propulsao": {
		"nome": "PROPULSÃO VETORIAL",
		"descricao": "Aumenta aceleração e velocidade; o primeiro nível concede +15%.",
		"icone": "res://Assets/UpgradeVelocidade.png",
		"categoria": "MOBILIDADE",
		"raridade": "COMUM",
		"cor": Color(0.3, 0.86, 1.0),
		"max_nivel": 5,
		"peso": 0.9,
		"tipo": TIPO_BASICA,
		"requisitos": {},
		"tags": [&"movimento"]
	},
	&"tiro_duplo": {
		"nome": "NÚCLEO PRISMÁTICO",
		"descricao": "ESTILO PRISMA: duas linhas paralelas, cada uma com 62% do dano. Bloqueia os outros estilos de tiro.",
		"icone": "res://Assets/UpgradeDano.png",
		"categoria": "ESTILO DE TIRO • PRISMA",
		"raridade": "INCOMUM",
		"cor": Color(1.0, 0.38, 0.7),
		"max_nivel": 1,
		"peso": 1.0,
		"tipo": TIPO_ESTRUTURAL,
		"slot_estrutural": SLOT_ESTILO_TIRO,
		"rota_estrutural": &"multitiro",
		"requisitos": {},
		"tags": [&"projetil", &"multitiro"]
	},
	&"tiro_triplo": {
		"nome": "FORMAÇÃO TRIDENTE",
		"descricao": "PRISMA II: um tiro central e dois laterais a 7°. Cada projétil causa 42% do dano.",
		"icone": "res://Assets/UpgradeDano.png",
		"categoria": "ESTILO PRISMA • EVOLUÇÃO",
		"raridade": "RARA",
		"cor": Color(0.82, 0.38, 1.0),
		"max_nivel": 1,
		"peso": 0.72,
		"tipo": TIPO_ESTRUTURAL,
		"slot_estrutural": SLOT_ESTILO_TIRO,
		"rota_estrutural": &"multitiro",
		"requisitos": {&"tiro_duplo": 1},
		"tags": [&"projetil", &"multitiro"]
	},
	&"leque_prismatico": {
		"nome": "LEQUE PRISMÁTICO",
		"descricao": "+1 projétil e +8° de cobertura; o dano total permanece próximo de 125%.",
		"icone": "res://Assets/UpgradeDano.png",
		"categoria": "ESTILO PRISMA • EVOLUÇÃO",
		"raridade": "RARA",
		"cor": Color(0.65, 0.3, 1.0),
		"max_nivel": 2,
		"peso": 0.6,
		"tipo": TIPO_ESTRUTURAL,
		"slot_estrutural": SLOT_ESTILO_TIRO,
		"rota_estrutural": &"multitiro",
		"requisitos": {&"tiro_triplo": 1},
		"tags": [&"projetil", &"multitiro"]
	},
	&"calibre_pesado": {
		"nome": "NÚCLEO DE IMPACTO",
		"descricao": "ESTILO IMPACTO: projétil maior e muito mais forte, mas 10% mais lento por nível. Bloqueia os outros estilos.",
		"icone": "res://Assets/UpgradeDano.png",
		"categoria": "ESTILO DE TIRO • IMPACTO",
		"raridade": "INCOMUM",
		"cor": Color(1.0, 0.5, 0.22),
		"max_nivel": 3,
		"peso": 0.9,
		"tipo": TIPO_ESTRUTURAL,
		"slot_estrutural": SLOT_ESTILO_TIRO,
		"rota_estrutural": &"impacto_pesado",
		"requisitos": {},
		"tags": [&"projetil", &"dano", &"pesado"]
	},
	&"perfuracao": {
		"nome": "PONTA PERFURANTE",
		"descricao": "IMPACTO II: o projétil pesado atravessa +1 inimigo por nível.",
		"icone": "res://Assets/UpgradeDano.png",
		"categoria": "ESTILO IMPACTO • EVOLUÇÃO",
		"raridade": "INCOMUM",
		"cor": Color(1.0, 0.64, 0.2),
		"max_nivel": 3,
		"peso": 0.72,
		"tipo": TIPO_ESTRUTURAL,
		"slot_estrutural": SLOT_ESTILO_TIRO,
		"rota_estrutural": &"impacto_pesado",
		"requisitos": {&"calibre_pesado": 1},
		"tags": [&"projetil", &"pesado"]
	},
	&"fragmentacao": {
		"nome": "NÚCLEO DE ESTILHAÇOS",
		"descricao": "ESTILO ESTILHAÇOS: o impacto gera dois fragmentos de 28% do dano; eles não se replicam.",
		"icone": "res://Assets/UpgradeDano.png",
		"categoria": "ESTILO DE TIRO • ESTILHAÇOS",
		"raridade": "RARA",
		"cor": Color(1.0, 0.24, 0.45),
		"max_nivel": 2,
		"peso": 0.48,
		"tipo": TIPO_ESTRUTURAL,
		"slot_estrutural": SLOT_ESTILO_TIRO,
		"rota_estrutural": &"fragmentacao",
		"requisitos": {},
		"tags": [&"projetil", &"multitiro", &"fragmentacao"]
	},
	&"mira_gravitacional": {
		"nome": "NÚCLEO PREDADOR",
		"descricao": "ESTILO PREDADOR: projéteis perseguem alvos, mas causam somente 88% do dano. Bloqueia os outros estilos.",
		"icone": "res://Assets/UpgradeAgilidade.png",
		"categoria": "ESTILO DE TIRO • PREDADOR",
		"raridade": "RARA",
		"cor": Color(0.42, 0.72, 1.0),
		"max_nivel": 3,
		"peso": 0.62,
		"tipo": TIPO_ESTRUTURAL,
		"slot_estrutural": SLOT_ESTILO_TIRO,
		"rota_estrutural": &"gravitacional",
		"requisitos": {},
		"tags": [&"projetil", &"movimento", &"homing"]
	},
	&"ricochete": {
		"nome": "NÚCLEO DE RICOCHETE",
		"descricao": "ESTILO RICOCHETE: projéteis rebatem nas bordas da arena. Bloqueia os outros estilos de tiro.",
		"icone": "res://Assets/UpgradeAgilidade.png",
		"categoria": "ESTILO DE TIRO • RICOCHETE",
		"raridade": "INCOMUM",
		"cor": Color(0.28, 1.0, 0.92),
		"max_nivel": 2,
		"peso": 0.68,
		"tipo": TIPO_ESTRUTURAL,
		"slot_estrutural": SLOT_ESTILO_TIRO,
		"rota_estrutural": &"ricochete",
		"requisitos": {},
		"tags": [&"projetil", &"movimento"]
	},
	&"formacao_convergente": {
		"nome": "FORMAÇÃO CONVERGENTE",
		"descricao": "Os projéteis partem separados e convergem à frente. Concentra dano sem bônus oculto.",
		"icone": "res://Assets/UpgradeDano.png",
		"categoria": "ESTILO PRISMA • EVOLUÇÃO",
		"raridade": "RARA",
		"cor": Color(1.0, 0.34, 0.76),
		"max_nivel": 1,
		"peso": 0.58,
		"tipo": TIPO_ESTRUTURAL,
		"slot_estrutural": SLOT_ESTILO_TIRO,
		"rota_estrutural": &"multitiro",
		"requisitos": {&"tiro_triplo": 1},
		"tags": [&"projetil", &"multitiro", &"evolucao"]
	},
	&"onda_impacto": {
		"nome": "ONDA DE IMPACTO",
		"descricao": "Projéteis pesados explodem ao acertar, causando dano em área. Cada nível amplia dano e raio.",
		"icone": "res://Assets/UpgradeDano.png",
		"categoria": "ESTILO IMPACTO • EVOLUÇÃO",
		"raridade": "RARA",
		"cor": Color(1.0, 0.55, 0.18),
		"max_nivel": 2,
		"peso": 0.52,
		"tipo": TIPO_ESTRUTURAL,
		"slot_estrutural": SLOT_ESTILO_TIRO,
		"rota_estrutural": &"impacto_pesado",
		"requisitos": {&"calibre_pesado": 2},
		"tags": [&"projetil", &"pesado", &"area", &"evolucao"]
	},
	&"ressonancia_borda": {
		"nome": "RESSONÂNCIA DE BORDA",
		"descricao": "Cada ricochete aumenta em 28% o dano restante do projétil e produz um pulso neon.",
		"icone": "res://Assets/UpgradeAgilidade.png",
		"categoria": "ESTILO RICOCHETE • EVOLUÇÃO",
		"raridade": "RARA",
		"cor": Color(0.22, 1.0, 0.88),
		"max_nivel": 2,
		"peso": 0.54,
		"tipo": TIPO_ESTRUTURAL,
		"slot_estrutural": SLOT_ESTILO_TIRO,
		"rota_estrutural": &"ricochete",
		"requisitos": {&"ricochete": 1},
		"tags": [&"projetil", &"ricochete", &"evolucao"]
	},
	&"predacao_gravitacional": {
		"nome": "PREDAÇÃO GRAVITACIONAL",
		"descricao": "A mira corrige com mais força e recupera parte da penalidade de dano dos projéteis guiados.",
		"icone": "res://Assets/UpgradeAgilidade.png",
		"categoria": "ESTILO PREDADOR • EVOLUÇÃO",
		"raridade": "RARA",
		"cor": Color(0.38, 0.66, 1.0),
		"max_nivel": 2,
		"peso": 0.50,
		"tipo": TIPO_ESTRUTURAL,
		"slot_estrutural": SLOT_ESTILO_TIRO,
		"rota_estrutural": &"gravitacional",
		"requisitos": {&"mira_gravitacional": 1},
		"tags": [&"projetil", &"homing", &"evolucao"]
	},
	&"estilhacos_predadores": {
		"nome": "ESTILHAÇOS PREDADORES",
		"descricao": "Fragmentos causam +8% do dano-base e recebem uma correção gravitacional leve.",
		"icone": "res://Assets/UpgradeDano.png",
		"categoria": "ESTILO ESTILHAÇOS • EVOLUÇÃO",
		"raridade": "RARA",
		"cor": Color(1.0, 0.24, 0.58),
		"max_nivel": 2,
		"peso": 0.48,
		"tipo": TIPO_ESTRUTURAL,
		"slot_estrutural": SLOT_ESTILO_TIRO,
		"rota_estrutural": &"fragmentacao",
		"requisitos": {&"fragmentacao": 1},
		"tags": [&"projetil", &"fragmentacao", &"evolucao"]
	},
	&"vetor_ofensivo": {
		"nome": "VETOR OFENSIVO",
		"descricao": "Quanto mais rápido a nave se move, maior o dano: até +16% por nível.",
		"icone": "res://Assets/UpgradeVelocidade.png",
		"categoria": "PASSIVO • PILOTAGEM",
		"raridade": "INCOMUM",
		"cor": Color(0.22, 0.9, 1.0),
		"max_nivel": 2,
		"peso": 0.72,
		"tipo": TIPO_SINERGIA,
		"requisitos": {&"propulsao": 1},
		"tags": [&"passivo", &"movimento", &"dano"]
	},
	&"casco_regenerativo": {
		"nome": "CASCO REGENERATIVO",
		"descricao": "Após 5 s sem sofrer dano, recupera 1,25 de vida por segundo por nível.",
		"icone": "res://Assets/UpgradeVida.png",
		"categoria": "PASSIVO • CASCO",
		"raridade": "INCOMUM",
		"cor": Color(0.34, 1.0, 0.62),
		"max_nivel": 2,
		"peso": 0.62,
		"tipo": TIPO_SINERGIA,
		"requisitos": {&"blindagem": 1},
		"tags": [&"passivo", &"casco", &"cura"]
	},
	&"capacitor_cinetico": {
		"nome": "CAPACITOR CINÉTICO",
		"descricao": "Acertos carregam o reator. Quando completo, a próxima salva causa dano massivo.",
		"icone": "res://Assets/UpgradeCadencia.png",
		"categoria": "PASSIVO • ARMA",
		"raridade": "RARA",
		"cor": Color(0.25, 0.95, 1.0),
		"max_nivel": 3,
		"peso": 0.56,
		"tipo": TIPO_SINERGIA,
		"requisitos": {&"cadencia": 1},
		"tags": [&"passivo", &"arma", &"impacto"]
	},
	&"reacao_adrenal": {
		"nome": "REAÇÃO ADRENAL",
		"descricao": "Ao sofrer dano, ganha +12% de cadência por nível durante 2,4 segundos.",
		"icone": "res://Assets/UpgradeAgilidade.png",
		"categoria": "PASSIVO • DEFESA",
		"raridade": "INCOMUM",
		"cor": Color(1.0, 0.35, 0.48),
		"max_nivel": 2,
		"peso": 0.64,
		"tipo": TIPO_SINERGIA,
		"requisitos": {&"blindagem": 1},
		"tags": [&"passivo", &"casco", &"cadencia"]
	},
	&"fluxo_habilidade": {
		"nome": "FLUXO DA HABILIDADE",
		"descricao": "A habilidade recarrega mais rápido, com bônus menor a cada nível.",
		"icone": "res://Assets/UpgradeCadencia.png",
		"categoria": "HABILIDADE",
		"raridade": "COMUM",
		"cor": Color(0.35, 0.72, 1.0),
		"max_nivel": 4,
		"peso": 1.0,
		"tipo": TIPO_BASICA,
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
		"tipo": TIPO_SINERGIA,
		"requisitos": {&"fluxo_habilidade": 1},
		"tags": [&"habilidade", &"arma", &"sinergia"]
	},
	&"conversor_impacto": {
		"nome": "CONVERSOR DE IMPACTO",
		"descricao": "Acertos reduzem a recarga em até 0,06 s no total; níveis posteriores rendem menos.",
		"icone": "res://Assets/UpgradeCadencia.png",
		"categoria": "HABILIDADE + PROJÉTIL",
		"raridade": "INCOMUM",
		"cor": Color(0.24, 0.92, 1.0),
		"max_nivel": 3,
		"peso": 0.78,
		"tipo": TIPO_SINERGIA,
		"requisitos": {&"fluxo_habilidade": 1},
		"tags": [&"habilidade", &"projetil", &"sinergia"]
	},
	&"nova_ativacao": {
		"nome": "NOVA DE ATIVAÇÃO",
		"descricao": "Ao usar a habilidade, dispara uma explosão circular de projéteis.",
		"icone": "res://Assets/UpgradeDano.png",
		"categoria": "HABILIDADE + PROJÉTIL",
		"raridade": "RARA",
		"cor": Color(0.95, 0.38, 1.0),
		"max_nivel": 2,
		"peso": 0.34,
		"tipo": TIPO_SINERGIA,
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
		"tipo": TIPO_SINERGIA,
		"requisitos": {&"fluxo_habilidade": 1, &"blindagem": 1},
		"tags": [&"habilidade", &"casco", &"sinergia"]
	},
	&"tempestade_prismatica": {
		"nome": "TEMPESTADE PRISMÁTICA",
		"descricao": "SUPERMOD: +1 projétil e +10% de cadência, mas -15% de velocidade dos projéteis.",
		"icone": "res://Assets/UpgradeDano.png",
		"categoria": "SUPERMOD",
		"raridade": "SUPERMOD",
		"cor": Color(1.0, 0.25, 0.82),
		"max_nivel": 1,
		"peso": 0.28,
		"tipo": TIPO_SUPERMOD,
		"slot_estrutural": SLOT_SUPERMOD,
		"rota_estrutural": &"tempestade_prismatica",
		"requisitos": {&"leque_prismatico": 1, &"cadencia": 3},
		"tags": [&"projetil", &"multitiro", &"cadencia"]
	},
	&"singularidade": {
		"nome": "COLAPSO DE SINGULARIDADE",
		"descricao": "SUPERMOD DE IMPACTO: projétil colossal e perfurante ganha atração própria, mas perde 25% de velocidade.",
		"icone": "res://Assets/UpgradeDano.png",
		"categoria": "SUPERMOD",
		"raridade": "SUPERMOD",
		"cor": Color(0.45, 0.35, 1.0),
		"max_nivel": 1,
		"peso": 0.25,
		"tipo": TIPO_SUPERMOD,
		"slot_estrutural": SLOT_SUPERMOD,
		"rota_estrutural": &"singularidade",
		"requisitos": {&"calibre_pesado": 2, &"onda_impacto": 1},
		"tags": [&"projetil", &"pesado", &"homing"]
	},
	&"reator_sincronizado": {
		"nome": "REATOR SINCRONIZADO",
		"descricao": "SUPERMOD: a Nova dispara mais projéteis e o overdrive dura o dobro, mas a habilidade recarrega 15% mais devagar.",
		"icone": "res://Assets/UpgradeCadencia.png",
		"categoria": "SUPERMOD",
		"raridade": "SUPERMOD",
		"cor": Color(0.25, 0.95, 1.0),
		"max_nivel": 1,
		"peso": 0.22,
		"tipo": TIPO_SUPERMOD,
		"slot_estrutural": SLOT_SUPERMOD,
		"rota_estrutural": &"reator_sincronizado",
		"requisitos": {&"overdrive_habilidade": 2, &"nova_ativacao": 1},
		"tags": [&"habilidade", &"projetil", &"sinergia"]
	}
}


static func obter(id: StringName, habilidade: Habilidade = null) -> Dictionary:
	if is_instance_valid(habilidade):
		var especificos := habilidade.obter_upgrades_especificos()
		if especificos.has(id):
			return especificos[id]
	var dados: Dictionary = DADOS.get(id, {})
	return dados


static func nivel(id: StringName, niveis: Dictionary) -> int:
	return int(niveis.get(id, 0))


static func requisitos_cumpridos(
	id: StringName,
	niveis: Dictionary,
	habilidade: Habilidade = null
) -> bool:
	var dados := obter(id, habilidade)
	var requisitos: Dictionary = dados.get("requisitos", {})
	for requisito in requisitos:
		if nivel(requisito, niveis) < int(requisitos[requisito]):
			return false
	return true


static func conflito_estrutural(
	id: StringName,
	niveis: Dictionary,
	habilidade: Habilidade = null
) -> bool:
	var dados := obter(id, habilidade)
	var slot: StringName = dados.get("slot_estrutural", &"")
	var rota: StringName = dados.get("rota_estrutural", &"")
	if slot == &"" or rota == &"":
		return false

	for adquirido in niveis:
		if int(niveis[adquirido]) <= 0:
			continue
		var dados_adquiridos := obter(adquirido, habilidade)
		var slot_adquirido: StringName = dados_adquiridos.get(
			"slot_estrutural", &""
		)
		if slot_adquirido != slot:
			continue
		var rota_adquirida: StringName = dados_adquiridos.get(
			"rota_estrutural", &""
		)
		if rota_adquirida != &"" and rota_adquirida != rota:
			return true
	return false


static func rotas_ativas(
	niveis: Dictionary,
	habilidade: Habilidade = null
) -> Dictionary:
	var rotas := {
		SLOT_ESTILO_TIRO: &"",
		SLOT_SUPERMOD: &"",
	}
	for adquirido in niveis:
		if int(niveis[adquirido]) <= 0:
			continue
		var dados := obter(adquirido, habilidade)
		var slot: StringName = dados.get("slot_estrutural", &"")
		var rota: StringName = dados.get("rota_estrutural", &"")
		if slot in rotas and rota != &"":
			rotas[slot] = rota
	return rotas


static func nome_slot(slot: StringName) -> String:
	match slot:
		SLOT_ESTILO_TIRO: return "ESTILO DE TIRO"
		SLOT_SUPERMOD: return "SUPERMOD"
		_: return str(slot).to_upper()


static func nome_rota(rota: StringName) -> String:
	match rota:
		&"multitiro": return "PRISMA"
		&"gravitacional": return "PREDADOR"
		&"ricochete": return "RICOCHETE"
		&"impacto_pesado": return "IMPACTO PESADO"
		&"fragmentacao": return "ESTILHAÇOS"
		&"tempestade_prismatica": return "TEMPESTADE"
		&"singularidade": return "SINGULARIDADE"
		&"reator_sincronizado": return "REATOR"
		&"": return "LIVRE"
		_: return str(rota).replace("_", " ").to_upper()


static func resumo_rotas(
	niveis: Dictionary,
	habilidade: Habilidade = null
) -> String:
	var rotas := rotas_ativas(niveis, habilidade)
	return "ESTILO DE TIRO: %s   •   SUPERMOD: %s" % [
		nome_rota(rotas[SLOT_ESTILO_TIRO]),
		nome_rota(rotas[SLOT_SUPERMOD]),
	]


static func disponivel(
	id: StringName,
	niveis: Dictionary,
	habilidade: Habilidade = null
) -> bool:
	var dados := obter(id, habilidade)
	if dados.is_empty():
		return false
	return (
		nivel(id, niveis) < int(dados.get("max_nivel", 1))
		and requisitos_cumpridos(id, niveis, habilidade)
		and not conflito_estrutural(id, niveis, habilidade)
	)


static func texto_requisitos(
	id: StringName,
	niveis: Dictionary,
	habilidade: Habilidade = null
) -> String:
	var dados := obter(id, habilidade)
	var requisitos: Dictionary = dados.get("requisitos", {})
	var slot: StringName = dados.get("slot_estrutural", &"")
	var rota: StringName = dados.get("rota_estrutural", &"")
	var texto_rota := ""
	if slot != &"" and rota != &"":
		texto_rota = "ROTA: %s • %s" % [nome_slot(slot), nome_rota(rota)]

	if requisitos.is_empty():
		if &"habilidade_especifica" in dados.get("tags", []):
			return "EXCLUSIVO DA HABILIDADE EQUIPADA"
		if not texto_rota.is_empty():
			return texto_rota
		return "SEM PRÉ-REQUISITOS"

	var partes: Array[String] = []
	for requisito in requisitos:
		var nome := str(obter(requisito, habilidade).get("nome", requisito))
		partes.append("%s %d/%d" % [
			nome,
			nivel(requisito, niveis),
			int(requisitos[requisito])
		])
	var texto_requisito := "REQUER: " + "  •  ".join(partes)
	if texto_rota.is_empty():
		return texto_requisito
	return texto_rota + "\n" + texto_requisito


static func sortear(
	niveis: Dictionary,
	quantidade := 3,
	habilidade: Habilidade = null,
	evitar: Array[StringName] = []
) -> Array[StringName]:
	var candidatos: Array[StringName] = []
	for id in DADOS:
		if disponivel(id, niveis, habilidade):
			candidatos.append(id)
	if is_instance_valid(habilidade):
		for id in habilidade.obter_upgrades_especificos():
			if disponivel(id, niveis, habilidade):
				candidatos.append(id)

	# Um reroll tenta não repetir imediatamente as mesmas cartas. Se o catálogo
	# disponível estiver pequeno, preserva candidatos suficientes para a oferta.
	for id in evitar:
		if candidatos.size() > quantidade:
			candidatos.erase(id)

	var resultado: Array[StringName] = []
	var especificos: Array[StringName] = []
	for id in candidatos:
		var tags: Array = obter(id, habilidade).get("tags", [])
		if &"habilidade_especifica" in tags:
			especificos.append(id)

	# A habilidade equipada entra por chance, nunca como dupla garantida.
	# Depois do sorteio, todas as demais específicas saem dos candidatos.
	if (
		not especificos.is_empty()
		and randf() <= CHANCE_UPGRADE_HABILIDADE_ESPECIFICA
	):
		resultado.append(_sortear_ponderado(especificos, niveis, habilidade))
	for id in especificos:
		candidatos.erase(id)

	var estilo_ativo: StringName = rotas_ativas(
		niveis, habilidade
	).get(SLOT_ESTILO_TIRO, &"")
	if estilo_ativo == &"":
		_adicionar_do_slot(
			resultado, candidatos, niveis, SLOT_ESTILO_TIRO, habilidade
		)
	else:
		_adicionar_da_rota(
			resultado, candidatos, niveis, SLOT_ESTILO_TIRO, estilo_ativo, habilidade
		)

	_adicionar_de_tipo(
		resultado,
		candidatos,
		niveis,
		TIPO_BASICA,
		habilidade
	)

	while resultado.size() < quantidade and not candidatos.is_empty():
		var escolhido := _sortear_ponderado(candidatos, niveis, habilidade)
		resultado.append(escolhido)
		candidatos.erase(escolhido)
	while resultado.size() > quantidade:
		resultado.pop_back()

	# Segurança para partidas muito longas nas quais todos os mods globais
	# chegaram ao nível máximo: ainda oferece uma específica, mas somente uma.
	if resultado.is_empty() and not especificos.is_empty():
		resultado.append(_sortear_ponderado(especificos, niveis, habilidade))

	resultado.shuffle()
	return resultado


static func _adicionar_do_slot(
	resultado: Array[StringName],
	candidatos: Array[StringName],
	niveis: Dictionary,
	slot: StringName,
	habilidade: Habilidade = null
) -> void:
	if resultado.size() >= 3:
		return
	var filtrados: Array[StringName] = []
	for id in candidatos:
		if StringName(obter(id, habilidade).get("slot_estrutural", &"")) == slot:
			filtrados.append(id)
	if filtrados.is_empty():
		return
	var escolhido := _sortear_ponderado(filtrados, niveis, habilidade)
	resultado.append(escolhido)
	candidatos.erase(escolhido)


static func _adicionar_da_rota(
	resultado: Array[StringName],
	candidatos: Array[StringName],
	niveis: Dictionary,
	slot: StringName,
	rota: StringName,
	habilidade: Habilidade = null
) -> void:
	if resultado.size() >= 3:
		return
	var filtrados: Array[StringName] = []
	for id in candidatos:
		var dados := obter(id, habilidade)
		if (
			StringName(dados.get("slot_estrutural", &"")) == slot
			and StringName(dados.get("rota_estrutural", &"")) == rota
		):
			filtrados.append(id)
	if filtrados.is_empty():
		return
	var escolhido := _sortear_ponderado(filtrados, niveis, habilidade)
	resultado.append(escolhido)
	candidatos.erase(escolhido)


static func _adicionar_de_categoria(
	resultado: Array[StringName],
	candidatos: Array[StringName],
	niveis: Dictionary,
	tag: StringName,
	habilidade: Habilidade = null
) -> void:
	if resultado.size() >= 3:
		return
	var filtrados: Array[StringName] = []
	for id in candidatos:
		var tags: Array = obter(id, habilidade).get("tags", [])
		if tag in tags:
			filtrados.append(id)

	if filtrados.is_empty():
		return

	var escolhido := _sortear_ponderado(filtrados, niveis, habilidade)
	resultado.append(escolhido)
	candidatos.erase(escolhido)


static func _adicionar_de_tipo(
	resultado: Array[StringName],
	candidatos: Array[StringName],
	niveis: Dictionary,
	tipo: StringName,
	habilidade: Habilidade = null
) -> void:
	if resultado.size() >= 3:
		return
	var filtrados: Array[StringName] = []
	for id in candidatos:
		var tipo_candidato: StringName = obter(id, habilidade).get("tipo", &"")
		if tipo_candidato == tipo:
			filtrados.append(id)
	if filtrados.is_empty():
		return
	var escolhido := _sortear_ponderado(filtrados, niveis, habilidade)
	resultado.append(escolhido)
	candidatos.erase(escolhido)


static func _adicionar_relacionado(
	resultado: Array[StringName],
	candidatos: Array[StringName],
	niveis: Dictionary,
	habilidade: Habilidade = null
) -> void:
	if resultado.size() >= 3:
		return
	var tags_ativas: Array = []
	for adquirido in niveis:
		if int(niveis[adquirido]) <= 0:
			continue
		for tag in obter(adquirido, habilidade).get("tags", []):
			if tag not in tags_ativas:
				tags_ativas.append(tag)

	var relacionados: Array[StringName] = []
	for id in candidatos:
		for tag in obter(id, habilidade).get("tags", []):
			if tag in tags_ativas:
				relacionados.append(id)
				break
	if relacionados.is_empty():
		return
	var escolhido := _sortear_ponderado(relacionados, niveis, habilidade)
	resultado.append(escolhido)
	candidatos.erase(escolhido)


static func _sortear_ponderado(
	candidatos: Array[StringName],
	niveis: Dictionary,
	habilidade: Habilidade = null
) -> StringName:
	var peso_total := 0.0
	for id in candidatos:
		peso_total += _peso_com_sinergia(id, niveis, habilidade)

	var alvo := randf() * maxf(peso_total, 0.01)
	var acumulado := 0.0
	for id in candidatos:
		acumulado += _peso_com_sinergia(id, niveis, habilidade)
		if alvo <= acumulado:
			return id

	return candidatos.back()


static func _peso_com_sinergia(
	id: StringName,
	niveis: Dictionary,
	habilidade: Habilidade = null
) -> float:
	var dados := obter(id, habilidade)
	var peso := float(dados.get("peso", 1.0))
	var tags: Array = dados.get("tags", [])

	for adquirido in niveis:
		var nivel_adquirido := int(niveis[adquirido])
		if nivel_adquirido <= 0:
			continue
		var tags_adquiridas: Array = obter(adquirido, habilidade).get("tags", [])
		for tag in tags:
			if tag in tags_adquiridas:
				peso += 0.16 * nivel_adquirido

	# Supermods continuam desejáveis quando os requisitos são cumpridos, mas
	# não se tornam uma conclusão garantida de toda construção compatível.
	var tipo: StringName = dados.get("tipo", &"")
	if tipo == TIPO_SUPERMOD:
		peso *= 0.55

	return maxf(peso, 0.05)
