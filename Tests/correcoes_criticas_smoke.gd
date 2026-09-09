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
	await testar_combo_habilidade_e_loja()
	await finalizar()


func testar_perfil_mobile_e_particulas() -> void:
	var presets := FileAccess.get_file_as_string("res://export_presets.cfg")
	verificar(
		'command_line/extra_args="--rendering-method gl_compatibility"' not in presets
		and str(ProjectSettings.get_setting("rendering/renderer/rendering_method")) == "mobile"
		and bool(ProjectSettings.get_setting("rendering/rendering_device/fallback_to_opengl3")),
		"o Android não usa Mobile/Vulkan com fallback seguro para OpenGL"
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
	verificar(particulas.amount == 200, "o menu perdeu a densidade visual da 0.7.1")
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
	var centro := Global.obter_retangulo_area_visivel(18.0).get_center().x
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


func testar_combo_habilidade_e_loja() -> void:
	var cena_batalha := load("res://Rooms/Battle_area.tscn") as PackedScene
	var batalha := cena_batalha.instantiate() as Node2D
	add_child(batalha)
	batalha.tutorial_ativo = false
	Global.Combo = 4
	batalha._processar_combo(0.1)
	batalha.player.ao_ativar_habilidade()
	batalha._processar_combo(0.35)
	verificar(Global.Combo == 4, "usar a habilidade ativa zerou o combo no singleplayer")

	var inimigo := load("res://Entities/InimigoSeguidor.tscn").instantiate() as InimigoBase
	batalha.add_child(inimigo)
	inimigo.global_position = Vector2(420, 240)
	await get_tree().process_frame
	inimigo.criar_particulas_morte()
	var encontrou_cor := false
	for filho in batalha.get_children():
		if filho is GPUParticles2D and (filho as CanvasItem).modulate != Color.WHITE:
			encontrou_cor = true
	verificar(encontrou_cor, "as partículas locais de inimigo continuam brancas")
	batalha.free()
	Global.Combo = 0
	await get_tree().process_frame

	var cena_loja := load("res://Rooms/Loja.tscn") as PackedScene
	var loja = cena_loja.instantiate()
	add_child(loja)
	await get_tree().process_frame
	loja._aplicar_layout_responsivo(Vector2(640, 360), true)
	await get_tree().process_frame
	verificar(loja.botao_acao.custom_minimum_size.y >= 44.0, "o botão Equipar ainda pode ser cortado verticalmente")
	verificar(not loja.detalhe_descricao.clip_text, "a descrição da loja ainda recorta o texto")
	var slider := loja.rolagem_detalhes.get_v_scroll_bar() as VScrollBar
	verificar(slider.custom_minimum_size.x <= 10.0, "o slider da descrição ocupa largura excessiva")
	verificar(
		loja.coluna_detalhes.get_combined_minimum_size().x <= loja.rolagem_detalhes.size.x + 1.0,
		"o conteúdo da loja continua mais largo que a caixa e corta o lado direito"
	)
	loja.free()


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
