extends RefCounted
class_name SectorData


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
		"boss": &"pet0",
		"inimigos": [
			[&"seguidor", 3.0], [&"melee", 1.3], [&"investida", 1.1],
			[&"tanque", 0.8], [&"atirador", 0.8]
		]
	},
	&"florescimento": {
		"nome": "FLORESCIMENTO",
		"subtitulo": "PRIMAVERA • SETEMBRO",
		"descricao": "Investidas e formações rápidas cercam a arena.",
		"usar_fundo_original": false,
		"cor_fundo": Color(0.008, 0.030, 0.025, 1.0),
		"cor_destaque": Color(1.0, 0.32, 0.68, 1.0),
		"boss": &"flor_equinocio",
		"inimigos": [
			[&"melee", 2.0], [&"investida", 1.8], [&"seguidor", 1.5],
			[&"atirador", 0.9]
		]
	},
	&"lua_colheita": {
		"nome": "ÓRBITA DA COLHEITA",
		"subtitulo": "LUA DA COLHEITA",
		"descricao": "Atiradores e investidas exigem movimento constante.",
		"usar_fundo_original": false,
		"cor_fundo": Color(0.008, 0.010, 0.038, 1.0),
		"cor_destaque": Color(0.56, 0.64, 1.0, 1.0),
		"boss": &"eclipse_colheita",
		"inimigos": [
			[&"atirador", 2.2], [&"investida", 1.9], [&"melee", 1.2],
			[&"seguidor", 1.0]
		]
	},
	&"rede_dourada": {
		"nome": "REDE DOURADA",
		"subtitulo": "AGOSTO DOURADO",
		"descricao": "Unidades resistentes protegem linhas de tiro.",
		"usar_fundo_original": false,
		"cor_fundo": Color(0.032, 0.026, 0.006, 1.0),
		"cor_destaque": Color(1.0, 0.78, 0.18, 1.0),
		"boss": &"sentinela_dourada",
		"inimigos": [
			[&"tanque", 2.0], [&"atirador", 1.7], [&"seguidor", 1.5],
			[&"melee", 1.0]
		]
	},
	&"ruptura_lilas": {
		"nome": "RUPTURA LILÁS",
		"subtitulo": "AGOSTO LILÁS",
		"descricao": "Ataques diretos alternam pressão e perseguição.",
		"usar_fundo_original": false,
		"cor_fundo": Color(0.026, 0.008, 0.038, 1.0),
		"cor_destaque": Color(0.82, 0.48, 1.0, 1.0),
		"boss": &"ruptura_lilas",
		"inimigos": [
			[&"melee", 2.0], [&"investida", 1.8], [&"tanque", 1.2],
			[&"seguidor", 1.1]
		]
	}
}


static func obter(id: StringName) -> Dictionary:
	return DADOS.get(id, DADOS[&"vazio_inicial"])


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
