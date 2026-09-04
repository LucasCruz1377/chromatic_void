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
var botoes_toque: Dictionary = {}
var dedos_acoes: Dictionary = {}
var ultimo_tamanho_interface := Vector2.ZERO


func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	superficie = VisualControlesMobile.new()
	superficie.controlador = self
	add_child(superficie)
	_criar_botoes_toque()
	get_viewport().size_changed.connect(_on_tamanho_viewport_alterado)
	set_process_input(true)
	_atualizar_visibilidade()
	call_deferred("_atualizar_layout")


func configurar(nova_area: Node, novo_jogador: Node, forcar := false) -> void:
	area_batalha = nova_area
	jogador = novo_jogador
	forcar_exibicao = forcar
	_atualizar_visibilidade()


func _process(_delta: float) -> void:
	_atualizar_visibilidade()
	var tamanho_atual := _obter_tamanho_interface()
	if not tamanho_atual.is_equal_approx(ultimo_tamanho_interface):
		_atualizar_layout()
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
	var tamanho := _obter_tamanho_interface()
	# Fallback explícito: além do TouchScreenButton nativo, converte o toque em
	# ação aqui. Isso mantém os comandos funcionais até em aparelhos/runtimes
	# que não encaminham o evento ao nó nativo depois do stretch da tela.
	for dados in _obter_botoes(tamanho):
		var centro_botao: Vector2 = dados["centro"]
		var raio_botao: float = dados["raio"]
		if posicao.distance_to(centro_botao) <= raio_botao * 1.22:
			var acao: StringName = dados["acao"]
			dedos_acoes[indice] = acao
			Input.action_press(acao)
			_on_botao_toque_pressionado()
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
	var raio := _raio_analogico(_obter_tamanho_interface())
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
		if acabou or escolhendo:
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
	for acao in botoes_toque:
		Input.action_release(StringName(acao))
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
		var botao := botoes_toque.get(acao) as TouchScreenButton
		var ativo := (
			(is_instance_valid(botao) and botao.is_pressed())
			or acao in dedos_acoes.values()
		)
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


func quantidade_botoes_toque_para_teste() -> int:
	return botoes_toque.size()


func _criar_botoes_toque() -> void:
	for dados in _obter_botoes(Vector2(960.0, 540.0)):
		var acao: StringName = dados["acao"]
		var botao := TouchScreenButton.new()
		botao.name = "Botao" + str(acao).capitalize().replace(" ", "")
		botao.action = acao
		botao.passby_press = true
		botao.shape_centered = true
		botao.shape_visible = false
		var forma := CircleShape2D.new()
		forma.radius = float(dados["raio"]) * 1.18
		botao.shape = forma
		botao.pressed.connect(_on_botao_toque_pressionado)
		add_child(botao)
		botoes_toque[acao] = botao


func _atualizar_layout() -> void:
	var tamanho := _obter_tamanho_interface()
	if tamanho.x <= 1.0 or tamanho.y <= 1.0:
		return
	ultimo_tamanho_interface = tamanho
	for dados in _obter_botoes(tamanho):
		var acao: StringName = dados["acao"]
		var botao := botoes_toque.get(acao) as TouchScreenButton
		if not is_instance_valid(botao):
			continue
		botao.position = dados["centro"]
		var forma := botao.shape as CircleShape2D
		if is_instance_valid(forma):
			forma.radius = float(dados["raio"]) * 1.18
	if is_instance_valid(superficie):
		superficie.queue_redraw()


func _obter_tamanho_interface() -> Vector2:
	if is_instance_valid(superficie) and superficie.size.x > 1.0 and superficie.size.y > 1.0:
		return superficie.size
	return get_viewport().get_visible_rect().size


func _on_tamanho_viewport_alterado() -> void:
	call_deferred("_atualizar_layout")


func _on_botao_toque_pressionado() -> void:
	Global.ultimo_dispositivo = &"toque"
	if Global.vibracao:
		Input.vibrate_handheld(18)


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
