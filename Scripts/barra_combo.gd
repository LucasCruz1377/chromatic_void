extends ProgressBar

@onready var textocombo: RichTextLabel = $textocombo
@onready var anim: AnimationPlayer = $anim


var combotarget := 0
const DURACAO_COMBO := 3.0
var timer := 0.0

func _process(delta: float) -> void:
	if Global.Combo <= 0:
		visible = false
	else:
		visible = true

	if combotarget != Global.Combo:
		if Global.Combo > combotarget:
			anim.play("combo_pop")
			timer = DURACAO_COMBO
		combotarget = Global.Combo

	if Global.Combo > 0:
		timer = maxf(timer - delta, 0.0)
	else:
		timer = 0.0

	# A HUD apenas representa o combo. A duração e a autoridade pertencem à
	# batalha/host; assim câmera lenta, FPS e habilidades não zeram o estado.
	value = timer / DURACAO_COMBO * max_value
	textocombo.text = "[shake]" + str(combotarget) + "x[/shake]"
