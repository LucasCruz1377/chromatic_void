extends RefCounted
class_name UpgradeData


# Chance de uma rodada oferecer exatamente uma carta da habilidade equipada.
# Mantém as cartas específicas presentes sem dominar todas as ofertas.
const CHANCE_UPGRADE_HABILIDADE_ESPECIFICA := 0.42

const TIPO_BASICA: StringName = &"basica"
const TIPO_ESTRUTURAL: StringName = &"estrutural"
const TIPO_SINERGIA: StringName = &"sinergia"
const TIPO_SUPERMOD: StringName = &"supermod"
const TIPO_ARMA_ESPECIFICA: StringName = &"arma_especifica"

const SLOT_ESTILO_TIRO: StringName = &"estilo_tiro"
const SLOT_SUPERMOD: StringName = &"supermod"
const SLOT_DETONADOR_MINA: StringName = &"detonador_mina"


# Catálogo central dos mods. Para personalizar a tela, altere aqui:
# nome, descrição, ícone, cor, raridade, níveis, peso e requisitos.
const DADOS: Dictionary = {
	&"dano_calibrado": {
		"nome": "DANO CALIBRADO",
		"descricao": "Seus tiros causam mais dano.",
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
		"descricao": "Sua nave dispara mais rápido.",
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
		"descricao": "Sua nave ganha mais vida máxima.",
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
		"descricao": "Sua nave acelera e se move mais rápido.",
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
		"descricao": "Dispara tiros paralelos mais fracos. Bloqueia outros estilos.",
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
		"descricao": "Adiciona um tiro central, mas reduz o dano de cada projétil.",
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
		"descricao": "Dispara mais projéteis em um leque maior.",
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
		"descricao": "Seus tiros ficam maiores, mais fortes e mais lentos. Bloqueia outros estilos.",
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
		"descricao": "Seus tiros pesados atravessam mais inimigos.",
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
		"descricao": "Seus tiros se partem ao atingir inimigos. Bloqueia outros estilos.",
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
		"descricao": "Seus tiros perseguem inimigos, mas perdem dano. Bloqueia outros estilos.",
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
		"descricao": "Seus tiros rebatem nas bordas da arena. Bloqueia outros estilos.",
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
		"descricao": "Seus tiros convergem à frente da nave.",
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
		"descricao": "Seus tiros pesados explodem e atingem inimigos próximos.",
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
		"descricao": "Seus tiros ganham dano a cada ricochete.",
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
		"descricao": "Seus tiros perseguem melhor e causam mais dano.",
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
		"descricao": "Seus fragmentos ficam mais fortes e seguem os inimigos.",
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
		"descricao": "Mover sua nave mais rápido aumenta o dano dos tiros.",
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
		"descricao": "Sua nave regenera vida após ficar um tempo sem sofrer dano.",
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
	&"precisao_critica": {
		"nome": "PRECISÃO CRÍTICA", "descricao": "Seus tiros acertam golpes críticos com mais frequência.",
		"icone": "res://Assets/UpgradeCadencia.png", "categoria": "COMBATE • CRÍTICO",
		"raridade": "INCOMUM", "cor": Color(1.0, 0.75, 0.2), "max_nivel": 3,
		"peso": 0.7, "tipo": TIPO_SINERGIA, "requisitos": {}, "tags": [&"arma", &"critico"]
	},
	&"impacto_critico": {
		"nome": "IMPACTO CRÍTICO", "descricao": "Seus acertos críticos causam mais dano.",
		"icone": "res://Assets/UpgradeDano.png", "categoria": "COMBATE • CRÍTICO",
		"raridade": "RARA", "cor": Color(1.0, 0.5, 0.2), "max_nivel": 3,
		"peso": 0.5, "tipo": TIPO_SINERGIA, "requisitos": {&"precisao_critica": 1}, "tags": [&"arma", &"critico"]
	},
	&"reacao_adrenal": {
		"nome": "REAÇÃO ADRENAL",
		"descricao": "Sofrer dano faz sua nave disparar mais rápido por um tempo.",
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
		"descricao": "Sua habilidade recarrega mais rápido.",
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
		"descricao": "Usar sua habilidade aumenta o dano e a cadência por um tempo.",
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
		"descricao": "Acertar inimigos ajuda a recarregar sua habilidade.",
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
		"descricao": "Usar sua habilidade lança tiros ao redor da nave.",
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
		"descricao": "Usar sua habilidade protege sua nave por um instante.",
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
		"descricao": "Dispara mais tiros e mais rápido, com projéteis mais lentos.",
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
		"descricao": "Seus tiros ficam enormes, perfurantes e perseguem inimigos, mas ficam mais lentos.",
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
		"descricao": "Amplia a nova e a sobrecarga da arma, mas sua habilidade recarrega mais devagar.",
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


# Evoluções que só entram no sorteio quando a arma indicada está equipada.
# Os nomes usam exclusivamente assuntos já presentes nos cards do Monthly
# Colors: campanhas mensais, datas comemorativas e as doze luas anuais.
const DADOS_ARMAS: Dictionary = {
	&"rosa_petalas_extras": {
		"nome": "PÉTALAS EXTRAS", "descricao": "Lança mais pétalas por disparo.",
		"icone": "res://Habilidades/Icones/upgrades_armas/rosa_petalas_extras.svg", "categoria": "LEQUE DA PRIMAVERA",
		"raridade": "INCOMUM", "cor": Color("ff7eb7"), "max_nivel": 2, "peso": 0.92,
		"tipo": TIPO_ARMA_ESPECIFICA, "requisitos": {}, "arma_exclusiva": &"a01_espingarda_lua_rosa",
		"tags": [&"arma_especifica", &"multitiro", &"primavera"]
	},
	&"rosa_cano_curto": {
		"nome": "FLORAÇÃO CONCENTRADA", "descricao": "Concentra as pétalas e aumenta o dano de perto.",
		"icone": "res://Habilidades/Icones/upgrades_armas/rosa_cano_curto.svg", "categoria": "LEQUE DA PRIMAVERA",
		"raridade": "RARA", "cor": Color("ff5f9f"), "max_nivel": 2, "peso": 0.66,
		"tipo": TIPO_ARMA_ESPECIFICA, "requisitos": {}, "arma_exclusiva": &"a01_espingarda_lua_rosa",
		"tags": [&"arma_especifica", &"dano", &"curto_alcance"]
	},
	&"fogos_formacao": {
		"nome": "CONSTELAÇÃO DE FOGOS", "descricao": "Lança mais fogos ao redor do alvo.",
		"icone": "res://Habilidades/Icones/upgrades_armas/fogos_formacao.svg", "categoria": "FOGOS DO RECOMEÇO",
		"raridade": "INCOMUM", "cor": Color("e7edff"), "max_nivel": 2, "peso": 0.88,
		"tipo": TIPO_ARMA_ESPECIFICA, "requisitos": {}, "arma_exclusiva": &"a03_alcateia_misseis",
		"tags": [&"arma_especifica", &"multitiro", &"ano_novo"]
	},
	&"fogos_estouro": {
		"nome": "VIRADA LUMINOSA", "descricao": "Seus fogos explodem com mais força e alcance.",
		"icone": "res://Habilidades/Icones/upgrades_armas/fogos_estouro.svg", "categoria": "FOGOS DO RECOMEÇO",
		"raridade": "RARA", "cor": Color("b8c8ff"), "max_nivel": 2, "peso": 0.62,
		"tipo": TIPO_ARMA_ESPECIFICA, "requisitos": {}, "arma_exclusiva": &"a03_alcateia_misseis",
		"tags": [&"arma_especifica", &"area", &"ano_novo"]
	},
	&"esturjao_correnteza": {
		"nome": "CORRENTEZA CRESCENTE", "descricao": "Seu canhão carrega mais rápido.",
		"icone": "res://Habilidades/Icones/upgrades_armas/esturjao_correnteza.svg", "categoria": "CANHÃO DO ESTURJÃO",
		"raridade": "INCOMUM", "cor": Color("54c6ff"), "max_nivel": 2, "peso": 0.86,
		"tipo": TIPO_ARMA_ESPECIFICA, "requisitos": {}, "arma_exclusiva": &"a04_canhao_esturjao",
		"tags": [&"arma_especifica", &"carga", &"esturjao"]
	},
	&"esturjao_perfurante": {
		"nome": "MIGRAÇÃO PROFUNDA", "descricao": "O tiro carregado fica mais forte e atravessa mais inimigos.",
		"icone": "res://Habilidades/Icones/upgrades_armas/esturjao_perfurante.svg", "categoria": "CANHÃO DO ESTURJÃO",
		"raridade": "RARA", "cor": Color("309fe8"), "max_nivel": 2, "peso": 0.64,
		"tipo": TIPO_ARMA_ESPECIFICA, "requisitos": {}, "arma_exclusiva": &"a04_canhao_esturjao",
		"tags": [&"arma_especifica", &"dano", &"perfuracao", &"esturjao"]
	},
	&"mina_pavio_curto": {
		"nome": "CONTAGEM PREVENTIVA", "descricao": "Seus sinalizadores explodem mais cedo.",
		"icone": "res://Habilidades/Icones/upgrades_armas/mina_pavio_curto.svg", "categoria": "SINALIZADORES AMARELOS",
		"raridade": "INCOMUM", "cor": Color("ffd447"), "max_nivel": 3, "peso": 0.94,
		"tipo": TIPO_ARMA_ESPECIFICA, "requisitos": {}, "arma_exclusiva": &"a05_minas_castor",
		"tags": [&"arma_especifica", &"tempo", &"maio_amarelo"]
	},
	&"mina_sensor_proximidade": {
		"nome": "SENSOR DE PROXIMIDADE", "descricao": "Seus sinalizadores explodem quando inimigos se aproximam.",
		"icone": "res://Habilidades/Icones/upgrades_armas/mina_sensor_proximidade.svg", "categoria": "SINALIZADORES AMARELOS",
		"raridade": "RARA", "cor": Color("fff06a"), "max_nivel": 1, "peso": 0.34,
		"tipo": TIPO_ESTRUTURAL, "slot_estrutural": SLOT_DETONADOR_MINA, "rota_estrutural": &"proximidade",
		"requisitos": {}, "arma_exclusiva": &"a05_minas_castor", "tags": [&"arma_especifica", &"detonador", &"maio_amarelo"]
	},
	&"mina_comando_remoto": {
		"nome": "COMANDO DE SEGURANÇA", "descricao": "Seu próximo disparo detona os sinalizadores; o seguinte instala outro.",
		"icone": "res://Habilidades/Icones/upgrades_armas/mina_comando_remoto.svg", "categoria": "SINALIZADORES AMARELOS",
		"raridade": "RARA", "cor": Color("ffb52e"), "max_nivel": 1, "peso": 0.30,
		"tipo": TIPO_ESTRUTURAL, "slot_estrutural": SLOT_DETONADOR_MINA, "rota_estrutural": &"remoto",
		"requisitos": {}, "arma_exclusiva": &"a05_minas_castor", "tags": [&"arma_especifica", &"detonador", &"maio_amarelo"]
	},
	&"perielio_resfriamento": {
		"nome": "JANELA DO PERIÉLIO", "descricao": "Seu feixe dura mais e se recupera mais rápido da sobrecarga.",
		"icone": "res://Habilidades/Icones/upgrades_armas/perielio_resfriamento.svg", "categoria": "FEIXE DO PERIÉLIO",
		"raridade": "INCOMUM", "cor": Color("ffcf45"), "max_nivel": 2, "peso": 0.88,
		"tipo": TIPO_ARMA_ESPECIFICA, "requisitos": {}, "arma_exclusiva": &"a06_feixe_perielio",
		"tags": [&"arma_especifica", &"duracao", &"perielio"]
	},
	&"perielio_foco": {
		"nome": "CONVERGÊNCIA SOLAR", "descricao": "Seu feixe atinge a potência máxima mais rápido.",
		"icone": "res://Habilidades/Icones/upgrades_armas/perielio_foco.svg", "categoria": "FEIXE DO PERIÉLIO",
		"raridade": "RARA", "cor": Color("ff9f2f"), "max_nivel": 2, "peso": 0.62,
		"tipo": TIPO_ARMA_ESPECIFICA, "requisitos": {}, "arma_exclusiva": &"a06_feixe_perielio",
		"tags": [&"arma_especifica", &"dano", &"perielio"]
	},
	&"perielio_potencia": {
		"nome": "NÚCLEO HIPERQUENTE", "descricao": "Aumenta a potência máxima do seu feixe.",
		"icone": "res://Habilidades/Icones/upgrades_armas/perielio_foco.svg", "categoria": "FEIXE DO PERIÉLIO",
		"raridade": "RARA", "cor": Color("ff6b35"), "max_nivel": 3, "peso": 0.42,
		"tipo": TIPO_ARMA_ESPECIFICA, "requisitos": {&"perielio_foco": 1}, "arma_exclusiva": &"a06_feixe_perielio",
		"tags": [&"arma_especifica", &"dano", &"perielio"]
	},
	&"perielio_infinito": {
		"nome": "SOL SEM OCASO", "descricao": "Seu feixe dispara sem parar, mas passa a causar dano ao seu casco.",
		"icone": "res://Habilidades/Icones/upgrades_armas/perielio_resfriamento.svg", "categoria": "FEIXE DO PERIÉLIO",
		"raridade": "ULTRARRARA", "cor": Color("ff3344"), "max_nivel": 1, "peso": 0.10,
		"tipo": TIPO_ARMA_ESPECIFICA, "requisitos": {&"perielio_resfriamento": 2, &"perielio_foco": 2}, "arma_exclusiva": &"a06_feixe_perielio",
		"tags": [&"arma_especifica", &"risco", &"perielio"]
	},
	&"colheita_dupla": {
		"nome": "CEIFA EM DUPLA", "descricao": "Lança mais arcos por disparo.",
		"icone": "res://Habilidades/Icones/upgrades_armas/colheita_dupla.svg", "categoria": "ARCO DA COLHEITA",
		"raridade": "INCOMUM", "cor": Color("ffb34d"), "max_nivel": 2, "peso": 0.86,
		"tipo": TIPO_ARMA_ESPECIFICA, "requisitos": {}, "arma_exclusiva": &"a07_foice_colheita",
		"tags": [&"arma_especifica", &"multitiro", &"colheita"]
	},
	&"colheita_retorno": {
		"nome": "COLHEITA COMPLETA", "descricao": "Seus arcos ficam mais fortes, voltam mais rápido e atravessam mais inimigos.",
		"icone": "res://Habilidades/Icones/upgrades_armas/colheita_retorno.svg", "categoria": "ARCO DA COLHEITA",
		"raridade": "RARA", "cor": Color("ff8f35"), "max_nivel": 2, "peso": 0.62,
		"tipo": TIPO_ARMA_ESPECIFICA, "requisitos": {}, "arma_exclusiva": &"a07_foice_colheita",
		"tags": [&"arma_especifica", &"dano", &"colheita"]
	},
	&"terra_raizes_gemeas": {
		"nome": "RAÍZES GÊMEAS", "descricao": "Lança mais raízes por caminhos diferentes.",
		"icone": "res://Habilidades/Icones/upgrades_armas/terra_raizes_gemeas.svg", "categoria": "RAIZ DO DIA DA TERRA",
		"raridade": "INCOMUM", "cor": Color("8ae878"), "max_nivel": 2, "peso": 0.86,
		"tipo": TIPO_ARMA_ESPECIFICA, "requisitos": {}, "arma_exclusiva": &"a08_torpedo_subterraneo",
		"tags": [&"arma_especifica", &"multitiro", &"dia_terra"]
	},
	&"terra_ruptura": {
		"nome": "SOLO RENOVADO", "descricao": "Suas raízes emergem com explosões maiores e mais fortes.",
		"icone": "res://Habilidades/Icones/upgrades_armas/terra_ruptura.svg", "categoria": "RAIZ DO DIA DA TERRA",
		"raridade": "RARA", "cor": Color("5fcf69"), "max_nivel": 2, "peso": 0.62,
		"tipo": TIPO_ARMA_ESPECIFICA, "requisitos": {}, "arma_exclusiva": &"a08_torpedo_subterraneo",
		"tags": [&"arma_especifica", &"area", &"dia_terra"]
	},
	&"fogueira_brasas": {
		"nome": "RODA DE BRASAS", "descricao": "Lança mais brasas ao redor da mira.",
		"icone": "res://Habilidades/Icones/upgrades_armas/fogueira_brasas.svg", "categoria": "MORTEIRO DA FOGUEIRA",
		"raridade": "INCOMUM", "cor": Color("ff6f32"), "max_nivel": 2, "peso": 0.86,
		"tipo": TIPO_ARMA_ESPECIFICA, "requisitos": {}, "arma_exclusiva": &"a09_morteiro_fogueira",
		"tags": [&"arma_especifica", &"multitiro", &"festa_junina"]
	},
	&"fogueira_circulo": {
		"nome": "FOGUEIRA MAIOR", "descricao": "Suas brasas explodem com mais força e queimam uma área maior.",
		"icone": "res://Habilidades/Icones/upgrades_armas/fogueira_circulo.svg", "categoria": "MORTEIRO DA FOGUEIRA",
		"raridade": "RARA", "cor": Color("ff4224"), "max_nivel": 2, "peso": 0.60,
		"tipo": TIPO_ARMA_ESPECIFICA, "requisitos": {}, "arma_exclusiva": &"a09_morteiro_fogueira",
		"tags": [&"arma_especifica", &"area", &"festa_junina"]
	},
	&"morango_cacho": {
		"nome": "CACHO DE MORANGOS", "descricao": "Sua rajada lança mais projéteis.",
		"icone": "res://Habilidades/Icones/upgrades_armas/morango_cacho.svg", "categoria": "SEMENTES VERMELHAS",
		"raridade": "INCOMUM", "cor": Color("ff405f"), "max_nivel": 2, "peso": 0.90,
		"tipo": TIPO_ARMA_ESPECIFICA, "requisitos": {}, "arma_exclusiva": &"a10_rajada_morango",
		"tags": [&"arma_especifica", &"multitiro", &"lua_morango"]
	},
	&"morango_sementes": {
		"nome": "SEMENTES SILVESTRES", "descricao": "Seus tiros ficam mais fortes e espalham mais sementes.",
		"icone": "res://Habilidades/Icones/upgrades_armas/morango_sementes.svg", "categoria": "SEMENTES VERMELHAS",
		"raridade": "RARA", "cor": Color("ff2448"), "max_nivel": 2, "peso": 0.62,
		"tipo": TIPO_ARMA_ESPECIFICA, "requisitos": {}, "arma_exclusiva": &"a10_rajada_morango",
		"tags": [&"arma_especifica", &"fragmentacao", &"lua_morango"]
	},
	&"roxo_neblina": {
		"nome": "NEBLINA VIOLETA", "descricao": "Seu disparo cobre uma área maior à frente da nave.",
		"icone": "res://Habilidades/Icones/upgrades_armas/roxo_neblina.svg", "categoria": "PROJETOR FEVEREIRO ROXO",
		"raridade": "INCOMUM", "cor": Color("bd8cff"), "max_nivel": 2, "peso": 0.88,
		"tipo": TIPO_ARMA_ESPECIFICA, "requisitos": {}, "arma_exclusiva": &"a11_projetor_nevasca",
		"tags": [&"arma_especifica", &"multitiro", &"fevereiro_roxo"]
	},
	&"roxo_persistencia": {
		"nome": "CUIDADO CONTÍNUO", "descricao": "Seus tiros causam mais dano e deixam os inimigos lentos por mais tempo.",
		"icone": "res://Habilidades/Icones/upgrades_armas/roxo_persistencia.svg", "categoria": "PROJETOR FEVEREIRO ROXO",
		"raridade": "RARA", "cor": Color("9562e8"), "max_nivel": 2, "peso": 0.60,
		"tipo": TIPO_ARMA_ESPECIFICA, "requisitos": {}, "arma_exclusiva": &"a11_projetor_nevasca",
		"tags": [&"arma_especifica", &"controle", &"fevereiro_roxo"]
	},
	&"jardim_petalas": {
		"nome": "JARDIM EM FLORAÇÃO", "descricao": "Mais pétalas orbitam sua nave antes de atacar.",
		"icone": "res://Habilidades/Icones/upgrades_armas/jardim_petalas.svg", "categoria": "JARDIM ORBITAL",
		"raridade": "INCOMUM", "cor": Color("ff67b3"), "max_nivel": 2, "peso": 0.88,
		"tipo": TIPO_ARMA_ESPECIFICA, "requisitos": {}, "arma_exclusiva": &"a12_jardim_orbital",
		"tags": [&"arma_especifica", &"multitiro", &"flores"]
	},
	&"jardim_sincronia": {
		"nome": "DESABROCHAR CONJUNTO", "descricao": "Suas pétalas atacam mais cedo e com mais força.",
		"icone": "res://Habilidades/Icones/upgrades_armas/jardim_sincronia.svg", "categoria": "JARDIM ORBITAL",
		"raridade": "RARA", "cor": Color("f04491"), "max_nivel": 2, "peso": 0.60,
		"tipo": TIPO_ARMA_ESPECIFICA, "requisitos": {}, "arma_exclusiva": &"a12_jardim_orbital",
		"tags": [&"arma_especifica", &"dano", &"flores"]
	},
	&"solsticio_nucleo": {
		"nome": "NEVASCA", "descricao": "Quebrar inimigos congelados espalha gelo nos inimigos próximos.",
		"icone": "res://Habilidades/Icones/upgrades_armas/solsticio_nucleo.svg", "categoria": "CANHÃO DO SOLSTÍCIO",
		"raridade": "RARA", "cor": Color("90dcff"), "max_nivel": 1, "peso": 0.34,
		"tipo": TIPO_ARMA_ESPECIFICA, "requisitos": {}, "arma_exclusiva": &"a13_canhao_lua_fria",
		"tags": [&"arma_especifica", &"area", &"gelo", &"solsticio"]
	},
	&"solsticio_absorcao": {
		"nome": "ABAIXO DE ZERO", "descricao": "O congelamento dura mais e espalha gelo continuamente.",
		"icone": "res://Habilidades/Icones/upgrades_armas/solsticio_absorcao.svg", "categoria": "CANHÃO DO SOLSTÍCIO",
		"raridade": "ULTRARRARA", "cor": Color("67a8ff"), "max_nivel": 1, "peso": 0.12,
		"tipo": TIPO_ARMA_ESPECIFICA, "requisitos": {&"solsticio_nucleo": 1}, "arma_exclusiva": &"a13_canhao_lua_fria",
		"tags": [&"arma_especifica", &"controle", &"gelo", &"solsticio"]
	},
}


static func obter(id: StringName, habilidade: Habilidade = null) -> Dictionary:
	if is_instance_valid(habilidade):
		var especificos := habilidade.obter_upgrades_especificos()
		if especificos.has(id):
			return especificos[id]
	if DADOS_ARMAS.has(id):
		return DADOS_ARMAS[id]
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
		SLOT_ESTILO_TIRO: return _tr("ESTILO DE TIRO")
		SLOT_SUPERMOD: return _tr("SUPERMOD")
		SLOT_DETONADOR_MINA: return _tr("DETONADOR DA MINA")
		_: return str(slot).to_upper()


static func nome_rota(rota: StringName) -> String:
	match rota:
		&"multitiro": return _tr("PRISMA")
		&"gravitacional": return _tr("PREDADOR")
		&"ricochete": return _tr("RICOCHETE")
		&"impacto_pesado": return _tr("IMPACTO PESADO")
		&"fragmentacao": return _tr("ESTILHAÇOS")
		&"tempestade_prismatica": return _tr("TEMPESTADE")
		&"singularidade": return _tr("SINGULARIDADE")
		&"reator_sincronizado": return _tr("REATOR")
		&"proximidade": return _tr("PROXIMIDADE")
		&"remoto": return _tr("COMANDO REMOTO")
		&"": return _tr("LIVRE")
		_: return str(rota).replace("_", " ").to_upper()


static func resumo_rotas(
	niveis: Dictionary,
	habilidade: Habilidade = null,
	arma: StringName = &""
) -> String:
	if not arma.is_empty():
		var melhorias_arma := 0
		for id in niveis:
			var dados := obter(id, habilidade)
			if StringName(dados.get("arma_exclusiva", &"")) == arma:
				melhorias_arma += int(niveis[id])
		return _tr("%s   •   %d MELHORIA(S) PRÓPRIA(S)") % [
			_tr(nome_arma(arma)), melhorias_arma
		]
	var rotas := rotas_ativas(niveis, habilidade)
	return _tr("ESTILO DE TIRO: %s   •   SUPERMOD: %s") % [
		nome_rota(rotas[SLOT_ESTILO_TIRO]),
		nome_rota(rotas[SLOT_SUPERMOD]),
	]


static func nome_arma(arma: StringName) -> String:
	match arma:
		&"a01_espingarda_lua_rosa": return "LEQUE DA PRIMAVERA"
		&"a03_alcateia_misseis": return "FOGOS DO RECOMEÇO"
		&"a04_canhao_esturjao": return "CANHÃO DO ESTURJÃO"
		&"a05_minas_castor": return "SINALIZADORES AMARELOS"
		&"a06_feixe_perielio": return "FEIXE DO PERIÉLIO"
		&"a07_foice_colheita": return "ARCO DA COLHEITA"
		&"a08_torpedo_subterraneo": return "RAIZ DO DIA DA TERRA"
		&"a09_morteiro_fogueira": return "MORTEIRO DA FOGUEIRA"
		&"a10_rajada_morango": return "SEMENTES VERMELHAS"
		&"a11_projetor_nevasca": return "PROJETOR FEVEREIRO ROXO"
		&"a12_jardim_orbital": return "JARDIM ORBITAL"
		&"a13_canhao_lua_fria": return "CANHÃO DO SOLSTÍCIO"
		_: return "ARMA PADRÃO"


static func disponivel(
	id: StringName,
	niveis: Dictionary,
	habilidade: Habilidade = null,
	arma: StringName = &""
) -> bool:
	var dados := obter(id, habilidade)
	if dados.is_empty():
		return false
	if not _compativel_com_arma(dados, arma):
		return false
	return (
		nivel(id, niveis) < int(dados.get("max_nivel", 1))
		and requisitos_cumpridos(id, niveis, habilidade)
		and not conflito_estrutural(id, niveis, habilidade)
	)


static func texto_requisitos(
	id: StringName,
	niveis: Dictionary,
	habilidade: Habilidade = null,
	_arma: StringName = &""
) -> String:
	var dados := obter(id, habilidade)
	var requisitos: Dictionary = dados.get("requisitos", {})
	var slot: StringName = dados.get("slot_estrutural", &"")
	var rota: StringName = dados.get("rota_estrutural", &"")
	var texto_rota := ""
	if slot != &"" and rota != &"":
		texto_rota = _tr("ROTA: %s • %s") % [nome_slot(slot), nome_rota(rota)]

	if requisitos.is_empty():
		if not StringName(dados.get("arma_exclusiva", &"")).is_empty():
			return _tr("EXCLUSIVO DA ARMA EQUIPADA")
		if &"habilidade_especifica" in dados.get("tags", []):
			return _tr("EXCLUSIVO DA HABILIDADE EQUIPADA")
		if not texto_rota.is_empty():
			return texto_rota
		return _tr("SEM PRÉ-REQUISITOS")

	var partes: Array[String] = []
	for requisito in requisitos:
		var nome := str(obter(requisito, habilidade).get("nome", requisito))
		partes.append("%s %d/%d" % [
			_tr(nome),
			nivel(requisito, niveis),
			int(requisitos[requisito])
		])
	var texto_requisito := _tr("REQUER: %s") % "  •  ".join(partes)
	if texto_rota.is_empty():
		return texto_requisito
	return texto_rota + "\n" + texto_requisito


static func _tr(texto: String) -> String:
	return str(TranslationServer.translate(texto))


static func sortear(
	niveis: Dictionary,
	quantidade := 3,
	habilidade: Habilidade = null,
	evitar: Array[StringName] = [],
	arma: StringName = &""
) -> Array[StringName]:
	var candidatos: Array[StringName] = []
	for id in DADOS:
		if disponivel(id, niveis, habilidade, arma):
			candidatos.append(id)
	for id in DADOS_ARMAS:
		if disponivel(id, niveis, habilidade, arma):
			candidatos.append(id)
	if is_instance_valid(habilidade):
		for id in habilidade.obter_upgrades_especificos():
			if disponivel(id, niveis, habilidade, arma):
				candidatos.append(id)

	# Um reroll tenta não repetir imediatamente as mesmas cartas. Se o catálogo
	# disponível estiver pequeno, preserva candidatos suficientes para a oferta.
	for id in evitar:
		if candidatos.size() > quantidade:
			candidatos.erase(id)

	var resultado: Array[StringName] = []
	var especificos: Array[StringName] = []
	var especificos_arma: Array[StringName] = []
	for id in candidatos:
		var dados_candidato := obter(id, habilidade)
		var tags: Array = dados_candidato.get("tags", [])
		if &"habilidade_especifica" in tags:
			especificos.append(id)
		if not StringName(dados_candidato.get("arma_exclusiva", &"")).is_empty():
			especificos_arma.append(id)

	# Toda arma Monthly recebe ao menos uma evolução própria por oferta enquanto
	# ainda houver alguma disponível. As demais cartas continuam sendo casco,
	# mobilidade, habilidade ou atributos universais realmente aplicáveis.
	if not especificos_arma.is_empty():
		resultado.append(_sortear_ponderado(especificos_arma, niveis, habilidade))
	for id in especificos_arma:
		candidatos.erase(id)
		especificos.erase(id)

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


static func _compativel_com_arma(dados: Dictionary, arma: StringName) -> bool:
	var exclusiva: StringName = dados.get("arma_exclusiva", &"")
	if not exclusiva.is_empty():
		return arma == exclusiva

	# Os estilos estruturais antigos modificam somente o tiro padrão. Uma arma
	# permanente possui geometria própria e nunca deve receber uma carta que não
	# altera seus projéteis de verdade.
	if not arma.is_empty() and StringName(dados.get("slot_estrutural", &"")) == SLOT_ESTILO_TIRO:
		return false
	if not arma.is_empty() and StringName(dados.get("tipo", &"")) == TIPO_SUPERMOD:
		return false
	return true


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
