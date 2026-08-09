extends Habilidade
class_name HabilidadeRetrocesso


# ============================================================
# COOLDOWN
# ============================================================

@export_category("Cooldown")
@export var cooldown_max: float = 8.0

var cooldown: float = 0.0


# ============================================================
# MEMÓRIA
# ============================================================

@export_category("Retrocesso")
@export var intervalo_memorias: float = 0.01
@export var max_memoria: int = 60
@export var intervalo_rastro_rewind: int = 3

var memoria: Array = []
var recordando := false


# ============================================================
# ATIVAÇÃO
# ============================================================

func activate(player: Player) -> void:

	if recordando:
		return

	if cooldown > 0:
		return

	if memoria.is_empty():
		return

	recordando = true

	# Começa o cooldown imediatamente.
	cooldown = cooldown_max

	player.BloquearGiro()
	player.BloquearControle()

	player.velocity = Vector2.ZERO

	rewind(player)


# ============================================================
# UPDATE
# ============================================================

func update(player: Player, delta: float) -> void:

	# -------------------------
	# Cooldown
	# -------------------------

	if cooldown > 0:
		cooldown -= delta

		if cooldown < 0:
			cooldown = 0


	# -------------------------
	# Não grava durante rewind
	# -------------------------

	if recordando:
		return


	# -------------------------
	# Salva estado do player
	# -------------------------

	if memoria.size() >= max_memoria:
		memoria.pop_front()

	memoria.append({
		"posicao": player.global_position,
		"rotacao": player.rotation,
		"vida": player.vida
	})


# ============================================================
# REWIND
# ============================================================

func rewind(player: Player) -> void:

	if memoria.is_empty():
		finalizar_rewind(player)
		return

	player.IniciarHabilidade()

	var camera = player.get_node_or_null("../Camera2D")

	for save in range(memoria.size() - 1, -1, -1):

		# Se o jogo estiver pausado, espera.
		while player.get_tree().paused:
			await player.get_tree().process_frame

		# Verifica se o player ainda existe.
		if not is_instance_valid(player):
			recordando = false
			return


		# -------------------------
		# Recupera posição
		# -------------------------

		player.global_position = memoria[save]["posicao"]

		player.rotation = memoria[save]["rotacao"]


		# -------------------------
		# Recupera vida
		# -------------------------

		var vida_salva: float = memoria[save]["vida"]

		# O rewind pode recuperar vida,
		# mas nunca causar perda de vida.
		if vida_salva > player.vida:
			player.vida = vida_salva


		# -------------------------
		# Camera shake
		# -------------------------

		if camera and camera.has_method("shake"):

			if save % 4 == 0:
				camera.shake(2.5)


		# -------------------------
		# Efeito visual
		# -------------------------

		player.modulate.a = randf_range(0.3, 0.9)


		# -------------------------
		# Rastro temporal
		# -------------------------

		if save % intervalo_rastro_rewind == 0:
			criar_rastros(player)


		# -------------------------
		# Espera entre memórias
		# -------------------------

		await player.get_tree().create_timer(
			intervalo_memorias
		).timeout


	# -------------------------
	# Finaliza
	# -------------------------

	finalizar_rewind(player)


# ============================================================
# FINALIZAR REWIND
# ============================================================

func finalizar_rewind(player: Player) -> void:

	if not is_instance_valid(player):
		recordando = false
		return

	player.modulate.a = 1.0

	var camera = player.get_node_or_null("../Camera2D")

	if camera and camera.has_method("shake"):
		camera.shake(4.0)

	player.EncerrarHabilidade()

	memoria.clear()

	recordando = false

	player.DesbloquearGiro()
	player.DesbloquearControle()


# ============================================================
# CRIAR RASTROS
# ============================================================

func criar_rastros(player: Player) -> void:

	# Procura todos os Polygon2D dentro do Player.
	var poligonos = player.find_children(
		"*",
		"Polygon2D",
		true,
		false
	)

	for poligono in poligonos:
		criar_rastro_temporal(player, poligono)


# ============================================================
# RASTRO TEMPORAL
# ============================================================

func criar_rastro_temporal(
	player: Player,
	poligono_original: Polygon2D
) -> void:

	if not is_instance_valid(poligono_original):
		return

	var copia := poligono_original.duplicate() as Polygon2D

	if not copia:
		return


	# Mantém a posição exata do Polygon2D.
	copia.global_position = poligono_original.global_position
	copia.global_rotation = poligono_original.global_rotation
	copia.global_scale = poligono_original.global_scale


	# Cor do rastro.
	copia.modulate = Color(
		0.8,
		0.0,
		1.0,
		0.6
	)


	# Coloca o rastro na mesma cena do Player.
	player.get_parent().add_child(copia)


	# Desaparece rapidamente.
	var tween := player.create_tween()

	tween.tween_property(
		copia,
		"modulate:a",
		0.0,
		0.15
	)

	tween.tween_callback(
		copia.queue_free
	)
