extends InimigoBase


@export_category("Recompensas")
@export_range(1.0, 100.0, 0.5) var cura_base: float = 10.0
@export_range(0.0, 20.0, 0.5) var cura_por_nivel_blindagem: float = 2.5
@export_range(1.0, 30.0, 0.5) var xp_base: float = 3.0
@export_range(0.0, 5.0, 0.1) var xp_por_nivel_player: float = 0.6

@export_category("Movimento")
@export_range(0.2, 3.0, 0.1) var velocidade_giro: float = 1.2

var direcao_movimento := Vector2.RIGHT
var sentido_giro: float = 1.0

@onready var visual: Node2D = $Visual


func _ready() -> void:
	super._ready()
	sentido_giro = -1.0 if randf() < 0.5 else 1.0
	var escala_aleatoria := randf_range(0.72, 0.94)
	scale = Vector2.ONE * escala_aleatoria


func configurar_movimento(destino: Vector2) -> void:
	direcao_movimento = global_position.direction_to(destino)
	if direcao_movimento.is_zero_approx():
		direcao_movimento = Vector2.from_angle(randf_range(0.0, TAU))
	direcao_movimento = direcao_movimento.rotated(randf_range(-0.22, 0.22))


func Mover(delta: float) -> void:
	visual.rotation += velocidade_giro * sentido_giro * delta
	velocity = direcao_movimento * Velocidade


func conceder_recompensa() -> void:
	if not is_instance_valid(player):
		return

	var cura_calculada := calcular_cura()
	var xp_calculado := calcular_xp()
	var vida_antes := float(player.get("vida"))
	if player.has_method("curar"):
		player.curar(cura_calculada)
	if player.has_method("ganhar_xp"):
		player.ganhar_xp(xp_calculado)
	var cura_recebida := maxf(float(player.get("vida")) - vida_antes, 0.0)
	mostrar_recompensa(
		"+%d VIDA  •  +%d XP" % [roundi(cura_recebida), roundi(xp_calculado)],
		Color(0.82, 0.86, 0.95, 1.0)
	)


func calcular_cura() -> float:
	var nivel_blindagem := 0
	var niveis = player.get("niveis_upgrades") if is_instance_valid(player) else null
	if niveis is Dictionary:
		nivel_blindagem = int(niveis.get(&"blindagem", 0))
	return cura_base + cura_por_nivel_blindagem * float(nivel_blindagem)


func calcular_xp() -> float:
	var nivel_player := 1
	if is_instance_valid(player):
		var nivel = player.get("nivel_atual")
		if nivel != null:
			nivel_player = maxi(int(nivel), 1)
	return xp_base + xp_por_nivel_player * float(nivel_player - 1)


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
