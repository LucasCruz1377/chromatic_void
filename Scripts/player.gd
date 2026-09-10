extends CharacterBody2D
class_name Player


const CAMINHO_HABILIDADE_PADRAO := "res://Habilidades/habilidadeRetrocesso.tres"
const DadosUpgrades = preload("res://Scripts/UpgradeData.gd")
const EfeitoCombateCena = preload("res://Scripts/EfeitoCombate.gd")
const ExplosaoMonthlyCena = preload("res://Scripts/MonthlyBurst.gd")
const CatalogoMonthly = preload("res://Scripts/MonthlyCatalog.gd")
const TEXTURA_COOLDOWN_RELOGIO = preload(
	"res://Habilidades/Icones/cooldown_relogio.svg"
)
const TEXTURA_MODELO_O = preload("res://UI/modelo_o.svg")
const TEXTURA_RASTRO_MODELO_O = preload("res://UI/rastro_estrela_modelo_o.svg")
const SHADER_COR_MODELO_O = preload("res://FX/canvas_shader/modelo_o_cor.gdshader")
const TEXTURA_MODELO_SPECTRUM = preload("res://UI/modelo_spectrum.svg")
const TEXTURA_MODELO_FSPEED = preload("res://UI/modelo_fspeed.svg")
const SHADER_SPECTRUM = preload("res://FX/canvas_shader/spectrum_rgb.gdshader")
const RASTRO_EXCLUSIVO_CENA = preload("res://Scripts/RastroExclusivo.gd")
const AJUDANTE_MONTHLY = preload("res://Scripts/AjudanteMonthly.gd")
const EFEITO_HABILIDADE_MONTHLY = preload("res://Scripts/MonthlyAbilityEffect.gd")
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
@onready var barra_vida: TextureProgressBar = $"../GUI/Barra_vida"
@onready var barra_xp: TextureProgressBar = $"../GUI/Barra_xp"
@onready var display_skill: TextureRect = $"../GUI/DisplaySkill"
@onready var lvl_text: Label = $"../GUI/LvlText"
@onready var somtiro: AudioStreamPlayer2D = $somtiro
@onready var death: AudioStreamPlayer2D = $death
@onready var corpo_visual: Polygon2D = $corpo
@onready var detalhe_visual: Polygon2D = $corpo2
@onready var luz_visual: PointLight2D = $luz

var vida: float
var cooldown := 0.0
var mira_mouse = Global.mira_mouse
var vivo := true
var giroblock := false
var ctrlblock := false
var UsandoHabilidade := false
var invulneravel_por_habilidade := false
var invulneravel_desenvolvedor := false
var multiplicador_dano_recebido := 1.0
var multiplicador_cura_recebida := 1.0
var multiplicador_velocidade_habilidade := 1.0
var foco_movimento_tempo_real := false
var multiplicador_dano_habilidade := 1.0
var multiplicador_cadencia_habilidade := 1.0
var escudo_habilidade := 0.0
var escudo_habilidade_max := 0.0
var tempo_escudo_habilidade := 0.0
var cor_escudo_habilidade := Color(0.72, 0.42, 1.0, 0.82)
var tempo_resistencia_temporaria := 0.0
var resistencia_temporaria_multiplicador := 1.0
var tempo_queimadura := 0.0
var contador_pulso_queimadura := 0.0
var intervalo_pulso_queimadura := 0.0
var dano_pulso_queimadura := 0.0
var pulsos_queimadura_restantes := 0
var dano_colisao_habilidade := 0.0
var xp_atual: float = 0.0
var _nivel_exibido := -1
var nivel_atual: int = 1
var xp_necessario: int = 2
var invencibilidade := false
var invencibilidade_cd := 0.0
var invencibilidade_cd_max := 1.15
var save := false
var peer_id_dono := 1
var nickname_rede := "PILOTO"
var configuracao_visual_rede: Dictionary = {}
var suporte_nickname_rede: Node2D
var rotulo_nickname_rede: Label
var barra_vida_rede: ProgressBar
var estilo_vida_rede: StyleBoxFlat
var habilidade_rede_path := ""
var niveis_upgrades_rede: Dictionary = {}
var contador_disparos_rede := 0

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

# Equipamentos permanentes escolhidos nas três novas abas da loja.
var arma_monthly: StringName = &""
var modulo_nave: StringName = &""
var mutacao_habilidade: StringName = &""
var modelo_visual_nave: StringName = &"c01_modelo_padrao"
var cor_visual_nave: StringName = &"c10_verde_original"
var rastro_visual_nave: StringName = &"c20_rastro_padrao"
var sprite_modelo_o: Sprite2D
var particulas_rastro_modelo_o: GPUParticles2D
var sprites_modelos_exclusivos: Dictionary = {}
var rastro_exclusivo: RastroExclusivo
var rastro_ativo_rede := false
var carga_arma := 0.0
var calor_feixe := 0.2
var feixe_perielio_ativo: Node2D
var tempo_uso_feixe_perielio := 0.0
var bloqueio_feixe_perielio := 0.0
var sobrecarga_feixe_perielio := false
var aviso_sobrecarga_feixe_perielio := 0.0
var tempo_poder_monthly := 0.0
var tipo_poder_temporario: StringName = &""
var cor_poder_temporario := Color.WHITE
var semente_renascimento_ativa := false
var posicao_semente := Vector2.ZERO
var janela_parry := 0.0
var folhas_tempestade_ativas := false
var tempo_eco_fantasma := 0.0
var historico_disparos: Array[Dictionary] = []
var sementes_vermelhas := 0
var reserva_celulas := 0.0
var progresso_luz_vital := 0.0
var ponto_seguro_ativo := false
var ponto_seguro := Vector2.ZERO
var tempo_motor_maia := 0.0
var tempo_scanner := 0.0
var tempo_reflexo := 0.0
var intervalo_quase_colisao := 0.0
var satelites_restantes := 3
var fase_equinocio_solar := false


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
	if configuracao_visual_rede.is_empty():
		carregar_equipamentos_monthly()
	else:
		_aplicar_campos_configuracao_rede()
	criar_visual_modelo_o()
	criar_visuais_modelos_exclusivos()
	aplicar_personalizacao_nave()
	_criar_nickname_rede()
	if Rede.modo_multiplayer and not is_multiplayer_authority():
		set_physics_process(false)
		return
	carregar_habilidade_equipada()
	criar_barra_cooldown_habilidade()
	if Rede.modo_multiplayer:
		call_deferred("_sincronizar_loadout_rede")
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
	_atualizar_nickname_rede()
	if Rede.modo_multiplayer and not is_multiplayer_authority():
		_atualizar_efeitos_visuais_rede()
		return
	mira_mouse = Global.mira_mouse
	atualizar_ui()
	atualizar_invencibilidade(delta)
	atualizar_efeitos_temporarios(delta)
	atualizar_passivos(delta)
	atualizar_equipamentos_monthly(delta)
	atualizar_overdrive(delta)
	atualizar_habilidade(delta)
	atualizar_movimento(delta)
	atualizar_combate(delta)
	atualizar_limites()
	atualizar_vida()


func _atualizar_efeitos_visuais_rede() -> void:
	var usando_estrelas_modelo_o := _usa_rastro_modelo_o()
	var usando_rastro_especial := _usa_rastro_exclusivo()
	if is_instance_valid(particles):
		particles.visible = not usando_estrelas_modelo_o and not usando_rastro_especial
		particles.emitting = rastro_ativo_rede and visible and not usando_estrelas_modelo_o and not usando_rastro_especial
	if is_instance_valid(particulas_rastro_modelo_o):
		particulas_rastro_modelo_o.visible = usando_estrelas_modelo_o
		particulas_rastro_modelo_o.emitting = rastro_ativo_rede and visible and usando_estrelas_modelo_o
	if is_instance_valid(rastro_exclusivo):
		rastro_exclusivo.definir_estado(rastro_ativo_rede and visible and usando_rastro_especial, obter_cor_personalizacao())
	queue_redraw()


func configurar_jogador_multiplayer(
	id_dono: int,
	novo_nickname: String,
	configuracao: Dictionary
) -> void:
	peer_id_dono = id_dono
	nickname_rede = Rede.sanitizar_nickname(novo_nickname)
	configuracao_visual_rede = configuracao.duplicate(true)
	if is_inside_tree():
		aplicar_configuracao_visual_rede()


func aplicar_configuracao_visual_rede() -> void:
	if not configuracao_visual_rede.is_empty():
		_aplicar_campos_configuracao_rede()
		aplicar_personalizacao_nave()
	if is_instance_valid(rotulo_nickname_rede):
		rotulo_nickname_rede.text = nickname_rede


func _aplicar_campos_configuracao_rede() -> void:
	arma_monthly = StringName(str(configuracao_visual_rede.get("arma", "")))
	modulo_nave = StringName(str(configuracao_visual_rede.get("modulo", "")))
	mutacao_habilidade = StringName(str(configuracao_visual_rede.get("mutacao", "")))
	modelo_visual_nave = StringName(str(configuracao_visual_rede.get("modelo", "c01_modelo_padrao")))
	cor_visual_nave = StringName(str(configuracao_visual_rede.get("cor", "c10_verde_original")))
	rastro_visual_nave = StringName(str(configuracao_visual_rede.get("rastro", "c20_rastro_padrao")))
	if (
		(rastro_visual_nave == &"c21_rastro_estelar_o" and modelo_visual_nave != &"c07_modelo_o")
		or (rastro_visual_nave == &"c22_rastro_spectrum" and modelo_visual_nave != &"c08_modelo_spectrum")
		or (rastro_visual_nave == &"c23_rastro_fspeed" and modelo_visual_nave != &"c09_modelo_fspeed")
	):
		rastro_visual_nave = &"c20_rastro_padrao"
	habilidade_rede_path = str(configuracao_visual_rede.get("habilidade", ""))
	var upgrades_variant: Variant = configuracao_visual_rede.get("upgrades", {})
	niveis_upgrades_rede = upgrades_variant.duplicate(true) if upgrades_variant is Dictionary else {}


func _criar_nickname_rede() -> void:
	if not Rede.modo_multiplayer or is_instance_valid(suporte_nickname_rede):
		return
	suporte_nickname_rede = Node2D.new()
	suporte_nickname_rede.name = "NicknameRede"
	suporte_nickname_rede.set_as_top_level(true)
	add_child(suporte_nickname_rede)
	rotulo_nickname_rede = Label.new()
	rotulo_nickname_rede.position = Vector2(-80.0, -58.0)
	rotulo_nickname_rede.size = Vector2(160.0, 28.0)
	rotulo_nickname_rede.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rotulo_nickname_rede.add_theme_font_size_override("font_size", 14)
	rotulo_nickname_rede.add_theme_color_override("font_color", obter_cor_personalizacao())
	rotulo_nickname_rede.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	rotulo_nickname_rede.add_theme_constant_override("shadow_offset_x", 1)
	rotulo_nickname_rede.add_theme_constant_override("shadow_offset_y", 2)
	rotulo_nickname_rede.text = nickname_rede
	rotulo_nickname_rede.mouse_filter = Control.MOUSE_FILTER_IGNORE
	suporte_nickname_rede.add_child(rotulo_nickname_rede)
	barra_vida_rede = ProgressBar.new()
	barra_vida_rede.name = "BarraVidaRede"
	barra_vida_rede.position = Vector2(-43.0, -29.0)
	barra_vida_rede.size = Vector2(86.0, 4.0)
	barra_vida_rede.custom_minimum_size = Vector2(86.0, 4.0)
	barra_vida_rede.max_value = VIDA_MAXIMA
	barra_vida_rede.value = vida
	barra_vida_rede.show_percentage = false
	barra_vida_rede.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fundo_vida := StyleBoxFlat.new()
	fundo_vida.bg_color = Color(0.01, 0.012, 0.03, 0.92)
	fundo_vida.set_corner_radius_all(1)
	estilo_vida_rede = StyleBoxFlat.new()
	estilo_vida_rede.bg_color = obter_cor_personalizacao()
	estilo_vida_rede.set_corner_radius_all(1)
	barra_vida_rede.add_theme_stylebox_override("background", fundo_vida)
	barra_vida_rede.add_theme_stylebox_override("fill", estilo_vida_rede)
	suporte_nickname_rede.add_child(barra_vida_rede)
	_atualizar_nickname_rede()


func _atualizar_nickname_rede() -> void:
	if is_instance_valid(suporte_nickname_rede):
		suporte_nickname_rede.global_position = global_position
		suporte_nickname_rede.global_rotation = 0.0
		suporte_nickname_rede.visible = visible
		var cor_identidade := obter_cor_personalizacao()
		if is_instance_valid(rotulo_nickname_rede):
			rotulo_nickname_rede.add_theme_color_override("font_color", cor_identidade)
		if is_instance_valid(barra_vida_rede):
			barra_vida_rede.max_value = maxf(VIDA_MAXIMA, 1.0)
			barra_vida_rede.value = clampf(vida, 0.0, VIDA_MAXIMA)
		if is_instance_valid(estilo_vida_rede):
			estilo_vida_rede.bg_color = cor_identidade


func obter_cor_personalizacao() -> Color:
	if modelo_visual_nave == &"c08_modelo_spectrum":
		return Color.from_hsv(fmod(float(Time.get_ticks_msec()) / 9000.0, 1.0), 0.72, 1.0)
	var dados_cor := CatalogoMonthly.encontrar(cor_visual_nave)
	var cor_nave := Color("8bff2a")
	if not dados_cor.is_empty():
		var cor_catalogo: Variant = dados_cor.get("cor", cor_nave)
		if typeof(cor_catalogo) == TYPE_COLOR:
			cor_nave = cor_catalogo
	return cor_nave


func obter_estado_loadout_rede() -> Dictionary:
	return {
		"arma": str(arma_monthly),
		"modulo": str(modulo_nave),
		"mutacao": str(mutacao_habilidade),
		"modelo": str(modelo_visual_nave),
		"cor": str(cor_visual_nave),
		"rastro": str(rastro_visual_nave),
		"habilidade": habilidade_rede_path,
		"upgrades": niveis_upgrades.duplicate(true),
	}


func aplicar_estado_loadout_rede(configuracao: Dictionary) -> void:
	configuracao_visual_rede = configuracao.duplicate(true)
	_aplicar_campos_configuracao_rede()
	aplicar_personalizacao_nave()
	if is_instance_valid(rotulo_nickname_rede):
		rotulo_nickname_rede.add_theme_color_override(
			"font_color", obter_cor_personalizacao()
		)


func _sincronizar_loadout_rede() -> void:
	if not Rede.esta_conectado() or not is_multiplayer_authority():
		return
	var batalha := get_parent()
	if is_instance_valid(batalha) and batalha.has_method("replicar_loadout_player"):
		batalha.call("replicar_loadout_player", obter_estado_loadout_rede())


func carregar_habilidade_equipada() -> void:
	var dados: Dictionary = GerenciadorDeSave.carregar()
	var caminho := (
		habilidade_rede_path
		if not configuracao_visual_rede.is_empty()
		else str(dados.get("habilidade_equipada", ""))
	)
	habilidade_rede_path = caminho
	var habilidade_carregada: Habilidade
	# Uma chave presente e vazia representa a escolha explícita de jogar sem
	# habilidade. Saves antigos sem a chave continuam recebendo a padrão.
	if dados.has("habilidade_equipada") and caminho.is_empty():
		if HabilidadeEquipada:
			HabilidadeEquipada.ao_desequipar(self)
		HabilidadeEquipada = null
		return

	if not Global.modo_desenvolvedor:
		var liberadas = dados.get(
			"habilidades_desbloqueadas",
			[CAMINHO_HABILIDADE_PADRAO]
		)
		var recurso_teste: Habilidade
		if not caminho.is_empty() and ResourceLoader.exists(caminho):
			var carregado := load(caminho)
			if carregado is Habilidade:
				recurso_teste = carregado
		var liberada_por_conquista := (
			is_instance_valid(recurso_teste)
			and Global.item_liberado_por_conquista(recurso_teste.Id)
		)
		if (not (liberadas is Array) or caminho not in liberadas) and not liberada_por_conquista:
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
	if habilidade_rede_path.is_empty() and not habilidade_carregada.resource_path.is_empty():
		habilidade_rede_path = habilidade_carregada.resource_path
	HabilidadeEquipada.reiniciar_estado()
	HabilidadeEquipada.ao_equipar(self)


func carregar_equipamentos_monthly() -> void:
	var dados: Dictionary = GerenciadorDeSave.carregar()
	var equipamentos: Variant = dados.get("equipamentos_loja", {})
	if equipamentos is Dictionary:
		arma_monthly = StringName(str(equipamentos.get("1", "")))
		modulo_nave = StringName(str(equipamentos.get("2", "")))
		mutacao_habilidade = StringName(str(equipamentos.get("3", "")))
	var personalizacao: Variant = dados.get("personalizacao_nave", {})
	if personalizacao is Dictionary:
		modelo_visual_nave = StringName(str(personalizacao.get("modelo", &"c01_modelo_padrao")))
		cor_visual_nave = StringName(str(personalizacao.get("cor", &"c10_verde_original")))
		rastro_visual_nave = StringName(str(personalizacao.get("rastro", &"c20_rastro_padrao")))
	var comprados: Variant = dados.get("itens_desbloqueados", [])
	# Migração transparente da skin de referência removida: compras e seleção
	# antigas passam ao Modelo O sem apagar o progresso do jogador.
	if modelo_visual_nave == &"c07_skin_kirby":
		modelo_visual_nave = &"c07_modelo_o"
		if equipamentos is Dictionary:
			equipamentos["4"] = modelo_visual_nave
	if rastro_visual_nave == &"c21_rastro_estrela_kirby":
		rastro_visual_nave = &"c21_rastro_estelar_o"
	if comprados is Array:
		if &"c07_skin_kirby" in comprados and &"c07_modelo_o" not in comprados:
			comprados.append(&"c07_modelo_o")
		if &"c21_rastro_estrela_kirby" in comprados and &"c21_rastro_estelar_o" not in comprados:
			comprados.append(&"c21_rastro_estelar_o")
	# A antiga sniper foi fundida ao Canhão do Esturjão. Quem a comprou mantém
	# a compra e já entra com a arma consolidada equipada.
	if arma_monthly == &"a02_rifle_cacador":
		arma_monthly = &"a04_canhao_esturjao"
		if equipamentos is Dictionary:
			equipamentos["1"] = arma_monthly
		if comprados is Array and &"a04_canhao_esturjao" not in comprados:
			comprados.append(&"a04_canhao_esturjao")
		GerenciadorDeSave.salvar({
			"equipamentos_loja": equipamentos,
			"itens_desbloqueados": comprados,
		})
	var item_modelo := CatalogoMonthly.encontrar(modelo_visual_nave)
	var item_cor := CatalogoMonthly.encontrar(cor_visual_nave)
	var item_rastro := CatalogoMonthly.encontrar(rastro_visual_nave)
	if item_modelo.is_empty() or StringName(item_modelo.get("grupo_personalizacao", &"")) != &"modelo":
		modelo_visual_nave = &"c01_modelo_padrao"
	if item_cor.is_empty() or StringName(item_cor.get("grupo_personalizacao", &"")) != &"cor":
		cor_visual_nave = &"c10_verde_original"
	if item_rastro.is_empty() or StringName(item_rastro.get("grupo_personalizacao", &"")) != &"rastro":
		rastro_visual_nave = &"c20_rastro_padrao"
	if (
		modelo_visual_nave != &"c01_modelo_padrao"
		and not Global.modo_desenvolvedor
		and (not (comprados is Array) or modelo_visual_nave not in comprados)
		and not Global.item_liberado_por_conquista(modelo_visual_nave)
	):
		modelo_visual_nave = &"c01_modelo_padrao"
	if (
		cor_visual_nave != &"c10_verde_original"
		and not Global.modo_desenvolvedor
		and (not (comprados is Array) or cor_visual_nave not in comprados)
	):
		cor_visual_nave = &"c10_verde_original"
	if (
		rastro_visual_nave == &"c21_rastro_estelar_o"
		and modelo_visual_nave != &"c07_modelo_o"
	) or (
		rastro_visual_nave == &"c22_rastro_spectrum"
		and modelo_visual_nave != &"c08_modelo_spectrum"
	) or (
		rastro_visual_nave == &"c23_rastro_fspeed"
		and modelo_visual_nave != &"c09_modelo_fspeed"
	):
		rastro_visual_nave = &"c20_rastro_padrao"
	for id in [arma_monthly, modulo_nave, mutacao_habilidade]:
		if id.is_empty():
			continue
		var item := CatalogoMonthly.encontrar(id)
		if item.is_empty() or (
			not Global.modo_desenvolvedor
			and id not in comprados
			and not Global.item_liberado_por_conquista(id)
		):
			if id == arma_monthly: arma_monthly = &""
			elif id == modulo_nave: modulo_nave = &""
			elif id == mutacao_habilidade: mutacao_habilidade = &""


func aplicar_personalizacao_nave() -> void:
	if not is_instance_valid(corpo_visual) or not is_instance_valid(detalhe_visual):
		return
	var cor_nave := obter_cor_personalizacao()
	corpo_visual.color = cor_nave
	detalhe_visual.color = cor_nave.lightened(0.10)
	if is_instance_valid(luz_visual):
		luz_visual.color = cor_nave
	if is_instance_valid(rotulo_nickname_rede):
		rotulo_nickname_rede.add_theme_color_override("font_color", cor_nave)
	var usando_modelo_o := modelo_visual_nave == &"c07_modelo_o"
	var usando_modelo_spectrum := modelo_visual_nave == &"c08_modelo_spectrum"
	var usando_modelo_fspeed := modelo_visual_nave == &"c09_modelo_fspeed"
	var usando_sprite_exclusivo := usando_modelo_o or usando_modelo_spectrum or usando_modelo_fspeed
	corpo_visual.visible = not usando_sprite_exclusivo
	detalhe_visual.visible = not usando_sprite_exclusivo
	if is_instance_valid(sprite_modelo_o):
		sprite_modelo_o.visible = usando_modelo_o
		var material_modelo_o := sprite_modelo_o.material as ShaderMaterial
		if is_instance_valid(material_modelo_o):
			material_modelo_o.set_shader_parameter("cor_estrela", cor_nave)
	for id_modelo in sprites_modelos_exclusivos:
		var sprite := sprites_modelos_exclusivos[id_modelo] as Sprite2D
		if not is_instance_valid(sprite):
			continue
		sprite.visible = StringName(id_modelo) == modelo_visual_nave
		if StringName(id_modelo) == &"c09_modelo_fspeed":
			var material_fspeed := sprite.material as ShaderMaterial
			if is_instance_valid(material_fspeed):
				material_fspeed.set_shader_parameter("cor_estrela", cor_nave)
	if is_instance_valid(particulas_rastro_modelo_o):
		particulas_rastro_modelo_o.visible = usando_modelo_o and _usa_rastro_modelo_o()
		var material_particulas_o := particulas_rastro_modelo_o.material as ShaderMaterial
		if is_instance_valid(material_particulas_o):
			material_particulas_o.set_shader_parameter("cor_estrela", cor_nave)
	var material_particulas := particles.process_material as ParticleProcessMaterial
	if is_instance_valid(material_particulas):
		material_particulas = material_particulas.duplicate(true) as ParticleProcessMaterial
		particles.process_material = material_particulas
		material_particulas.color = cor_nave
	_configurar_rastro_exclusivo(cor_nave)

	# O modelo padrão conserva os polígonos originais da cena. As variações usam
	# a mesma caixa visual (aprox. 56 x 44 px) e nunca alteram a colisão circular.
	if modelo_visual_nave == &"c01_modelo_padrao":
		PontaArma.position = Vector2(17.74477, 0.0)
		return
	if usando_modelo_o:
		PontaArma.position = Vector2(34.0, 0.0)
		return
	if usando_modelo_spectrum:
		PontaArma.position = Vector2(30.0, 0.0)
		return
	if usando_modelo_fspeed:
		PontaArma.position = Vector2(31.0, 0.0)
		return
	corpo_visual.position = Vector2.ZERO
	corpo_visual.rotation = 0.0
	corpo_visual.scale = Vector2.ONE
	detalhe_visual.position = Vector2.ZERO
	detalhe_visual.rotation = 0.0
	detalhe_visual.scale = Vector2.ONE
	PontaArma.position = Vector2(30.0, 0.0)
	match modelo_visual_nave:
		&"c02_asa_delta":
			corpo_visual.polygon = PackedVector2Array([
				Vector2(30, 0), Vector2(-15, -22), Vector2(-7, -7),
				Vector2(-22, 0), Vector2(-7, 7), Vector2(-15, 22),
			])
			detalhe_visual.polygon = PackedVector2Array([
				Vector2(24, 0), Vector2(-7, -7), Vector2(5, 0), Vector2(-7, 7),
			])
		&"c03_nucleo_orbital":
			corpo_visual.polygon = PackedVector2Array([
				Vector2(29, 0), Vector2(-10, -22), Vector2(-7, -10),
				Vector2(-22, -5), Vector2(-15, 0), Vector2(-22, 5),
				Vector2(-7, 10), Vector2(-10, 22),
			])
			detalhe_visual.polygon = PackedVector2Array([
				Vector2(2, 0), Vector2(-1, -7), Vector2(-7, -10),
				Vector2(-13, -7), Vector2(-16, 0), Vector2(-13, 7),
				Vector2(-7, 10), Vector2(-1, 7),
			])
		&"c04_dardo":
			corpo_visual.polygon = PackedVector2Array([
				Vector2(31, 0), Vector2(-14, -15), Vector2(-8, -5),
				Vector2(-24, -8), Vector2(-16, 0), Vector2(-24, 8),
				Vector2(-8, 5), Vector2(-14, 15),
			])
			detalhe_visual.polygon = PackedVector2Array([
				Vector2(25, 0), Vector2(-8, -5), Vector2(0, 0), Vector2(-8, 5),
			])
		&"c05_interceptor":
			corpo_visual.polygon = PackedVector2Array([
				Vector2(29, 0), Vector2(5, -5), Vector2(-12, -22),
				Vector2(-7, -7), Vector2(-24, -11), Vector2(-15, 0),
				Vector2(-24, 11), Vector2(-7, 7), Vector2(-12, 22), Vector2(5, 5),
			])
			detalhe_visual.polygon = PackedVector2Array([
				Vector2(23, 0), Vector2(5, -5), Vector2(-3, 0), Vector2(5, 5),
			])
		&"c06_estrela_rosa":
			corpo_visual.polygon = PackedVector2Array([
				Vector2(29, 0), Vector2(15, -8), Vector2(7, -24),
				Vector2(-2, -12), Vector2(-19, -16), Vector2(-14, -3),
				Vector2(-27, 8), Vector2(-9, 9), Vector2(-3, 24),
				Vector2(7, 12), Vector2(22, 16), Vector2(18, 4),
			])
			detalhe_visual.polygon = PackedVector2Array([
				Vector2(20, 0), Vector2(7, -5), Vector2(1, -14),
				Vector2(-4, -6), Vector2(-15, -7), Vector2(-8, 0),
				Vector2(-15, 7), Vector2(-4, 6), Vector2(1, 14), Vector2(7, 5),
			])
		_:
			modelo_visual_nave = &"c01_modelo_padrao"


func criar_visual_modelo_o() -> void:
	if is_instance_valid(sprite_modelo_o):
		return
	sprite_modelo_o = Sprite2D.new()
	sprite_modelo_o.name = "ModeloO"
	sprite_modelo_o.texture = TEXTURA_MODELO_O
	sprite_modelo_o.scale = Vector2(0.31, 0.31)
	sprite_modelo_o.z_index = 3
	sprite_modelo_o.visible = false
	var material_modelo_o := ShaderMaterial.new()
	material_modelo_o.shader = SHADER_COR_MODELO_O
	sprite_modelo_o.material = material_modelo_o
	add_child(sprite_modelo_o)

	particulas_rastro_modelo_o = GPUParticles2D.new()
	particulas_rastro_modelo_o.name = "RastroEstelarModeloO"
	particulas_rastro_modelo_o.texture = TEXTURA_RASTRO_MODELO_O
	particulas_rastro_modelo_o.position = Vector2(-25.0, 0.0)
	particulas_rastro_modelo_o.z_index = 2
	particulas_rastro_modelo_o.amount = 18
	particulas_rastro_modelo_o.lifetime = 0.72
	particulas_rastro_modelo_o.randomness = 0.35
	particulas_rastro_modelo_o.fixed_fps = 30
	particulas_rastro_modelo_o.local_coords = false
	particulas_rastro_modelo_o.visibility_rect = Rect2(-160, -160, 320, 320)
	particulas_rastro_modelo_o.emitting = false
	var material_rastro := ParticleProcessMaterial.new()
	material_rastro.particle_flag_disable_z = true
	material_rastro.direction = Vector3(-1.0, 0.0, 0.0)
	material_rastro.spread = 24.0
	material_rastro.initial_velocity_min = 24.0
	material_rastro.initial_velocity_max = 58.0
	material_rastro.angular_velocity_min = -150.0
	material_rastro.angular_velocity_max = 150.0
	material_rastro.scale_min = 0.035
	material_rastro.scale_max = 0.075
	material_rastro.gravity = Vector3.ZERO
	material_rastro.color = Color.WHITE
	particulas_rastro_modelo_o.process_material = material_rastro
	var material_canvas := ShaderMaterial.new()
	material_canvas.shader = SHADER_COR_MODELO_O
	particulas_rastro_modelo_o.material = material_canvas
	add_child(particulas_rastro_modelo_o)


func criar_visuais_modelos_exclusivos() -> void:
	if not sprites_modelos_exclusivos.is_empty():
		return
	var spectrum := Sprite2D.new()
	spectrum.name = "ModeloSpectrum"
	spectrum.texture = TEXTURA_MODELO_SPECTRUM
	spectrum.scale = Vector2(0.25, 0.25)
	spectrum.z_index = 3
	spectrum.visible = false
	var material_spectrum := ShaderMaterial.new()
	material_spectrum.shader = SHADER_SPECTRUM
	spectrum.material = material_spectrum
	add_child(spectrum)
	sprites_modelos_exclusivos[&"c08_modelo_spectrum"] = spectrum

	var fspeed := Sprite2D.new()
	fspeed.name = "ModeloFspeed"
	fspeed.texture = TEXTURA_MODELO_FSPEED
	fspeed.scale = Vector2(0.28, 0.28)
	fspeed.z_index = 3
	fspeed.visible = false
	var material_fspeed := ShaderMaterial.new()
	material_fspeed.shader = SHADER_COR_MODELO_O
	fspeed.material = material_fspeed
	add_child(fspeed)
	sprites_modelos_exclusivos[&"c09_modelo_fspeed"] = fspeed

	rastro_exclusivo = RASTRO_EXCLUSIVO_CENA.new()
	rastro_exclusivo.name = "RastroExclusivo"
	add_child(rastro_exclusivo)
	rastro_exclusivo.configurar(self, &"", obter_cor_personalizacao())


func _configurar_rastro_exclusivo(cor: Color) -> void:
	if not is_instance_valid(rastro_exclusivo):
		return
	var tipo: StringName = &""
	if modelo_visual_nave == &"c08_modelo_spectrum" and rastro_visual_nave == &"c22_rastro_spectrum":
		tipo = &"spectrum"
	elif modelo_visual_nave == &"c09_modelo_fspeed" and rastro_visual_nave == &"c23_rastro_fspeed":
		tipo = &"fspeed"
	rastro_exclusivo.configurar(self, tipo, cor)


func _usa_rastro_modelo_o() -> bool:
	return modelo_visual_nave == &"c07_modelo_o" and rastro_visual_nave == &"c21_rastro_estelar_o"


func _usa_rastro_exclusivo() -> bool:
	return (
		modelo_visual_nave == &"c08_modelo_spectrum" and rastro_visual_nave == &"c22_rastro_spectrum"
	) or (
		modelo_visual_nave == &"c09_modelo_fspeed" and rastro_visual_nave == &"c23_rastro_fspeed"
	)


func atualizar_ui() -> void:
	if _nivel_exibido != nivel_atual:
		_nivel_exibido = nivel_atual
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
		ctrlblock = true
		if is_instance_valid(barra_cooldown_habilidade):
			barra_cooldown_habilidade.hide()
		return
	ctrlblock = false
	atualizar_barra_cooldown_habilidade()


func atualizar_vida() -> void:
	vida = clampf(vida, 0.0, VIDA_MAXIMA)
	if is_instance_valid(barra_vida):
		barra_vida.max_value = VIDA_MAXIMA
		barra_vida.value = vida
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
	if not (HabilidadeEquipada is HabilidadeMonthly):
		_replicar_habilidade_visual_generica()
	if duracao_overdrive > 0.0:
		var multiplicador_duracao := 2.0 if reator_sincronizado else 1.0
		tempo_overdrive = duracao_overdrive * multiplicador_duracao

	if duracao_escudo_fase > 0.0:
		invencibilidade = true
		invencibilidade_cd = maxf(invencibilidade_cd, duracao_escudo_fase)

	if nivel_nova_ativacao > 0:
		disparar_nova_de_ativacao()

	if modulo_nave == &"n10_chassi_equinocio":
		fase_equinocio_solar = not fase_equinocio_solar
		if fase_equinocio_solar:
			_criar_feedback_monthly(global_position, Color(1.0, 0.72, 0.18), 1.1, 2.0)
		else:
			ativar_escudo(16.0, 4.0, Color(0.48, 0.62, 1.0))
			_criar_feedback_monthly(global_position, Color(0.48, 0.62, 1.0), 1.1, 1.0)
	aplicar_mutacao_habilidade()


func aplicar_poder_monthly(efeito_id: StringName, cor: Color, potencia: float, config: Dictionary = {}) -> void:
	var cena := get_tree().current_scene
	if not is_instance_valid(cena):
		return
	# Uma assinatura visual própria nasce em toda ativação. Os feedbacks de
	# impacto posteriores continuam separados e não escondem a leitura do poder.
	# A ativação já é recriada pelo evento da habilidade no outro peer.
	ExplosaoMonthlyCena.criar(cena, global_position, cor, 0.82 * potencia, efeito_id, -1, false)
	_replicar_habilidade_visual({
		"monthly": true,
		"efeito_id": efeito_id,
		"cor": cor,
		"potencia": potencia,
		"config": config.duplicate(true),
	})
	if efeito_id in [&"ovo", &"florescimento", &"fantasma", &"presente", &"laco", &"tempestade"]:
		EFEITO_HABILIDADE_MONTHLY.criar(cena, self, efeito_id, cor, potencia, config)
		return
	match efeito_id:
		&"clone":
			_invocar_ajudante_monthly(AjudanteMonthly.Tipo.CLONE, cor, potencia)
			_criar_feedback_monthly(global_position - transform.y * 28.0, cor, 1.0, 1.0)
		&"renascimento":
			semente_renascimento_ativa = true
			posicao_semente = global_position
			_criar_feedback_monthly(posicao_semente, cor, 1.4, 2.0)
		&"protetor":
			_invocar_ajudante_monthly(AjudanteMonthly.Tipo.GUARDIAO, cor, potencia)
			_criar_feedback_monthly(global_position, cor, 1.35, 5.0)
		&"parry":
			janela_parry = 1.15
			_criar_feedback_monthly(global_position, cor, 0.85, 0.0)
		&"imaginacao":
			tipo_poder_temporario = &"imaginacao"
			tempo_poder_monthly = 6.0
			cor_poder_temporario = cor
			_disparar_radial(7, 0.5, &"toy", cor)
		&"natureza":
			_furia_natureza_em_sequencia(cor, potencia)
			_criar_feedback_monthly(global_position, cor, 1.25, 7.0)
		&"onda":
			_limpar_projeteis_inimigos(global_position, 245.0, false)
			_atingir_area(global_position, 245.0, 6.0 * potencia, 360.0, 0.45)
			_criar_feedback_monthly(global_position + transform.x * 80.0, cor, 2.0, 8.0)
		&"determinacao":
			ativar_escudo(32.0 * potencia, 6.0, cor)
			for alvo in _inimigos_mais_proximos(6):
				alvo.set_meta("marcado_determinacao", Time.get_ticks_msec() + 6000)
				_criar_feedback_monthly(alvo.global_position, cor, 0.48, 0.0)
			_atingir_area(global_position, 190.0, 13.0 * potencia, 260.0, 0.8)
			_criar_feedback_monthly(global_position, cor, 1.7, 10.0)


func aplicar_mutacao_habilidade() -> void:
	if mutacao_habilidade.is_empty():
		return
	match mutacao_habilidade:
		&"u01_alcateia_lunar":
			criar_projetil(rotation - 0.32, 0.58, true, null, 0.0, &"moon", Color(0.78, 0.88, 1.0))
			criar_projetil(rotation + 0.32, 0.58, true, null, 0.0, &"moon", Color(0.78, 0.88, 1.0))
		&"u02_cobertura_neve":
			_atingir_area(global_position, 150.0, 1.0, 0.0, 1.8)
			_criar_feedback_monthly(global_position, Color(0.72, 0.92, 1.0), 1.2, 0.0)
		&"u03_retorno_subterraneo":
			_mutacao_atrasada(&"worm")
		&"u04_floracao_rosa":
			_disparar_radial(10, 0.38, &"petal", Color(1.0, 0.48, 0.7))
		&"u05_jardim_crescente":
			_atingir_area(global_position, 180.0, 4.5, 60.0, 0.65)
			_criar_feedback_monthly(global_position, Color(1.0, 0.42, 0.68), 1.45, 3.0)
		&"u06_sementes_vermelhas":
			var bonus := 1.0 + float(sementes_vermelhas) * 0.12
			_disparar_radial(6 + sementes_vermelhas, 0.38 * bonus, &"seed", Color(1.0, 0.25, 0.36))
			sementes_vermelhas = 0
		&"u07_galhos_lunares":
			for deslocamento in [-0.48, 0.48]:
				criar_projetil(rotation + deslocamento, 0.62, true, null, 0.0, &"branch", Color(0.77, 0.55, 0.34))
		&"u08_corrente_esturjao":
			criar_projetil(rotation, 0.72, true, null, 0.0, &"wave", Color(0.35, 0.78, 1.0), {"penetracao": 2})
		&"u09_colheita_cromatica":
			_coletar_experiencia_proxima()
			_disparar_radial(6, 0.4, &"harvest", Color(1.0, 0.7, 0.26))
		&"u10_marca_cacador":
			var alvos := _inimigos_mais_fortes(1)
			if not alvos.is_empty():
				for angulo in [-0.12, 0.0, 0.12]:
					criar_projetil(rotation + angulo, 0.55, true, alvos[0], 0.0, &"hunter", Color(1.0, 0.55, 0.25), {"homing": 4.0})
		&"u11_barragem_castor":
			ativar_escudo(22.0, 5.0, Color(0.78, 0.53, 0.3))
		&"u12_noite_congelada":
			_limpar_projeteis_inimigos(global_position, 190.0, true)
			_criar_feedback_monthly(global_position, Color(0.5, 0.78, 1.0), 1.35, 2.0)


func _criar_feedback_monthly(posicao: Vector2, cor: Color, intensidade: float, tremor: float) -> void:
	var cena := get_tree().current_scene
	if is_instance_valid(cena):
		EfeitoCombateCena.criar(cena, posicao, EfeitoCombate.Tipo.MORTE, cor, intensidade, transform.x)
		ExplosaoMonthlyCena.criar(cena, posicao, cor, intensidade)
	var camera_efeito := get_tree().get_first_node_in_group("camera") as Camera2D
	if tremor > 0.0 and is_instance_valid(camera_efeito) and camera_efeito.has_method("shake"):
		camera_efeito.shake(tremor)


func _atingir_area(
	centro: Vector2, raio: float, dano_area: float, empurrao: float, atordoamento: float
) -> void:
	for node in get_tree().get_nodes_in_group("inimigo"):
		if not is_instance_valid(node) or not (node is Node2D):
			continue
		var alvo := node as Node2D
		var distancia := centro.distance_to(alvo.global_position)
		if distancia > raio:
			continue
		var queda := clampf(1.0 - distancia / maxf(raio, 1.0), 0.25, 1.0)
		if alvo.has_method("tomarDano"):
			alvo.tomarDano(dano_area * queda * multiplicador_dano_habilidade)
		if empurrao > 0.0 and alvo.has_method("aplicar_empurrao"):
			var direcao := centro.direction_to(alvo.global_position)
			alvo.aplicar_empurrao(direcao * empurrao * queda)
		if atordoamento > 0.0 and alvo.has_method("aplicar_atordoamento"):
			alvo.aplicar_atordoamento(atordoamento * queda)


func _limpar_projeteis_inimigos(centro: Vector2, raio: float, com_estilhacos: bool) -> void:
	for node in get_tree().get_nodes_in_group("projetil_inimigo"):
		if not is_instance_valid(node) or not (node is Node2D):
			continue
		var projetil_inimigo := node as Node2D
		if centro.distance_to(projetil_inimigo.global_position) > raio:
			continue
		if com_estilhacos:
			EfeitoCombateCena.criar(get_tree().current_scene, projetil_inimigo.global_position, EfeitoCombate.Tipo.ACERTO, Color(0.62, 0.86, 1.0), 0.55)
		projetil_inimigo.queue_free()


func _disparar_radial(
	quantidade: int, dano_extra: float, estilo: StringName, cor: Color
) -> void:
	for indice in range(quantidade):
		var angulo := rotation + TAU * float(indice) / float(maxi(quantidade, 1))
		criar_projetil(angulo, dano_extra, true, null, 0.0, estilo, cor)


func _disparar_leque(
	quantidade: int, abertura_graus: float, dano_extra: float,
	estilo: StringName, cor: Color
) -> void:
	for indice in range(quantidade):
		var progresso := float(indice) / float(maxi(quantidade - 1, 1))
		var angulo := rotation + deg_to_rad(lerpf(-abertura_graus * 0.5, abertura_graus * 0.5, progresso))
		criar_projetil(angulo, dano_extra, true, null, 0.0, estilo, cor)


func _disparar_leque_monthly(
	quantidade: int, abertura_graus: float, dano_extra: float,
	estilo: StringName, cor: Color, config: Dictionary
) -> void:
	for indice in range(quantidade):
		var progresso := float(indice) / float(maxi(quantidade - 1, 1))
		var angulo := rotation + deg_to_rad(lerpf(-abertura_graus * 0.5, abertura_graus * 0.5, progresso))
		criar_projetil(angulo, dano_extra, false, null, 0.0, estilo, cor, config)


func _explodir_em_linha(
	cor: Color, quantidade: int, passo: float, raio: float, dano_linha: float
) -> void:
	for indice in range(1, quantidade + 1):
		var ponto := global_position + transform.x * passo * float(indice)
		_atingir_area(ponto, raio, dano_linha, 90.0, 0.5)
		EfeitoCombateCena.criar(get_tree().current_scene, ponto, EfeitoCombate.Tipo.MORTE, cor, 0.68, transform.x)
	_criar_feedback_monthly(global_position + transform.x * passo * 2.0, cor, 0.9, 5.0)


func _inimigos_mais_proximos(quantidade: int) -> Array[Node2D]:
	var alvos: Array[Node2D] = []
	for node in get_tree().get_nodes_in_group("inimigo"):
		if is_instance_valid(node) and node is Node2D:
			alvos.append(node as Node2D)
	alvos.sort_custom(func(a: Node2D, b: Node2D) -> bool:
		return global_position.distance_squared_to(a.global_position) < global_position.distance_squared_to(b.global_position)
	)
	if alvos.size() > quantidade:
		alvos.resize(quantidade)
	return alvos


func _inimigos_mais_fortes(quantidade: int) -> Array[Node2D]:
	var alvos: Array[Node2D] = []
	for node in get_tree().get_nodes_in_group("inimigo"):
		if is_instance_valid(node) and node is Node2D:
			alvos.append(node as Node2D)
	alvos.sort_custom(func(a: Node2D, b: Node2D) -> bool:
		return float(a.get("Vida")) > float(b.get("Vida"))
	)
	if alvos.size() > quantidade:
		alvos.resize(quantidade)
	return alvos


func _repetir_disparo_clone(cor: Color, potencia: float) -> void:
	await get_tree().create_timer(0.28).timeout
	if not vivo:
		return
	for deslocamento in [-0.18, 0.0, 0.18]:
		criar_projetil(rotation + deslocamento, 0.65 * potencia, true, null, 20.0 * deslocamento, &"clone", cor)
	_criar_feedback_monthly(global_position - transform.y * 28.0, cor, 0.7, 1.0)


func _abrir_presente_depois(tipo_presente: int, cor: Color, potencia: float) -> void:
	await get_tree().create_timer(0.48).timeout
	if not vivo:
		return
	_criar_feedback_monthly(global_position, cor, 1.35, 3.0)
	if tipo_presente == 0:
		_disparar_radial(12, 0.55 * potencia, &"gift", cor)
	elif tipo_presente == 1:
		ativar_escudo(28.0 * potencia, 6.0, cor)
	else:
		_atingir_area(global_position, 210.0, 3.0, 80.0, 2.4)


func _repetir_disparos_recentes(cor: Color, potencia: float) -> void:
	var agora := Time.get_ticks_msec()
	var recentes: Array[Dictionary] = []
	for registro in historico_disparos:
		if agora - int(registro.get("tempo", 0)) <= 4200:
			recentes.append(registro.duplicate(true))
	if recentes.is_empty():
		_disparar_radial(10, 0.48 * potencia, &"firework", cor)
		return
	var inicio := maxi(recentes.size() - 10, 0)
	for indice in range(inicio, recentes.size()):
		var registro := recentes[indice]
		var angulo := float(registro.get("angulo", rotation))
		criar_projetil(angulo, 0.58 * potencia, true, null, 0.0, &"firework", cor)


func _furia_natureza_em_sequencia(cor: Color, potencia: float) -> void:
	for indice in range(1, 8):
		if not vivo:
			return
		var ponto := global_position + transform.x * 62.0 * float(indice)
		_atingir_area(ponto, 55.0, 8.0 * potencia, 90.0, 0.5)
		EfeitoCombateCena.criar(get_tree().current_scene, ponto, EfeitoCombate.Tipo.MORTE, cor, 0.68, transform.x)
		await get_tree().create_timer(0.065).timeout


func _invocar_ajudante_monthly(tipo: AjudanteMonthly.Tipo, cor: Color, potencia: float) -> void:
	# Cada nova ativação renova o ajudante correspondente, sem empilhar dezenas
	# de drones e sem fingir a invocação com uma simples rajada.
	var grupo := "ajudante_clone" if tipo == AjudanteMonthly.Tipo.CLONE else "ajudante_guardiao"
	for antigo in get_tree().get_nodes_in_group(grupo):
		if is_instance_valid(antigo):
			antigo.queue_free()
	var ajudante := AJUDANTE_MONTHLY.new() as AjudanteMonthly
	get_tree().current_scene.add_child(ajudante)
	ajudante.add_to_group(grupo)
	ajudante.configurar(self, tipo, cor, potencia)


func _mutacao_atrasada(estilo: StringName) -> void:
	await get_tree().create_timer(0.45).timeout
	if not vivo:
		return
	var alvos := _inimigos_mais_proximos(1)
	if alvos.is_empty():
		return
	var alvo := alvos[0]
	_atingir_area(alvo.global_position, 72.0, 7.0, 110.0, 0.45)
	EfeitoCombateCena.criar(get_tree().current_scene, alvo.global_position, EfeitoCombate.Tipo.MORTE, Color(0.58, 0.88, 0.46), 0.9, Vector2.UP)


func _coletar_experiencia_proxima() -> void:
	for grupo in [&"xp", &"experiencia", &"cristal_xp"]:
		for node in get_tree().get_nodes_in_group(grupo):
			if is_instance_valid(node) and node is Node2D:
				(node as Node2D).global_position = global_position


func atualizar_equipamentos_monthly(delta: float) -> void:
	janela_parry = maxf(janela_parry - delta, 0.0)
	tempo_reflexo = maxf(tempo_reflexo - delta, 0.0)
	calor_feixe = maxf(calor_feixe - delta * 0.34, 0.0)
	if tempo_poder_monthly > 0.0:
		tempo_poder_monthly = maxf(tempo_poder_monthly - delta, 0.0)
		tempo_eco_fantasma -= delta
		if tipo_poder_temporario == &"fantasma" and tempo_eco_fantasma <= 0.0:
			tempo_eco_fantasma = 0.16
			EfeitoCombateCena.criar(get_tree().current_scene, global_position, EfeitoCombate.Tipo.RASTRO, cor_poder_temporario, 0.7, -transform.x)
			_explodir_eco_fantasma(global_position, cor_poder_temporario)
		if tempo_poder_monthly <= 0.0:
			if tipo_poder_temporario == &"fantasma":
				invulneravel_por_habilidade = false
				multiplicador_velocidade_habilidade = 1.0
			tipo_poder_temporario = &""
	if modulo_nave == &"n08_motor_maia":
		if velocity.length() > 150.0 and tempo_sem_dano > 0.4:
			tempo_motor_maia = minf(tempo_motor_maia + delta, 12.0)
		else:
			tempo_motor_maia = maxf(tempo_motor_maia - delta * 2.0, 0.0)
	if modulo_nave == &"n06_scanner_preventivo":
		tempo_scanner -= delta
		if tempo_scanner <= 0.0:
			tempo_scanner = 0.18
			_atualizar_scanner()
	if modulo_nave == &"n01_reflexos_rapidos":
		intervalo_quase_colisao -= delta
		if intervalo_quase_colisao <= 0.0:
			intervalo_quase_colisao = 0.09
			_verificar_quase_colisao()
	if ponto_seguro_ativo and global_position.distance_to(ponto_seguro) <= 42.0:
		ponto_seguro_ativo = false
		ativar_escudo(20.0, 5.0, Color(1.0, 0.82, 0.24))
		_criar_feedback_monthly(global_position, Color(1.0, 0.82, 0.24), 0.9, 1.5)
	if (
		semente_renascimento_ativa
		or ponto_seguro_ativo
		or folhas_tempestade_ativas
		or modulo_nave in [&"n02_luz_vital", &"n09_familia_satelites"]
	):
		queue_redraw()


func _explodir_eco_fantasma(posicao: Vector2, cor: Color) -> void:
	await get_tree().create_timer(0.42).timeout
	if not is_inside_tree():
		return
	_atingir_area(posicao, 42.0, 2.2, 45.0, 0.1)
	EfeitoCombateCena.criar(get_tree().current_scene, posicao, EfeitoCombate.Tipo.MORTE, cor, 0.56)


func _atualizar_scanner() -> void:
	for node in get_tree().get_nodes_in_group("projetil_inimigo"):
		if not is_instance_valid(node) or not (node is CanvasItem) or not (node is Node2D):
			continue
		var distancia := global_position.distance_to((node as Node2D).global_position)
		(node as CanvasItem).modulate = Color(1.3, 0.55, 0.25, 1.0) if distancia < 210.0 else Color.WHITE


func _verificar_quase_colisao() -> void:
	if tempo_reflexo > 0.0:
		return
	for node in get_tree().get_nodes_in_group("projetil_inimigo"):
		if not is_instance_valid(node) or not (node is Node2D):
			continue
		var distancia := global_position.distance_to((node as Node2D).global_position)
		if distancia > 34.0 and distancia < 72.0:
			tempo_reflexo = 1.1
			rotation += PI * 0.38
			_criar_feedback_monthly(global_position, Color(1.0, 0.9, 0.35), 0.55, 1.0)
			break


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
	# No Foco, velocidade linear compensa o time_scale, mas a rotação usa delta
	# real. Isso mantém o controle normal sem transformar a nave em um pião.
	var fator_rotacao := 1.0 if foco_movimento_tempo_real else fator_movimento
	var delta_rotacao := delta / maxf(Engine.time_scale, 0.01) if foco_movimento_tempo_real else delta
	if modulo_nave == &"n08_motor_maia":
		fator_movimento *= 1.0 + minf(tempo_motor_maia / 12.0, 1.0) * 0.22
	if tempo_reflexo > 0.0:
		fator_movimento *= 1.18
	var usando_toque: bool = Global.controle_toque_ativo
	var usando_controle_simplificado: bool = usando_toque or (
		not Global.controle_avancado
		and Global.ultimo_dispositivo == &"controle"
	)
	var direcao_simplificada := Vector2.ZERO
	var intensidade_re := 0.0
	if usando_controle_simplificado:
		if usando_toque:
			direcao_simplificada = Global.direcao_controle_toque
		else:
			direcao_simplificada = _obter_analogico_esquerdo()
			intensidade_re = _obter_intensidade_l2()
	var acelerando := false

	if usando_controle_simplificado:
		if not giroblock and direcao_simplificada.length_squared() > 0.0:
			rotation = rotate_toward(
				rotation,
				direcao_simplificada.angle(),
				VelocidadeVirar * fator_rotacao * resposta_controle_simplificado * delta_rotacao
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
				VelocidadeVirar * fator_rotacao * delta_rotacao
			)
		elif (
			mira_mouse
			and Global.ultimo_dispositivo != &"controle"
			and not Global.dispositivo_mobile()
		):
			var target_angle := global_position.angle_to_point(get_global_mouse_position())
			rotation = rotate_toward(
				rotation,
				target_angle,
				VelocidadeVirar * fator_rotacao * delta_rotacao
			)
		else:
			arrowsctrl(delta_rotacao, fator_rotacao)

	if not usando_controle_simplificado and not ctrlblock:
		if Input.is_action_pressed("acelerar"):
			acelerar(delta, fator_movimento)
			acelerando = true
		if Input.is_action_pressed("freio"):
			brake(delta, fator_movimento)

	var emitindo_rastro := acelerando or UsandoHabilidade
	rastro_ativo_rede = emitindo_rastro
	var usando_estrelas_modelo_o := _usa_rastro_modelo_o()
	var usando_rastro_especial := _usa_rastro_exclusivo()
	particles.visible = not usando_estrelas_modelo_o and not usando_rastro_especial
	particles.emitting = emitindo_rastro and not usando_estrelas_modelo_o and not usando_rastro_especial
	if is_instance_valid(particulas_rastro_modelo_o):
		particulas_rastro_modelo_o.visible = usando_estrelas_modelo_o
		particulas_rastro_modelo_o.emitting = emitindo_rastro and usando_estrelas_modelo_o
	if is_instance_valid(rastro_exclusivo):
		rastro_exclusivo.definir_estado(emitindo_rastro and usando_rastro_especial, obter_cor_personalizacao())
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
	if arma_monthly == &"a06_feixe_perielio":
		_atualizar_feixe_perielio(delta)
		return
	elif is_instance_valid(feixe_perielio_ativo):
		_encerrar_feixe_perielio(true)
	if ctrlblock:
		if carga_arma > 0.0:
			carga_arma = 0.0
			queue_redraw()
		return
	if arma_monthly == &"a04_canhao_esturjao":
		if vivo and Input.is_action_pressed("atirar"):
			carga_arma = minf(carga_arma + delta, 1.8)
			queue_redraw()
		if vivo and Input.is_action_just_released("atirar") and carga_arma > 0.08 and cooldown <= 0.0:
			fire()
		return
	if carga_arma > 0.0:
		carga_arma = 0.0
		queue_redraw()

	if vivo and Input.is_action_pressed("atirar") and cooldown <= 0.0:
		fire()


func fire() -> void:
	if not tiro:
		return
	if tipo_poder_temporario == &"imaginacao" and tempo_poder_monthly > 0.0:
		var forma := randi_range(0, 2)
		var cor_brinquedo: Color = [Color(1.0, 0.35, 0.72), Color(0.25, 0.86, 1.0), Color(1.0, 0.84, 0.25)][forma]
		if forma == 0:
			_disparar_leque(5, 46.0, 0.42, &"toy", cor_brinquedo)
		elif forma == 1:
			criar_projetil(rotation, 1.25, false, null, 0.0, &"boomerang", cor_brinquedo, {"velocidade": 0.75, "penetracao": 2})
		else:
			criar_projetil(rotation, 0.85, false, null, 0.0, &"missile", cor_brinquedo, {"homing": 3.4})
		somtiro.play()
		cooldown = maxf(CD_MAX * 1.25, 0.08)
		return
	if not arma_monthly.is_empty():
		disparar_arma_monthly()
		return

	var quantidade := maxi(projeteis_por_tiro, 1)
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
		var padrao := calcular_padrao_multitiro(indice, quantidade)
		var alvo_preferido: Node2D
		if not alvos_guiados.is_empty():
			alvo_preferido = alvos_guiados[indice % alvos_guiados.size()]
		criar_projetil(
			rotation + padrao.x,
			bonus_capacitor,
			false,
			alvo_preferido,
			padrao.y
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


func nivel_upgrade_arma(id: StringName) -> int:
	return DadosUpgrades.nivel(id, niveis_upgrades)


func _atualizar_feixe_perielio(delta: float) -> void:
	bloqueio_feixe_perielio = maxf(bloqueio_feixe_perielio - delta, 0)
	if aviso_sobrecarga_feixe_perielio > 0.0:
		aviso_sobrecarga_feixe_perielio = maxf(
			aviso_sobrecarga_feixe_perielio - delta, 0.0
		)
		sobrecarga_feixe_perielio = true
		if aviso_sobrecarga_feixe_perielio <= 0.0:
			_concluir_sobrecarga_feixe_perielio()
		return
	var pressionando := vivo and not ctrlblock and Input.is_action_pressed("atirar")
	if not pressionando:
		_encerrar_feixe_perielio(true)
		return
	if bloqueio_feixe_perielio > 0.0:
		return
	if not is_instance_valid(feixe_perielio_ativo):
		_iniciar_feixe_perielio()
	if not is_instance_valid(feixe_perielio_ativo):
		return
	tempo_uso_feixe_perielio += delta
	var limite_uso := obter_limite_uso_feixe_perielio()
	var infinito := nivel_upgrade_arma(&"perielio_infinito") > 0
	if tempo_uso_feixe_perielio < limite_uso:
		sobrecarga_feixe_perielio = false
		return
	if infinito:
		sobrecarga_feixe_perielio = true
		# Custo direto e contínuo: usar tomar_dano aqui faria os frames de
		# invencibilidade descartarem quase todo o 1% prometido pela melhoria.
		# Como é um custo da própria arma, ele também não interfere no combo.
		vida = maxf(vida - obter_dps_feixe_perielio() * 0.01 * delta, 0.0)
		return
	sobrecarga_feixe_perielio = true
	_criar_feedback_monthly(
		PontaArma.global_position, Color(1.0, 0.14, 0.10), 0.9, 2.0
	)
	# Mantém um aviso vermelho curto e sem dano antes de recolher o Line2D.
	aviso_sobrecarga_feixe_perielio = 0.70


func _concluir_sobrecarga_feixe_perielio() -> void:
	_encerrar_feixe_perielio(false)
	tempo_uso_feixe_perielio = 0.0
	bloqueio_feixe_perielio = clampf(
		2.2 - float(nivel_upgrade_arma(&"perielio_resfriamento")) * 0.35,
		1.0, 3.0
	)


func _iniciar_feixe_perielio() -> void:
	if is_instance_valid(feixe_perielio_ativo) or bloqueio_feixe_perielio > 0.0:
		return
	sobrecarga_feixe_perielio = false
	feixe_perielio_ativo = criar_projetil(
		rotation, 1.0, false, null, 0.0, &"perielio_ray",
		Color(1.0, 0.78, 0.08), {"tempo_vida": 3600.0}
	)
	if is_instance_valid(somtiro):
		somtiro.pitch_scale = 0.82
		somtiro.play()


func _encerrar_feixe_perielio(reiniciar_carga: bool) -> void:
	if is_instance_valid(feixe_perielio_ativo):
		feixe_perielio_ativo.queue_free()
	feixe_perielio_ativo = null
	if reiniciar_carga:
		tempo_uso_feixe_perielio = 0.0
		sobrecarga_feixe_perielio = false
		aviso_sobrecarga_feixe_perielio = 0.0


func obter_limite_uso_feixe_perielio() -> float:
	return 10.0 + float(nivel_upgrade_arma(&"perielio_resfriamento")) * 2.5


func obter_dps_feixe_perielio() -> float:
	var nivel_potencia := nivel_upgrade_arma(&"perielio_potencia")
	var dano_maximo := 5.0
	match nivel_potencia:
		1: dano_maximo = 10.0
		2: dano_maximo = 20.0
		3: dano_maximo = 30.0
	var tempo_crescimento := 10.0 * pow(
		0.70, nivel_upgrade_arma(&"perielio_foco")
	)
	# Começa em 0,2 DPS e avança em degraus perceptíveis a cada 0,5 s.
	var tempo_em_degraus := floorf(tempo_uso_feixe_perielio / 0.5) * 0.5
	var progresso := clampf(
		tempo_em_degraus / maxf(tempo_crescimento, 0.1), 0.0, 1.0
	)
	# Interpolação exponencial de 0,2 DPS até o teto atual.
	return 0.2 * pow(dano_maximo / 0.2, progresso)


func feixe_perielio_em_sobrecarga() -> bool:
	return sobrecarga_feixe_perielio


func feixe_perielio_pode_causar_dano() -> bool:
	return (
		not sobrecarga_feixe_perielio
		or nivel_upgrade_arma(&"perielio_infinito") > 0
	)


func obter_tempo_carga_esturjao() -> float:
	return maxf(1.55 * pow(0.80, nivel_upgrade_arma(&"esturjao_correnteza")), 0.82)


func obter_modo_mina() -> StringName:
	if nivel_upgrade_arma(&"mina_comando_remoto") > 0:
		return &"remoto"
	if nivel_upgrade_arma(&"mina_sensor_proximidade") > 0:
		return &"proximidade"
	return &"tempo"


func _detonar_minas_remotamente() -> bool:
	var detonou := false
	for node in get_tree().get_nodes_in_group("monthly_mine"):
		if (
			is_instance_valid(node)
			and node.has_method("detonar_mina")
			and float(node.get("tempo_estilo")) >= 0.30
		):
			node.call("detonar_mina")
			detonou = true
	return detonou


func disparar_arma_monthly() -> void:
	var cor := Color(0.55, 0.9, 1.0)
	var recarga := CD_MAX
	match arma_monthly:
		&"a01_espingarda_lua_rosa":
			cor = Color(1.0, 0.46, 0.7)
			var nivel_petalas := nivel_upgrade_arma(&"rosa_petalas_extras")
			var nivel_foco := nivel_upgrade_arma(&"rosa_cano_curto")
			var quantidade := 7 + nivel_petalas * 2
			var abertura := 54.0 - float(nivel_foco) * 8.0
			var dano_petala := 0.50 * (1.0 + float(nivel_foco) * 0.18)
			_disparar_leque_monthly(
				quantidade, abertura, dano_petala, &"petal", cor,
				{"tempo_vida": 0.26, "velocidade": 0.92}
			)
			# Cadência deliberadamente baixa: é uma espingarda de aproximação,
			# não um leque capaz de limpar a tela continuamente.
			recarga = maxf(CD_MAX * 3.35, 0.58)
		&"a03_alcateia_misseis":
			cor = Color(0.72, 0.84, 1.0)
			var quantidade := 3 + nivel_upgrade_arma(&"fogos_formacao")
			var nivel_estouro := nivel_upgrade_arma(&"fogos_estouro")
			for indice in range(quantidade):
				var centro := float(indice) - float(quantidade - 1) * 0.5
				criar_projetil(rotation + centro * 0.25, 0.62, false, null, centro * 12.0, &"missile", cor, {"homing": 4.2, "velocidade": 0.72, "explosao": 0.35 + float(nivel_estouro) * 0.18, "raio": 54.0 + float(nivel_estouro) * 12.0})
			recarga *= 2.8
		&"a04_canhao_esturjao":
			cor = Color(0.32, 0.74, 1.0)
			var carga_maxima := obter_tempo_carga_esturjao()
			var proporcao := clampf(carga_arma / carga_maxima, 0.15, 1.0)
			var nivel_perfuracao := nivel_upgrade_arma(&"esturjao_perfurante")
			criar_projetil(rotation, 1.0 + proporcao * (3.2 + float(nivel_perfuracao) * 0.25), false, null, 0.0, &"wave", cor, {"velocidade": 0.72, "escala": 1.0 + proporcao, "penetracao": 2 + roundi(proporcao * 2.0) + nivel_perfuracao})
			carga_arma = 0.0
			recarga *= 3.8
			_criar_feedback_monthly(PontaArma.global_position, cor, 1.0, 4.0 + proporcao * 4.0)
		&"a05_minas_castor":
			cor = Color(1.0, 0.79, 0.16)
			var modo_mina: StringName = obter_modo_mina()
			if modo_mina == &"remoto" and _detonar_minas_remotamente():
				recarga = maxf(CD_MAX * 1.4, 0.22)
			else:
				var tempo_detonacao := maxf(5.0 - float(nivel_upgrade_arma(&"mina_pavio_curto")), 2.0)
				criar_projetil(rotation + PI, 2.4, false, null, 0.0, &"mine", cor, {"velocidade": 0.0, "escala": 1.35, "explosao": 1.2, "raio": 142.0, "modo_mina": modo_mina, "tempo_detonacao": tempo_detonacao})
			recarga *= 4.8
		&"a06_feixe_perielio":
			_iniciar_feixe_perielio()
			return
		&"a07_foice_colheita":
			cor = Color(1.0, 0.68, 0.24)
			var quantidade := 1 + nivel_upgrade_arma(&"colheita_dupla")
			var nivel_retorno := nivel_upgrade_arma(&"colheita_retorno")
			for indice in range(quantidade):
				var centro := float(indice) - float(quantidade - 1) * 0.5
				criar_projetil(rotation + centro * 0.24, 1.4 + float(nivel_retorno) * 0.16, false, null, centro * 10.0, &"harvest_boomerang", cor, {"velocidade": 0.72, "escala": 1.45, "alcance_ida": 390.0, "multiplicador_retorno": 1.25 + float(nivel_retorno) * 0.18})
			recarga *= 3.0
		&"a08_torpedo_subterraneo":
			cor = Color(0.52, 0.9, 0.42)
			var quantidade := 1 + nivel_upgrade_arma(&"terra_raizes_gemeas")
			var nivel_ruptura := nivel_upgrade_arma(&"terra_ruptura")
			for indice in range(quantidade):
				var centro := float(indice) - float(quantidade - 1) * 0.5
				criar_projetil(rotation + centro * 0.18, 1.75, false, null, centro * 18.0, &"underground", cor, {"velocidade": 0.55, "escala": 1.25, "explosao": 0.7 + float(nivel_ruptura) * 0.18, "raio": 82.0 + float(nivel_ruptura) * 14.0})
			recarga *= 3.4
		&"a09_morteiro_fogueira":
			cor = Color(1.0, 0.38, 0.12)
			var quantidade := 1 + nivel_upgrade_arma(&"fogueira_brasas")
			var nivel_circulo := nivel_upgrade_arma(&"fogueira_circulo")
			for indice in range(quantidade):
				var centro := float(indice) - float(quantidade - 1) * 0.5
				criar_projetil(rotation + centro * 0.18, 1.5, false, null, centro * 12.0, &"mortar", cor, {"velocidade": 0.42, "escala": 1.4, "explosao": 0.7 + float(nivel_circulo) * 0.2, "raio": 78.0 + float(nivel_circulo) * 15.0})
			recarga *= 2.9
		&"a10_rajada_morango":
			cor = Color(1.0, 0.24, 0.36)
			var quantidade := 3 + nivel_upgrade_arma(&"morango_cacho") * 2
			var nivel_sementes := nivel_upgrade_arma(&"morango_sementes")
			for indice in range(quantidade):
				var centro := float(indice) - float(quantidade - 1) * 0.5
				var deslocamento := centro * 0.10
				criar_projetil(rotation + deslocamento, 0.48 + float(nivel_sementes) * 0.06, false, null, centro * 7.0, &"seed", cor, {"fragmentos": 3 + nivel_sementes, "escala": 0.72})
			recarga *= 1.8
		&"a11_projetor_nevasca":
			cor = Color(0.7, 0.92, 1.0)
			var nivel_neblina := nivel_upgrade_arma(&"roxo_neblina")
			var nivel_persistencia := nivel_upgrade_arma(&"roxo_persistencia")
			_disparar_leque_monthly(5 + nivel_neblina * 2, 38.0 + float(nivel_neblina) * 5.0, 0.34 + float(nivel_persistencia) * 0.06, &"snow", cor, {"tempo_vida": 0.55, "duracao_lentidao": 0.32 + float(nivel_persistencia) * 0.22})
			recarga *= 1.35
		&"a12_jardim_orbital":
			cor = Color(1.0, 0.38, 0.67)
			var quantidade := 6 + nivel_upgrade_arma(&"jardim_petalas") * 2
			var nivel_sincronia := nivel_upgrade_arma(&"jardim_sincronia")
			for indice in range(quantidade):
				criar_projetil(rotation + TAU * float(indice) / float(quantidade), 0.45 + float(nivel_sincronia) * 0.07, false, null, 0.0, &"orbit", cor, {"indice_orbita": indice, "quantidade_orbita": quantidade, "tempo_orbita": 0.65 - float(nivel_sincronia) * 0.10})
			recarga *= 3.1
		&"a13_canhao_lua_fria":
			cor = Color(0.42, 0.86, 1.0)
			criar_projetil(
				rotation, 0.5, false, null, 0.0, &"ice_stack", cor,
				{
					"velocidade": 0.92,
					"escala": 0.82,
					"tempo_vida": 2.2,
					"nevasca_gelo": nivel_upgrade_arma(&"solsticio_nucleo") > 0,
					"abaixo_zero_gelo": nivel_upgrade_arma(&"solsticio_absorcao") > 0,
				}
			)
			recarga *= 1.15
		_:
			arma_monthly = &""
			fire()
			return

	somtiro.pitch_scale = randf_range(0.88, 1.12)
	somtiro.play()
	var fator_overdrive := 0.75 if tempo_overdrive > 0.0 else 1.0
	cooldown = maxf(recarga * fator_overdrive * multiplicador_cadencia_habilidade, 0.04)


func calcular_padrao_multitiro(indice: int, quantidade: int) -> Vector2:
	if quantidade <= 1:
		return Vector2.ZERO
	var centro := float(indice) - float(quantidade - 1) * 0.5
	var separacao_lateral := 14.0 if quantidade == 2 else 9.0
	var deslocamento_lateral := centro * separacao_lateral
	var deslocamento_angular := 0.0

	# O tiro duplo viaja em paralelo. O tridente abre pouco e o leque só passa
	# a cobrir uma área grande quando existem quatro ou mais projéteis.
	if quantidade == 3:
		deslocamento_angular = deg_to_rad(centro * 7.0)
	elif quantidade >= 4:
		var progresso := float(indice) / float(quantidade - 1)
		deslocamento_angular = lerpf(
			-deg_to_rad(dispersao_graus) * 0.5,
			deg_to_rad(dispersao_graus) * 0.5,
			progresso
		)

	if formacao_convergente:
		# As linhas partem separadas e se encontram aproximadamente 300 px à
		# frente. É uma mudança de geometria, não um bônus escondido de dano.
		deslocamento_angular = atan2(-deslocamento_lateral, 300.0)
	return Vector2(deslocamento_angular, deslocamento_lateral)


func criar_projetil(
	angulo: float,
	multiplicador_dano_extra := 1.0,
	eh_nova := false,
	alvo_homing_preferido: Node2D = null,
	deslocamento_lateral := 0.0,
	estilo_monthly: StringName = &"",
	cor_monthly: Color = Color.WHITE,
	config_monthly: Dictionary = {}
) -> Node2D:
	var projetil = tiro.instantiate()
	get_tree().current_scene.add_child(projetil)
	if estilo_monthly == &"mine":
		projetil.global_position = global_position - global_transform.x.normalized() * 38.0
	else:
		projetil.global_position = (
			PontaArma.global_position
			+ global_transform.y.normalized() * deslocamento_lateral
		)
	var origem_personalizada: Variant = config_monthly.get("origem_global", null)
	if origem_personalizada is Vector2:
		projetil.global_position = origem_personalizada
	projetil.rotation = angulo
	if not eh_nova:
		historico_disparos.append({"tempo": Time.get_ticks_msec(), "angulo": angulo})
		while historico_disparos.size() > 24:
			historico_disparos.pop_front()

	var bonus_overdrive := 1.25 if tempo_overdrive > 0.0 else 1.0
	var velocidade_relativa := clampf(
		velocity.length() / maxf(MAX_VELOCIDADE, 1.0),
		0.0,
		1.0
	)
	var bonus_movimento := 1.0 + bonus_vetor_ofensivo * velocidade_relativa
	var bonus_chassi := 1.18 if modulo_nave == &"n10_chassi_equinocio" and fase_equinocio_solar else 1.0
	var dano_final := (
		dano
		* multiplicador_dano_projetil
		* multiplicador_dano_forma
		* multiplicador_dano_mira
		* multiplicador_dano_habilidade
		* bonus_overdrive
		* bonus_movimento
		* multiplicador_dano_extra
		* bonus_chassi
	)

	if not eh_nova:
		var critico := preload("res://Scripts/Criticos.gd").valores(arma_monthly, niveis_upgrades)
		if randf() < critico.x:
			dano_final *= critico.y
			projetil.set("eh_critico", true)
	if projetil.has_method("configurar"):
		var velocidade_config := 1000.0 * multiplicador_velocidade_projetil * float(config_monthly.get("velocidade", 1.0))
		var escala_config := multiplicador_escala_projetil * float(config_monthly.get("escala", 1.0))
		var penetracao_config := penetracao_projetil + int(config_monthly.get("penetracao", 0))
		var homing_config := maxf(forca_mira_gravitacional, float(config_monthly.get("homing", 0.0)))
		var fragmentos_config := 0 if eh_nova else fragmentos_projetil + int(config_monthly.get("fragmentos", 0))
		projetil.configurar(
			dano_final,
			velocidade_config,
			escala_config,
			penetracao_config,
			homing_config,
			fragmentos_config,
			ricochetes_projetil,
			self,
			tiro,
			false,
			multiplicador_fragmentos,
			maxf(dano_explosao_impacto, float(config_monthly.get("explosao", 0.0))),
			maxf(raio_explosao_impacto, float(config_monthly.get("raio", 0.0))),
			bonus_dano_ricochete
		)
		if not estilo_monthly.is_empty() and projetil.has_method("configurar_estilo_monthly"):
			projetil.configurar_estilo_monthly(estilo_monthly, cor_monthly, config_monthly)
		if (
			is_instance_valid(alvo_homing_preferido)
			and projetil.has_method("definir_alvo_homing")
		):
			projetil.definir_alvo_homing(alvo_homing_preferido)
	else:
		projetil.dmg = dano_final

	if Rede.esta_conectado():
		registrar_projetil_rede(projetil, estilo_monthly, cor_monthly, config_monthly)
	return projetil as Node2D


func registrar_projetil_rede(
	projetil: Node2D, estilo: StringName, cor: Color, config: Dictionary
) -> void:
	var batalha := get_parent()
	if not is_instance_valid(batalha) or not batalha.has_method("replicar_disparo_player"):
		return
	contador_disparos_rede += 1
	var id_disparo := "%d:%d" % [peer_id_dono, contador_disparos_rede]
	projetil.set_meta("id_disparo_rede", id_disparo)
	if projetil.has_method("configurar_id_disparo_rede"):
		projetil.call("configurar_id_disparo_rede", id_disparo, false)
	var cena_path := "res://Entities/fireball.tscn"
	if tiro and not tiro.resource_path.is_empty():
		cena_path = tiro.resource_path
	batalha.call("replicar_disparo_player", {
		"peer_id": peer_id_dono,
		"id_disparo": id_disparo,
		"cena": cena_path,
		"posicao": projetil.global_position,
		"rotacao": projetil.global_rotation,
		"velocidade": float(projetil.get("velocidade")),
		"escala": projetil.scale,
		"tempo_vida": float(projetil.get("tempo_vida")),
		"estilo": estilo,
		"cor": cor,
		"config": config.duplicate(true),
		"fragmento": bool(projetil.get("eh_fragmento")),
		"critico": bool(projetil.get("eh_critico")),
	})


func _replicar_habilidade_visual_generica() -> void:
	if not HabilidadeEquipada:
		return
	var caminho_icone := ""
	if HabilidadeEquipada.Icone:
		caminho_icone = HabilidadeEquipada.Icone.resource_path
	_replicar_habilidade_visual({
		"monthly": false,
		"habilidade_id": HabilidadeEquipada.Id,
		"icone": caminho_icone,
		"cor": _cor_visual_habilidade(HabilidadeEquipada.Id),
	})


func _replicar_habilidade_visual(dados: Dictionary) -> void:
	if not Rede.esta_conectado():
		return
	var batalha := get_parent()
	if is_instance_valid(batalha) and batalha.has_method("replicar_habilidade_player"):
		dados["peer_id"] = peer_id_dono
		batalha.call("replicar_habilidade_player", dados)


func _cor_visual_habilidade(id: StringName) -> Color:
	match id:
		&"foco_absoluto": return Color(0.3, 0.68, 1.0)
		&"hiperdash": return Color(0.1, 0.82, 1.0)
		&"transfusao": return Color(1.0, 0.08, 0.28)
		&"fogueira_ardente": return Color(1.0, 0.52, 0.1)
		&"escudo_protetor": return Color(0.72, 0.42, 1.0)
		&"abraco_materno": return Color(1.0, 0.42, 0.68)
		_: return Color(0.55, 0.92, 1.0)

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
	if mutacao_habilidade == &"u06_sementes_vermelhas":
		sementes_vermelhas = mini(sementes_vermelhas + 1, 5)
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
	if Rede.modo_multiplayer and not is_multiplayer_authority():
		if multiplayer.is_server() and peer_id_dono > 1:
			_receber_dano_autoritativo.rpc_id(peer_id_dono, clampf(valor, 0.0, 10000.0))
		return
	if (
		invencibilidade
		or invulneravel_por_habilidade
		or invulneravel_desenvolvedor
		or not vivo
	):
		return
	if janela_parry > 0.0:
		janela_parry = 0.0
		_disparar_radial(12, 0.62, &"thorn", Color(0.92, 0.42, 1.0))
		_criar_feedback_monthly(global_position, Color(0.92, 0.42, 1.0), 1.35, 7.0)
		invencibilidade = true
		invencibilidade_cd = 0.42
		return

	var dano_restante := maxf(valor, 0.0)
	if modulo_nave == &"n09_familia_satelites" and satelites_restantes > 0:
		satelites_restantes -= 1
		dano_restante *= 0.35
		_criar_feedback_monthly(global_position, Color(1.0, 0.82, 0.28), 0.7, 2.0)
	if modulo_nave == &"n05_reserva_solidaria" and reserva_celulas > 0.0:
		var reserva_usada := minf(reserva_celulas, dano_restante)
		reserva_celulas -= reserva_usada
		dano_restante -= reserva_usada
	if modulo_nave == &"n04_armadura_aco" and velocity.dot(transform.x) > 40.0:
		dano_restante *= 0.7
	if modulo_nave == &"n07_propulsor_janus":
		var impulso_frontal := velocity.dot(transform.x)
		if absf(impulso_frontal) > 80.0:
			dano_restante *= 0.78
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
	if modulo_nave == &"n03_rede_apoio":
		ponto_seguro_ativo = true
		var lado_x := -1.0 if randf() < 0.5 else 1.0
		var lado_y := -1.0 if randf() < 0.5 else 1.0
		var area_segura := Global.obter_retangulo_area_visivel(32.0)
		ponto_seguro = Vector2(
			wrapf(
				global_position.x + randf_range(85.0, 150.0) * lado_x,
				area_segura.position.x,
				area_segura.end.x
			),
			wrapf(
				global_position.y + randf_range(70.0, 125.0) * lado_y,
				area_segura.position.y,
				area_segura.end.y
			)
		)


@rpc("any_peer", "call_remote", "reliable")
func _receber_dano_autoritativo(valor: float) -> void:
	if multiplayer.get_remote_sender_id() == 1 and is_multiplayer_authority():
		tomar_dano(clampf(valor, 0.0, 10000.0))


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
	if vida < VIDA_MAXIMA:
		preload("res://Scripts/AudioCombate.gd").tocar(self, &"cura", 1.5)
	var cura_total := valor * multiplicador_cura_recebida
	var excedente := maxf(vida + cura_total - VIDA_MAXIMA, 0.0)
	vida = minf(vida + cura_total, VIDA_MAXIMA)
	if modulo_nave == &"n05_reserva_solidaria" and excedente > 0.0:
		reserva_celulas = minf(reserva_celulas + excedente, 35.0)


func conceder_cura_rede(valor: float) -> void:
	if Rede.modo_multiplayer and not is_multiplayer_authority():
		if multiplayer.is_server() and peer_id_dono > 1:
			_receber_cura_autoritativa.rpc_id(peer_id_dono, clampf(valor, 0.0, 10000.0))
		return
	curar(valor)


@rpc("any_peer", "call_remote", "reliable")
func _receber_cura_autoritativa(valor: float) -> void:
	if multiplayer.get_remote_sender_id() == 1 and is_multiplayer_authority():
		curar(clampf(valor, 0.0, 10000.0))


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


func aplicar_queimadura(dano_total: float, duracao: float) -> void:
	if not vivo or dano_total <= 0.0 or duracao <= 0.0:
		return
	# Uma nova fonte renova a duração e conserva apenas o pulso mais forte.
	# Assim a queimadura permanece perigosa sem acumular infinitamente.
	pulsos_queimadura_restantes = 3
	tempo_queimadura = duracao
	intervalo_pulso_queimadura = duracao / 3.0
	contador_pulso_queimadura = intervalo_pulso_queimadura
	dano_pulso_queimadura = maxf(dano_pulso_queimadura, dano_total / 3.0)
	queue_redraw()


func aplicar_pulso_queimadura() -> void:
	if not vivo or pulsos_queimadura_restantes <= 0:
		return
	var dano_final := maxf(
		dano_pulso_queimadura
		* multiplicador_dano_recebido
		* resistencia_temporaria_multiplicador,
		0.0
	)
	vida = maxf(vida - dano_final, 0.0)
	tempo_sem_dano = 0.0
	pulsos_queimadura_restantes -= 1
	Global.vibrar_controle(0.18, 0.38, 0.10)
	reproduzir_feedback_dano(dano_final)
	var cena := get_tree().current_scene
	if is_instance_valid(cena):
		EfeitoCombateCena.criar(
			cena,
			global_position - Vector2(0.0, 18.0),
			EfeitoCombate.Tipo.RASTRO,
			Color(1.0, 0.38, 0.06),
			0.75,
			Vector2.UP
		)


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

	if tempo_queimadura > 0.0 and pulsos_queimadura_restantes > 0:
		tempo_queimadura = maxf(tempo_queimadura - delta, 0.0)
		contador_pulso_queimadura -= delta
		if contador_pulso_queimadura <= 0.0:
			contador_pulso_queimadura += intervalo_pulso_queimadura
			aplicar_pulso_queimadura()
		queue_redraw()
	else:
		if dano_pulso_queimadura > 0.0:
			dano_pulso_queimadura = 0.0
			pulsos_queimadura_restantes = 0
			queue_redraw()


func atualizar_passivos(delta: float) -> void:
	tempo_sem_dano += delta
	# O método só grava quando há recorde; atualizar por segundo evita I/O por frame.
	if floori(tempo_sem_dano) > floori(tempo_sem_dano - delta):
		Global.registrar_recordes_partida(Global.Combo, Global.Pontos, tempo_sem_dano)
	if tempo_reacao > 0.0:
		tempo_reacao = maxf(tempo_reacao - delta, 0.0)
	if (
		regeneracao_casco_por_segundo > 0.0
		and tempo_sem_dano >= 5.0
		and vida < VIDA_MAXIMA
	):
		curar(regeneracao_casco_por_segundo * delta)


func _draw() -> void:
	_desenhar_carga_arma()
	if escudo_habilidade > 0.0 and escudo_habilidade_max > 0.0:
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
	if tempo_queimadura > 0.0 and pulsos_queimadura_restantes > 0:
		var chama := Color(1.0, 0.35, 0.06, 0.86)
		var oscilacao := sin(Time.get_ticks_msec() * 0.018) * 3.0
		draw_colored_polygon(PackedVector2Array([
			Vector2(-7.0, -30.0),
			Vector2(oscilacao, -47.0),
			Vector2(8.0, -31.0),
			Vector2(2.0, -25.0),
		]), chama)
	if semente_renascimento_ativa:
		var local_semente := to_local(posicao_semente)
		draw_circle(local_semente, 10.0, Color(0.2, 1.0, 0.48, 0.2))
		draw_arc(local_semente, 15.0, 0.0, TAU, 24, Color(0.35, 1.0, 0.58), 2.5, true)
	if ponto_seguro_ativo:
		var local_seguro := to_local(ponto_seguro)
		draw_circle(local_seguro, 28.0, Color(1.0, 0.82, 0.24, 0.08))
		draw_arc(local_seguro, 28.0, 0.0, TAU, 32, Color(1.0, 0.82, 0.24, 0.8), 2.0, true)
	if modulo_nave == &"n09_familia_satelites":
		for indice in range(satelites_restantes):
			var angulo := Time.get_ticks_msec() * 0.0015 + TAU * float(indice) / 3.0
			var ponto := Vector2.from_angle(angulo) * 48.0
			draw_circle(ponto, 5.0, Color(1.0, 0.78, 0.24, 0.9))
	if modulo_nave == &"n02_luz_vital" and progresso_luz_vital > 0.0:
		draw_arc(Vector2.ZERO, 44.0, -PI * 0.5, -PI * 0.5 + TAU * clampf(progresso_luz_vital / 30.0, 0.0, 1.0), 40, Color(1.0, 0.84, 0.28), 3.0, true)
	if folhas_tempestade_ativas:
		for indice in range(8):
			var angulo := -Time.get_ticks_msec() * 0.002 + TAU * float(indice) / 8.0
			draw_circle(Vector2.from_angle(angulo) * 48.0, 3.5, Color(0.3, 1.0, 0.55, 0.9))


func _desenhar_carga_arma() -> void:
	if carga_arma <= 0.0 or arma_monthly != &"a04_canhao_esturjao":
		return
	var carga_maxima := obter_tempo_carga_esturjao()
	var progresso := clampf(carga_arma / carga_maxima, 0.0, 1.0)
	var cor_carga := Color(0.26, 0.86, 1.0)
	var pulso := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.022)
	var centro := PontaArma.position + Vector2(5.0, 0.0)
	var raio := lerpf(2.8, 9.5, progresso)
	draw_circle(
		centro,
		raio * (1.75 + pulso * 0.18),
		Color(cor_carga.r, cor_carga.g, cor_carga.b, 0.10 + progresso * 0.12)
	)
	draw_circle(
		centro,
		raio,
		Color(cor_carga.r, cor_carga.g, cor_carga.b, 0.72 + progresso * 0.25)
	)
	draw_circle(
		centro + Vector2(-raio * 0.24, -raio * 0.24),
		maxf(raio * 0.28, 1.2),
		Color(1.0, 1.0, 1.0, 0.82)
	)


func ganhar_xp(valor: float) -> void:
	xp_atual += valor
	if modulo_nave == &"n02_luz_vital":
		progresso_luz_vital += valor
		if progresso_luz_vital >= 30.0:
			progresso_luz_vital -= 30.0
			curar(12.0)
			ativar_escudo(16.0, 4.0, Color(1.0, 0.84, 0.28))
			_criar_feedback_monthly(global_position, Color(1.0, 0.84, 0.28), 1.05, 2.0)
	while xp_atual >= xp_necessario:
		xp_atual -= xp_necessario
		subir_de_nivel()


func conceder_xp_rede(valor: float) -> void:
	if Rede.modo_multiplayer and not is_multiplayer_authority():
		if multiplayer.is_server() and peer_id_dono > 1:
			_receber_xp_autoritativo.rpc_id(peer_id_dono, clampf(valor, 0.0, 10000.0))
		return
	ganhar_xp(valor)


@rpc("any_peer", "call_remote", "reliable")
func _receber_xp_autoritativo(valor: float) -> void:
	if multiplayer.get_remote_sender_id() == 1 and is_multiplayer_authority():
		ganhar_xp(clampf(valor, 0.0, 10000.0))


func subir_de_nivel() -> void:
	nivel_atual += 1
	xp_necessario = calcular_xp_proximo_nivel(nivel_atual)
	# A frequência acompanha o tamanho atual da equipe: solo/1, dupla/2,
	# trio/3 e quarteto/4. Todos continuam recebendo a mesma quantidade.
	var intervalo_melhoria := 1
	if Rede.modo_multiplayer:
		intervalo_melhoria = clampi(Rede.jogadores.size(), 1, Rede.MAX_JOGADORES)
	if nivel_atual % intervalo_melhoria == 0:
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
	if not DadosUpgrades.disponivel(id, niveis_upgrades, HabilidadeEquipada, arma_monthly):
		return false

	var novo_nivel := DadosUpgrades.nivel(id, niveis_upgrades) + 1
	niveis_upgrades[id] = novo_nivel
	pontos_upgrade_pendentes -= 1
	aplicar_upgrade(id)
	pontos_upgrade_alterados.emit(pontos_upgrade_pendentes)
	upgrade_adquirido.emit(id, novo_nivel)
	_sincronizar_loadout_rede()
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
		2: multiplicador_dano_forma = 0.62
		3: multiplicador_dano_forma = 0.42
		4: multiplicador_dano_forma = 0.31
		5: multiplicador_dano_forma = 0.25
		6: multiplicador_dano_forma = 0.21
		_:
			multiplicador_dano_forma = 1.25 / float(maxi(projeteis_por_tiro, 1))


func aplicar_upgrade(id: StringName) -> void:
	var nivel_atual_upgrade := DadosUpgrades.nivel(id, niveis_upgrades)
	var dados_upgrade := DadosUpgrades.obter(id, HabilidadeEquipada)
	# As melhorias exclusivas são consultadas diretamente no momento do disparo;
	# o nível já foi salvo e não deve cair no manipulador da habilidade ativa.
	if not StringName(dados_upgrade.get("arma_exclusiva", &"")).is_empty():
		return
	match id:
		&"precisao_critica", &"impacto_critico":
			pass # Consultados por Criticos.valores a cada disparo.
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
			dispersao_graus = 0.0
			atualizar_multiplicador_forma()
		&"tiro_triplo":
			projeteis_por_tiro = 3
			dispersao_graus = 14.0
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
			pass # removido em v0.7.3
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
	if semente_renascimento_ativa:
		semente_renascimento_ativa = false
		global_position = posicao_semente
		vida = VIDA_MAXIMA * 0.42
		invencibilidade = true
		invencibilidade_cd = 2.0
		ativar_escudo(VIDA_MAXIMA * 0.18, 4.0, Color(0.32, 1.0, 0.55))
		_criar_feedback_monthly(global_position, Color(0.32, 1.0, 0.55), 1.8, 10.0)
		queue_redraw()
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
		particle.modulate = obter_cor_personalizacao()
		particle.emitting = true
		get_tree().current_scene.add_child(particle)
	var batalha := get_parent()
	if Rede.esta_conectado() and is_instance_valid(batalha) and batalha.has_method("replicar_feedback_visual"):
		batalha.call("replicar_feedback_visual", {
			"classe": &"particula_cena",
			"cena": "res://FX/player_death_parts.tscn",
			"posicao": global_position,
			"rotacao": global_rotation,
			"cor": obter_cor_personalizacao(),
		})
	if is_instance_valid(batalha) and batalha.has_method("_on_player_morreu"):
		batalha.call("_on_player_morreu", self)

	await get_tree().create_timer(1.5).timeout
	if Rede.modo_multiplayer:
		return
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
	var area := Global.obter_retangulo_area_visivel()
	global_position.x = wrapf(global_position.x, area.position.x, area.end.x)
	global_position.y = wrapf(global_position.y, area.position.y, area.end.y)


func _on_hitbox_body_entered(body: Node2D) -> void:
	if (
		not vivo
		or not is_instance_valid(body)
		or body.is_queued_for_deletion()
		or not body.is_in_group("inimigo")
		or bool(body.get("morto"))
	):
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
