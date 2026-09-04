extends Area2D


const BRILHO_PROJETEIS_PADRAO := 1.65
const EfeitoCombateCena = preload("res://Scripts/EfeitoCombate.gd")
const ExplosaoMonthlyCena = preload("res://Scripts/MonthlyBurst.gd")

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
var estilo_monthly: StringName = &""
var cor_monthly := Color.WHITE
var tempo_estilo := 0.0
var origem_estilo := Vector2.ZERO
var angulo_estilo := 0.0
var indice_orbita := 0
var rastro_contador := 0.0

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
	bonus_ricochete_configurado := 0.0
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

	if eh_fragmento:
		visual.color = Color(0.92, 0.20, 1.0, 1.0)
		luz.color = Color(0.95, 0.30, 1.0, 1.0)
		aplicar_glow()

func definir_alvo_homing(alvo: Node2D) -> void:
	if forca_homing <= 0.0 or not is_instance_valid(alvo):
		return
	if global_position.distance_to(alvo.global_position) <= alcance_homing:
		alvo_homing = alvo


func configurar_estilo_monthly(estilo: StringName, cor: Color, config: Dictionary) -> void:
	estilo_monthly = estilo
	cor_monthly = cor
	origem_estilo = global_position
	angulo_estilo = global_rotation
	indice_orbita = int(config.get("indice_orbita", 0))
	if is_instance_valid(visual):
		visual.color = cor
		visual.self_modulate = Color(1.45, 1.45, 1.45, 1.0)
	if is_instance_valid(luz):
		luz.color = cor
		luz.energy = 1.35
	match estilo_monthly:
		&"mine":
			add_to_group("monthly_mine")
			tempo_vida = 9.0
			velocidade = 0.0
			var minas := get_tree().get_nodes_in_group("monthly_mine")
			if minas.size() > 3 and is_instance_valid(minas[0]):
				(minas[0] as Node).queue_free()
		&"boomerang": tempo_vida = 2.4
		&"underground":
			visible = false
			monitoring = false
		&"mortar": tempo_vida = 1.1
		&"orbit": tempo_vida = 2.8
		&"cold": tempo_vida = 3.0


func _physics_process(delta: float) -> void:
	tempo_vida -= delta
	tempo_estilo += delta
	rastro_contador -= delta
	if tempo_vida <= 0.0:
		if estilo_monthly in [&"mortar", &"cold"] and dano_explosao > 0.0:
			aplicar_onda_de_impacto(null)
			_criar_feedback_monthly(1.0)
		queue_free()
		return

	atualizar_mira_gravitacional(delta)
	if _processar_movimento_monthly(delta):
		atualizar_bordas()
		return
	global_position += transform.x * velocidade * delta
	_criar_rastro_monthly()
	atualizar_bordas()


func _processar_movimento_monthly(delta: float) -> bool:
	match estilo_monthly:
		&"mine":
			rotation += delta * 1.8
			for node in get_tree().get_nodes_in_group("inimigo"):
				if is_instance_valid(node) and node is Node2D and global_position.distance_to((node as Node2D).global_position) < 72.0:
					aplicar_onda_de_impacto(node as Node2D)
					_criar_feedback_monthly(1.0)
					queue_free()
					break
			return true
		&"boomerang":
			if tempo_estilo < 0.62:
				global_position += transform.x * velocidade * delta
			elif is_instance_valid(dono_player) and dono_player is Node2D:
				var direcao_retorno := global_position.direction_to((dono_player as Node2D).global_position)
				global_rotation = direcao_retorno.angle()
				global_position += direcao_retorno * velocidade * 1.25 * delta
				if global_position.distance_to((dono_player as Node2D).global_position) < 28.0:
					queue_free()
			rotation += delta * 8.0
			_criar_rastro_monthly()
			return true
		&"wave":
			var frente := Vector2.from_angle(angulo_estilo)
			var lateral := frente.orthogonal()
			global_position += frente * velocidade * delta + lateral * cos(tempo_estilo * 9.0) * 125.0 * delta
			global_rotation = frente.angle() + sin(tempo_estilo * 9.0) * 0.18
			_criar_rastro_monthly()
			return true
		&"underground":
			if tempo_estilo < 0.32:
				return true
			if not visible:
				var alvo := encontrar_inimigo_mais_proximo()
				if is_instance_valid(alvo):
					global_position = alvo.global_position - transform.x * 36.0
				visible = true
				monitoring = true
				_criar_feedback_monthly(0.75)
			global_position += transform.x * velocidade * delta
			_criar_rastro_monthly()
			return true
		&"mortar":
			global_position += transform.x * velocidade * delta
			var pulso := 0.82 + sin(tempo_estilo * PI / 1.1) * 0.55
			scale = Vector2.ONE * maxf(pulso, 0.35)
			_criar_rastro_monthly()
			return true
		&"orbit":
			if tempo_estilo < 0.65 and is_instance_valid(dono_player) and dono_player is Node2D:
				var angulo := tempo_estilo * 7.0 + TAU * float(indice_orbita) / 6.0
				global_position = (dono_player as Node2D).global_position + Vector2.from_angle(angulo) * 58.0
				global_rotation = angulo + PI * 0.5
			else:
				global_position += transform.x * velocidade * delta
			_criar_rastro_monthly()
			return true
		&"cold":
			global_position += transform.x * velocidade * delta
			for node in get_tree().get_nodes_in_group("projetil_inimigo"):
				if is_instance_valid(node) and node is Node2D and global_position.distance_to((node as Node2D).global_position) < 42.0:
					EfeitoCombateCena.criar(get_tree().current_scene, (node as Node2D).global_position, EfeitoCombate.Tipo.ACERTO, cor_monthly, 0.45)
					node.queue_free()
			_criar_rastro_monthly()
			return true
	return false


func _criar_rastro_monthly() -> void:
	if estilo_monthly.is_empty() or rastro_contador > 0.0:
		return
	rastro_contador = 0.055 if estilo_monthly in [&"beam", &"sniper"] else 0.09
	EfeitoCombateCena.criar(get_tree().current_scene, global_position, EfeitoCombate.Tipo.RASTRO, cor_monthly, 0.42 if estilo_monthly != &"cold" else 0.72, -transform.x)


func _criar_feedback_monthly(intensidade: float) -> void:
	EfeitoCombateCena.criar(get_tree().current_scene, global_position, EfeitoCombate.Tipo.MORTE, cor_monthly, intensidade, transform.x)
	ExplosaoMonthlyCena.criar(get_tree().current_scene, global_position, cor_monthly, intensidade)
	var camera := get_tree().get_first_node_in_group("camera") as Camera2D
	if is_instance_valid(camera) and camera.has_method("shake"):
		camera.shake(4.0 + intensidade * 2.5)


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
	if estilo_monthly == &"snow" and body.has_method("aplicar_atordoamento"):
		body.aplicar_atordoamento(0.32)
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
				bonus_dano_por_ricochete * 0.5
			)


# Mantida para compatibilidade com a conexão existente na cena.
func _on_visible_on_screen_notifier_3d_screen_exited() -> void:
	if ricochetes_restantes <= 0:
		verificar_fora_da_arena()
