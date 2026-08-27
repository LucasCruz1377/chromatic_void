extends Area2D


const BRILHO_PROJETEIS_PADRAO := 1.65
const EfeitoCombateCena = preload("res://Scripts/EfeitoCombate.gd")

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
var alcance_homing := 0.0
var multiplicador_dano_fragmento := 0.28
var dano_explosao := 0.0
var raio_explosao := 0.0
var bonus_dano_por_ricochete := 0.0

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
	fragmento := false,
	multiplicador_fragmento := 0.28,
	dano_explosao_configurado := 0.0,
	raio_explosao_configurado := 0.0,
	bonus_ricochete_configurado := 0.0,
	estilo_projetil: StringName = &"padrao"
) -> void:
	dmg = dano_configurado
	velocidade = velocidade_configurada
	scale *= maxf(escala_visual, 0.15)
	penetracoes_restantes = maxi(penetracao, 0)
	forca_homing = maxf(homing, 0.0)
	alcance_homing = clampf(240.0 + forca_homing * 70.0, 280.0, 520.0)
	quantidade_fragmentos = maxi(fragmentos, 0)
	ricochetes_restantes = maxi(ricochetes, 0)
	dono_player = player_ref
	cena_origem = cena_ref
	eh_fragmento = fragmento
	multiplicador_dano_fragmento = maxf(multiplicador_fragmento, 0.05)
	dano_explosao = maxf(dano_explosao_configurado, 0.0)
	raio_explosao = maxf(raio_explosao_configurado, 0.0)
	bonus_dano_por_ricochete = maxf(bonus_ricochete_configurado, 0.0)
	aplicar_estilo_visual(&"fragmento" if eh_fragmento else estilo_projetil)

	if eh_fragmento:
		visual.color = Color(0.92, 0.20, 1.0, 1.0)
		luz.color = Color(0.95, 0.30, 1.0, 1.0)
		aplicar_glow()


func aplicar_estilo_visual(estilo: StringName) -> void:
	if not is_instance_valid(visual) or not is_instance_valid(luz):
		return
	match estilo:
		&"multitiro":
			visual.color = Color(1.0, 0.28, 0.72)
			luz.color = Color(1.0, 0.22, 0.78)
			visual.scale.y *= 0.82
		&"pesado":
			visual.color = Color(1.0, 0.48, 0.10)
			luz.color = Color(1.0, 0.62, 0.16)
			visual.scale.y *= 1.45
		&"impacto":
			visual.color = Color(1.0, 0.72, 0.16)
			luz.color = Color(1.0, 0.38, 0.08)
			visual.scale.y *= 1.65
		&"fragmentacao", &"fragmento":
			visual.color = Color(0.95, 0.18, 1.0)
			luz.color = Color(1.0, 0.25, 0.82)
		&"gravitacional":
			visual.color = Color(0.28, 0.62, 1.0)
			luz.color = Color(0.22, 0.82, 1.0)
		&"ricochete":
			visual.color = Color(0.20, 1.0, 0.82)
			luz.color = Color(0.16, 1.0, 0.95)
		_:
			visual.color = Color(0.72, 1.0, 0.22)
			luz.color = Color(0.58, 1.0, 0.18)
	aplicar_glow()


func definir_alvo_homing(alvo: Node2D) -> void:
	if forca_homing <= 0.0 or not is_instance_valid(alvo):
		return
	if global_position.distance_to(alvo.global_position) <= alcance_homing:
		alvo_homing = alvo


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

	if (
		is_instance_valid(alvo_homing)
		and global_position.distance_to(alvo_homing.global_position) > alcance_homing
	):
		alvo_homing = null

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
	var menor_distancia := alcance_homing * alcance_homing
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
		if bonus_dano_por_ricochete > 0.0:
			dmg *= 1.0 + bonus_dano_por_ricochete
		EfeitoCombateCena.criar(
			get_tree().current_scene,
			global_position,
			EfeitoCombate.Tipo.ACERTO,
			Color(0.24, 1.0, 0.9),
			0.7,
			transform.x
		)
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
	if dano_explosao > 0.0 and raio_explosao > 0.0 and not eh_fragmento:
		aplicar_onda_de_impacto(body)

	if penetracoes_restantes > 0:
		penetracoes_restantes -= 1
		return

	queue_free()


func aplicar_onda_de_impacto(alvo_direto: Node2D) -> void:
	EfeitoCombateCena.criar(
		get_tree().current_scene,
		global_position,
		EfeitoCombate.Tipo.MORTE,
		Color(1.0, 0.52, 0.16),
		clampf(raio_explosao / 72.0, 0.75, 1.35),
		transform.x
	)
	for inimigo in get_tree().get_nodes_in_group("inimigo"):
		if (
			not is_instance_valid(inimigo)
			or inimigo == alvo_direto
			or not (inimigo is Node2D)
			or not inimigo.has_method("tomarDano")
		):
			continue
		var alvo := inimigo as Node2D
		if global_position.distance_to(alvo.global_position) <= raio_explosao:
			alvo.tomarDano(dmg * dano_explosao)


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
				dmg * multiplicador_dano_fragmento,
				velocidade * 0.82,
				0.55,
				0,
				forca_homing * 0.45,
				0,
				maxi(ricochetes_restantes - 1, 0),
				dono_player,
				cena_origem,
				true,
				multiplicador_dano_fragmento,
				0.0,
				0.0,
				bonus_dano_por_ricochete * 0.5,
				&"fragmento"
			)


# Mantida para compatibilidade com a conexão existente na cena.
func _on_visible_on_screen_notifier_3d_screen_exited() -> void:
	if ricochetes_restantes <= 0:
		verificar_fora_da_arena()
