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
		menu.free()

	if falhas.is_empty():
		print("TESTE OK: telas principais carregam e podem ser instanciadas")
		get_tree().quit(0)
	else:
		print("TESTE FALHOU: %d tela(s) principal(is) inválida(s)" % falhas.size())
		get_tree().quit(1)
