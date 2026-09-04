extends RefCounted
class_name MonthlyCatalog


const ICONE := "res://Habilidades/Icones/monthly_cristal.svg"

static func ativos() -> Array[Dictionary]:
	return [
	_item(&"p01_ovo_surpresa", "OVO SURPRESA", "O ovo anuncia pela cor se chocará um drone, uma cura ou uma explosão.", 0, Color("ffd45a"), "ABR • PÁSCOA", [3, 3, 3], &"primeiro_brilho", "A renovação e as cores da Páscoa viram uma escolha rápida em combate.", "res://Habilidades/monthly_p01.tres"),
	_item(&"p02_clone_enganador", "CLONE ENGANADOR", "Cria um eco da nave que repete sua direção e dispara uma cópia atrasada.", 2800, Color("ff62ce"), "ABR • MENTIRA", [3, 4, 3], &"", "Uma brincadeira visual inspirada no Dia da Mentira.", "res://Habilidades/monthly_p02.tres"),
	_item(&"p03_renascimento", "RENASCIMENTO", "Planta uma semente de retorno. Se o casco cair, você renasce nela uma vez.", 5200, Color("52ff91"), "JUL • VERDE", [4, 5, 2], &"", "Verde representa recomeço, cuidado e crescimento.", "res://Habilidades/monthly_p03.tres"),
	_item(&"p04_espirito_protetor", "ESPÍRITO PROTETOR", "Invoca um guardião que intercepta tiros e responde com uma rajada dourada.", 0, Color("ffd65c"), "AGO • PROTEÇÃO", [3, 5, 2], &"boss_sentinela", "Proteção presente na campanha do Agosto Dourado.", "res://Habilidades/monthly_p04.tres"),
	_item(&"p05_florescimento", "FLORESCIMENTO", "Raízes prendem inimigos à frente e desabrocham em pétalas ofensivas.", 0, Color("ff68ae"), "SET • PRIMAVERA", [5, 4, 2], &"boss_florescimento", "A primavera vira movimento, raiz e floração.", "res://Habilidades/monthly_p05.tres"),
	_item(&"p06_rosa_espinhosa", "ROSA ESPINHOSA", "Abre uma janela curta de contra-ataque: o próximo dano explode em espinhos.", 0, Color("e578ff"), "AGO • LILÁS", [5, 2, 3], &"boss_ruptura", "Uma defesa ativa que transforma ruptura em reação.", "res://Habilidades/monthly_p06.tres"),
	_item(&"p07_forma_fantasma", "FORMA FANTASMA", "Fica intangível, acelera e deixa ecos que explodem depois.", 4700, Color("a978ff"), "OUT • HALLOWEEN", [4, 4, 2], &"", "Fantasmas e o imaginário do Halloween em movimento neon.", "res://Habilidades/monthly_p07.tres"),
	_item(&"p08_presente_misterioso", "PRESENTE MISTERIOSO", "Abre um presente aleatório de ataque, defesa ou controle; a fita denuncia o tipo.", 3200, Color("ff4c61"), "DEZ • NATAL", [3, 3, 3], &"", "Um presente legível antes de ser aberto, sem depender apenas da sorte.", "res://Habilidades/monthly_p08.tres"),
	_item(&"p09_recomeco", "RECOMEÇO", "Limpa efeitos negativos e repete seus disparos recentes como fogos de artifício.", 0, Color("f5f6ff"), "JAN • ANO NOVO", [4, 4, 2], &"jogo_zerado", "O fim do ciclo abre um novo começo.", "res://Habilidades/monthly_p09.tres"),
	_item(&"p10_laco_uniao", "LAÇO DA UNIÃO", "Liga dois inimigos; parte do dano sofrido por um ecoa no outro.", 4000, Color("ff5b8d"), "JUN • VERMELHO", [4, 5, 2], &"", "Conexão, cuidado e responsabilidade compartilhada.", "res://Habilidades/monthly_p10.tres"),
	_item(&"p11_imaginacao", "IMAGINAÇÃO SEM LIMITES", "Transforma temporariamente o tiro em um brinquedo cromático imprevisível.", 3600, Color("45dfff"), "OUT • CRIANÇAS", [4, 3, 3], &"", "Formas simples e lúdicas celebram a infância.", "res://Habilidades/monthly_p11.tres"),
	_item(&"p12_furia_natureza", "FÚRIA DA NATUREZA", "Ergue raízes, rochas e cristais em sequência na direção da mira.", 5400, Color("6ee65b"), "ABR • TERRA", [5, 3, 2], &"", "O planeta responde em camadas: solo, raiz e cristal.", "res://Habilidades/monthly_p12.tres"),
	_item(&"p13_onda_gigante", "ONDA GIGANTE", "Uma onda larga apaga projéteis pequenos, empurra inimigos e deixa correnteza.", 4300, Color("36cfff"), "MAR • ÁGUA", [4, 4, 2], &"", "Água como força, movimento e preservação.", "res://Habilidades/monthly_p13.tres"),
	_item(&"p14_tempestade_verde", "TEMPESTADE VERDE", "Folhas orbitam a nave e são lançadas em leque na próxima ativação.", 3900, Color("48f49a"), "JUN • AMBIENTE", [4, 5, 2], &"", "Uma pequena floresta defensiva que depois vira rajada.", "res://Habilidades/monthly_p14.tres"),
	_item(&"p15_determinacao", "DETERMINAÇÃO INABALÁVEL", "Marca ameaças próximas e libera proteção com uma explosão concentrada.", 0, Color("d879ff"), "MAR • MULHERES", [5, 4, 1], &"constelacao_1000", "Força e autonomia representadas por pressão seguida de resposta.", "res://Habilidades/monthly_p15.tres"),
]

static func armas() -> Array[Dictionary]:
	return [
	_item(&"a01_espingarda_lua_rosa", "ESPINGARDA LUA ROSA", "Sete pétalas em cone. Devastadora perto, dispersa longe.", 2500, Color("ff7eb7"), "ABR • LUA ROSA", [5, 2, 4]),
	_item(&"a02_rifle_cacador", "RIFLE DO CAÇADOR", "Segure para carregar uma linha de precisão perfurante.", 4200, Color("ff9a45"), "OUT • LUA DO CAÇADOR", [5, 4, 1]),
	_item(&"a03_alcateia_misseis", "ALCATEIA DE MÍSSEIS", "Três mísseis inteligentes cercam o alvo por ângulos diferentes.", 4600, Color("b8d7ff"), "JAN • LUA DO LOBO", [4, 3, 2]),
	_item(&"a04_canhao_esturjao", "CANHÃO DO ESTURJÃO", "Projétil pesado, carregável, ondulante e perfurante.", 5100, Color("54c6ff"), "AGO • LUA DO ESTURJÃO", [5, 3, 1]),
	_item(&"a05_minas_castor", "MINAS DO CASTOR", "Solta até três minas atrás da nave; explodem por proximidade.", 0, Color("d79d63"), "NOV • LUA DO CASTOR", [5, 5, 2], &"constelacao_50"),
	_item(&"a06_feixe_perielio", "FEIXE DO PERIÉLIO", "Feixe contínuo que esquenta e causa mais dano a curta distância.", 0, Color("ffcf45"), "JAN • PERIÉLIO", [5, 3, 2], &"boss_sizigia"),
	_item(&"a07_foice_colheita", "FOICE DA COLHEITA", "Crescente bumerangue que causa dano na ida e na volta.", 3900, Color("ffb34d"), "SET • COLHEITA", [4, 4, 3]),
	_item(&"a08_torpedo_subterraneo", "TORPEDO SUBTERRÂNEO", "Some no solo e emerge sob o inimigo marcado.", 4400, Color("8ae878"), "MAR • LUA DO VERME", [5, 3, 2]),
	_item(&"a09_morteiro_fogueira", "MORTEIRO DA FOGUEIRA", "Brasas lentas explodem e deixam uma zona curta de fogo.", 4300, Color("ff6f32"), "JUN • FOGUEIRA", [5, 4, 1]),
	_item(&"a10_rajada_morango", "RAJADA DE MORANGO", "Rajada em cachos que se divide em sementes no impacto.", 3500, Color("ff405f"), "JUN • LUA DE MORANGO", [4, 3, 4]),
	_item(&"a11_projetor_nevasca", "PROJETOR DA NEVASCA", "Cone de flocos; impactos seguidos desaceleram o alvo.", 3800, Color("c4efff"), "FEV • LUA DA NEVE", [3, 5, 4]),
	_item(&"a12_jardim_orbital", "JARDIM ORBITAL", "As pétalas orbitam primeiro e atacam juntas depois.", 0, Color("ff67b3"), "SET • FLORES", [4, 5, 2], &"boss_florescimento"),
	_item(&"a13_canhao_lua_fria", "CANHÃO DA LUA FRIA", "Orbe congelado captura tiros pequenos e estilhaça ao atingir.", 0, Color("90caff"), "DEZ • LUA FRIA", [5, 4, 1], &"boss_sizigia"),
]

static func naves() -> Array[Dictionary]:
	return [
	_item(&"n01_reflexos_rapidos", "REFLEXOS RÁPIDOS", "Quase-colisões carregam uma curva evasiva instantânea.", 0, Color("ffe567"), "SET • PREVENÇÃO", [2, 4, 5], &"constelacao_10"),
	_item(&"n02_luz_vital", "LUZ VITAL", "Experiência enche um halo que cura e concede escudo.", 3000, Color("ffd95d"), "SET • VIDA", [3, 5, 3]),
	_item(&"n03_rede_apoio", "REDE DE APOIO", "Após sofrer dano, alcançar um ponto seguro concede proteção.", 3200, Color("f4d34e"), "SET • CUIDADO", [2, 5, 4]),
	_item(&"n04_armadura_aco", "ARMADURA DE AÇO", "Placas frontais reduzem dano quando você encara o perigo.", 0, Color("d89bff"), "AGO • LILÁS", [1, 5, 2], &"boss_ruptura"),
	_item(&"n05_reserva_solidaria", "RESERVA SOLIDÁRIA", "Cura excedente vira células orbitais consumidas ao receber dano.", 0, Color("54f2a6"), "JUN • SOLIDARIEDADE", [2, 5, 3], &"boss_pet0"),
	_item(&"n06_scanner_preventivo", "SCANNER PREVENTIVO", "Destaca projéteis que seguem rota de colisão com a nave.", 2800, Color("53e8ff"), "SET • PREVENÇÃO", [1, 4, 5]),
	_item(&"n07_propulsor_janus", "PROPULSOR DE DUAS FACES", "Acelerar protege a frente; dar ré protege a traseira.", 3700, Color("f6d374"), "JAN • JANUS", [3, 4, 4]),
	_item(&"n08_motor_maia", "MOTOR DO CRESCIMENTO", "Viajar sem colidir evolui o motor em três estágios.", 4100, Color("76f187"), "MAI • MAIA", [3, 5, 4]),
	_item(&"n09_familia_satelites", "FAMÍLIA DE SATÉLITES", "Satélites ligados absorvem impactos e mudam de formação.", 0, Color("ffd45d"), "AGO • REDE", [3, 5, 2], &"boss_sentinela"),
	_item(&"n10_chassi_equinocio", "CHASSI DO EQUINÓCIO", "Cada habilidade alterna entre ataque solar e defesa lunar.", 0, Color("d88cff"), "MAR/SET • EQUINÓCIO", [4, 4, 3], &"bosses_5"),
]

static func upgrades() -> Array[Dictionary]:
	return [
	_item(&"u01_alcateia_lunar", "ALCATEIA LUNAR", "A habilidade cria duas cópias menores em direções laterais.", 0, Color("dcecff"), "JAN • LUA DO LOBO", [4, 3, 3], &"boss_sizigia"),
	_item(&"u02_cobertura_neve", "COBERTURA DE NEVE", "A habilidade deixa uma área que desacelera inimigos.", 0, Color("c9efff"), "FEV • LUA DA NEVE", [2, 5, 3], &"bosses_1"),
	_item(&"u03_retorno_subterraneo", "RETORNO SUBTERRÂNEO", "A habilidade se repete sob o inimigo mais próximo após um atraso.", 0, Color("a7e887"), "MAR • LUA DO VERME", [4, 3, 2], &"constelacao_50"),
	_item(&"u04_floracao_rosa", "FLORAÇÃO ROSA", "A habilidade termina lançando uma coroa radial de pétalas.", 0, Color("ff89bd"), "ABR • LUA ROSA", [4, 3, 3], &"boss_florescimento"),
	_item(&"u05_jardim_crescente", "JARDIM CRESCENTE", "Inimigos atingidos recebem flores que desabrocham no fim.", 0, Color("ff79b2"), "MAI • LUA DAS FLORES", [4, 4, 2], &"boss_florescimento"),
	_item(&"u06_sementes_vermelhas", "SEMENTES VERMELHAS", "Acertos guardam sementes que fortalecem a próxima ativação.", 0, Color("ff4f66"), "JUN • LUA DE MORANGO", [5, 4, 2], &"bosses_3"),
	_item(&"u07_galhos_lunares", "GALHOS LUNARES", "A direção principal se ramifica em dois ângulos secundários.", 0, Color("c48c5f"), "JUL • LUA DOS CERVOS", [4, 3, 3], &"constelacao_250"),
	_item(&"u08_corrente_esturjao", "CORRENTE DO ESTURJÃO", "Projéteis da habilidade ondulam e atravessam um alvo extra.", 0, Color("5ac7ff"), "AGO • LUA DO ESTURJÃO", [5, 3, 2], &"boss_sizigia"),
	_item(&"u09_colheita_cromatica", "COLHEITA CROMÁTICA", "A ativação puxa experiência e a converte em projéteis orbitais.", 0, Color("ffc35c"), "SET • LUA DA COLHEITA", [3, 5, 3], &"constelacao_250"),
	_item(&"u10_marca_cacador", "MARCA DO CAÇADOR", "A habilidade procura o inimigo mais resistente e concentra fogo nele.", 0, Color("ff9852"), "OUT • LUA DO CAÇADOR", [5, 2, 3], &"boss_sizigia"),
	_item(&"u11_barragem_castor", "BARRAGEM DO CASTOR", "Ergue uma barreira temporária no lado oposto ao movimento.", 0, Color("d99c63"), "NOV • LUA DO CASTOR", [2, 5, 2], &"constelacao_1000"),
	_item(&"u12_noite_congelada", "NOITE CONGELADA", "Projéteis inimigos alcançados pela habilidade congelam e se desfazem.", 0, Color("8fc7ff"), "DEZ • LUA FRIA", [3, 5, 2], &"boss_sizigia"),
]


static func _item(
	id: StringName, nome: String, descricao: String, preco: int, cor: Color,
	raridade: String, stats: Array, conquista: StringName = &"",
	contexto: String = "", caminho: String = ""
) -> Dictionary:
	return {
		"id": id, "nome": nome, "descricao": descricao, "preco": preco,
		"cor": cor, "raridade": raridade, "stats": stats,
		"conquista": conquista, "contexto": contexto,
		"caminho": caminho, "icone": ICONE,
	}


static func categoria(indice: int) -> Array[Dictionary]:
	match indice:
		0: return ativos()
		1: return armas()
		2: return naves()
		3: return upgrades()
	return []


static func encontrar(id: StringName) -> Dictionary:
	for categoria_itens in [ativos(), armas(), naves(), upgrades()]:
		for item in categoria_itens:
			if item["id"] == id:
				return item
	return {}
