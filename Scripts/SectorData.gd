extends RefCounted
class_name SectorData


const ORDEM_CICLO: Array[StringName] = [
	&"vazio_inicial", &"constelacao_amparo", &"no_ametista",
	&"florescimento", &"lua_colheita",
]


# Catálogo central dos setores. O primeiro é deliberadamente o jogo original:
# fundo espacial escuro, inimigos padrão e PET-0 no nível 10.
const DADOS: Dictionary = {
	&"vazio_inicial": {
		"nome": "VAZIO CROMÁTICO",
		"subtitulo": "SETOR 01 • ORIGEM",
		"descricao": "A formação original do jogo e o território do PET-0.",
		"usar_fundo_original": true,
		"cor_fundo": Color(0.004, 0.006, 0.022, 1.0),
		"cor_destaque": Color(0.35, 1.0, 0.65, 1.0),
		"simbolo": "◇",
		"boss": &"pet0",
		"inimigos": [
			[&"estilhaco_vazio", 3.0], [&"melee", 1.3], [&"investida", 1.1],
			[&"tanque", 0.8], [&"atirador", 0.8]
		]
	},
	&"florescimento": {
		"nome": "FLORESCIMENTO",
		"subtitulo": "PRIMAVERA • SETEMBRO",
		"descricao": "Espinhos, pétalas e vinhas transformam a arena em uma dança.",
		"usar_fundo_original": false,
		"cor_fundo": Color(0.008, 0.030, 0.025, 1.0),
		"cor_destaque": Color(1.0, 0.32, 0.68, 1.0),
		"simbolo": "✿",
		"boss": &"flor_equinocio",
		"inimigos": [
			[&"broto_primaveril", 2.4], [&"semente_canhao", 1.8],
			[&"polen_errante", 1.5], [&"cipo_espiral", 1.2], [&"fruto_explosivo", 1.0]
		]
	},
	&"lua_colheita": {
		"nome": "ÓRBITA DA SIZÍGIA",
		"subtitulo": "SOL • LUA • ECLIPSE ABSOLUTO",
		"descricao": "A rota mais longa culmina na união dos dois astros.",
		"usar_fundo_original": false,
		"cor_fundo": Color(0.008, 0.010, 0.038, 1.0),
		"cor_destaque": Color(0.56, 0.64, 1.0, 1.0),
		"simbolo": "◐",
		"boss": &"eclipse_colheita",
		"inimigos": [
			[&"fragmento_lunar", 2.4], [&"centelha_solar", 1.8],
			[&"meteoro_jovem", 1.5], [&"eco_gravitacional", 1.2], [&"satelite_coroa", 1.0]
		]
	},
	&"constelacao_amparo": {
		"nome": "CONSTELAÇÃO DO AMPARO",
		"subtitulo": "AGOSTO DOURADO • CUIDADO",
		"descricao": "Satélites cooperam, formam elos e protegem o núcleo da constelação.",
		"usar_fundo_original": false,
		"cor_fundo": Color(0.032, 0.026, 0.006, 1.0),
		"cor_destaque": Color(1.0, 0.78, 0.18, 1.0),
		"simbolo": "⬡",
		"boss": &"constelacao_amparo",
		"inimigos": [
			[&"centelha_guia", 2.4], [&"elo_dourado", 1.8],
			[&"prisma_amparo", 1.4], [&"satelite_berco", 1.2], [&"pulso_solar", 1.0]
		]
	},
	&"no_ametista": {
		"nome": "NÓ DE AMETISTA",
		"subtitulo": "AGOSTO LILÁS",
		"descricao": "Fitas cristalinas tecem caminhos perigosos que precisam ser desatados.",
		"usar_fundo_original": false,
		"cor_fundo": Color(0.026, 0.008, 0.038, 1.0),
		"cor_destaque": Color(0.82, 0.48, 1.0, 1.0),
		"simbolo": "✦",
		"boss": &"no_ametista",
		"inimigos": [
			[&"fita_violeta", 2.4], [&"no_flutuante", 1.8],
			[&"eco_ametista", 1.5], [&"lamina_iris", 1.2], [&"casulo_prismatico", 1.0]
		]
	}
}


static func obter(id: StringName) -> Dictionary:
	return DADOS.get(id, DADOS[&"vazio_inicial"])


static func proximo_no_ciclo(id: StringName) -> StringName:
	var indice := ORDEM_CICLO.find(id)
	if indice < 0 or indice + 1 >= ORDEM_CICLO.size():
		return &""
	return ORDEM_CICLO[indice + 1]


static func sortear_opcoes(
	setores_concluidos: Array[StringName],
	setor_atual: StringName,
	quantidade: int = 2
) -> Array[StringName]:
	var disponiveis: Array[StringName] = []
	for id in DADOS:
		if id == &"vazio_inicial" or id == setor_atual or id in setores_concluidos:
			continue
		disponiveis.append(id)
	disponiveis.shuffle()
	return disponiveis.slice(0, mini(quantidade, disponiveis.size()))
