extends Area2D
class_name ProjetilInimigo


const BRILHO_PROJETEIS_PADRAO := 1.45

@export_category("Neon")
@export_range(0.6, 3.0, 0.05) var brilho_visual: float = BRILHO_PROJETEIS_PADRAO

@export_category("Movimento e dano")
@export var velocidade: float = 330.0
@export var dano: float = 10.0
@export var tempo_vida: float = 5.0
@export var rebotes_max: int = 0
@export var usa_wrap: bool = false

var direcao: Vector2 = Vector2.RIGHT
var rebotes: int = 0
# Prazo de segurança local para cópias que perderam o despawn do host.
var prazo_visual_rede: float = 0.0
var prazo_visual_iniciado := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	aplicar_glow()
	_configurar_sincronizador_multiplayer()
	if Rede.modo_multiplayer and not multiplayer.is_server():
		# O cliente mantém somente o movimento visual. Colisão e dano continuam
		# exclusivamente no host.
		monitoring = false
		monitorable = false


func _configurar_sincronizador_multiplayer() -> void:
	if not Rede.modo_multiplayer or has_node("MultiplayerSynchronizer"):
		return
	var sincronizador := MultiplayerSynchronizer.new()
	sincronizador.name = "MultiplayerSynchronizer"
	sincronizador.root_path = NodePath("..")
	var configuracao := SceneReplicationConfig.new()
	var propriedades_movimento: Array[NodePath] = [
		NodePath(".:position"),
		NodePath(".:rotation"),
		NodePath(".:direcao"),
		NodePath(".:rebotes"),
	]
	var propriedades_configuracao: Array[NodePath] = [
		NodePath(".:velocidade"),
		NodePath(".:usa_wrap"),
		NodePath(".:rebotes_max"),
		NodePath(".:tempo_vida"),
		NodePath(".:scale"),
		NodePath(".:modulate"),
	]
	# O host define a configuracao inicial e corrige a trajetoria durante
	# a vida do projetil. Isso evita divergencia de ricochetes sob latencia.
	for caminho in propriedades_movimento + propriedades_configuracao:
		configuracao.add_property(caminho)
		configuracao.property_set_spawn(caminho, true)
		configuracao.property_set_sync(caminho, caminho in propriedades_movimento)
	sincronizador.replication_interval = 0.10
	sincronizador.replication_config = configuracao
	add_child(sincronizador)


func aplicar_glow() -> void:
	var intensidade := clampf(brilho_visual, 0.6, 3.0)
	for node in find_children("*", "CanvasItem", true, false):
		var item := node as CanvasItem
		if (
			item is Polygon2D
			or item is Line2D
			or item is Sprite2D
			or item is AnimatedSprite2D
		):
			item.self_modulate = Color(
				intensidade, intensidade, intensidade, item.self_modulate.a
			)


func configurar(
	nova_direcao: Vector2,
	novo_dano: float,
	nova_velocidade: float = -1.0,
	novos_rebotes: int = -1
) -> void:
	direcao = nova_direcao.normalized()
	dano = novo_dano
	rotation = direcao.angle()

	if nova_velocidade > 0.0:
		velocidade = nova_velocidade
	if novos_rebotes >= 0:
		rebotes_max = novos_rebotes


func _physics_process(delta: float) -> void:
	if Rede.modo_multiplayer and not multiplayer.is_server():
		if not prazo_visual_iniciado:
			prazo_visual_iniciado = true
			prazo_visual_rede = maxf(tempo_vida, 0.5) + 2.0
		prazo_visual_rede -= delta
		if prazo_visual_rede <= 0.0:
			queue_free()
			return
		# Predição visual entre snapshots; não processa bordas, vida ou colisão.
		# No primeiro quadro de um spawn remoto, a direção configurada pode chegar
		# depois do nó. A rotação inicial mantém o tiro em movimento nesse intervalo.
		var direcao_visual := direcao
		if direcao_visual.is_zero_approx():
			direcao_visual = Vector2.RIGHT.rotated(rotation)
		global_position += direcao_visual.normalized() * velocidade * delta
		rotation = direcao_visual.angle()
		if usa_wrap:
			var area_visual := Global.obter_retangulo_area_visivel()
			global_position.x = wrapf(global_position.x, area_visual.position.x, area_visual.end.x)
			global_position.y = wrapf(global_position.y, area_visual.position.y, area_visual.end.y)
		# A simulacao de bordas, rebotes e destruicao e exclusiva do host.
		# O MultiplayerSpawner remove a copia ao receber o despawn autoritativo.
		return
	tempo_vida -= delta
	if tempo_vida <= 0.0:
		queue_free()
		return

	global_position += direcao * velocidade * delta

	if usa_wrap:
		var area := Global.obter_retangulo_area_visivel()
		global_position.x = wrapf(global_position.x, area.position.x, area.end.x)
		global_position.y = wrapf(global_position.y, area.position.y, area.end.y)
	else:
		processar_bordas()


func processar_bordas() -> void:
	var bateu := false
	var area := Global.obter_retangulo_area_visivel()

	if global_position.x <= area.position.x or global_position.x >= area.end.x:
		direcao.x *= -1.0
		global_position.x = clampf(global_position.x, area.position.x + 2.0, area.end.x - 2.0)
		bateu = true

	if global_position.y <= area.position.y or global_position.y >= area.end.y:
		direcao.y *= -1.0
		global_position.y = clampf(global_position.y, area.position.y + 2.0, area.end.y - 2.0)
		bateu = true

	if not bateu:
		return

	rebotes += 1
	rotation = direcao.angle()
	if rebotes > rebotes_max:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("tomar_dano"):
		body.tomar_dano(dano)
		queue_free()


func _processar_bordas_visual() -> void:
	var area := Global.obter_retangulo_area_visivel()
	if global_position.x <= area.position.x or global_position.x >= area.end.x:
		direcao.x *= -1.0
		global_position.x = clampf(global_position.x, area.position.x + 2.0, area.end.x - 2.0)
	if global_position.y <= area.position.y or global_position.y >= area.end.y:
		direcao.y *= -1.0
		global_position.y = clampf(global_position.y, area.position.y + 2.0, area.end.y - 2.0)
	rotation = direcao.angle()
