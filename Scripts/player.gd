extends CharacterBody2D
class_name Player


const CAMINHO_HABILIDADE_PADRAO := "res://Habilidades/habilidadeRetrocesso.tres"
const DadosUpgrades = preload("res://Scripts/UpgradeData.gd")
const TEXTURA_COOLDOWN_RELOGIO = preload(
	"res://Habilidades/Icones/cooldown_relogio.svg"
)


@export_category("Combate")
@export var tiro: PackedScene
@export var HabilidadeEquipada: Habilidade
@export var dano := 1.0
@export var CD_MAX := 0.22

@export_category("Movimento")
@export var VelocidadeVirar := 4.0
@export var SPEED := 400.0
@export var MAX_VELOCIDADE := 500.0
@export var friction := 100.0

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
var xp_necessario: int = 3
var invencibilidade := false
var invencibilidade_cd := 0.0
var invencibilidade_cd_max := 3.0
var save := false

# Pontos não interrompem a partida. O jogador abre o menu quando quiser.
var pontos_upgrade_pendentes := 0
var niveis_upgrades: Dictionary = {}

# Montagem dinâmica da arma.
var projeteis_por_tiro := 1
var dispersao_graus := 0.0
var multiplicador_dano_projetil := 1.0
var multiplicador_velocidade_projetil := 1.0
var multiplicador_escala_projetil := 1.0
var penetracao_projetil := 0
var fragmentos_projetil := 0
var forca_mira_gravitacional := 0.0
var ricochetes_projetil := 0

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


func _exit_tree() -> void:
	if HabilidadeEquipada:
		HabilidadeEquipada.ao_desequipar(self)


func _process(delta: float) -> void:
	mira_mouse = Global.mira_mouse
	atualizar_ui()
	atualizar_invencibilidade(delta)
	atualizar_efeitos_temporarios(delta)
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
		not HabilidadeEquipada
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


func atualizar_vida() -> void:
	vida = clampf(vida, 0.0, VIDA_MAXIMA)
	barra_vida.scale.x = escala_base * (vida / VIDA_MAXIMA)
	if vida <= 0.0 and vivo:
		morrer()


func atualizar_invencibilidade(delta: float) -> void:
	if invencibilidade_cd > 0.0:
		invencibilidade_cd = maxf(invencibilidade_cd - delta, 0.0)
		modulate.a = absf(sin(Time.get_ticks_msec() / 100.0))
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
	if not giroblock:
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

	if not ctrlblock:
		if Input.is_action_pressed("acelerar"):
			acelerar(delta, fator_movimento)
		if Input.is_action_pressed("freio"):
			brake(delta, fator_movimento)

	particles.emitting = Input.is_action_pressed("acelerar") or UsandoHabilidade
	velocity = velocity.move_toward(Vector2.ZERO, friction * fator_movimento * delta)

	if not UsandoHabilidade:
		velocity = velocity.limit_length(MAX_VELOCIDADE * fator_movimento)

	move_and_slide()


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
	var arco := deg_to_rad(dispersao_graus)
	for indice in range(quantidade):
		var deslocamento := 0.0
		if quantidade > 1:
			deslocamento = lerpf(
				-arco * 0.5,
				arco * 0.5,
				float(indice) / float(quantidade - 1)
			)
		criar_projetil(rotation + deslocamento)

	somtiro.pitch_scale = randf_range(0.9, 1.1)
	somtiro.play()
	var fator_cadencia := 0.75 if tempo_overdrive > 0.0 else 1.0
	cooldown = maxf(
		CD_MAX * fator_cadencia * multiplicador_cadencia_habilidade,
		0.04
	)


func criar_projetil(
	angulo: float,
	multiplicador_dano_extra := 1.0,
	eh_nova := false
) -> void:
	var projetil = tiro.instantiate()
	get_tree().current_scene.add_child(projetil)
	projetil.global_position = PontaArma.global_position
	projetil.rotation = angulo

	var bonus_overdrive := 1.25 if tempo_overdrive > 0.0 else 1.0
	var dano_final := (
		dano
		* multiplicador_dano_projetil
		* multiplicador_dano_habilidade
		* bonus_overdrive
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
			false
		)
	else:
		projetil.dmg = dano_final


func registrar_acerto_projetil() -> void:
	if reducao_cooldown_por_impacto <= 0.0 or not HabilidadeEquipada:
		return
	HabilidadeEquipada.reduzir_cooldown_atual(reducao_cooldown_por_impacto)


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
	invencibilidade = true
	invencibilidade_cd = invencibilidade_cd_max
	Global.vibrar_controle(0.35, 0.75, 0.2)


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
	xp_necessario += 2
	pontos_upgrade_pendentes += 1
	pontos_upgrade_alterados.emit(pontos_upgrade_pendentes)
	subiuDeNivel.emit()


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


func aplicar_upgrade(id: StringName) -> void:
	match id:
		&"dano_calibrado":
			dano += 0.45
		&"cadencia":
			CD_MAX = maxf(CD_MAX * 0.9, 0.04)
		&"blindagem":
			var vida_anterior := VIDA_MAXIMA
			VIDA_MAXIMA *= 1.12
			vida += VIDA_MAXIMA - vida_anterior
		&"propulsao":
			SPEED *= 1.1
			MAX_VELOCIDADE *= 1.1
		&"tiro_duplo":
			projeteis_por_tiro = 2
			dispersao_graus = maxf(dispersao_graus, 12.0)
			multiplicador_dano_projetil *= 0.78
		&"tiro_triplo":
			projeteis_por_tiro = 3
			dispersao_graus = maxf(dispersao_graus, 18.0)
		&"leque_prismatico":
			projeteis_por_tiro += 1
			dispersao_graus += 8.0
			multiplicador_dano_projetil *= 0.92
		&"calibre_pesado":
			multiplicador_dano_projetil *= 1.24
			multiplicador_escala_projetil *= 1.18
			multiplicador_velocidade_projetil *= 0.92
		&"perfuracao":
			penetracao_projetil += 1
		&"fragmentacao":
			fragmentos_projetil += 2
		&"mira_gravitacional":
			forca_mira_gravitacional += 1.6
		&"ricochete":
			ricochetes_projetil += 1
		&"fluxo_habilidade":
			if HabilidadeEquipada:
				HabilidadeEquipada.reduzir_cooldown(0.9)
		&"overdrive_habilidade":
			duracao_overdrive += 1.5
		&"conversor_impacto":
			reducao_cooldown_por_impacto += 0.06
		&"nova_ativacao":
			nivel_nova_ativacao += 1
		&"escudo_fase":
			duracao_escudo_fase += 0.35
		&"tempestade_prismatica":
			projeteis_por_tiro += 2
			dispersao_graus += 12.0
			CD_MAX = maxf(CD_MAX * 0.85, 0.04)
			multiplicador_dano_projetil *= 0.86
		&"singularidade":
			multiplicador_dano_projetil *= 1.5
			multiplicador_escala_projetil *= 1.5
			multiplicador_velocidade_projetil *= 0.75
			penetracao_projetil += 1
			forca_mira_gravitacional += 2.5
		&"reator_sincronizado":
			reator_sincronizado = true
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
