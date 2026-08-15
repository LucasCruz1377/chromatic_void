extends InimigoBase
class_name FragmentoReciclavel


var dono_boss: Node
var direcao_deriva := Vector2.RIGHT


func _ready() -> void:
	super._ready()
	direcao_deriva = Vector2.from_angle(randf_range(0.0, TAU))
	velocity = direcao_deriva * Velocidade


func Mover(delta: float) -> void:
	rotation += delta * 2.4
	velocity = velocity.move_toward(direcao_deriva * Velocidade, 30.0 * delta)


func morrer() -> void:
	if morto:
		return
	if Vida > 0.0:
		return

	if is_instance_valid(dono_boss) and dono_boss.has_method("registrar_reciclagem"):
		dono_boss.registrar_reciclagem(1)

	super.morrer()


func ao_colidir_com_player(_alvo: Node) -> void:
	# É lixo que deve ser destruído pelos tiros; tocar nele não causa dano.
	pass
