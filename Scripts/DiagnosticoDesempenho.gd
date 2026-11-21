extends CanvasLayer
## Diagnostico local: nao altera simulacao, saves nem estado de rede.
## F3 alterna a visualizacao; os numeros sao amostras locais, nao valores do host.

const INTERVALO_ATUALIZACAO := 0.25
const INTERVALO_HISTORICO := 1.0
const LIMITE_HISTORICO := 120

var painel: PanelContainer
var texto: Label
var visivel := false
var acumulado := 0.0
var acumulado_historico := 0.0
var historico_objetos: Array[int] = []


func _ready() -> void:
	name = "DiagnosticoDesempenho"
	layer = 110
	process_mode = Node.PROCESS_MODE_ALWAYS
	_construir_interface()
	set_process(true)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
		visivel = not visivel
		painel.visible = visivel
		get_viewport().set_input_as_handled()
		if visivel:
			_atualizar()


func _process(delta: float) -> void:
	if not visivel:
		return
	acumulado += delta
	acumulado_historico += delta
	if acumulado_historico >= INTERVALO_HISTORICO:
		acumulado_historico = 0.0
		historico_objetos.append(int(Performance.get_monitor(Performance.OBJECT_COUNT)))
		if historico_objetos.size() > LIMITE_HISTORICO:
			historico_objetos.pop_front()
	if acumulado >= INTERVALO_ATUALIZACAO:
		acumulado = 0.0
		_atualizar()


func _construir_interface() -> void:
	painel = PanelContainer.new()
	painel.position = Vector2(12.0, 12.0)
	painel.custom_minimum_size = Vector2(330.0, 0.0)
	painel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(painel)
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.015, 0.025, 0.055, 0.92)
	estilo.border_color = Color(0.25, 0.8, 1.0, 0.7)
	estilo.set_border_width_all(1)
	estilo.set_corner_radius_all(8)
	estilo.set_content_margin_all(12)
	painel.add_theme_stylebox_override("panel", estilo)
	texto = Label.new()
	texto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texto.add_theme_font_size_override("font_size", 12)
	texto.add_theme_color_override("font_color", Color(0.8, 0.94, 1.0))
	painel.add_child(texto)
	painel.hide()


func _atualizar() -> void:
	var fps := Engine.get_frames_per_second()
	var frame_ms := 1000.0 / maxf(float(fps), 1.0)
	var inimigos := get_tree().get_nodes_in_group("inimigo").size()
	var projeteis := get_tree().get_nodes_in_group("projeteis").size()
	var jogadores := get_tree().get_nodes_in_group("player").size()
	var objetos := int(Performance.get_monitor(Performance.OBJECT_COUNT))
	var nos := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var memoria := float(Performance.get_monitor(Performance.MEMORY_STATIC)) / (1024.0 * 1024.0)
	var fisica_ms := float(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)) * 1000.0
	var processo_ms := float(Performance.get_monitor(Performance.TIME_PROCESS)) * 1000.0
	var peer := multiplayer.multiplayer_peer
	var conectado := peer != null and peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED
	var papel := "SOLO"
	if conectado:
		papel = "HOST" if multiplayer.is_server() else "CLIENTE"
	var variacao := 0
	if historico_objetos.size() > 1:
		variacao = objetos - historico_objetos[0]
	var observacao := "Monitorar tendencia; crescimento nao comprova vazamento."
	texto.text = ("CHROMATIC VOID | DIAGNOSTICO [F3]\n"
		+ "FPS: %d | frame estimado: %.2f ms\n"
		+ "Processo: %.2f ms | fisica: %.2f ms\n"
		+ "Inimigos: %d | projeteis: %d | players: %d\n"
		+ "Objetos: %d | nos: %d | delta objetos: %+d\n"
		+ "Memoria estatica: %.1f MiB\n"
		+ "Rede: %s | peer local: %d\n"
		+ "%s") % [
			fps, frame_ms, processo_ms, fisica_ms,
			inimigos, projeteis, jogadores,
			objetos, nos, variacao, memoria,
			papel, multiplayer.get_unique_id() if conectado else 0,
			observacao,
		]
