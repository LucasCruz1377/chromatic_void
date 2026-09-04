extends CanvasLayer
class_name ControlesMobile


const VisualControlesMobile = preload("res://Scripts/VisualControlesMobile.gd")

const COR_BASE := Color(0.035, 0.06, 0.14, 0.48)
const COR_BORDA := Color(0.26, 0.78, 1.0, 0.74)
const COR_DETALHE := Color(0.48, 0.9, 1.0, 0.34)
const COR_ATIVO := Color(0.76, 0.28, 1.0, 0.88)

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
	if _tentar_abrir_melhorias_pelo_indicador(posicao):
		_marcar_toque_como_usado()
		return
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
	var raio_analogico := _raio_analogico(tamanho)
	var area_analogico := (
		posicao.x <= tamanho.x * 0.43
		and posicao.y >= tamanho.y * 0.48
	)
	if dedo_analogico < 0 and area_analogico:
		dedo_analogico = indice
		centro_analogico = Vector2(
			clampf(posicao.x, raio_analogico * 1.15, tamanho.x * 0.38),
			clampf(posicao.y, tamanho.y * 0.56, tamanho.y - raio_analogico * 1.15)
		)
		_atualizar_analogico(posicao)
		_marcar_toque_como_usado()


func _finalizar_toque(indice: int) -> void:
	if indice == dedo_analogico:
		dedo_analogico = -1
		centro_analogico = Vector2.ZERO
		direcao_analogico = Vector2.ZERO
		Global.limpar_controle_toque()
		if is_instance_valid(superficie):
			superficie.queue_redraw()
		_marcar_toque_como_usado()
	if dedos_acoes.has(indice):
		var acao: StringName = dedos_acoes[indice]
		Input.action_release(acao)
		dedos_acoes.erase(indice)
		if is_instance_valid(superficie):
			superficie.queue_redraw()
		_marcar_toque_como_usado()


func _atualizar_analogico(posicao: Vector2) -> void:
	var raio := _raio_analogico(_obter_tamanho_interface())
	direcao_analogico = ((posicao - centro_analogico) / raio).limit_length(1.0)
	Global.definir_direcao_toque(direcao_analogico)
	if is_instance_valid(superficie):
		superficie.queue_redraw()


func _atualizar_visibilidade() -> void:
	var visibilidade_anterior := visible
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
		if is_instance_valid(tela_upgrades):
			var menu_melhorias_aberto := false
			if tela_upgrades.has_method("esta_aberta"):
				menu_melhorias_aberto = bool(tela_upgrades.call("esta_aberta"))
			else:
				menu_melhorias_aberto = tela_upgrades.visible
			if menu_melhorias_aberto:
				deve_mostrar = false
	if visible and not deve_mostrar:
		_liberar_todos_os_comandos()
	visible = deve_mostrar
	if visibilidade_anterior != visible and visible and is_instance_valid(superficie):
		superficie.queue_redraw()


func _liberar_todos_os_comandos() -> void:
	if dedo_analogico >= 0 or Global.controle_toque_ativo:
		Global.limpar_controle_toque()
	dedo_analogico = -1
	centro_analogico = Vector2.ZERO
	direcao_analogico = Vector2.ZERO
	for acao in botoes_toque:
		Input.action_release(StringName(acao))
	dedos_acoes.clear()


func desenhar_controles(alvo: Control) -> void:
	var tamanho := alvo.size
	var centro := (
		centro_analogico
		if dedo_analogico >= 0
		else _centro_analogico(tamanho)
	)
	var raio := _raio_analogico(tamanho)
	alvo.draw_circle(centro, raio, COR_BASE)
	alvo.draw_arc(centro, raio, 0.0, TAU, 36, COR_BORDA, 2.4, true)
	alvo.draw_arc(centro, raio * 0.70, 0.0, TAU, 32, COR_DETALHE, 1.2, true)
	for direcao in [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]:
		alvo.draw_line(
			centro + direcao * raio * 0.77,
			centro + direcao * raio * 0.91,
			COR_DETALHE,
			2.0,
			true
		)
	var deslocamento := direcao_analogico * raio * 0.55
	var cor_manopla := COR_ATIVO if dedo_analogico >= 0 else COR_BORDA
	alvo.draw_circle(centro + deslocamento, raio * 0.32, Color(cor_manopla, 0.62))
	alvo.draw_arc(centro + deslocamento, raio * 0.32, 0.0, TAU, 28, cor_manopla, 2.0, true)

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
		alvo.draw_arc(centro_botao, raio_botao, 0.0, TAU, 32, COR_BORDA, 2.2, true)
		alvo.draw_arc(centro_botao, raio_botao * 0.76, -2.4, 0.75, 18, COR_DETALHE, 1.2, true)
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
		botao.released.connect(_on_botao_toque_liberado)
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
	if is_instance_valid(superficie):
		superficie.queue_redraw()
	if Global.vibracao:
		Input.vibrate_handheld(18)


func _on_botao_toque_liberado() -> void:
	if is_instance_valid(superficie):
		superficie.queue_redraw()


func _centro_analogico(tamanho: Vector2) -> Vector2:
	return Vector2(tamanho.x * 0.15, tamanho.y * 0.77)


func _raio_analogico(tamanho: Vector2) -> float:
	return minf(tamanho.x, tamanho.y) * 0.115


func _obter_botoes(tamanho: Vector2) -> Array[Dictionary]:
	var unidade := minf(tamanho.x, tamanho.y)
	return [
		{
			"acao": &"atirar",
			"texto": "TIRO",
			"centro": Vector2(tamanho.x * 0.86, tamanho.y * 0.76),
			"raio": unidade * 0.087,
		},
		{
			"acao": &"Habilidade",
			"texto": "PODER",
			"centro": Vector2(tamanho.x * 0.73, tamanho.y * 0.84),
			"raio": unidade * 0.067,
		},
		{
			"acao": &"pausar",
			"texto": "II",
			"centro": Vector2(tamanho.x * 0.94, tamanho.y * 0.10),
			"raio": unidade * 0.052,
		},
	]


func _tentar_abrir_melhorias_pelo_indicador(posicao: Vector2) -> bool:
	if not is_instance_valid(area_batalha):
		return false
	var tela_upgrades := area_batalha.get_node_or_null("GUI/TelaUpgrades") as Control
	if not is_instance_valid(tela_upgrades):
		return false
	var indicador := tela_upgrades.get_node_or_null("IndicadorMelhorias") as Control
	if not is_instance_valid(indicador) or not indicador.is_visible_in_tree():
		return false
	if not indicador.get_global_rect().has_point(posicao):
		return false
	if tela_upgrades.has_method("abrir_menu"):
		tela_upgrades.call("abrir_menu")
		return true
	return false


func _marcar_toque_como_usado() -> void:
	if get_viewport():
		get_viewport().set_input_as_handled()
