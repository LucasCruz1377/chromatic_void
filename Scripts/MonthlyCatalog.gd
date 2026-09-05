extends RefCounted
class_name MonthlyCatalog


const ICONE := "res://Habilidades/Icones/monthly_cristal.svg"
const ICONE_NAVE := "res://UI/nave_padrao_preview.svg"
const ICONE_EM_BREVE := "res://UI/personalizacao_em_breve.svg"
const ICONE_COR := "res://UI/cor_nave_preview.svg"

# Uma única coleção reúne as luas cheias populares apresentadas pelo Astro e
# pelos cards do Monthly Colors. Assim não existem dezenas de "luas" repetidas
# em armas diferentes: são exatamente doze, uma para cada mês.
const LUAS_ANUAIS := [
	"LUA DO LOBO", "LUA DA NEVE", "LUA DO VERME", "LUA ROSA",
	"LUA DAS FLORES", "LUA DE MORANGO", "LUA DOS CERVOS",
	"LUA DO ESTURJÃO", "LUA DA COLHEITA", "LUA DO CAÇADOR",
	"LUA DO CASTOR", "LUA FRIA",
]

# Lista positiva das informações presentes nos cards expandidos e páginas do
# Monthly Colors usadas pelo jogo. Categorias de combate só exibem itens desta
# tabela; assim uma ideia nova não entra na loja apenas por ter um nome bonito.
const FONTES_SITE: Dictionary = {
	&"p01_ovo_surpresa": "Abril • Páscoa e renovação",
	&"p02_clone_enganador": "Abril • Dia da Mentira",
	&"p03_renascimento": "Julho Verde • cuidado e recomeço",
	&"p04_espirito_protetor": "Agosto Dourado • proteção e cuidado",
	&"p05_florescimento": "Setembro • primavera e floração",
	&"p06_rosa_espinhosa": "Agosto Lilás • enfrentamento à violência",
	&"p07_forma_fantasma": "Outubro • Halloween",
	&"p08_presente_misterioso": "Dezembro • Natal",
	&"p09_recomeco": "Janeiro • Ano-Novo",
	&"p10_laco_uniao": "Junho Vermelho • doação de sangue",
	&"p11_imaginacao": "Outubro • Dia das Crianças",
	&"p12_furia_natureza": "Abril • Dia da Terra",
	&"p13_onda_gigante": "Março • Dia Mundial da Água",
	&"p14_tempestade_verde": "Junho Verde • meio ambiente",
	&"p15_determinacao": "Março • Dia Internacional da Mulher",
	&"a01_espingarda_lua_rosa": "Setembro • primavera e floração",
	&"a03_alcateia_misseis": "Janeiro • fogos e Ano-Novo",
	&"a04_canhao_esturjao": "Agosto • Lua do Esturjão",
	&"a05_minas_castor": "Maio Amarelo • segurança no trânsito",
	&"a06_feixe_perielio": "Janeiro • periélio",
	&"a07_foice_colheita": "Setembro • Lua da Colheita",
	&"a08_torpedo_subterraneo": "Abril • Dia da Terra",
	&"a09_morteiro_fogueira": "Junho • festas juninas",
	&"a10_rajada_morango": "Junho • Lua de Morango",
	&"a11_projetor_nevasca": "Fevereiro Roxo • conscientização",
	&"a12_jardim_orbital": "Setembro • primavera e flores",
	&"a13_canhao_lua_fria": "Dezembro • solstício e Lua Fria",
	&"n01_reflexos_rapidos": "Maio Amarelo • prevenção de acidentes",
	&"n02_luz_vital": "Agosto Dourado • proteção à vida",
	&"n03_rede_apoio": "Setembro Amarelo • rede de apoio",
	&"n04_armadura_aco": "Agosto Lilás • proteção",
	&"n05_reserva_solidaria": "Junho Vermelho • solidariedade",
	&"n06_scanner_preventivo": "Outubro Rosa • prevenção",
	&"n07_propulsor_janus": "Janeiro • origem do nome e Janus",
	&"n08_motor_maia": "Maio • origem do nome e Maia",
	&"n09_familia_satelites": "Maio • Dia da Família",
	&"n10_chassi_equinocio": "Março e setembro • equinócios",
	&"u01_alcateia_lunar": "Janeiro • Lua do Lobo",
	&"u02_cobertura_neve": "Fevereiro • Lua da Neve",
	&"u03_retorno_subterraneo": "Março • Lua do Verme",
	&"u04_floracao_rosa": "Abril • Lua Rosa",
	&"u05_jardim_crescente": "Maio • Lua das Flores",
	&"u06_sementes_vermelhas": "Junho • Lua de Morango",
	&"u07_galhos_lunares": "Julho • Lua dos Cervos",
	&"u08_corrente_esturjao": "Agosto • Lua do Esturjão",
	&"u09_colheita_cromatica": "Setembro • Lua da Colheita",
	&"u10_marca_cacador": "Outubro • Lua do Caçador",
	&"u11_barragem_castor": "Novembro • Lua do Castor",
	&"u12_noite_congelada": "Dezembro • Lua Fria",
}

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
	# Os IDs antigos permanecem para que equipamentos já comprados continuem
	# funcionando por migração, mas somente a arma consolidada aparece na loja.
	_item(&"a01_espingarda_lua_rosa", "LEQUE DA PRIMAVERA", "Espingarda de sete pétalas: curto alcance, baixa cadência e alto dano de perto.", 2500, Color("ff7eb7"), "SET • PRIMAVERA", [5, 2, 4], &"", "A chegada da primavera e sua floração, apresentadas no site, viram uma rajada curta e colorida."),
	_item(&"a03_alcateia_misseis", "FOGOS DO RECOMEÇO", "Três foguetes inteligentes cercam o alvo por ângulos diferentes.", 4600, Color("e7edff"), "JAN • ANO NOVO", [4, 3, 2], &"", "Fogos de Ano Novo representam o encerramento de um ciclo e o começo do próximo."),
	_item(&"a04_canhao_esturjao", "CANHÃO DO ESTURJÃO", "Segure para carregar um único disparo ondulante, pesado e perfurante.", 5100, Color("54c6ff"), "AGO • LUA DO ESTURJÃO", [5, 3, 1], &"", "A Lua do Esturjão, apresentada no card de agosto, inspira um disparo profundo que avança como correnteza."),
	_item(&"a05_minas_castor", "SINALIZADORES AMARELOS", "Instala até quatro sinais que explodem após 5 segundos. Melhorias liberam pavio curto, sensor ou comando remoto.", 0, Color("ffd447"), "MAI • MAIO AMARELO", [5, 5, 3], &"constelacao_50", "O Maio Amarelo chama atenção para segurança e prevenção; o sinalizador usa contagem visível antes do perigo."),
	_item(&"a06_feixe_perielio", "FEIXE DO PERIÉLIO", "Feixe contínuo que esquenta e causa mais dano a curta distância.", 0, Color("ffcf45"), "JAN • PERIÉLIO", [5, 3, 2], &"boss_sizigia"),
	_item(&"a07_foice_colheita", "ARCO DA COLHEITA", "Crescente bumerangue que causa dano na ida e na volta.", 3900, Color("ffb34d"), "SET • COLHEITA", [4, 4, 3]),
	_item(&"a08_torpedo_subterraneo", "RAIZ DO DIA DA TERRA", "Some no solo e emerge sob o inimigo marcado.", 4400, Color("8ae878"), "ABR • DIA DA TERRA", [5, 3, 2], &"", "O Dia da Terra inspira um ataque que viaja sob o solo antes de reaparecer."),
	_item(&"a09_morteiro_fogueira", "MORTEIRO DA FOGUEIRA", "Brasas lentas explodem e deixam uma zona curta de fogo.", 4300, Color("ff6f32"), "JUN • FOGUEIRA", [5, 4, 1]),
	_item(&"a10_rajada_morango", "SEMENTES VERMELHAS", "Rajada em cachos que se divide em sementes no impacto.", 3500, Color("ff405f"), "JUN • VERMELHO", [4, 3, 4], &"", "O Junho Vermelho ganha uma rajada que se espalha e mantém o combate em movimento."),
	_item(&"a11_projetor_nevasca", "PROJETOR FEVEREIRO ROXO", "Cone violeta; impactos seguidos desaceleram o alvo.", 3800, Color("bd8cff"), "FEV • ROXO", [3, 5, 4], &"", "Uma névoa violeta transforma a cor de conscientização de fevereiro em controle de espaço."),
	_item(&"a12_jardim_orbital", "JARDIM ORBITAL", "As pétalas orbitam primeiro e atacam juntas depois.", 0, Color("ff67b3"), "SET • FLORES", [4, 5, 2], &"boss_florescimento"),
	_item(&"a13_canhao_lua_fria", "CANHÃO DO SOLSTÍCIO", "Orbe congelado captura tiros pequenos e estilhaça ao atingir.", 0, Color("90caff"), "DEZ • SOLSTÍCIO", [5, 4, 1], &"boss_sizigia", "As noites longas do solstício de dezembro viram um projétil frio e defensivo."),
	]

static func naves() -> Array[Dictionary]:
	return [
	_item(&"n01_reflexos_rapidos", "REFLEXOS RÁPIDOS", "Quase-colisões carregam uma curva evasiva instantânea.", 0, Color("ffe567"), "MAI • AMARELO", [2, 4, 5], &"constelacao_10"),
	_item(&"n02_luz_vital", "LUZ VITAL", "Experiência enche um halo que cura e concede escudo.", 3000, Color("ffd95d"), "AGO • DOURADO", [3, 5, 3]),
	_item(&"n03_rede_apoio", "REDE DE APOIO", "Após sofrer dano, alcançar um ponto seguro concede proteção.", 3200, Color("f4d34e"), "SET • CUIDADO", [2, 5, 4]),
	_item(&"n04_armadura_aco", "ARMADURA DE AÇO", "Placas frontais reduzem dano quando você encara o perigo.", 0, Color("d89bff"), "AGO • LILÁS", [1, 5, 2], &"boss_ruptura"),
	_item(&"n05_reserva_solidaria", "RESERVA SOLIDÁRIA", "Cura excedente vira células orbitais consumidas ao receber dano.", 0, Color("54f2a6"), "JUN • SOLIDARIEDADE", [2, 5, 3], &"boss_pet0"),
	_item(&"n06_scanner_preventivo", "SCANNER PREVENTIVO", "Destaca projéteis que seguem rota de colisão com a nave.", 2800, Color("53e8ff"), "OUT • ROSA", [1, 4, 5]),
	_item(&"n07_propulsor_janus", "PROPULSOR DE DUAS FACES", "Acelerar protege a frente; dar ré protege a traseira.", 3700, Color("f6d374"), "JAN • JANUS", [3, 4, 4]),
	_item(&"n08_motor_maia", "MOTOR DO CRESCIMENTO", "Viajar sem colidir evolui o motor em três estágios.", 4100, Color("76f187"), "MAI • MAIA", [3, 5, 4]),
	_item(&"n09_familia_satelites", "FAMÍLIA DE SATÉLITES", "Satélites ligados absorvem impactos e mudam de formação.", 0, Color("ffd45d"), "MAI • FAMÍLIA", [3, 5, 2], &"boss_sentinela"),
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


static func personalizacao() -> Array[Dictionary]:
	return [
		{
			"id": &"c01_modelo_padrao", "nome": "NAVE PADRÃO",
			"descricao": "O modelo clássico do Chromatic Void. Disponível gratuitamente para todos os pilotos.",
			"preco": 0, "cor": Color("aaff53"), "raridade": "MODELO • PADRÃO",
			"stats": [3, 3, 3], "conquista": &"", "contexto": "O visual original da nave permanece selecionado por padrão.",
			"caminho": "", "icone": ICONE_NAVE, "em_breve": false,
			"grupo_personalizacao": &"modelo",
		},
		{
			"id": &"c02_asa_delta", "nome": "ASA DELTA",
			"descricao": "Uma variação triangular de três pontas, compacta e próxima da silhueta clássica.",
			"preco": 1600, "cor": Color("8beaff"), "raridade": "MODELO • DELTA",
			"stats": [3, 3, 3], "conquista": &"", "contexto": "Inspirada nas naves triangulares da referência, simplificada para o traço geométrico do jogo.",
			"caminho": "", "icone": "res://UI/nave_asa_delta.svg", "em_breve": false,
			"grupo_personalizacao": &"modelo",
		},
		{
			"id": &"c03_nucleo_orbital", "nome": "NÚCLEO ORBITAL",
			"descricao": "Asas curtas ao redor de um núcleo hexagonal, mantendo direção e leitura imediatas.",
			"preco": 2200, "cor": Color("c897ff"), "raridade": "MODELO • ORBITAL",
			"stats": [3, 3, 3], "conquista": &"", "contexto": "Reinterpreta o modelo triangular com núcleo circular visto na referência.",
			"caminho": "", "icone": "res://UI/nave_nucleo_orbital.svg", "em_breve": false,
			"grupo_personalizacao": &"modelo",
		},
		{
			"id": &"c04_dardo", "nome": "DARDO",
			"descricao": "Uma nave alongada, simples e estreita, com o mesmo volume visual do modelo padrão.",
			"preco": 1900, "cor": Color("ff77b8"), "raridade": "MODELO • DARDO",
			"stats": [3, 3, 3], "conquista": &"", "contexto": "Derivada das pequenas naves em forma de seta da referência.",
			"caminho": "", "icone": "res://UI/nave_dardo.svg", "em_breve": false,
			"grupo_personalizacao": &"modelo",
		},
		{
			"id": &"c05_interceptor", "nome": "INTERCEPTOR",
			"descricao": "Asas recuadas e nariz curto formam uma alternativa ágil sem mudar a jogabilidade.",
			"preco": 2500, "cor": Color("ffd36a"), "raridade": "MODELO • INTERCEPTOR",
			"stats": [3, 3, 3], "conquista": &"", "contexto": "Combina as asas curvas e pontudas mais próximas da nave padrão.",
			"caminho": "", "icone": "res://UI/nave_interceptor.svg", "em_breve": false,
			"grupo_personalizacao": &"modelo",
		},
		_cor(&"c10_verde_original", "VERDE ORIGINAL", 0, Color("8bff2a"), "A cor clássica do Chromatic Void."),
		_cor(&"c11_ciano", "CIANO", 650, Color("39dcff"), "Um brilho frio inspirado no vazio espacial."),
		_cor(&"c12_rosa", "ROSA", 650, Color("ff4fa3"), "Uma cor viva inspirada na primavera e no Outubro Rosa."),
		_cor(&"c13_violeta", "VIOLETA", 800, Color("b867ff"), "Um tom neon ligado às campanhas roxas do calendário."),
		_cor(&"c14_dourado", "DOURADO", 950, Color("ffd447"), "O brilho acolhedor associado ao Agosto Dourado."),
		_cor(&"c15_branco", "BRANCO LUNAR", 1100, Color("eaf7ff"), "Uma opção clara inspirada no céu e nas fases da Lua."),
		{
			"id": &"c20_rastros_em_breve", "nome": "RASTROS",
			"descricao": "Rastros cosméticos para o propulsor chegarão depois, sem alterar atributos da nave.",
			"preco": 0, "cor": Color("62ddff"), "raridade": "PROPULSOR • EM BREVE",
			"stats": [0, 0, 0], "conquista": &"", "contexto": "Os rastros futuros serão apenas visuais e não darão vantagem de combate.",
			"caminho": "", "icone": ICONE_EM_BREVE, "em_breve": true,
			"grupo_personalizacao": &"rastro",
		},
	]


static func _cor(
	id: StringName, nome: String, preco: int, cor: Color, contexto: String
) -> Dictionary:
	return {
		"id": id, "nome": nome, "descricao": "Troca a cor de todos os modelos de nave sem alterar seus atributos.",
		"preco": preco, "cor": cor, "raridade": "COR • PALETA",
		"stats": [3, 3, 3], "conquista": &"", "contexto": contexto,
		"caminho": "", "icone": ICONE_COR, "em_breve": false,
		"grupo_personalizacao": &"cor",
	}


static func _item(
	id: StringName, nome: String, descricao: String, preco: int, cor: Color,
	raridade: String, stats: Array, conquista: StringName = &"",
	contexto: String = "", caminho: String = ""
) -> Dictionary:
	var fonte_site := str(FONTES_SITE.get(id, ""))
	var contexto_final := contexto if not contexto.strip_edges().is_empty() else fonte_site
	return {
		"id": id, "nome": nome, "descricao": descricao, "preco": preco,
		"cor": cor, "raridade": raridade, "stats": stats,
		"conquista": conquista, "contexto": contexto_final,
		"caminho": caminho,
		"icone": "res://Habilidades/Icones/monthly/%s.svg" % String(id),
		"fonte_site": fonte_site,
	}


static func categoria(indice: int) -> Array[Dictionary]:
	match indice:
		0: return _somente_itens_do_site(ativos())
		1: return _somente_itens_do_site(armas())
		2: return _somente_itens_do_site(naves())
		3: return _somente_itens_do_site(upgrades())
		4: return personalizacao()
	return []


static func _somente_itens_do_site(itens: Array[Dictionary]) -> Array[Dictionary]:
	var validados: Array[Dictionary] = []
	for item in itens:
		if not str(item.get("fonte_site", "")).strip_edges().is_empty():
			validados.append(item)
	return validados


static func encontrar(id: StringName) -> Dictionary:
	for indice in range(5):
		for item in categoria(indice):
			if item["id"] == id:
				return item
	return {}
