extends Control

@onready var texto_label: RichTextLabel = $DialogoAstro
@onready var som_digito: AudioStreamPlayer2D = $VozAstro
@onready var timer_proxima: Timer = $Timer

@export var velocidade_escrita: float = 0.03

const INTERVALO_CURIOSIDADE_MENU := 6.5

var apresentacao: Array[String] = [
	"Olá! Eu sou o Astro, seu guia pelo Chromatic Void e pelas histórias do Monthly Colors!"
]

var curiosidades_monthly_colors: Array[String] = [
	"Janeiro recebeu esse nome por causa de Janus, o deus romano que olhava para o passado e para o futuro.",
	"No calendário romano original, o ano começava em março e possuía apenas dez meses.",
	"No começo de janeiro acontece o periélio: o ponto em que a Terra fica mais próxima do Sol.",
	"A Lua Cheia de janeiro é chamada [color=#72e7ff]Lua do Lobo[/color], por uma tradição do Hemisfério Norte.",
	"Fevereiro vem de [i]Februarius[/i], nome ligado a um antigo ritual romano de purificação.",
	"A [color=#72e7ff]Lua da Neve[/color] recebeu esse nome por causa das nevascas de fevereiro no Hemisfério Norte.",
	"O Carnaval possui raízes em festas antigas e, no Brasil, misturou influências africanas, indígenas e europeias.",
	"Março vem de Marte, que além da guerra também era considerado protetor da agricultura pelos romanos.",
	"No equinócio de março, dia e noite ficam com durações muito próximas em todo o planeta.",
	"A [color=#72e7ff]Lua do Verme[/color] marca o degelo e o retorno das minhocas no Hemisfério Norte.",
	"Abril pode vir do latim [i]aperire[/i], que significa abrir, como as flores na primavera do Hemisfério Norte.",
	"A [color=#ff8fd8]Lua Rosa[/color] não fica rosa: o nome vem de uma flor que desabrocha em abril.",
	"O Dia da Terra é celebrado em 22 de abril e chama atenção para a preservação ambiental.",
	"Maio provavelmente homenageia Maia, deusa romana ligada ao crescimento e à fertilidade.",
	"A [color=#72e7ff]Lua das Flores[/color] representa o período de muitas flores silvestres no Hemisfério Norte.",
	"Junho pode ter recebido esse nome em homenagem a Juno, divindade romana ligada à família.",
	"As festas juninas celebram Santo Antônio no dia 13, São João no dia 24 e São Pedro no dia 29.",
	"O solstício de junho traz o dia mais curto e a noite mais longa do ano para o Hemisfério Sul.",
	"A [color=#ff7070]Lua de Morango[/color] não fica vermelha: o nome vem da época de colher morangos silvestres.",
	"Julho já se chamou [i]Quintilis[/i] e foi renomeado em homenagem a Júlio César.",
	"A [color=#72e7ff]Lua dos Cervos[/color] lembra a época em que novas galhadas crescem nesses animais.",
	"Agosto já se chamou [i]Sextilis[/i] e recebeu o nome atual em homenagem ao imperador César Augusto.",
	"A [color=#72e7ff]Lua do Esturjão[/color] lembra a época de pesca abundante desse peixe nos grandes lagos.",
	"Setembro vem de [i]septem[/i], sete em latim, porque já foi o sétimo mês do calendário romano.",
	"A [color=#ffd86b]Lua da Colheita[/color] é a Lua Cheia mais próxima do equinócio de setembro.",
	"Outubro vem de [i]octo[/i], oito em latim, embora hoje seja o décimo mês.",
	"A [color=#72e7ff]Lua do Caçador[/color] é a Lua Cheia que tradicionalmente sucede a Lua da Colheita.",
	"Novembro vem de [i]novem[/i], nove em latim, posição que ocupava no calendário romano antigo.",
	"A [color=#72e7ff]Lua do Castor[/color] está ligada ao período de preparação para o inverno no Hemisfério Norte.",
	"Dezembro vem de [i]decem[/i], dez em latim, embora atualmente encerre os doze meses do ano.",
	"A [color=#72e7ff]Lua Fria[/color] recebeu esse nome por causa das noites longas de dezembro no Hemisfério Norte.",
	"Gostou da curiosidade? Há muito mais nos cards de [color=#72e7ff]tami4lvess.github.io/Monthly-Colors[/color]!",
	"O Monthly Colors também reúne campanhas, datas e fases da Lua. Visite o site e escolha um mês para explorar!"
]

var dialogo_inicial: Array[String] = [
	"Agora vou te ensinar o básico sobre o jogo.",
	"O jogo ainda está em desenvolvimento, então podem existir alguns erros.",
	"Para acelerar use W e para frear use S.",
	"Para virar a nave, use o mouse. Nas configurações você pode mudar para usar apenas o teclado.",
	"Para atirar, use o botão esquerdo do mouse ou a tecla [color=yellow]F[/color].",
	"Pressione Espaço para usar sua habilidade especial."
]

var dialogo_inicial_mobile: Array[String] = [
	"Agora vou te ensinar o básico sobre o jogo.",
	"O jogo ainda está em desenvolvimento, então podem existir alguns erros.",
	"Arraste o analógico do lado esquerdo para apontar e acelerar a nave.",
	"Segure [color=yellow]TIRO[/color] para disparar. Você pode mover e atirar com dois dedos ao mesmo tempo.",
	"Toque em [color=yellow]PODER[/color] para usar sua habilidade especial.",
	"Os botões [color=yellow]UP[/color] e [color=yellow]II[/color] abrem as melhorias e a pausa. Toque no texto para avançar mais rápido."
]

var indice_dialogo: int = 0
var escrevendo: bool = false
var tutorial_ativo: bool = false
var tutorial_terminado: bool = false
var modo_menu: bool = false
var fila_curiosidades: Array[String] = []
var ultima_curiosidade: String = ""
var geracao_fala: int = 0
var tween_texto: Tween
var jogador: Player


func _ready() -> void:
	# O Astro só deve aparecer quando Battle_area mandar iniciar o tutorial.
	visible = false
	texto_label.visible = false
	set_process_input(false)
	timer_proxima.one_shot = true
	timer_proxima.wait_time = INTERVALO_CURIOSIDADE_MENU
	if not timer_proxima.timeout.is_connected(_on_timer_proxima_timeout):
		timer_proxima.timeout.connect(_on_timer_proxima_timeout)


func apresentar() -> void:
	# A apresentação pessoal acontece uma única vez; as curiosidades continuam
	# aparecendo em todas as visitas à tela inicial.
	var dados: Dictionary = GerenciadorDeSave.carregar()
	var primeira_apresentacao: bool = _deve_se_apresentar(dados)
	modo_menu = true
	visible = true
	texto_label.visible = true
	set_process_input(true)
	if primeira_apresentacao:
		GerenciadorDeSave.salvar({"astro_apresentado_menu": true})
		falar(apresentacao[0])
	else:
		mostrar_proxima_curiosidade()


func _deve_se_apresentar(dados: Dictionary) -> bool:
	# Saves antigos ainda não possuem a nova chave. O tutorial concluído permite
	# reconhecer quem já jogava antes desta atualização e evita reapresentá-lo.
	return (
		not bool(dados.get("astro_apresentado_menu", false))
		and not bool(dados.get("tutorialconcluido", false))
	)


func iniciar_tutorial(player: Player) -> void:
	if tutorial_ativo or tutorial_terminado:
		return

	print("ASTRO: INICIANDO TUTORIAL")

	jogador = player
	modo_menu = false
	timer_proxima.stop()
	indice_dialogo = 0
	if Global.dispositivo_mobile():
		dialogo_inicial = dialogo_inicial_mobile.duplicate()
	tutorial_ativo = true
	tutorial_terminado = false

	visible = true
	texto_label.visible = true
	set_process_input(true)

	if is_instance_valid(jogador):
		jogador.BloquearControle()
		jogador.BloquearGiro()

	# Garante que o primeiro texto seja mostrado já no começo do tutorial.
	falar(dialogo_inicial[indice_dialogo])


func falar(texto: String) -> void:
	geracao_fala += 1
	var fala_atual: int = geracao_fala
	if tween_texto and tween_texto.is_valid():
		tween_texto.kill()

	visible = true
	texto_label.visible = true
	texto_label.text = texto
	texto_label.visible_characters = 0

	escrevendo = true

	var total_caracteres: int = texto_label.get_parsed_text().length()

	for i in range(total_caracteres + 1):
		# Caso outra fala tenha interrompido essa.
		if fala_atual != geracao_fala or not escrevendo:
			return

		texto_label.visible_characters = i

		# Toca o som a cada caractere.
		if i > 0 and som_digito.stream:
			som_digito.pitch_scale = randf_range(0.95, 1.05)
			som_digito.play()

		await get_tree().create_timer(velocidade_escrita).timeout

	escrevendo = false
	_on_fala_terminou()


func _on_fala_terminou() -> void:
	escrevendo = false
	if modo_menu and not curiosidades_monthly_colors.is_empty():
		timer_proxima.start(INTERVALO_CURIOSIDADE_MENU)


func _on_timer_proxima_timeout() -> void:
	if not modo_menu or curiosidades_monthly_colors.is_empty():
		return
	mostrar_proxima_curiosidade()


func mostrar_proxima_curiosidade() -> void:
	if not modo_menu or curiosidades_monthly_colors.is_empty():
		return
	timer_proxima.stop()
	falar(_sortear_curiosidade())


func _sortear_curiosidade() -> String:
	if fila_curiosidades.is_empty():
		fila_curiosidades = curiosidades_monthly_colors.duplicate()
		fila_curiosidades.shuffle()
		if fila_curiosidades.size() > 1 and fila_curiosidades.back() == ultima_curiosidade:
			var primeira: String = fila_curiosidades[0]
			fila_curiosidades[0] = fila_curiosidades.back()
			fila_curiosidades[fila_curiosidades.size() - 1] = primeira

	var curiosidade: String = fila_curiosidades.pop_back()
	ultima_curiosidade = curiosidade
	return curiosidade


func completar_fala() -> void:
	if not escrevendo:
		return

	if tween_texto and tween_texto.is_valid():
		tween_texto.kill()

	geracao_fala += 1
	texto_label.visible_ratio = 1.0
	escrevendo = false
	_on_fala_terminou()


func proxima_fala() -> void:
	if modo_menu:
		mostrar_proxima_curiosidade()
		return

	if not tutorial_ativo:
		return

	indice_dialogo += 1

	if indice_dialogo < dialogo_inicial.size():
		falar(dialogo_inicial[indice_dialogo])
	else:
		terminar_tutorial()


func terminar_tutorial() -> void:
	if tutorial_terminado:
		return

	print("ASTRO: TUTORIAL TERMINADO")

	tutorial_ativo = false
	tutorial_terminado = true
	modo_menu = false
	timer_proxima.stop()
	set_process_input(false)

	if tween_texto and tween_texto.is_valid():
		tween_texto.kill()

	escrevendo = false

	# Marca permanentemente que o tutorial já foi visto.
	GerenciadorDeSave.salvar({
		"tutorialconcluido": true
	})

	# Libera completamente o jogador.
	if is_instance_valid(jogador):
		jogador.DesbloquearControle()
		jogador.DesbloquearGiro()

	# A Battle Area volta a rodar spawn e gameplay normal.
	var area_batalha := get_tree().current_scene
	if area_batalha and area_batalha.has_method("finalizar_tutorial"):
		area_batalha.finalizar_tutorial()

	# O Astro existe apenas para o tutorial.
	queue_free()


func _input(event: InputEvent) -> void:
	if not tutorial_ativo and not modo_menu:
		return

	var avancar := false

	# Clique esquerdo.
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			avancar = true
	if event is InputEventScreenTouch:
		var toque := event as InputEventScreenTouch
		if toque.pressed:
			avancar = true

	# Teclado e controle também podem avançar sem tirar o suporte ao clique.
	if event.is_action_pressed("atirar"):
		avancar = true
	if event.is_action_pressed("ui_accept"):
		avancar = true

	if not avancar:
		return

	# No tutorial a conversa é modal. No menu, o clique também pode acionar o
	# botão escolhido pelo jogador enquanto adianta a fala do Astro.
	if tutorial_ativo:
		get_viewport().set_input_as_handled()

	# Um clique completa a frase; o próximo passa para a seguinte.
	if escrevendo:
		completar_fala()
	else:
		proxima_fala()
