extends InimigoBase


enum TipoRecompensa {
	CURA,
	XP,
}

@export_range(1.0, 100.0, 1.0) var cura_bonus: float = 18.0
@export_range(1.0, 30.0, 1.0) var xp_bonus: float = 5.0
@export_range(0.2, 3.0, 0.1) var velocidade_giro: float = 1.2

var tipo_recompensa: TipoRecompensa = TipoRecompensa.XP
var direcao_movimento := Vector2.RIGHT
var sentido_giro: float = 1.0

@onready var visual: Node2D = $Visual
@onready var nucleo: Polygon2D = $Visual/Nucleo


func _ready() -> void:
	super._ready()
	tipo_recompensa = (
		TipoRecompensa.CURA if randf() < 0.5 else TipoRecompensa.XP
	)
	sentido_giro = -1.0 if randf() < 0.5 else 1.0
	var escala_aleatoria := randf_range(0.72, 0.94)
	scale = Vector2.ONE * escala_aleatoria
	atualizar_cor_recompensa()


func configurar_movimento(destino: Vector2) -> void:
	direcao_movimento = global_position.direction_to(destino)
	if direcao_movimento.is_zero_approx():
		direcao_movimento = Vector2.from_angle(randf_range(0.0, TAU))
	direcao_movimento = direcao_movimento.rotated(randf_range(-0.22, 0.22))


func Mover(delta: float) -> void:
	visual.rotation += velocidade_giro * sentido_giro * delta
	velocity = direcao_movimento * Velocidade


func atualizar_cor_recompensa() -> void:
	if tipo_recompensa == TipoRecompensa.CURA:
		nucleo.color = Color(0.20, 1.0, 0.48, 1.0)
	else:
		nucleo.color = Color(0.28, 0.82, 1.0, 1.0)


func conceder_recompensa() -> void:
	if not is_instance_valid(player):
		return

	var recompensa_final := tipo_recompensa
	var vida_atual = player.get("vida")
	var vida_maxima = player.get("VIDA_MAXIMA")
	if (
		recompensa_final == TipoRecompensa.CURA
		and vida_atual != null
		and vida_maxima != null
		and float(vida_atual) >= float(vida_maxima) - 0.01
	):
		recompensa_final = TipoRecompensa.XP

	if recompensa_final == TipoRecompensa.CURA and player.has_method("curar"):
		player.curar(cura_bonus)
		mostrar_recompensa("+CURA", Color(0.20, 1.0, 0.48, 1.0))
	elif player.has_method("ganhar_xp"):
		player.ganhar_xp(xp_bonus)
		mostrar_recompensa("+XP", Color(0.28, 0.82, 1.0, 1.0))


func mostrar_recompensa(texto: String, cor: Color) -> void:
	var aviso := Label.new()
	aviso.text = texto
	aviso.global_position = global_position - Vector2(24.0, 28.0)
	aviso.z_index = 20
	aviso.add_theme_color_override("font_color", cor)
	aviso.add_theme_font_size_override("font_size", 15)
	get_tree().current_scene.add_child(aviso)

	var tween := aviso.create_tween().set_parallel(true)
	tween.tween_property(aviso, "position:y", aviso.position.y - 26.0, 0.65)
	tween.tween_property(aviso, "modulate:a", 0.0, 0.65)
	tween.chain().tween_callback(aviso.queue_free)
