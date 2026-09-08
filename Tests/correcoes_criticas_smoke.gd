extends Node


const LojaController = preload("res://Scripts/shopcontroler.gd")
const TelaInicialScript = preload("res://Scripts/tela_inicial.gd")


class AlvoContato:
	extends Node
	var dano_recebido := 0.0

	func tomar_dano(valor: float) -> void:
		dano_recebido += valor


var falhas: Array[String] = []
var setor_atual: StringName = &"rede_dourada"


func verificar(condicao: bool, mensagem: String) -> void:
	if not condicao:
		falhas.append(mensagem)
		push_error("CORREÇÕES CRÍTICAS: " + mensagem)


func _ready() -> void:
	await testar_perfil_mobile_e_particulas()
	await testar_contato_vinculos_e_pausa()
	await testar_hud_e_icone()
	await finalizar()


func testar_perfil_mobile_e_particulas() -> void:
	var presets := FileAccess.get_file_as_string("res://export_presets.cfg")
	verificar(
		'command_line/extra_args="--rendering-method gl_compatibility"' in presets,
		"o Android não usa o renderer de compatibilidade"
	)
	verificar(
		TelaInicialScript.estado_carregamento_falhou(ResourceLoader.THREAD_LOAD_FAILED)
		and TelaInicialScript.estado_carregamento_falhou(ResourceLoader.THREAD_LOAD_INVALID_RESOURCE),
		"o carregamento ainda ignora estados que fechavam o jogo"
	)
	var cena_menu := load("res://Rooms/TelaInicial.tscn") as PackedScene
	var menu := cena_menu.instantiate()
	var particulas := menu.get_node("parts_fundo") as GPUParticles2D
	verificar(not particulas.trail_enabled, "as partículas do menu ainda formam teias")
	verificar(particulas.preprocess <= 1.5, "o menu ainda possui pico alto de preprocess")
	verificar(particulas.amount <= 72, "o menu ainda cria partículas em excesso")
	menu.free()
	# Reproduz a corrida que existia entre node_added e a remoção no mesmo frame.
	var ambiente_transitorio := WorldEnvironment.new()
	ambiente_transitorio.add_to_group("ambiente_global")
	add_child(ambiente_transitorio)
	ambiente_transitorio.free()
	await get_tree().process_frame


func testar_contato_vinculos_e_pausa() -> void:
	var cena := load("res://Entities/InimigoCentelhaGuia.tscn") as PackedScene
	var inimigo := cena.instantiate() as InimigoSetorial
	add_child(inimigo)
	var alvo := AlvoContato.new()
	add_child(alvo)
	await get_tree().process_frame
	var vida_antes := inimigo.Vida
	inimigo.ao_colidir_com_player(alvo)
	verificar(not inimigo.morto, "o inimigo novo morreu ao tocar o player")
	verificar(is_equal_approx(inimigo.Vida, vida_antes), "o contato removeu vida do inimigo novo")

	var aliado := cena.instantiate() as InimigoSetorial
	add_child(aliado)
	await get_tree().process_frame
	inimigo.protegido = aliado
	aliado.set_meta("escudo_guia", inimigo)
	aliado.free()
	inimigo._manter_vinculos()
	verificar(inimigo.protegido == null, "o vínculo manteve referência a inimigo apagado")

	get_tree().paused = true
	inimigo.tomarDano(inimigo.Vida + 1.0)
	verificar(inimigo.morto, "a morte durante a pausa não foi concluída")
	verificar(inimigo.is_queued_for_deletion(), "a morte durante a pausa não agendou a remoção segura")
	get_tree().paused = false
	await get_tree().process_frame
	alvo.free()


func testar_hud_e_icone() -> void:
	var cena := load("res://Rooms/Battle_area.tscn") as PackedScene
	var batalha := cena.instantiate() as Node2D
	add_child(batalha)
	var vida := batalha.get_node("GUI/Barra_vida") as TextureProgressBar
	var xp := batalha.get_node("GUI/Barra_xp") as TextureProgressBar
	batalha.get_node("GUI")._ajustar_hud_responsivo()
	var centro := batalha.get_viewport().get_visible_rect().size.x * 0.5
	verificar(is_equal_approx(vida.position.x + vida.size.x * 0.5, centro), "a vida continua torta")
	verificar(is_equal_approx(xp.position.x + xp.size.x * 0.5, centro), "o XP continua torto")
	verificar(is_equal_approx(vida.size.x, xp.size.x), "vida e XP usam larguras diferentes")
	verificar(
		vida.fill_mode == TextureProgressBar.FILL_BILINEAR_LEFT_AND_RIGHT
		and xp.fill_mode == TextureProgressBar.FILL_BILINEAR_LEFT_AND_RIGHT,
		"as barras não variam a partir do centro"
	)

	# Reproduz a ordem exata relatada no PC: morte e comando de pausa no mesmo frame.
	var cena_classico := load("res://Entities/InimigoSeguidor.tscn") as PackedScene
	var classico := cena_classico.instantiate() as InimigoBase
	batalha.add_child(classico)
	classico.global_position = batalha.player.global_position + Vector2(120.0, 0.0)
	await get_tree().process_frame
	classico.tomarDano(classico.Vida + 1.0)
	Input.action_press("pausar")
	await get_tree().process_frame
	Input.action_release("pausar")
	verificar(get_tree().paused, "a pausa no frame da morte ficou inconsistente")
	get_tree().paused = false
	await get_tree().process_frame
	for audio in batalha.find_children("*", "AudioStreamPlayer2D", true, false):
		(audio as AudioStreamPlayer2D).stop()
	batalha.free()

	var tamanho_padrao := LojaController.tamanho_icone_item(&"c01_modelo_padrao")
	var tamanho_estrela := LojaController.tamanho_icone_item(&"c07_modelo_o")
	verificar(tamanho_estrela.x < tamanho_padrao.x, "o ícone da estrela continua maior que os layouts")


func finalizar() -> void:
	get_tree().paused = false
	for filho in get_children():
		if is_instance_valid(filho):
			filho.free()
	await get_tree().process_frame
	await get_tree().process_frame
	if falhas.is_empty():
		print("TESTE OK: crashes, contato, partículas, HUD e ícone da estrela")
	get_tree().quit(0 if falhas.is_empty() else 1)
