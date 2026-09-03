extends CanvasLayer
class_name PainelDesenvolvedor


const COR_FUNDO := Color(0.006, 0.009, 0.026, 0.97)
const COR_DESTAQUE := Color(0.28, 0.88, 1.0)

var batalha
var player: Player
var overlay: ColorRect
var painel: PanelContainer
var status: Label
var indicador: Label
var botoes: Array[Button] = []
var aberto := false
var pausado_antes := false
var mouse_antes := Input.MOUSE_MODE_HIDDEN


func configurar(alvo_batalha: Node2D, alvo_player: Player) -> void:
	batalha = alvo_batalha
	player = alvo_player
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 95
	construir_interface()


func construir_interface() -> void:
	indicador = Label.new()
	indicador.position = Vector2(847.0, 14.0)
	indicador.size = Vector2(96.0, 24.0)
	indicador.text = "DEV • F10"
	indicador.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	indicador.mouse_filter = Control.MOUSE_FILTER_IGNORE
	indicador.add_theme_font_size_override("font_size", 11)
	indicador.add_theme_color_override("font_color", Color(0.35, 0.86, 1.0, 0.72))
	add_child(indicador)

	overlay = ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.0, 0.0, 0.015, 0.72)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	painel = PanelContainer.new()
	painel.position = Vector2(120.0, 44.0)
	painel.size = Vector2(720.0, 452.0)
	painel.add_theme_stylebox_override("panel", criar_estilo_painel())
	overlay.add_child(painel)

	var margem := MarginContainer.new()
	margem.add_theme_constant_override("margin_left", 24)
	margem.add_theme_constant_override("margin_top", 20)
	margem.add_theme_constant_override("margin_right", 24)
	margem.add_theme_constant_override("margin_bottom", 18)
	painel.add_child(margem)

	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 9)
	margem.add_child(coluna)

	var titulo := Label.new()
	titulo.text = "LABORATÓRIO DE TESTES"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 24)
	titulo.add_theme_color_override("font_color", COR_DESTAQUE)
	coluna.add_child(titulo)

	var descricao := Label.new()
	descricao.text = "Somente modo desenvolvedor • F10 ou L3+R3 • ESC volta ao jogo"
	descricao.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	descricao.add_theme_font_size_override("font_size", 11)
	descricao.add_theme_color_override("font_color", Color(0.55, 0.65, 0.82))
	coluna.add_child(descricao)

	status = Label.new()
	status.custom_minimum_size = Vector2(0.0, 25.0)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status.add_theme_font_size_override("font_size", 12)
	status.add_theme_color_override("font_color", Color(0.75, 0.9, 1.0))
	status.add_theme_stylebox_override("normal", criar_estilo_status())
	coluna.add_child(status)

	adicionar_secao(coluna, "PROGRESSÃO E ESTADO")
	var grade_estado := GridContainer.new()
	grade_estado.columns = 4
	grade_estado.add_theme_constant_override("h_separation", 8)
	grade_estado.add_theme_constant_override("v_separation", 8)
	coluna.add_child(grade_estado)
	adicionar_botao(grade_estado, "+1 PONTO", _dar_ponto)
	adicionar_botao(grade_estado, "+1 NÍVEL", _subir_niveis.bind(1))
	adicionar_botao(grade_estado, "+5 NÍVEIS", _subir_niveis.bind(5))
	adicionar_botao(grade_estado, "CURAR", _curar_total)
	adicionar_botao(grade_estado, "INVULNERÁVEL", _alternar_invulnerabilidade)
	adicionar_botao(grade_estado, "PAUSAR SPAWNS", _alternar_spawns)
	adicionar_botao(grade_estado, "LIMPAR ARENA", _limpar_arena)
	adicionar_botao(grade_estado, "REINICIAR", _reiniciar_partida)

	adicionar_secao(coluna, "INVOCAR BOSS PARA TESTE")
	var grade_bosses := GridContainer.new()
	grade_bosses.columns = 3
	grade_bosses.add_theme_constant_override("h_separation", 8)
	grade_bosses.add_theme_constant_override("v_separation", 8)
	coluna.add_child(grade_bosses)
	adicionar_botao(grade_bosses, "PET-0", _invocar_boss.bind(&"pet0"))
	adicionar_botao(grade_bosses, "FLOR", _invocar_boss.bind(&"flor_equinocio"))
	adicionar_botao(grade_bosses, "SIZÍGIA", _invocar_boss.bind(&"eclipse_colheita"))
	adicionar_botao(grade_bosses, "SENTINELA", _invocar_boss.bind(&"sentinela_dourada"))
	adicionar_botao(grade_bosses, "RUPTURA", _invocar_boss.bind(&"ruptura_lilas"))
	adicionar_botao(grade_bosses, "FECHAR", fechar)

	configurar_navegacao()
	overlay.hide()


func adicionar_secao(pai: VBoxContainer, texto: String) -> void:
	var rotulo := Label.new()
	rotulo.text = texto
	rotulo.add_theme_font_size_override("font_size", 12)
	rotulo.add_theme_color_override("font_color", Color(1.0, 0.76, 0.28))
	pai.add_child(rotulo)


func adicionar_botao(pai: Control, texto: String, acao: Callable) -> Button:
	var botao := Button.new()
	botao.custom_minimum_size = Vector2(156.0, 42.0)
	botao.text = texto
	botao.focus_mode = Control.FOCUS_ALL
	botao.add_theme_font_size_override("font_size", 11)
	botao.add_theme_stylebox_override("normal", criar_estilo_botao(false))
	botao.add_theme_stylebox_override("hover", criar_estilo_botao(true))
	botao.add_theme_stylebox_override("focus", criar_estilo_botao(true))
	botao.pressed.connect(acao)
	pai.add_child(botao)
	botoes.append(botao)
	return botao


func configurar_navegacao() -> void:
	for indice in range(botoes.size()):
		var atual := botoes[indice]
		var anterior := botoes[(indice - 1 + botoes.size()) % botoes.size()]
		var proximo := botoes[(indice + 1) % botoes.size()]
		atual.focus_neighbor_left = atual.get_path_to(anterior)
		atual.focus_neighbor_top = atual.get_path_to(anterior)
		atual.focus_neighbor_right = atual.get_path_to(proximo)
		atual.focus_neighbor_bottom = atual.get_path_to(proximo)


func criar_estilo_painel() -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = COR_FUNDO
	estilo.border_color = Color(0.24, 0.72, 1.0, 0.82)
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(16)
	estilo.shadow_color = Color(0.18, 0.65, 1.0, 0.22)
	estilo.shadow_size = 12
	return estilo


func criar_estilo_status() -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.04, 0.08, 0.15, 0.9)
	estilo.border_color = Color(0.18, 0.42, 0.7, 0.75)
	estilo.set_border_width_all(1)
	estilo.set_corner_radius_all(7)
	return estilo


func criar_estilo_botao(destacado: bool) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = (
		Color(0.07, 0.17, 0.25, 1.0)
		if destacado
		else Color(0.035, 0.06, 0.12, 1.0)
	)
	estilo.border_color = COR_DESTAQUE if destacado else Color(0.2, 0.38, 0.58)
	estilo.set_border_width_all(2 if destacado else 1)
	estilo.set_corner_radius_all(9)
	return estilo


func _unhandled_input(event: InputEvent) -> void:
	if (
		event is InputEventKey
		and event.pressed
		and not event.echo
		and event.keycode == KEY_F10
	):
		get_viewport().set_input_as_handled()
		alternar()
		return
	if (
		event is InputEventJoypadButton
		and event.pressed
		and (
			(event.button_index == JOY_BUTTON_LEFT_STICK
			and Input.is_joy_button_pressed(event.device, JOY_BUTTON_RIGHT_STICK))
			or (event.button_index == JOY_BUTTON_RIGHT_STICK
			and Input.is_joy_button_pressed(event.device, JOY_BUTTON_LEFT_STICK))
		)
	):
		get_viewport().set_input_as_handled()
		alternar()
		return
	if aberto and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		fechar()


func alternar() -> void:
	if aberto:
		fechar()
	else:
		abrir()


func abrir() -> void:
	if (
		aberto
		or not is_instance_valid(player)
		or not is_instance_valid(batalha)
		or not bool(batalha.call("pode_abrir_painel_desenvolvedor"))
	):
		return
	aberto = true
	pausado_antes = get_tree().paused
	mouse_antes = Input.mouse_mode
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	atualizar_status("Painel de testes ativo")
	indicador.hide()
	overlay.show()
	if not botoes.is_empty():
		botoes[0].call_deferred("grab_focus")


func fechar() -> void:
	if not aberto:
		return
	aberto = false
	overlay.hide()
	indicador.show()
	get_tree().paused = pausado_antes
	Input.set_mouse_mode(mouse_antes)


func atualizar_status(mensagem := "") -> void:
	if not is_instance_valid(status) or not is_instance_valid(player):
		return
	var invulneravel := "ON" if player.invulneravel_desenvolvedor else "OFF"
	var spawns_pausados := bool(batalha.call("spawns_teste_estao_pausados"))
	var spawns := "PAUSADOS" if spawns_pausados else "ATIVOS"
	status.text = "%s  •  LVL %d  •  PONTOS %d  •  INVULN %s  •  SPAWNS %s" % [
		mensagem,
		player.nivel_atual,
		player.pontos_upgrade_pendentes,
		invulneravel,
		spawns,
	]


func _dar_ponto() -> void:
	player.pontos_upgrade_pendentes += 1
	player.pontos_upgrade_alterados.emit(player.pontos_upgrade_pendentes)
	atualizar_status("Ponto concedido")


func _subir_niveis(quantidade: int) -> void:
	for _indice in range(maxi(quantidade, 0)):
		player.subir_de_nivel()
	atualizar_status("Nível ajustado")


func _curar_total() -> void:
	player.vida = player.VIDA_MAXIMA
	atualizar_status("Casco restaurado")


func _alternar_invulnerabilidade() -> void:
	player.invulneravel_desenvolvedor = not player.invulneravel_desenvolvedor
	atualizar_status("Invulnerabilidade alternada")


func _alternar_spawns() -> void:
	batalha.call("alternar_spawns_teste")
	atualizar_status("Spawns alternados")


func _limpar_arena() -> void:
	batalha.call("limpar_arena_teste")
	atualizar_status("Arena limpa")


func _reiniciar_partida() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()


func _invocar_boss(id: StringName) -> void:
	fechar()
	batalha.call_deferred("invocar_boss_teste", id)
