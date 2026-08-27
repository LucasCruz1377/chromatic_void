extends CharacterBody2D
class_name Player


const CAMINHO_HABILIDADE_PADRAO := "res://Habilidades/habilidadeRetrocesso.tres"
const DadosUpgrades = preload("res://Scripts/UpgradeData.gd")
const EfeitoCombateCena = preload("res://Scripts/EfeitoCombate.gd")
const TEXTURA_COOLDOWN_RELOGIO = preload(
	"res://Habilidades/Icones/cooldown_relogio.svg"
)
const REROLLS_UPGRADES_INICIAIS := 3
const BONUS_DANO_POR_NIVEL := [0.25, 0.18, 0.14, 0.10, 0.08]
const FATOR_CADENCIA_POR_NIVEL := [0.85, 0.88, 0.91, 0.94, 0.96]
const BONUS_VIDA_POR_NIVEL := [0.20, 0.15, 0.12, 0.10, 0.08]
const BONUS_PROPULSAO_POR_NIVEL := [0.15, 0.10, 0.08, 0.06, 0.05]
const FATOR_FLUXO_POR_NIVEL := [0.85, 0.90, 0.93, 0.95]
const REDUCAO_IMPACTO_POR_NIVEL := [0.025, 0.020, 0.015]
const FORCA_HOMING_POR_NIVEL := [1.55, 2.15, 2.70]
const BONUS_CALIBRE_POR_NIVEL := [0.22, 0.16, 0.12]
const XP_PROGRESSAO_INICIAL := [2, 3, 4, 6, 8, 11, 14, 18, 23]


@export_category("Combate")
@export var tiro: PackedScene
@export var HabilidadeEquipada: Habilidade
@export var dano := 1.25
@export var CD_MAX := 0.22

@export_category("Movimento")
@export var VelocidadeVirar := 4.0
@export var SPEED := 400.0
@export var MAX_VELOCIDADE := 500.0
@export var friction := 100.0
@export_range(1.0, 4.0, 0.1) var resposta_controle_simplificado := 2.0

@export_category("Vida")
@export var VIDA_MAXIMA := 100.0

@export_category("Morte")
@export var ParticulaMorte: PackedScene

@onready var PontaArma: Marker2D = $ponta
@onready var particles: GPUParticles2D = $particles
@onready var barra_vida = $"../GUI/Barra_vida"
@onready var barra_xp: TextureProgressBar = $"../GUI/Barra_xp"
@onready var display_skill: TextureRect = $"../GUI/DisplaySkill"
@onready var lvl_text: Label = $"../GUI/LvlText"
@onready var somtiro: AudioStreamPlayer2D = $somtiro
@onready var death: AudioStreamPlayer2D = $death

var vida: float
var cooldown := 0.0
var mira_mouse = Global.mira_mouse
var vivo := true
var giroblock := false
var ctrlblock := false
var escala_base := 9.85
var UsandoHabilidade := false
var invulneravel_por_habilidade := false
var multiplicador_dano_recebido := 1.0
var multiplicador_cura_recebida := 1.0
var multiplicador_velocidade_habilidade := 1.0
var multiplicador_dano_habilidade := 1.0
var multiplicador_cadencia_habilidade := 1.0
var escudo_habilidade := 0.0
var escudo_habilidade_max := 0.0
var tempo_escudo_habilidade := 0.0
var cor_escudo_habilidade := Color(0.72, 0.42, 1.0, 0.82)
var tempo_resistencia_temporaria := 0.0
var resistencia_temporaria_multiplicador := 1.0
var dano_colisao_habilidade := 0.0
var xp_atual: float = 0.0
var nivel_atual: int = 1
var xp_necessario: int = 2
var invencibilidade := false
var invencibilidade_cd := 0.0
var invencibilidade_cd_max := 1.15
var save := false

# Pontos não interrompem a partida. O jogador abre o menu quando quiser.
var pontos_upgrade_pendentes := 0
var niveis_upgrades: Dictionary = {}
var rerolls_upgrades_restantes := REROLLS_UPGRADES_INICIAIS

# Montagem dinâmica da arma.
var projeteis_por_tiro := 1
var dispersao_graus := 0.0
var multiplicador_dano_projetil := 1.0
var multiplicador_dano_forma := 1.0
var multiplicador_dano_mira := 1.0
var multiplicador_velocidade_projetil := 1.0
var multiplicador_escala_projetil := 1.0
var penetracao_projetil := 0
var fragmentos_projetil := 0
var forca_mira_gravitacional := 0.0
var ricochetes_projetil := 0
var bonus_dano_ricochete := 0.0
var dano_explosao_impacto := 0.0
var raio_explosao_impacto := 0.0
var multiplicador_fragmentos := 0.28
var formacao_convergente := false

# Passivos que mudam decisões durante a pilotagem.
var bonus_vetor_ofensivo := 0.0
var regeneracao_casco_por_segundo := 0.0
var tempo_sem_dano := 0.0
var nivel_capacitor_cinetico := 0
var impactos_capacitor := 0
var capacitor_pronto := false
var bonus_cadencia_reacao := 0.0
var tempo_reacao := 0.0
var tween_dano_visual: Tween

# Sinergias entre a arma e a habilidade equipada.
var duracao_overdrive := 0.0
var tempo_overdrive := 0.0
var reducao_cooldown_por_impacto := 0.0
var nivel_nova_ativacao := 0
var duracao_escudo_fase := 0.0
var reator_sincronizado := false
var barra_cooldown_habilidade: TextureProgressBar


enum Upgrade {
	CADENCIA,
	BLINDAGEM,
	DANO,
	VELOCIDADE,
	TURNSPD,
}


signal subiuDeNivel()
signal pontos_upgrade_alterados(novo_total: int)
signal upgrade_adquirido(id: StringName, novo_nivel: int)


func _ready() -> void:
	vida = VIDA_MAXIMA
	carregar_habilidade_equipada()
	criar_barra_cooldown_habilidade()
	var menu := get_node_or_null("../GUI/TelaUpgrades")
	if (
		is_instance_valid(menu)
		and menu.has_signal("estado_alterado")
		and not menu.is_connected(
			"estado_alterado", _on_menu_melhorias_estado_alterado
		)
	):
		menu.connect("estado_alterado", _on_menu_melhorias_estado_alterado)


func _exit_tree() -> void:
	if HabilidadeEquipada:
		HabilidadeEquipada.ao_desequipar(self)


func _process(delta: float) -> void:
	mira_mouse = Global.mira_mouse
	atualizar_ui()
	atualizar_invencibilidade(delta)
	atualizar_efeitos_temporarios(delta)
	atualizar_passivos(delta)
	atualizar_overdrive(delta)
	atualizar_habilidade(delta)
	atualizar_movimento(delta)
	atualizar_combate(delta)
	atualizar_limites()
	atualizar_vida()


func carregar_habilidade_equipada() -> void:
	var dados: Dictionary = GerenciadorDeSave.carregar()
	var caminho := str(dados.get("habilidade_equipada", ""))
	var habilidade_carregada: Habilidade

	if not Global.modo_desenvolvedor:
		var liberadas = dados.get(
			"habilidades_desbloqueadas",
			[CAMINHO_HABILIDADE_PADRAO]
		)
		if not (liberadas is Array) or caminho not in liberadas:
			caminho = CAMINHO_HABILIDADE_PADRAO
			GerenciadorDeSave.salvar({"habilidade_equipada": caminho})

	if not caminho.is_empty() and ResourceLoader.exists(caminho):
		var recurso := load(caminho)
		if recurso is Habilidade:
			habilidade_carregada = recurso

	if not habilidade_carregada and HabilidadeEquipada:
		habilidade_carregada = HabilidadeEquipada

	if not habilidade_carregada and ResourceLoader.exists(CAMINHO_HABILIDADE_PADRAO):
		var recurso_padrao := load(CAMINHO_HABILIDADE_PADRAO)
		if recurso_padrao is Habilidade:
			habilidade_carregada = recurso_padrao

	if not habilidade_carregada:
		push_warning("Nenhuma habilidade válida foi encontrada para o Player.")
		HabilidadeEquipada = null
		return

	var copia := habilidade_carregada.duplicate(true) as Habilidade
	if not copia:
		push_error("Não foi possível duplicar a habilidade equipada.")
		HabilidadeEquipada = null
		return

	HabilidadeEquipada = copia
	HabilidadeEquipada.reiniciar_estado()
	HabilidadeEquipada.ao_equipar(self)


func atualizar_ui() -> void:
	lvl_text.text = "LVL: " + str(nivel_atual)
	if HabilidadeEquipada:
		display_skill.texture = HabilidadeEquipada.Icone
	else:
		display_skill.texture = null
	atualizar_barra_cooldown_habilidade()

	barra_xp.value = xp_atual
	barra_xp.max_value = xp_necessario


func criar_barra_cooldown_habilidade() -> void:
	if not is_instance_valid(display_skill):
		return

	barra_cooldown_habilidade = TextureProgressBar.new()
	barra_cooldown_habilidade.name = "CooldownHabilidade"
	# Tamanho fixo e âncoras no centro impedem o indicador de deslocar quando
	# o DisplaySkill possui dimensões diferentes da textura do ícone.
	barra_cooldown_habilidade.anchor_left = 0.5
	barra_cooldown_habilidade.anchor_right = 0.5
	barra_cooldown_habilidade.anchor_top = 0.5
	barra_cooldown_habilidade.anchor_bottom = 0.5
	barra_cooldown_habilidade.offset_left = -32.0
	barra_cooldown_habilidade.offset_right = 32.0
	barra_cooldown_habilidade.offset_top = -32.0
	barra_cooldown_habilidade.offset_bottom = 32.0
	barra_cooldown_habilidade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	barra_cooldown_habilidade.z_index = 5
	barra_cooldown_habilidade.min_value = 0.0
	barra_cooldown_habilidade.step = 0.01
	barra_cooldown_habilidade.fill_mode = TextureProgressBar.FILL_CLOCKWISE
	barra_cooldown_habilidade.radial_initial_angle = 270.0
	barra_cooldown_habilidade.radial_fill_degrees = 360.0
	barra_cooldown_habilidade.texture_under = null
	barra_cooldown_habilidade.texture_progress = TEXTURA_COOLDOWN_RELOGIO
	barra_cooldown_habilidade.tint_progress = Color(1.0, 1.0, 1.0, 0.52)
	barra_cooldown_habilidade.hide()
	display_skill.add_child(barra_cooldown_habilidade)


func atualizar_barra_cooldown_habilidade() -> void:
	if not is_instance_valid(barra_cooldown_habilidade):
		return
	if (
		not vivo
		or _menu_melhorias_aberto()
		or not HabilidadeEquipada
		or HabilidadeEquipada.cooldown_atual <= 0.0
	):
		barra_cooldown_habilidade.hide()
		return

	barra_cooldown_habilidade.show()
	barra_cooldown_habilidade.max_value = maxf(HabilidadeEquipada.Cooldown, 0.01)
	# O disco começa cheio e esvazia no sentido horário enquanto recarrega.
	barra_cooldown_habilidade.value = clampf(
		HabilidadeEquipada.cooldown_atual,
		0.0,
		barra_cooldown_habilidade.max_value
	)
	barra_cooldown_habilidade.modulate = Color.WHITE
	barra_cooldown_habilidade.tooltip_text = "Recarga: %.1f s" % [
		HabilidadeEquipada.cooldown_atual
	]


func _menu_melhorias_aberto() -> bool:
	var menu := get_node_or_null("../GUI/TelaUpgrades")
	return (
		is_instance_valid(menu)
		and menu.has_method("esta_aberta")
		and bool(menu.call("esta_aberta"))
	)


func _on_menu_melhorias_estado_alterado(aberto: bool) -> void:
	if aberto:
		if is_instance_valid(barra_cooldown_habilidade):
			barra_cooldown_habilidade.hide()
		return
	atualizar_barra_cooldown_habilidade()


func atualizar_vida() -> void:
	vida = clampf(vida, 0.0, VIDA_MAXIMA)
	barra_vida.scale.x = escala_base * (vida / VIDA_MAXIMA)
	if vida <= 0.0 and vivo:
		morrer()


func atualizar_invencibilidade(delta: float) -> void:
	if invencibilidade_cd > 0.0:
		invencibilidade_cd = maxf(invencibilidade_cd - delta, 0.0)
		modulate.a = 0.48 + absf(sin(Time.get_ticks_msec() / 90.0)) * 0.52
	else:
		modulate.a = 1.0
		invencibilidade = false


func atualizar_overdrive(delta: float) -> void:
	if tempo_overdrive > 0.0:
		tempo_overdrive = maxf(tempo_overdrive - delta, 0.0)


func atualizar_habilidade(delta: float) -> void:
	if not HabilidadeEquipada:
		return

	HabilidadeEquipada.update(self, delta)
	if ctrlblock:
		return

	if vivo and Input.is_action_just_pressed("Habilidade"):
		var ativou := HabilidadeEquipada.activate(self)
		if ativou:
			ao_ativar_habilidade()


func ao_ativar_habilidade() -> void:
	if duracao_overdrive > 0.0:
		var multiplicador_duracao := 2.0 if reator_sincronizado else 1.0
		tempo_overdrive = duracao_overdrive * multiplicador_duracao

	if duracao_escudo_fase > 0.0:
		invencibilidade = true
		invencibilidade_cd = maxf(invencibilidade_cd, duracao_escudo_fase)

	if nivel_nova_ativacao > 0:
		disparar_nova_de_ativacao()


func disparar_nova_de_ativacao() -> void:
	var quantidade := 6 + nivel_nova_ativacao * 2
	if reator_sincronizado:
		quantidade += 4

	for indice in range(quantidade):
		var angulo := rotation + TAU * float(indice) / float(quantidade)
		criar_projetil(angulo, 0.45, true)


func IniciarHabilidade(concede_invulnerabilidade := false) -> void:
	UsandoHabilidade = true
	invulneravel_por_habilidade = concede_invulnerabilidade


func EncerrarHabilidade() -> void:
	UsandoHabilidade = false
	invulneravel_por_habilidade = false
	dano_colisao_habilidade = 0.0


func atualizar_movimento(delta: float) -> void:
	if not vivo:
		return

	var fator_movimento := multiplicador_velocidade_habilidade
	var usando_controle_simplificado := (
		not Global.controle_avancado
		and Global.ultimo_dispositivo == &"controle"
	)
	var direcao_simplificada := Vector2.ZERO
	var intensidade_re := 0.0
	if usando_controle_simplificado:
		direcao_simplificada = _obter_analogico_esquerdo()
		intensidade_re = _obter_intensidade_l2()
	var acelerando := false

	if usando_controle_simplificado:
		if not giroblock and direcao_simplificada.length_squared() > 0.0:
			rotation = rotate_toward(
				rotation,
				direcao_simplificada.angle(),
				VelocidadeVirar * fator_movimento * resposta_controle_simplificado * delta
			)
		if not ctrlblock:
			# L2 tem prioridade para a ré não disputar força com a aceleração
			# automática do analógico esquerdo.
			if intensidade_re > 0.0:
				brake(delta, fator_movimento * intensidade_re)
			elif direcao_simplificada.length_squared() > 0.0:
				var intensidade := clampf(direcao_simplificada.length(), 0.0, 1.0)
				acelerar(delta, fator_movimento * intensidade)
				acelerando = true
	elif not giroblock:
		var direcao_mira_controle := Input.get_vector(
			"mirar_esquerda",
			"mirar_direita",
			"mirar_cima",
			"mirar_baixo",
			Global.zona_morta_controle
		)
		if direcao_mira_controle.length_squared() > 0.01:
			rotation = rotate_toward(
				rotation,
				direcao_mira_controle.angle(),
				VelocidadeVirar * fator_movimento * delta
			)
		elif mira_mouse and Global.ultimo_dispositivo != &"controle":
			var target_angle := global_position.angle_to_point(get_global_mouse_position())
			rotation = rotate_toward(
				rotation,
				target_angle,
				VelocidadeVirar * fator_movimento * delta
			)
		else:
			arrowsctrl(delta, fator_movimento)

	if not usando_controle_simplificado and not ctrlblock:
		if Input.is_action_pressed("acelerar"):
			acelerar(delta, fator_movimento)
			acelerando = true
		if Input.is_action_pressed("freio"):
			brake(delta, fator_movimento)

	particles.emitting = acelerando or UsandoHabilidade
	velocity = velocity.move_toward(Vector2.ZERO, friction * fator_movimento * delta)

	if not UsandoHabilidade:
		velocity = velocity.limit_length(MAX_VELOCIDADE * fator_movimento)

	move_and_slide()


func _obter_controle_ativo() -> int:
	var controles := Input.get_connected_joypads()
	if controles.is_empty():
		return -1
	if controles.has(Global.ultimo_controle_id):
		return Global.ultimo_controle_id
	return controles[0]


func _obter_analogico_esquerdo() -> Vector2:
	var controle := _obter_controle_ativo()
	if controle < 0:
		return Vector2.ZERO
	var direcao := Vector2(
		Input.get_joy_axis(controle, JOY_AXIS_LEFT_X),
		Input.get_joy_axis(controle, JOY_AXIS_LEFT_Y)
	)
	var intensidade := direcao.length()
	if intensidade <= Global.zona_morta_controle:
		return Vector2.ZERO
	# Reescala a área após a zona morta para preservar controle analógico fino.
	var intensidade_util := inverse_lerp(
		Global.zona_morta_controle,
		1.0,
		minf(intensidade, 1.0)
	)
	return direcao.normalized() * intensidade_util


func _obter_intensidade_l2() -> float:
	var controle := _obter_controle_ativo()
	if controle < 0:
		return 0.0
	var valor := maxf(
		Input.get_joy_axis(controle, JOY_AXIS_TRIGGER_LEFT),
		0.0
	)
	if valor <= Global.zona_morta_controle:
		return 0.0
	return inverse_lerp(Global.zona_morta_controle, 1.0, minf(valor, 1.0))


func acelerar(delta: float, fator_movimento := 1.0) -> void:
	velocity += transform.x * SPEED * fator_movimento * delta


func brake(delta: float, fator_movimento := 1.0) -> void:
	velocity -= transform.x * SPEED * 0.8 * fator_movimento * delta


func arrowsctrl(delta: float, fator_movimento := 1.0) -> void:
	rotation += (
		Input.get_axis("esquerda", "direita")
		* VelocidadeVirar
		* fator_movimento
		* delta
	)


func atualizar_combate(delta: float) -> void:
	cooldown = maxf(cooldown - delta, 0.0)
	if ctrlblock:
		return

	if vivo and Input.is_action_pressed("atirar") and cooldown <= 0.0:
		fire()


func fire() -> void:
	if not tiro:
		return

	var quantidade := maxi(projeteis_por_tiro, 1)
	var dispersao_efetiva := dispersao_graus * (0.58 if formacao_convergente else 1.0)
	var arco := deg_to_rad(dispersao_efetiva)
	var alvos_guiados := obter_alvos_para_multitiro(quantidade)
	var bonus_capacitor := 1.0
	if capacitor_pronto:
		bonus_capacitor = 1.45 + float(nivel_capacitor_cinetico) * 0.15
		EfeitoCombateCena.criar(
			get_tree().current_scene,
			PontaArma.global_position,
			EfeitoCombate.Tipo.AVISO,
			Color(0.25, 0.95, 1.0),
			0.75,
			transform.x
		)
	for indice in range(quantidade):
		var deslocamento := 0.0
		if quantidade > 1:
			deslocamento = lerpf(
				-arco * 0.5,
				arco * 0.5,
				float(indice) / float(quantidade - 1)
			)
		var alvo_preferido: Node2D
		if not alvos_guiados.is_empty():
			alvo_preferido = alvos_guiados[indice % alvos_guiados.size()]
		criar_projetil(
			rotation + deslocamento,
			bonus_capacitor,
			false,
			alvo_preferido
		)
	if capacitor_pronto:
		capacitor_pronto = false
		impactos_capacitor = 0

	somtiro.pitch_scale = randf_range(0.9, 1.1)
	somtiro.play()
	var fator_cadencia := 0.75 if tempo_overdrive > 0.0 else 1.0
	if tempo_reacao > 0.0:
		fator_cadencia *= 1.0 - bonus_cadencia_reacao
	cooldown = maxf(
		CD_MAX * fator_cadencia * multiplicador_cadencia_habilidade,
		0.04
	)


func criar_projetil(
	angulo: float,
	multiplicador_dano_extra := 1.0,
	eh_nova := false,
	alvo_homing_preferido: Node2D = null
) -> void:
	var projetil = tiro.instantiate()
	get_tree().current_scene.add_child(projetil)
	projetil.global_position = PontaArma.global_position
	projetil.rotation = angulo

	var bonus_overdrive := 1.25 if tempo_overdrive > 0.0 else 1.0
	var velocidade_relativa := clampf(
		velocity.length() / maxf(MAX_VELOCIDADE, 1.0),
		0.0,
		1.0
	)
	var bonus_movimento := 1.0 + bonus_vetor_ofensivo * velocidade_relativa
	var dano_final := (
		dano
		* multiplicador_dano_projetil
		* multiplicador_dano_forma
		* multiplicador_dano_mira
		* multiplicador_dano_habilidade
		* bonus_overdrive
		* bonus_movimento
		* multiplicador_dano_extra
	)

	if projetil.has_method("configurar"):
		projetil.configurar(
			dano_final,
			1000.0 * multiplicador_velocidade_projetil,
			multiplicador_escala_projetil,
			penetracao_projetil,
			forca_mira_gravitacional,
			0 if eh_nova else fragmentos_projetil,
			ricochetes_projetil,
			self,
			tiro,
			false,
			multiplicador_fragmentos,
			dano_explosao_impacto,
			raio_explosao_impacto,
			bonus_dano_ricochete,
			obter_estilo_projetil()
		)
		if (
			is_instance_valid(alvo_homing_preferido)
			and projetil.has_method("definir_alvo_homing")
		):
			projetil.definir_alvo_homing(alvo_homing_preferido)
	else:
		projetil.dmg = dano_final


func obter_estilo_projetil() -> StringName:
	if dano_explosao_impacto > 0.0:
		return &"impacto"
	if multiplicador_escala_projetil > 1.05:
		return &"pesado"
	if fragmentos_projetil > 0:
		return &"fragmentacao"
	if forca_mira_gravitacional > 0.0:
		return &"gravitacional"
	if ricochetes_projetil > 0:
		return &"ricochete"
	if projeteis_por_tiro > 1:
		return &"multitiro"
	return &"padrao"


func obter_alvos_para_multitiro(quantidade: int) -> Array[Node2D]:
	var alvos: Array[Node2D] = []
	if forca_mira_gravitacional <= 0.0:
		return alvos
	for inimigo in get_tree().get_nodes_in_group("inimigo"):
		if not is_instance_valid(inimigo) or not (inimigo is Node2D):
			continue
		var alvo := inimigo as Node2D
		if global_position.distance_squared_to(alvo.global_position) > 270400.0:
			continue
		alvos.append(alvo)
		if alvos.size() >= quantidade:
			break
	return alvos


func registrar_acerto_projetil() -> void:
	if reducao_cooldown_por_impacto > 0.0 and HabilidadeEquipada:
		HabilidadeEquipada.reduzir_cooldown_atual(reducao_cooldown_por_impacto)
	if nivel_capacitor_cinetico <= 0 or capacitor_pronto:
		return
	impactos_capacitor += 1
	var impactos_necessarios := maxi(11 - nivel_capacitor_cinetico * 2, 5)
	if impactos_capacitor >= impactos_necessarios:
		capacitor_pronto = true
		EfeitoCombateCena.criar(
			get_tree().current_scene,
			global_position,
			EfeitoCombate.Tipo.AVISO,
			Color(0.25, 0.95, 1.0),
			1.0,
			transform.x
		)


func tomar_dano(valor: float) -> void:
	if invencibilidade or invulneravel_por_habilidade or not vivo:
		return

	var dano_restante := maxf(valor, 0.0)
	if escudo_habilidade > 0.0:
		var absorvido := minf(escudo_habilidade, dano_restante)
		escudo_habilidade -= absorvido
		dano_restante -= absorvido
		queue_redraw()

	var dano_final := maxf(
		dano_restante
		* multiplicador_dano_recebido
		* resistencia_temporaria_multiplicador,
		0.0
	)
	vida = maxf(vida - dano_final, 0.0)
	tempo_sem_dano = 0.0
	if bonus_cadencia_reacao > 0.0:
		tempo_reacao = 2.4
	invencibilidade = true
	invencibilidade_cd = invencibilidade_cd_max
	Global.vibrar_controle(0.35, 0.75, 0.2)
	reproduzir_feedback_dano(dano_final)


func reproduzir_feedback_dano(dano_recebido: float) -> void:
	var cena := get_tree().current_scene
	if is_instance_valid(cena):
		EfeitoCombateCena.criar(
			cena,
			global_position,
			EfeitoCombate.Tipo.DANO_PLAYER,
			Color(1.0, 0.22, 0.38),
			clampf(0.85 + dano_recebido / 45.0, 0.9, 1.45),
			-transform.x
		)
	var camera := get_tree().get_first_node_in_group("camera") as Camera2D
	if is_instance_valid(camera) and camera.has_method("shake"):
		camera.shake(clampf(2.5 + dano_recebido * 0.12, 3.0, 7.0))
	if tween_dano_visual and tween_dano_visual.is_valid():
		tween_dano_visual.kill()
	modulate = Color(1.0, 0.32, 0.42, 1.0)
	tween_dano_visual = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween_dano_visual.tween_property(self, "modulate", Color.WHITE, 0.18)


func curar(valor: float) -> void:
	if valor <= 0.0 or not vivo:
		return

	vida = minf(vida + valor * multiplicador_cura_recebida, VIDA_MAXIMA)


func sacrificar_vida(valor: float) -> bool:
	var custo := maxf(valor, 0.0)
	if not vivo or custo <= 0.0 or vida <= custo + 1.0:
		return false
	vida -= custo
	return true


func ativar_escudo(valor: float, duracao: float, cor: Color) -> void:
	escudo_habilidade = maxf(valor, 0.0)
	escudo_habilidade_max = escudo_habilidade
	tempo_escudo_habilidade = maxf(duracao, 0.0)
	cor_escudo_habilidade = cor
	queue_redraw()


func aplicar_resistencia_temporaria(multiplicador: float, duracao: float) -> void:
	resistencia_temporaria_multiplicador = clampf(multiplicador, 0.05, 1.0)
	tempo_resistencia_temporaria = maxf(duracao, 0.0)


func atualizar_efeitos_temporarios(delta: float) -> void:
	if tempo_escudo_habilidade > 0.0:
		tempo_escudo_habilidade = maxf(tempo_escudo_habilidade - delta, 0.0)
		if tempo_escudo_habilidade <= 0.0:
			escudo_habilidade = 0.0
		queue_redraw()

	if tempo_resistencia_temporaria > 0.0:
		tempo_resistencia_temporaria = maxf(
			tempo_resistencia_temporaria - delta,
			0.0
		)
		if tempo_resistencia_temporaria <= 0.0:
			resistencia_temporaria_multiplicador = 1.0


func atualizar_passivos(delta: float) -> void:
	tempo_sem_dano += delta
	if tempo_reacao > 0.0:
		tempo_reacao = maxf(tempo_reacao - delta, 0.0)
	if (
		regeneracao_casco_por_segundo > 0.0
		and tempo_sem_dano >= 5.0
		and vida < VIDA_MAXIMA
	):
		curar(regeneracao_casco_por_segundo * delta)


func _draw() -> void:
	if escudo_habilidade <= 0.0 or escudo_habilidade_max <= 0.0:
		return

	var proporcao := clampf(escudo_habilidade / escudo_habilidade_max, 0.0, 1.0)
	var cor_fundo := cor_escudo_habilidade
	cor_fundo.a = 0.10
	draw_circle(Vector2.ZERO, 39.0, cor_fundo)
	draw_arc(
		Vector2.ZERO,
		39.0,
		-PI * 0.5,
		-PI * 0.5 + TAU * proporcao,
		48,
		cor_escudo_habilidade,
		3.0,
		true
	)


func ganhar_xp(valor: float) -> void:
	xp_atual += valor
	while xp_atual >= xp_necessario:
		xp_atual -= xp_necessario
		subir_de_nivel()


func subir_de_nivel() -> void:
	nivel_atual += 1
	xp_necessario = calcular_xp_proximo_nivel(nivel_atual)
	pontos_upgrade_pendentes += 1
	pontos_upgrade_alterados.emit(pontos_upgrade_pendentes)
	subiuDeNivel.emit()


func calcular_xp_proximo_nivel(nivel: int) -> int:
	var indice := maxi(nivel - 1, 0)
	if indice < XP_PROGRESSAO_INICIAL.size():
		return int(XP_PROGRESSAO_INICIAL[indice])
	var niveis_apos_dez := indice - XP_PROGRESSAO_INICIAL.size() + 1
	return 23 + niveis_apos_dez * 5 + int(niveis_apos_dez * niveis_apos_dez / 5.0)


func comprar_upgrade(id: StringName) -> bool:
	if pontos_upgrade_pendentes <= 0:
		return false
	if not DadosUpgrades.disponivel(id, niveis_upgrades, HabilidadeEquipada):
		return false

	var novo_nivel := DadosUpgrades.nivel(id, niveis_upgrades) + 1
	niveis_upgrades[id] = novo_nivel
	pontos_upgrade_pendentes -= 1
	aplicar_upgrade(id)
	pontos_upgrade_alterados.emit(pontos_upgrade_pendentes)
	upgrade_adquirido.emit(id, novo_nivel)
	return true


func gastar_reroll_upgrade() -> bool:
	if rerolls_upgrades_restantes <= 0:
		return false
	rerolls_upgrades_restantes -= 1
	return true


func _valor_tabela(tabela: Array, nivel: int, padrao: float) -> float:
	var indice := nivel - 1
	if indice < 0 or indice >= tabela.size():
		return padrao
	return float(tabela[indice])


func atualizar_multiplicador_forma() -> void:
	match projeteis_por_tiro:
		1: multiplicador_dano_forma = 1.0
		2: multiplicador_dano_forma = 0.68
		3: multiplicador_dano_forma = 0.48
		4: multiplicador_dano_forma = 0.37
		5: multiplicador_dano_forma = 0.30
		6: multiplicador_dano_forma = 0.255
		_:
			multiplicador_dano_forma = 1.55 / float(maxi(projeteis_por_tiro, 1))


func aplicar_upgrade(id: StringName) -> void:
	var nivel_atual_upgrade := DadosUpgrades.nivel(id, niveis_upgrades)
	match id:
		&"dano_calibrado":
			dano *= 1.0 + _valor_tabela(
				BONUS_DANO_POR_NIVEL, nivel_atual_upgrade, 0.04
			)
		&"cadencia":
			CD_MAX = maxf(
				CD_MAX * _valor_tabela(
					FATOR_CADENCIA_POR_NIVEL, nivel_atual_upgrade, 0.97
				),
				0.07
			)
		&"blindagem":
			var vida_anterior := VIDA_MAXIMA
			VIDA_MAXIMA *= 1.0 + _valor_tabela(
				BONUS_VIDA_POR_NIVEL, nivel_atual_upgrade, 0.05
			)
			vida += VIDA_MAXIMA - vida_anterior
		&"propulsao":
			var bonus_propulsao := _valor_tabela(
				BONUS_PROPULSAO_POR_NIVEL, nivel_atual_upgrade, 0.03
			)
			SPEED *= 1.0 + bonus_propulsao
			MAX_VELOCIDADE *= 1.0 + bonus_propulsao
		&"tiro_duplo":
			projeteis_por_tiro = 2
			dispersao_graus = maxf(dispersao_graus, 12.0)
			atualizar_multiplicador_forma()
		&"tiro_triplo":
			projeteis_por_tiro = 3
			dispersao_graus = maxf(dispersao_graus, 18.0)
			atualizar_multiplicador_forma()
		&"leque_prismatico":
			projeteis_por_tiro += 1
			dispersao_graus += 8.0
			atualizar_multiplicador_forma()
		&"calibre_pesado":
			multiplicador_dano_projetil *= 1.0 + _valor_tabela(
				BONUS_CALIBRE_POR_NIVEL, nivel_atual_upgrade, 0.10
			)
			multiplicador_escala_projetil *= 1.14
			multiplicador_velocidade_projetil *= 0.90
		&"perfuracao":
			penetracao_projetil += 1
		&"fragmentacao":
			fragmentos_projetil += 2
		&"mira_gravitacional":
			multiplicador_dano_mira = 0.88
			forca_mira_gravitacional = _valor_tabela(
				FORCA_HOMING_POR_NIVEL, nivel_atual_upgrade, 2.70
			)
		&"ricochete":
			ricochetes_projetil += 1
		&"formacao_convergente":
			formacao_convergente = true
			multiplicador_dano_forma *= 1.08
		&"onda_impacto":
			dano_explosao_impacto += 0.30
			raio_explosao_impacto += 54.0
		&"ressonancia_borda":
			bonus_dano_ricochete += 0.28
		&"predacao_gravitacional":
			forca_mira_gravitacional += 0.75
			multiplicador_dano_mira = minf(multiplicador_dano_mira + 0.06, 1.0)
		&"estilhacos_predadores":
			multiplicador_fragmentos += 0.08
			forca_mira_gravitacional += 0.25
		&"vetor_ofensivo":
			bonus_vetor_ofensivo += 0.16
		&"casco_regenerativo":
			regeneracao_casco_por_segundo += 1.25
		&"capacitor_cinetico":
			nivel_capacitor_cinetico += 1
		&"reacao_adrenal":
			bonus_cadencia_reacao += 0.12
		&"fluxo_habilidade":
			if HabilidadeEquipada:
				HabilidadeEquipada.reduzir_cooldown(
					_valor_tabela(
						FATOR_FLUXO_POR_NIVEL, nivel_atual_upgrade, 0.96
					)
				)
		&"overdrive_habilidade":
			duracao_overdrive += 1.25
		&"conversor_impacto":
			reducao_cooldown_por_impacto += _valor_tabela(
				REDUCAO_IMPACTO_POR_NIVEL, nivel_atual_upgrade, 0.01
			)
		&"nova_ativacao":
			nivel_nova_ativacao += 1
		&"escudo_fase":
			duracao_escudo_fase += 0.35
		&"tempestade_prismatica":
			projeteis_por_tiro += 1
			dispersao_graus += 10.0
			atualizar_multiplicador_forma()
			CD_MAX = maxf(CD_MAX / 1.10, 0.07)
			multiplicador_velocidade_projetil *= 0.85
		&"singularidade":
			multiplicador_dano_projetil *= 1.25
			multiplicador_escala_projetil *= 1.35
			multiplicador_velocidade_projetil *= 0.75
			penetracao_projetil += 1
			forca_mira_gravitacional += 0.8
		&"reator_sincronizado":
			reator_sincronizado = true
			if HabilidadeEquipada:
				HabilidadeEquipada.Cooldown *= 1.15
				HabilidadeEquipada.cooldown_atual = minf(
					HabilidadeEquipada.cooldown_atual,
					HabilidadeEquipada.Cooldown
				)
		_:
			if HabilidadeEquipada:
				HabilidadeEquipada.aplicar_upgrade_especifico(
					id,
					DadosUpgrades.nivel(id, niveis_upgrades)
				)


# Mantém scripts antigos funcionando caso alguma cena ainda chame este método.
func receber_upgrade(tipo: int) -> void:
	var id: StringName
	match tipo:
		Upgrade.CADENCIA:
			id = &"cadencia"
		Upgrade.BLINDAGEM:
			id = &"blindagem"
		Upgrade.DANO:
			id = &"dano_calibrado"
		Upgrade.VELOCIDADE:
			id = &"propulsao"
		Upgrade.TURNSPD:
			VelocidadeVirar *= 1.1
			return
		_:
			return

	niveis_upgrades[id] = DadosUpgrades.nivel(id, niveis_upgrades) + 1
	aplicar_upgrade(id)


func morrer() -> void:
	if not vivo:
		return

	vivo = false
	if is_instance_valid(barra_cooldown_habilidade):
		barra_cooldown_habilidade.hide()
	velocity = Vector2.ZERO
	if HabilidadeEquipada:
		HabilidadeEquipada.ao_desequipar(self)

	visible = false
	death.play()
	if ParticulaMorte:
		var particle = ParticulaMorte.instantiate()
		particle.position = global_position
		particle.rotation = global_rotation
		particle.emitting = true
		get_tree().current_scene.add_child(particle)

	await get_tree().create_timer(1.5).timeout
	queue_free()


func BloquearControle() -> void:
	ctrlblock = true


func DesbloquearControle() -> void:
	ctrlblock = false


func BloquearGiro() -> void:
	giroblock = true


func DesbloquearGiro() -> void:
	giroblock = false


func atualizar_limites() -> void:
	position.x = wrapf(position.x, 0.0, 960.0)
	position.y = wrapf(position.y, 0.0, 540.0)


func _on_hitbox_body_entered(body: Node2D) -> void:
	if not vivo or not body.is_in_group("inimigo"):
		return
	if UsandoHabilidade and dano_colisao_habilidade > 0.0:
		if body.has_method("tomarDano"):
			body.tomarDano(dano_colisao_habilidade)
		if body.is_queued_for_deletion():
			return

	if body.has_method("ao_colidir_com_player"):
		body.ao_colidir_com_player(self)
		return

	var dano_contato = body.get("Dano")
	if dano_contato != null:
		tomar_dano(float(dano_contato))
	if body.has_method("morrer"):
		body.morrer()
