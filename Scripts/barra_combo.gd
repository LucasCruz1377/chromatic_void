extends ProgressBar

@onready var textocombo: Label = $textocombo
@onready var anim: AnimationPlayer = $anim


var combotarget = 0
const max_timer = 60 * 5
var timer = max_timer

func _process(_delta: float) -> void:
	if Global.Combo <= 0:
		visible = false
	else:
		visible = true
		
	if combotarget < Global.Combo:
		anim.play("combo_pop")
		combotarget += 1
		timer = max_timer
		
	if timer > 0 and Global.Combo != 0:
		timer -= 1
	else:
		visible = false
	
	if timer == 0 :
		Global.Combo = 0
		combotarget = 0
		timer = -2
	
	if Global.Combo != 0:
		visible = true

	value = timer
	textocombo.text = str(combotarget) + "x"
