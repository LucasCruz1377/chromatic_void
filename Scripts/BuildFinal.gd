extends Control

const COLUNAS := 5
const CELULA := Vector2(36, 42)
const MARGEM := Vector2(2, 2)
const COR_VAZIA := Color("#566073")

var itens: Array[Dictionary] = []


func capturar(jogador: Player) -> void:
	itens.clear()
	if is_instance_valid(jogador):
		adicionar_catalogo(jogador.modelo_visual_nave, "SKIN")
		if jogador.arma_monthly.is_empty():
			adicionar("ARMA", "ARMA PADRÃO", preload("res://Assets/UpgradeDano.png"), Color("#f4aa52"))
		else:
			adicionar_catalogo(jogador.arma_monthly, "ARMA")
		var habilidade := jogador.HabilidadeEquipada
		if habilidade:
			adicionar("HABILIDADE", habilidade.Nome.to_upper(), habilidade.Icone, Color("#c5a9ff"))
		else:
			adicionar("HABILIDADE", "SEM EQUIPAMENTO", null, COR_VAZIA)
		adicionar_catalogo(jogador.mutacao_habilidade, "UPGRADE")
		adicionar_catalogo(jogador.modulo_nave, "PASSIVA DA NAVE")
		for id in jogador.niveis_upgrades:
			var nivel := int(jogador.niveis_upgrades[id])
			if nivel > 0:
				var dados := UpgradeData.obter(id, habilidade)
				adicionar_dados("MELHORIAS", dados, str(id), nivel)
	var linhas := ceili(float(itens.size()) / COLUNAS)
	custom_minimum_size = MARGEM * 2 + Vector2(
		CELULA.x * (COLUNAS + 0.5),
		CELULA.y * (1.0 + 0.75 * maxi(0, linhas - 1))
	)
	queue_redraw()


func adicionar_catalogo(id: StringName, categoria: String) -> void:
	var dados := MonthlyCatalog.encontrar(id) if not id.is_empty() else {}
	adicionar_dados(categoria, dados, "SEM EQUIPAMENTO" if id.is_empty() else str(id))


func adicionar_dados(categoria: String, dados: Dictionary, nome_padrao: String, nivel := 0) -> void:
	var caminho := str(dados.get("icone", ""))
	var icone := load(caminho) as Texture2D if not caminho.is_empty() and ResourceLoader.exists(caminho) else null
	# Os modelos da loja têm margens transparentes diferentes em torno da nave.
	if categoria == "SKIN" and icone:
		var imagem := icone.get_image()
		if imagem:
			var recorte := AtlasTexture.new()
			recorte.atlas = icone
			recorte.region = imagem.get_used_rect()
			icone = recorte
	adicionar(categoria, dados.get("nome", nome_padrao), icone, dados.get("cor", COR_VAZIA), nivel)


func adicionar(categoria: String, nome_item: String, icone: Texture2D, cor: Color, nivel := 0) -> void:
	itens.append({"categoria": categoria, "nome": nome_item, "icone": icone, "cor": cor, "nivel": nivel})


func origem_celula(indice: int) -> Vector2:
	var linha := floori(float(indice) / COLUNAS)
	return MARGEM + CELULA * Vector2(indice % COLUNAS + (linha % 2) * 0.5, linha * 0.75)


func _draw() -> void:
	var vertices := UpgradeCardNova.vertices_hexagono(CELULA)
	var fonte := ThemeDB.fallback_font
	for i in itens.size():
		var dados := itens[i]
		var origem := origem_celula(i)
		var pontos := Transform2D(0.0, origem) * vertices
		var cor: Color = dados.cor
		draw_colored_polygon(pontos, Color("#0e1b2b").lerp(cor, 0.09))
		pontos.append(pontos[0])
		draw_polyline(pontos, Color(cor, 0.8), 1.0, true)
		var centro := origem + CELULA * 0.5
		var icone: Texture2D = dados.icone
		if icone:
			var tamanho := icone.get_size() * (28.0 / maxf(icone.get_width(), icone.get_height()))
			draw_texture_rect(icone, Rect2(centro - tamanho * 0.5, tamanho), false)
		else:
			draw_line(centro - Vector2(4, 0), centro + Vector2(4, 0), cor, 1.5, true)
		if dados.nivel > 1:
			var texto := "×%d" % int(dados.nivel)
			var pos := centro + Vector2(-fonte.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x * 0.5, 13)
			draw_string_outline(fonte, pos, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, 3, Color("#0a121c"))
			draw_string(fonte, pos, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)


func _get_tooltip(at_position: Vector2) -> String:
	var vertices := UpgradeCardNova.vertices_hexagono(CELULA)
	for i in itens.size():
		if Geometry2D.is_point_in_polygon(at_position - origem_celula(i), vertices):
			var item := itens[i]
			var quantidade := " ×%d" % int(item.nivel) if item.nivel > 1 else ""
			return "%s · %s%s" % [tr(item.categoria), tr(item.nome), quantidade]
	return ""
