extends ProgressBar

@onready var progresso: ProgressBar = $Progresso

func _process(_delta: float) -> void:
	progresso.value = value	
