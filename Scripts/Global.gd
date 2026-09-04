extends Node


signal dispositivo_alterado(tipo: StringName)
signal configuracoes_alteradas
signal cristais_alterados(total: int, alteracao: int)

const CONFIG_PADRAO := {
	"mira_mouse": true,
	"volume_master": 0.0,
	"volume_musica": 0.0,
	"volume_som": 0.0,
	"idioma": "pt_BR",
	"tela_cheia": true,
	"vsync": true,
	"limite_fps": 60,
	"neon": 1.0,
	"bloom": 0.12,
	"tremor_tela": 1.0,
	"zona_morta_controle": 0.22,
	"vibracao": true,
	"controle_avancado": false
}

const MAX_SLOTS_CONTROLE := 3
const ACOES_REMAPEAVEIS := {
	&"acelerar": "T_BIND_ACCELERATE",
	&"freio": "T_BIND_BRAKE",
	&"esquerda": "T_BIND_TURN_LEFT",
	&"direita": "T_BIND_TURN_RIGHT",
	&"atirar": "T_BIND_SHOOT",
	&"Habilidade": "T_BIND_ABILITY",
	&"abrir_melhorias": "T_BIND_UPGRADES",
	&"pausar": "T_BIND_PAUSE",
	&"mirar_esquerda": "T_BIND_AIM_LEFT",
	&"mirar_direita": "T_BIND_AIM_RIGHT",
	&"mirar_cima": "T_BIND_AIM_UP",
	&"mirar_baixo": "T_BIND_AIM_DOWN",
}

const CRISTAIS_INICIAIS := 1250
const MODO_DESENVOLVEDOR_EM_TESTES := true

var primeira_vez_jogando: bool = true
var Pontos := 0
var kills_max := 0
var Combo: int = 0

# Mantidos para compatibilidade com os scripts antigos.
var mira_mouse := true
var volume_som := 0.0
var volume_musica := 0.0

var volume_master := 0.0
var idioma := "pt_BR"
var tela_cheia := true
var vsync := true
var limite_fps := 60
var neon := 1.0
var bloom := 0.12
var tremor_tela := 1.0
var zona_morta_controle := 0.22
var vibracao := true
var controle_avancado := false
var ultimo_dispositivo: StringName = &"teclado_mouse"
var ultimo_controle_id := -1
var controle_toque_ativo := false
var direcao_controle_toque := Vector2.ZERO
var mapeamentos_controles: Dictionary = {}
var _mapeamentos_padrao: Dictionary = {}

var cristais := CRISTAIS_INICIAIS
var modo_desenvolvedor := false
var _salvamento_economia_agendado := false

var conquistas_disponiveis = ["ACH_10KILlS", "ACH_100KILlS", "ACH_1000KILlS"]
var conquistas_desbloqueadas = [""]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	modo_desenvolvedor = calcular_permissao_desenvolvedor(
		OS.has_feature("editor"),
		OS.has_feature("debug"),
		OS.has_feature("release")
	)
	_capturar_mapeamentos_padrao()
	carregar_configuracoes()
	carregar_economia()
	get_tree().node_added.connect(_on_node_adicionado)
	call_deferred("aplicar_configuracoes")


func carregar_economia() -> void:
	var dados: Dictionary = GerenciadorDeSave.carregar()
	cristais = maxi(int(dados.get("cristais", CRISTAIS_INICIAIS)), 0)


func adicionar_cristais(quantidade: int, salvar_imediatamente := false) -> void:
	if quantidade <= 0:
		return
	cristais += quantidade
	cristais_alterados.emit(cristais, quantidade)
	if salvar_imediatamente:
		salvar_economia()
	else:
		_agendar_salvamento_economia()


func pode_gastar_cristais(quantidade: int) -> bool:
	return quantidade >= 0 and cristais >= quantidade


func gastar_cristais(quantidade: int) -> bool:
	if quantidade < 0 or not pode_gastar_cristais(quantidade):
		return false
	cristais -= quantidade
	cristais_alterados.emit(cristais, -quantidade)
	salvar_economia()
	return true


func salvar_economia() -> void:
	_salvamento_economia_agendado = false
	GerenciadorDeSave.salvar({"cristais": cristais})


func _agendar_salvamento_economia() -> void:
	if _salvamento_economia_agendado:
		return
	_salvamento_economia_agendado = true
	_salvar_economia_depois()


func _salvar_economia_depois() -> void:
	await get_tree().create_timer(1.5, true).timeout
	if _salvamento_economia_agendado:
		salvar_economia()


func _input(event: InputEvent) -> void:
	var novo_tipo := ultimo_dispositivo
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		novo_tipo = &"toque"
	elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
		if event is InputEventJoypadMotion and absf(event.axis_value) < zona_morta_controle:
			return
		if event.device >= 0:
			ultimo_controle_id = event.device
		novo_tipo = &"controle"
	elif event is InputEventMouseButton or event is InputEventMouseMotion:
		novo_tipo = &"teclado_mouse"
	elif event is InputEventKey and event.pressed:
		novo_tipo = &"teclado_mouse"

	if novo_tipo != ultimo_dispositivo:
		ultimo_dispositivo = novo_tipo
		dispositivo_alterado.emit(ultimo_dispositivo)


static func calcular_permissao_desenvolvedor(
	eh_editor: bool,
	_eh_debug: bool,
	eh_release: bool
) -> bool:
	return (
		MODO_DESENVOLVEDOR_EM_TESTES
		and not eh_release
		and eh_editor
	)


func dispositivo_mobile() -> bool:
	return (
		OS.get_name() in ["Android", "iOS"]
		or OS.has_feature("mobile")
		or OS.has_feature("mobile_controls")
		or OS.has_feature("android")
		or OS.has_feature("ios")
	)


func deve_exibir_controles_toque() -> bool:
	return dispositivo_mobile()


func definir_direcao_toque(direcao: Vector2) -> void:
	direcao_controle_toque = direcao.limit_length(1.0)
	controle_toque_ativo = direcao_controle_toque.length_squared() > 0.0001
	if controle_toque_ativo and ultimo_dispositivo != &"toque":
		ultimo_dispositivo = &"toque"
		dispositivo_alterado.emit(ultimo_dispositivo)


func limpar_controle_toque() -> void:
	direcao_controle_toque = Vector2.ZERO
	controle_toque_ativo = false


func carregar_configuracoes() -> void:
	var dados: Dictionary = GerenciadorDeSave.carregar()
	var config: Dictionary = {}
	var config_salva = dados.get("configuracoes", {})
	if config_salva is Dictionary:
		config = config_salva
	for chave in CONFIG_PADRAO:
		if not config.has(chave):
			config[chave] = CONFIG_PADRAO[chave]

	mira_mouse = bool(config["mira_mouse"])
	volume_master = float(config["volume_master"])
	volume_musica = float(config["volume_musica"])
	volume_som = float(config["volume_som"])
	idioma = str(config["idioma"])
	tela_cheia = bool(config["tela_cheia"])
	vsync = bool(config["vsync"])
	limite_fps = int(config["limite_fps"])
	neon = clampf(float(config["neon"]), 0.0, 2.0)
	bloom = clampf(float(config["bloom"]), 0.0, 0.5)
	tremor_tela = clampf(float(config["tremor_tela"]), 0.0, 1.0)
	zona_morta_controle = clampf(float(config["zona_morta_controle"]), 0.05, 0.6)
	vibracao = bool(config["vibracao"])
	controle_avancado = bool(config["controle_avancado"])

	var mapeamentos_salvos = config.get("mapeamentos_controles", {})
	if mapeamentos_salvos is Dictionary and not mapeamentos_salvos.is_empty():
		mapeamentos_controles = _normalizar_mapeamentos(mapeamentos_salvos)
	else:
		mapeamentos_controles = _mapeamentos_padrao.duplicate(true)


func salvar_configuracoes() -> void:
	GerenciadorDeSave.salvar({"configuracoes": obter_configuracoes()})
	aplicar_configuracoes()
	configuracoes_alteradas.emit()


func obter_configuracoes() -> Dictionary:
	return {
		"mira_mouse": mira_mouse,
		"volume_master": volume_master,
		"volume_musica": volume_musica,
		"volume_som": volume_som,
		"idioma": idioma,
		"tela_cheia": tela_cheia,
		"vsync": vsync,
		"limite_fps": limite_fps,
		"neon": neon,
		"bloom": bloom,
		"tremor_tela": tremor_tela,
		"zona_morta_controle": zona_morta_controle,
		"vibracao": vibracao,
		"controle_avancado": controle_avancado,
		"mapeamentos_controles": mapeamentos_controles.duplicate(true),
	}


func restaurar_configuracoes_padrao() -> void:
	var config := CONFIG_PADRAO.duplicate(true)
	mira_mouse = bool(config["mira_mouse"])
	volume_master = float(config["volume_master"])
	volume_musica = float(config["volume_musica"])
	volume_som = float(config["volume_som"])
	idioma = str(config["idioma"])
	tela_cheia = bool(config["tela_cheia"])
	vsync = bool(config["vsync"])
	limite_fps = int(config["limite_fps"])
	neon = float(config["neon"])
	bloom = float(config["bloom"])
	tremor_tela = float(config["tremor_tela"])
	zona_morta_controle = float(config["zona_morta_controle"])
	vibracao = bool(config["vibracao"])
	controle_avancado = bool(config["controle_avancado"])
	mapeamentos_controles = _mapeamentos_padrao.duplicate(true)
	salvar_configuracoes()


func apagar_save_completo() -> void:
	_salvamento_economia_agendado = false
	primeira_vez_jogando = true
	Pontos = 0
	kills_max = 0
	Combo = 0
	conquistas_desbloqueadas = [""]

	var cristais_anteriores: int = cristais
	cristais = CRISTAIS_INICIAIS
	restaurar_configuracoes_padrao()
	GerenciadorDeSave.deletar_save()
	cristais_alterados.emit(cristais, cristais - cristais_anteriores)


func aplicar_configuracoes() -> void:
	_aplicar_mapeamentos_controles()
	_aplicar_volume("Master", volume_master)
	_aplicar_volume("Music", volume_musica)
	_aplicar_volume("Sound", volume_som)
	TranslationServer.set_locale(idioma)

	if not OS.has_feature("web") and not dispositivo_mobile():
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_FULLSCREEN
			if tela_cheia
			else DisplayServer.WINDOW_MODE_WINDOWED
		)
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED
	)
	Engine.max_fps = limite_fps

	for acao in [
		&"acelerar",
		&"freio",
		&"esquerda",
		&"direita",
		&"mirar_esquerda",
		&"mirar_direita",
		&"mirar_cima",
		&"mirar_baixo"
	]:
		if InputMap.has_action(acao):
			InputMap.action_set_deadzone(acao, zona_morta_controle)

	for ambiente in get_tree().get_nodes_in_group("ambiente_global"):
		_aplicar_ambiente(ambiente)


func _aplicar_volume(nome_bus: String, valor_db: float) -> void:
	var indice := AudioServer.get_bus_index(nome_bus)
	if indice >= 0:
		AudioServer.set_bus_volume_db(indice, clampf(valor_db, -80.0, 6.0))


func _on_node_adicionado(node: Node) -> void:
	if node.is_in_group("ambiente_global"):
		call_deferred("_aplicar_ambiente", node)


func _aplicar_ambiente(node: Node) -> void:
	if not is_instance_valid(node) or not (node is WorldEnvironment):
		return
	var world := node as WorldEnvironment
	if not world.environment:
		return
	world.environment.glow_enabled = neon > 0.01 or bloom > 0.01
	world.environment.glow_intensity = neon
	world.environment.glow_bloom = bloom


func vibrar_controle(fraco := 0.25, forte := 0.5, duracao := 0.16) -> void:
	if not vibracao:
		return
	for dispositivo in Input.get_connected_joypads():
		Input.start_joy_vibration(dispositivo, fraco, forte, duracao)


func obter_acoes_remapeaveis() -> Dictionary:
	return ACOES_REMAPEAVEIS


func obter_evento_mapeado(acao: StringName, slot: int) -> InputEvent:
	var slots := _obter_slots(acao)
	if slot < 0 or slot >= slots.size():
		return null
	var dados = slots[slot]
	if not (dados is Dictionary) or dados.is_empty():
		return null
	return _desserializar_evento(dados)


func definir_mapeamento(acao: StringName, slot: int, evento: InputEvent) -> void:
	if not ACOES_REMAPEAVEIS.has(acao) or slot < 0 or slot >= MAX_SLOTS_CONTROLE:
		return
	var dados := _serializar_evento(evento)
	if dados.is_empty():
		return

	# Um mesmo comando em duas ações pode disparar comportamentos simultâneos.
	# Ao realocar a entrada, o vínculo anterior é removido automaticamente.
	for outra_acao in ACOES_REMAPEAVEIS:
		var slots_outra := _obter_slots(outra_acao)
		for indice in slots_outra.size():
			if outra_acao == acao and indice == slot:
				continue
			if _eventos_serializados_iguais(slots_outra[indice], dados):
				slots_outra[indice] = {}
		mapeamentos_controles[str(outra_acao)] = slots_outra

	var slots := _obter_slots(acao)
	slots[slot] = dados
	mapeamentos_controles[str(acao)] = slots
	_aplicar_mapeamentos_controles()
	salvar_configuracoes()


func limpar_mapeamento(acao: StringName, slot: int) -> void:
	if not ACOES_REMAPEAVEIS.has(acao) or slot < 0 or slot >= MAX_SLOTS_CONTROLE:
		return
	var slots := _obter_slots(acao)
	slots[slot] = {}
	mapeamentos_controles[str(acao)] = slots
	_aplicar_mapeamentos_controles()
	salvar_configuracoes()


func restaurar_mapeamentos_padrao() -> void:
	mapeamentos_controles = _mapeamentos_padrao.duplicate(true)
	_aplicar_mapeamentos_controles()
	salvar_configuracoes()


func _capturar_mapeamentos_padrao() -> void:
	_mapeamentos_padrao.clear()
	for acao in ACOES_REMAPEAVEIS:
		var eventos: Array[InputEvent] = []
		if InputMap.has_action(acao):
			eventos.assign(InputMap.action_get_events(acao))

		# O gatilho direito é o padrão mais natural para tiro em controles.
		# Ele ganha prioridade sobre RB/R1 quando existem mais de três vínculos.
		if acao == &"atirar":
			eventos.sort_custom(func(a: InputEvent, b: InputEvent) -> bool:
				var prioridade_a := 1 if a is InputEventJoypadButton else 0
				var prioridade_b := 1 if b is InputEventJoypadButton else 0
				return prioridade_a < prioridade_b
			)

		var slots: Array = []
		for evento in eventos:
			var dados := _serializar_evento(evento)
			if not dados.is_empty() and slots.size() < MAX_SLOTS_CONTROLE:
				slots.append(dados)
		while slots.size() < MAX_SLOTS_CONTROLE:
			slots.append({})
		_mapeamentos_padrao[str(acao)] = slots


func _normalizar_mapeamentos(origem: Dictionary) -> Dictionary:
	var resultado := _mapeamentos_padrao.duplicate(true)
	for acao in ACOES_REMAPEAVEIS:
		var chave := str(acao)
		var origem_slots = origem.get(chave, [])
		if not (origem_slots is Array):
			continue
		var slots: Array = [{}, {}, {}]
		for indice in mini(origem_slots.size(), MAX_SLOTS_CONTROLE):
			var dados = origem_slots[indice]
			if dados is Dictionary and not _desserializar_evento(dados) == null:
				slots[indice] = dados.duplicate(true)
		resultado[chave] = slots
	return resultado


func _obter_slots(acao: StringName) -> Array:
	var chave := str(acao)
	var slots = mapeamentos_controles.get(chave, [{}, {}, {}])
	if not (slots is Array):
		slots = [{}, {}, {}]
	else:
		slots = slots.duplicate(true)
	while slots.size() < MAX_SLOTS_CONTROLE:
		slots.append({})
	if slots.size() > MAX_SLOTS_CONTROLE:
		slots.resize(MAX_SLOTS_CONTROLE)
	return slots


func _aplicar_mapeamentos_controles() -> void:
	for acao in ACOES_REMAPEAVEIS:
		if not InputMap.has_action(acao):
			continue
		InputMap.action_erase_events(acao)
		for dados in _obter_slots(acao):
			if not (dados is Dictionary) or dados.is_empty():
				continue
			var evento := _desserializar_evento(dados)
			if evento:
				InputMap.action_add_event(acao, evento)


func _serializar_evento(evento: InputEvent) -> Dictionary:
	if evento is InputEventKey:
		var tecla := evento as InputEventKey
		var codigo := tecla.physical_keycode if tecla.physical_keycode != 0 else tecla.keycode
		if codigo == 0:
			return {}
		return {
			"tipo": "tecla",
			"codigo": int(codigo),
			"fisica": tecla.physical_keycode != 0,
			"alt": tecla.alt_pressed,
			"shift": tecla.shift_pressed,
			"ctrl": tecla.ctrl_pressed,
			"meta": tecla.meta_pressed,
		}
	if evento is InputEventMouseButton:
		var mouse := evento as InputEventMouseButton
		return {"tipo": "mouse", "botao": int(mouse.button_index)}
	if evento is InputEventJoypadButton:
		var botao := evento as InputEventJoypadButton
		return {"tipo": "botao_controle", "botao": botao.button_index}
	if evento is InputEventJoypadMotion:
		var eixo := evento as InputEventJoypadMotion
		if absf(eixo.axis_value) < 0.5:
			return {}
		return {
			"tipo": "eixo_controle",
			"eixo": eixo.axis,
			"direcao": 1.0 if eixo.axis_value > 0.0 else -1.0,
		}
	return {}


func _desserializar_evento(dados: Dictionary) -> InputEvent:
	match str(dados.get("tipo", "")):
		"tecla":
			var tecla := InputEventKey.new()
			var codigo := int(dados.get("codigo", 0))
			if codigo == 0:
				return null
			if bool(dados.get("fisica", true)):
				tecla.physical_keycode = codigo
			else:
				tecla.keycode = codigo
			tecla.alt_pressed = bool(dados.get("alt", false))
			tecla.shift_pressed = bool(dados.get("shift", false))
			tecla.ctrl_pressed = bool(dados.get("ctrl", false))
			tecla.meta_pressed = bool(dados.get("meta", false))
			return tecla
		"mouse":
			var mouse := InputEventMouseButton.new()
			mouse.button_index = int(dados.get("botao", 0))
			return mouse if mouse.button_index != MOUSE_BUTTON_NONE else null
		"botao_controle":
			var botao := InputEventJoypadButton.new()
			botao.device = -1
			botao.button_index = int(dados.get("botao", -1))
			return botao if botao.button_index >= 0 else null
		"eixo_controle":
			var eixo := InputEventJoypadMotion.new()
			eixo.device = -1
			eixo.axis = int(dados.get("eixo", -1))
			eixo.axis_value = float(dados.get("direcao", 0.0))
			return eixo if eixo.axis >= 0 and not is_zero_approx(eixo.axis_value) else null
	return null


func _eventos_serializados_iguais(a, b) -> bool:
	return a is Dictionary and b is Dictionary and not a.is_empty() and a == b
