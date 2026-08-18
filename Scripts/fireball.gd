extends Area2D


const BRILHO_PROJETEIS_PADRAO := 1.65

@export_category("Neon")
@export_range(0.6, 3.0, 0.05) var brilho_visual: float = BRILHO_PROJETEIS_PADRAO
@export_range(0.0, 4.0, 0.05) var energia_luz: float = 1.15

var dmg := 1.0
var velocidade := 1000.0
var tempo_vida := 5.0
var penetracoes_restantes := 0
var forca_homing := 0.0
var quantidade_fragmentos := 0
var ricochetes_restantes := 0
var dono_player: Node
var cena_origem: PackedScene
var eh_fragmento := false
var alvo_homing: Node2D

@onready var visual: Polygon2D = $Polygon2D
@onready var luz: PointLight2D = $PointLight2D


func _ready() -> void:
	aplicar_glow()


func aplicar_glow() -> void:
	var intensidade := clampf(brilho_visual, 0.6, 3.0)
	if is_instance_valid(visual):
		visual.self_modulate = Color(intensidade, intensidade, intensidade, 1.0)
	if is_instance_valid(luz):
		luz.energy = maxf(energia_luz, 0.0)


func configurar(
	dano_configurado: float,
	velocidade_configurada: float,
	escala_visual: float,
	penetracao: int,
	homing: float,
	fragmentos: int,
	ricochetes: int,
	player_ref: Node,
	cena_ref: PackedScene,
	fragmento := false
) -> void:
	dmg = dano_configurado
	velocidade = velocidade_configurada
	scale *= maxf(escala_visual, 0.15)
	penetracoes_restantes = maxi(penetracao, 0)
	forca_homing = maxf(homing, 0.0)
	quantidade_fragmentos = maxi(fragmentos, 0)
	ricochetes_restantes = maxi(ricochetes, 0)
	dono_player = player_ref
	cena_origem = cena_ref
	eh_fragmento = fragmento

	if eh_fragmento:
		visual.color = Color(0.92, 0.20, 1.0, 1.0)
		luz.color = Color(0.95, 0.30, 1.0, 1.0)
		aplicar_glow()


func _physics_process(delta: float) -> void:
	tempo_vida -= delta
	if tempo_vida <= 0.0:
		queue_free()
		return

	atualizar_mira_gravitacional(delta)
	global_position += transform.x * velocidade * delta
	atualizar_bordas()


func atualizar_mira_gravitacional(delta: float) -> void:
	if forca_homing <= 0.0:
		return

	if not is_instance_valid(alvo_homing):
		alvo_homing = encontrar_inimigo_mais_proximo()
	if not is_instance_valid(alvo_homing):
		return

	var angulo_alvo := global_position.angle_to_point(alvo_homing.global_position)
	global_rotation = rotate_toward(
		global_rotation,
		angulo_alvo,
		forca_homing * delta
	)


func encontrar_inimigo_mais_proximo() -> Node2D:
	var melhor: Node2D
	var menor_distancia := INF
	for inimigo in get_tree().get_nodes_in_group("inimigo"):
		if not is_instance_valid(inimigo) or not (inimigo is Node2D):
			continue
		var distancia := global_position.distance_squared_to(inimigo.global_position)
		if distancia < menor_distancia:
			menor_distancia = distancia
			melhor = inimigo as Node2D
	return melhor


func atualizar_bordas() -> void:
	var rebateu := false
	if global_position.x < 0.0 or global_position.x > 960.0:
		if ricochetes_restantes > 0:
			global_position.x = clampf(global_position.x, 2.0, 958.0)
			global_rotation = PI - global_rotation
			rebateu = true
		else:
			verificar_fora_da_arena()

	if global_position.y < 0.0 or global_position.y > 540.0:
		if ricochetes_restantes > 0:
			global_position.y = clampf(global_position.y, 2.0, 538.0)
			global_rotation = -global_rotation
			rebateu = true
		else:
			verificar_fora_da_arena()

	if rebateu:
		ricochetes_restantes -= 1
		alvo_homing = null


func verificar_fora_da_arena() -> void:
	if (
		global_position.x < -80.0
		or global_position.x > 1040.0
		or global_position.y < -80.0
		or global_position.y > 620.0
	):
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if not body.has_method("tomarDano"):
		return

	body.tomarDano(dmg)
	if body is CharacterBody2D:
		var corpo := body as CharacterBody2D
		corpo.velocity *= 0.1

	if is_instance_valid(dono_player) and dono_player.has_method("registrar_acerto_projetil"):
		dono_player.registrar_acerto_projetil()

	if quantidade_fragmentos > 0 and not eh_fragmento:
		criar_fragmentos()

	if penetracoes_restantes > 0:
		penetracoes_restantes -= 1
		return

	queue_free()


func criar_fragmentos() -> void:
	if not cena_origem:
		return

	var arco := deg_to_rad(130.0)
	var base := global_rotation + PI
	for indice in range(quantidade_fragmentos):
		var deslocamento := 0.0
		if quantidade_fragmentos > 1:
			deslocamento = lerpf(
				-arco * 0.5,
				arco * 0.5,
				float(indice) / float(quantidade_fragmentos - 1)
			)

		var fragmento = cena_origem.instantiate()
		get_tree().current_scene.add_child(fragmento)
		fragmento.global_rotation = base + deslocamento
		fragmento.global_position = global_position + fragmento.transform.x * 16.0

		if fragmento.has_method("configurar"):
			fragmento.configurar(
				dmg * 0.34,
				velocidade * 0.82,
				0.55,
				0,
				forca_homing * 0.45,
				0,
				maxi(ricochetes_restantes - 1, 0),
				dono_player,
				cena_origem,
				true
			)


# Mantida para compatibilidade com a conexão existente na cena.
func _on_visible_on_screen_notifier_3d_screen_exited() -> void:
	if ricochetes_restantes <= 0:
		verificar_fora_da_arena()
