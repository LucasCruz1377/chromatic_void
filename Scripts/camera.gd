extends Camera2D

var ForcaShake := 0.0
var DuracaoShake := 0.0
var DuracaoMax := 0

func _ready() -> void:
	CameraShake.Camera = self

func shake(forca: float, duracao: float):
	if forca > ForcaShake:
		ForcaShake = forca
	
	DuracaoShake = max(DuracaoShake,duracao)
	DuracaoMax = max(DuracaoShake,duracao)
	
func _process(delta: float) -> void:
	if DuracaoShake > 0:
		DuracaoShake -= delta
	
		var tempo = DuracaoShake/ DuracaoMax 
		
		offset = Vector2(randf_range(-ForcaShake * tempo, ForcaShake * tempo), randf_range(-ForcaShake * tempo, ForcaShake * tempo) )
		
		
	else:
		offset = Vector2.ZERO
