extends Node


const CENAS_PRINCIPAIS: Array[String] = [
	"res://Rooms/TelaInicial.tscn",
	"res://Rooms/Loja.tscn",
	"res://Rooms/configuracoes.tscn",
	"res://Rooms/Battle_area.tscn",
	"res://Rooms/loading_screen.tscn",
]

var falhas: Array[String] = []


func verificar(condicao: bool, mensagem: String) -> void:
	if not condicao:
		falhas.append(mensagem)
		push_error("CENAS PRINCIPAIS: " + mensagem)


func _ready() -> void:
	for caminho in CENAS_PRINCIPAIS:
		var cena := load(caminho) as PackedScene
		verificar(cena != null, "%s não carregou" % caminho)
		if cena == null:
			continue

		var instancia := cena.instantiate()
		verificar(instancia != null, "%s não pôde ser instanciada" % caminho)
		if is_instance_valid(instancia):
			instancia.free()

	var cena_menu := load("res://Rooms/TelaInicial.tscn") as PackedScene
	if cena_menu != null:
		var menu := cena_menu.instantiate()
		var musica := menu.get_node_or_null("menumusica") as AudioStreamPlayer2D
		var astro := menu.get_node_or_null("Astro")
		verificar(is_instance_valid(musica), "a tela inicial não possui player de música")
		if is_instance_valid(musica):
			verificar(
				musica.stream != null
				and musica.stream.resource_path.ends_with("sounds/OST/The colors of the void.ogg"),
				"The colors of the void não está configurada na tela inicial"
			)
			verificar(musica.bus == &"Music", "a nova faixa não utiliza o barramento Music")
		verificar(
			menu.get_node_or_null("CanvasLayer/Button") == null,
			"o botão antigo Apagar Save ainda está na tela inicial"
		)
		verificar(is_instance_valid(astro), "o Astro não está presente na tela inicial")
		if is_instance_valid(astro):
			var curiosidades: Array = astro.get("curiosidades_monthly_colors") as Array
			verificar(
				curiosidades.size() >= 30,
				"o Astro não possui curiosidades suficientes sobre o Monthly Colors"
			)
			verificar(
				curiosidades.any(func(texto: String) -> bool: return "Lua Rosa" in texto),
				"o Astro não utiliza as curiosidades específicas dos cards do site"
			)
		menu.get_node("JanelaAtualizacao").verificar_automaticamente = false
		get_tree().root.add_child.call_deferred(menu)
		await get_tree().process_frame
		await get_tree().process_frame
		get_tree().current_scene = menu
		menu.botao_iniciar.pressed.emit()
		var solo := menu.conteudo_fluxo.get_child(2) as Button
		verificar(solo != null and solo.text == tr("JOGAR SOLO"), "o menu não oferece Jogar Solo")
		if solo:
			solo.pressed.emit()
			verificar(menu.tela_carregamento.is_visible_in_tree(), "o carregamento não apareceu no clique")
			verificar(not menu.camada_fluxo.visible and not menu.get_node("CanvasLayer").visible and not menu.get_node("CursorLayer").visible, "o menu ou cursor ficou sobre o carregamento")
			verificar(menu.tela_carregamento.get_global_rect().is_equal_approx(get_viewport().get_visible_rect()), "carregamento não cobre a tela")
			var prazo := Time.get_ticks_msec() + 10000
			while is_instance_valid(menu) and Time.get_ticks_msec() < prazo:
				await get_tree().process_frame
			var destino := get_tree().current_scene
			verificar(is_instance_valid(destino) and destino.scene_file_path == "res://Rooms/Battle_area.tscn", "Jogar Solo não abriu a arena")
			if is_instance_valid(destino):
				destino.queue_free()
				await get_tree().process_frame
				await get_tree().create_timer(0.3).timeout

	if falhas.is_empty():
		print("TESTE OK: telas principais carregam e podem ser instanciadas")
		get_tree().quit(0)
	else:
		print("TESTE FALHOU: %d tela(s) principal(is) inválida(s)" % falhas.size())
		get_tree().quit(1)
