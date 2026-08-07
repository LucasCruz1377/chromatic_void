extends Control

@onready var texto_label : RichTextLabel = $DialogoAstro
@onready var som_digito : AudioStreamPlayer2D = $VozAstro
@onready var timer_proxima : Timer = $Timer

@export var velocidade_escrita : float = 0.03
@export var tempo_espera_frase : float = 5.0


var dialogo_inicial = [
	"Olá, é sua primeira vez jogando?",
	"Me chamo Astro, e quero te ensinar o básico sobre esse jogo",
	"Antes de tudo, o jogo está em desenvolvimento, então pode conter erros",
	"Para acelerar use W, para frear use S e para virar a nave para os lados você pode usar o mouse, mas nas configurações é possível mudar os controles para apenas teclado",
	"Para atirar, aperte ou segure o botão esquero do mouse ou a tecla [color=yellow]F[/color], caso esteja jogando sem mirar com o mouse",
	"Além desses controles você pode apertar Espaço para usar sua habilidade especial, que nesta versão por padrão é o poder do Retrocesso",
]

var curiosidades : Array[String] = [
	"T_CURIOSIDADE1",
	"O aniversário do programador deste jogo é em fevereiro",
	"A Co-Criadora deste jogo adora crochê",
	"Os criadores deste jogo estão juntos há mais de 1 ano ",
	"Acesse também nosso site Monthly Colors"
]

func _ready() -> void:
	

	timer_proxima.wait_time = tempo_espera_frase
	timer_proxima.timeout.connect(mostrar_nova_curiosidade)
	
	mostrar_nova_curiosidade()

func mostrar_nova_curiosidade() -> void:
	if Global.primeira_vez_jogando:
		texto_label.text = "[wave]Olá, eu sou o [color=yellow]Astro"
		return
		
	timer_proxima.stop()
	
	var chave_aleatoria = curiosidades.pick_random()
	texto_label.text = tr(chave_aleatoria)
	texto_label.visible_ratio = 0.0
	
	var total_caracteres = texto_label.get_parsed_text().length()
	var duracao_total = total_caracteres * velocidade_escrita
	
	var tween = create_tween()
	tween.tween_property(texto_label, "visible_ratio", 1.0, duracao_total).from(0.0)
	
	var ratio_anterior = 0.0
	while tween.is_running():
		var caracteres_atuais = floor(texto_label.visible_ratio * total_caracteres)
		var caracteres_anteriores = floor(ratio_anterior * total_caracteres)
		
		if caracteres_atuais > caracteres_anteriores:
			if som_digito and not som_digito.playing:
				som_digito.pitch_scale = randf_range(0.9, 1.1)
				som_digito.play()
				
		ratio_anterior = texto_label.visible_ratio
		await get_tree().process_frame
		
	texto_label.visible_ratio = 1.0
	timer_proxima.start()

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("atirar"):
		texto_label.visible_ratio += 0.1
	
	var tempo = Time.get_ticks_msec() / 1000.0
	position.y += sin(tempo * 3.0) * 0.5
	rotation = sin(tempo * 2.0) * 0.02
