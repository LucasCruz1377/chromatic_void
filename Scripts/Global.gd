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
	"vibracao": true
}

const CRISTAIS_INICIAIS := 1250
const MODO_DESENVOLVEDOR := true

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
var ultimo_dispositivo: StringName = &"teclado_mouse"

var cristais := CRISTAIS_INICIAIS
var modo_desenvolvedor := MODO_DESENVOLVEDOR
var _salvamento_economia_agendado := false

var conquistas_disponiveis = ["ACH_10KILlS", "ACH_100KILlS", "ACH_1000KILlS"]
var conquistas_desbloqueadas = [""]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
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
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		if event is InputEventJoypadMotion and absf(event.axis_value) < zona_morta_controle:
			return
		novo_tipo = &"controle"
	elif event is InputEventMouseButton or event is InputEventMouseMotion:
		novo_tipo = &"teclado_mouse"
	elif event is InputEventKey and event.pressed:
		novo_tipo = &"teclado_mouse"

	if novo_tipo != ultimo_dispositivo:
		ultimo_dispositivo = novo_tipo
		dispositivo_alterado.emit(ultimo_dispositivo)


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
		"vibracao": vibracao
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
	salvar_configuracoes()


func aplicar_configuracoes() -> void:
	_aplicar_volume("Master", volume_master)
	_aplicar_volume("Music", volume_musica)
	_aplicar_volume("Sound", volume_som)
	TranslationServer.set_locale(idioma)

	if not OS.has_feature("web"):
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
