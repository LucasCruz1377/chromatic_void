extends CanvasLayer
class_name ControlesMobile


const VisualControlesMobile = preload("res://Scripts/VisualControlesMobile.gd")

const COR_BASE := Color(0.08, 0.10, 0.22, 0.42)
const COR_BORDA := Color(0.32, 0.84, 1.0, 0.72)
const COR_ATIVO := Color(0.82, 0.34, 1.0, 0.82)

var area_batalha: Node
var jogador: Node
var forcar_exibicao := false
var superficie: Control
var dedo_analogico := -1
var centro_analogico := Vector2.ZERO
var direcao_analogico := Vector2.ZERO
var dedos_acoes: Dictionary = {}


func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	superficie = VisualControlesMobile.new()
	superficie.controlador = self
	add_child(superficie)
	set_process_input(true)
	_atualizar_visibilidade()


func configurar(nova_area: Node, novo_jogador: Node, forcar := false) -> void:
	area_batalha = nova_area
	jogador = novo_jogador
	forcar_exibicao = forcar
	_atualizar_visibilidade()


func _process(_delta: float) -> void:
	_atualizar_visibilidade()
	if visible and is_instance_valid(superficie):
		superficie.queue_redraw()


func _exit_tree() -> void:
	_liberar_todos_os_comandos()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch:
		var toque := event as InputEventScreenTouch
		if toque.pressed:
			_iniciar_toque(toque.index, toque.position)
		else:
			_finalizar_toque(toque.index)
	elif event is InputEventScreenDrag:
		var arrasto := event as InputEventScreenDrag
		if arrasto.index == dedo_analogico:
			_atualizar_analogico(arrasto.position)


func _iniciar_toque(indice: int, posicao: Vector2) -> void:
	var tamanho := get_viewport().get_visible_rect().size
	var dados_botoes := _obter_botoes(tamanho)
	for dados in dados_botoes:
		var centro: Vector2 = dados["centro"]
		var raio: float = dados["raio"]
		if posicao.distance_to(centro) <= raio * 1.22:
			var acao: StringName = dados["acao"]
			dedos_acoes[indice] = acao
			Input.action_press(acao)
			if Global.vibracao:
				Input.vibrate_handheld(18)
			_marcar_toque_como_usado()
			return

	var centro_esperado := _centro_analogico(tamanho)
	var raio_analogico := _raio_analogico(tamanho)
	if dedo_analogico < 0 and posicao.distance_to(centro_esperado) <= raio_analogico * 1.55:
		dedo_analogico = indice
		centro_analogico = centro_esperado
		_atualizar_analogico(posicao)
		_marcar_toque_como_usado()


func _finalizar_toque(indice: int) -> void:
	if indice == dedo_analogico:
		dedo_analogico = -1
		direcao_analogico = Vector2.ZERO
		Global.limpar_controle_toque()
		_marcar_toque_como_usado()
	if dedos_acoes.has(indice):
		var acao: StringName = dedos_acoes[indice]
		Input.action_release(acao)
		dedos_acoes.erase(indice)
		_marcar_toque_como_usado()


func _atualizar_analogico(posicao: Vector2) -> void:
	var raio := _raio_analogico(get_viewport().get_visible_rect().size)
	direcao_analogico = ((posicao - centro_analogico) / raio).limit_length(1.0)
	Global.definir_direcao_toque(direcao_analogico)
	if is_instance_valid(superficie):
		superficie.queue_redraw()


func _atualizar_visibilidade() -> void:
	var deve_mostrar := forcar_exibicao or Global.deve_exibir_controles_toque()
	if get_tree().paused:
		deve_mostrar = false
	if not is_instance_valid(jogador):
		deve_mostrar = false
	if is_instance_valid(area_batalha):
		var acabou: bool = bool(area_batalha.get("game_over"))
		var escolhendo: bool = bool(area_batalha.get("escolha_setor_ativa"))
		var em_tutorial: bool = bool(area_batalha.get("tutorial_ativo"))
		if acabou or escolhendo or em_tutorial:
			deve_mostrar = false
		var tela_upgrades := area_batalha.get_node_or_null("GUI/TelaUpgrades") as Control
		if is_instance_valid(tela_upgrades) and tela_upgrades.visible:
			deve_mostrar = false
	if visible and not deve_mostrar:
		_liberar_todos_os_comandos()
	visible = deve_mostrar


func _liberar_todos_os_comandos() -> void:
	if dedo_analogico >= 0 or Global.controle_toque_ativo:
		Global.limpar_controle_toque()
	dedo_analogico = -1
	direcao_analogico = Vector2.ZERO
	for valor in dedos_acoes.values():
		Input.action_release(valor as StringName)
	dedos_acoes.clear()


func desenhar_controles(alvo: Control) -> void:
	var tamanho := alvo.size
	var centro := _centro_analogico(tamanho)
	var raio := _raio_analogico(tamanho)
	alvo.draw_circle(centro, raio, COR_BASE)
	alvo.draw_arc(centro, raio, 0.0, TAU, 48, COR_BORDA, 3.0, true)
	var deslocamento := direcao_analogico * raio * 0.58
	alvo.draw_circle(centro + deslocamento, raio * 0.38, COR_ATIVO if dedo_analogico >= 0 else COR_BORDA)

	for dados in _obter_botoes(tamanho):
		var centro_botao: Vector2 = dados["centro"]
		var raio_botao: float = dados["raio"]
		var acao: StringName = dados["acao"]
		var ativo := acao in dedos_acoes.values()
		alvo.draw_circle(centro_botao, raio_botao, COR_ATIVO if ativo else COR_BASE)
		alvo.draw_arc(centro_botao, raio_botao, 0.0, TAU, 40, COR_BORDA, 3.0, true)
		var texto: String = dados["texto"]
		var tamanho_fonte: int = maxi(13, int(raio_botao * 0.34))
		var fonte := ThemeDB.fallback_font
		var medida := fonte.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho_fonte)
		alvo.draw_string(
			fonte,
			centro_botao + Vector2(-medida.x * 0.5, medida.y * 0.34),
			texto,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			tamanho_fonte,
			Color.WHITE
		)


func definir_analogico_para_teste(direcao: Vector2) -> void:
	direcao_analogico = direcao.limit_length(1.0)
	Global.definir_direcao_toque(direcao_analogico)


func pressionar_acao_para_teste(acao: StringName) -> void:
	Input.action_press(acao)


func liberar_acao_para_teste(acao: StringName) -> void:
	Input.action_release(acao)


func _centro_analogico(tamanho: Vector2) -> Vector2:
	return Vector2(tamanho.x * 0.14, tamanho.y * 0.78)


func _raio_analogico(tamanho: Vector2) -> float:
	return minf(tamanho.x, tamanho.y) * 0.13


func _obter_botoes(tamanho: Vector2) -> Array[Dictionary]:
	var unidade := minf(tamanho.x, tamanho.y)
	return [
		{
			"acao": &"atirar",
			"texto": "TIRO",
			"centro": Vector2(tamanho.x * 0.87, tamanho.y * 0.78),
			"raio": unidade * 0.105,
		},
		{
			"acao": &"Habilidade",
			"texto": "PODER",
			"centro": Vector2(tamanho.x * 0.74, tamanho.y * 0.85),
			"raio": unidade * 0.078,
		},
		{
			"acao": &"abrir_melhorias",
			"texto": "UP",
			"centro": Vector2(tamanho.x * 0.87, tamanho.y * 0.53),
			"raio": unidade * 0.065,
		},
		{
			"acao": &"pausar",
			"texto": "II",
			"centro": Vector2(tamanho.x * 0.94, tamanho.y * 0.10),
			"raio": unidade * 0.052,
		},
	]


func _marcar_toque_como_usado() -> void:
	if get_viewport():
		get_viewport().set_input_as_handled()
