extends Node2D


const DadosSetores = preload("res://Scripts/SectorData.gd")
const PainelDesenvolvedorCena = preload("res://Scripts/PainelDesenvolvedor.gd")
const ControlesMobileCena = preload("res://Scripts/ControlesMobile.gd")
const JOGADOR_CENA := preload("res://Entities/player.tscn")
const EfeitoHabilidadeRedeCena = preload("res://Scripts/EfeitoHabilidadeRede.gd")
const EfeitoMonthlyRedeCena = preload("res://Scripts/MonthlyAbilityEffect.gd")
const ExplosaoMonthlyCena = preload("res://Scripts/MonthlyBurst.gd")
const EfeitoCombateRedeCena = preload("res://Scripts/EfeitoCombate.gd")
const IndicadorDanoRedeCena = preload("res://Scripts/IndicadorDano.gd")
const LimiteArenaCoopCena = preload("res://Scripts/LimiteArenaCoop.gd")
const DURACAO_COMBO := 3.0
# Snapshot de recuperação; Player e inimigos já possuem MultiplayerSynchronizer.
# Dez envios por segundo evitam duplicar tráfego sem perder correção de estado.
const INTERVALO_POSICOES_REDE := 0.10
const BONUS_CRISTAIS_COOP_POR_COMPANHEIRO := 0.10
const MULTIPLICADOR_DANO_BOSSES_AJUSTADOS := 1.18
const BOSSES_DANO_PRESERVADO: Array[StringName] = [&"pet0", &"flor_equinocio"]
const TEMPO_RENASCIMENTO_COOP := 8.0

const INIMIGOS: Dictionary = {
	&"seguidor": preload("res://Entities/InimigoSeguidor.tscn"),
	&"melee": preload("res://Entities/InimigoMelee.tscn"),
	&"investida": preload("res://Entities/InimigoInvestida.tscn"),
	&"tanque": preload("res://Entities/InimigoTanque.tscn"),
	&"atirador": preload("res://Entities/InimigoAtirador.tscn"),
	&"broto_primaveril": preload("res://Entities/InimigoBrotoPrimaveril.tscn"),
	&"centelha_guia": preload("res://Entities/InimigoCentelhaGuia.tscn"),
	&"elo_dourado": preload("res://Entities/InimigoEloDourado.tscn"),
	&"prisma_amparo": preload("res://Entities/InimigoPrismaAmparo.tscn"),
	&"satelite_berco": preload("res://Entities/InimigoSateliteBerco.tscn"),
	&"pulso_solar": preload("res://Entities/InimigoPulsoSolar.tscn"),
	&"fita_violeta": preload("res://Entities/InimigoFitaVioleta.tscn"),
	&"no_flutuante": preload("res://Entities/InimigoNoFlutuante.tscn"),
	&"eco_ametista": preload("res://Entities/InimigoEcoAmetista.tscn"),
	&"lamina_iris": preload("res://Entities/InimigoLaminaIris.tscn"),
	&"casulo_prismatico": preload("res://Entities/InimigoCasuloPrismatico.tscn"),
	&"semente_canhao": preload("res://Entities/InimigoSementeCanhao.tscn"),
	&"polen_errante": preload("res://Entities/InimigoPolenErrante.tscn"),
	&"cipo_espiral": preload("res://Entities/InimigoCipoEspiral.tscn"),
	&"fruto_explosivo": preload("res://Entities/InimigoFrutoExplosivo.tscn"),
	&"fragmento_lunar": preload("res://Entities/InimigoFragmentoLunar.tscn"),
	&"centelha_solar": preload("res://Entities/InimigoCentelhaSolar.tscn"),
	&"meteoro_jovem": preload("res://Entities/InimigoMeteoroJovem.tscn"),
	&"eco_gravitacional": preload("res://Entities/InimigoEcoGravitacional.tscn"),
	&"satelite_coroa": preload("res://Entities/InimigoSateliteCoroa.tscn"),
}

const BOSSES: Dictionary = {
	&"pet0": preload("res://Entities/BossPet0.tscn"),
	&"flor_equinocio": preload("res://Entities/BossFlorEquinocio.tscn"),
	&"eclipse_colheita": preload("res://Entities/BossEclipseColheita.tscn"),
	&"constelacao_amparo": preload("res://Entities/BossConstelacaoAmparo.tscn"),
	&"no_ametista": preload("res://Entities/BossNoAmetista.tscn"),
}

const ASTEROIDE_BONUS := preload("res://Entities/AsteroideBonus.tscn")
const TIMER_MAX := 2.4
const TIMER_MIN := 0.72
const MIN_ENEMIES := 2
const MAX_ENEMIES := 10
const MAX_ENEMIES_BASE := 3
const INTERVALO_BOSS := 10
# Construído em duas partes porque a faixa é adicionada pelo autor ao projeto e
# não faz parte dos pacotes de código. O caminho final continua sendo
# res://sounds/OST/LotusDance.mp3.
const CAMINHO_LOTUS_DANCE := "res:/" + "/sounds/OST/LotusDance.mp3"
const CAMINHO_BATALHA_BOSS := "res:/" + "/sounds/OST/The Battle True Colors.ogg"

@export_category("Asteroides bônus")
@export_range(8.0, 90.0, 1.0) var intervalo_asteroide_min: float = 18.0
@export_range(8.0, 120.0, 1.0) var intervalo_asteroide_max: float = 32.0
@export_range(0.0, 1.0, 0.05) var chance_asteroide: float = 0.65
@export_range(0, 4, 1) var max_asteroides: int = 2

@export_category("Setores e bosses")
@export var ativar_bosses: bool = true
@export var testar_boss_ao_iniciar: bool = false

@onready var contpontos: Label = $GUI/Pontos
@onready var player: CharacterBody2D = $Player
@onready var caixa_gameover: VBoxContainer = $"GUI/caixa gameover"
@onready var tocarmusica: AudioStreamPlayer2D = $tocarmusica
@onready var astro = $GUI/Astro
@onready var fundo_original: CanvasItem = $espaco
@onready var tela_upgrades: Control = $GUI/TelaUpgrades
@onready var player_spawner: MultiplayerSpawner = $PlayerSpawner
@onready var world_spawner: MultiplayerSpawner = $WorldSpawner

var pontos: float = 0.0
var timer: float = TIMER_MAX
var tutorial_ativo: bool = false
var game_over: bool = false
var tempo_asteroide: float = 0.0

# A partida sempre começa aqui. Não existe tela de escolha antes do PET-0.
var setor_atual: StringName = &"vazio_inicial"
var setores_concluidos: Array[StringName] = []
var proximo_nivel_boss: int = INTERVALO_BOSS
var escolha_setor_ativa: bool = false
var camada_escolha: CanvasLayer
var fundo_setor: ColorRect
var rotulo_setor: Label

var boss_ativo: InimigoBase
var boss_atual_id: StringName = &""
var boss_hud: VBoxContainer
var boss_nome: Label
var boss_vida: ProgressBar
var boss_detalhe_texto: Label
var boss_detalhe: ProgressBar
var spawns_pausados_desenvolvedor := false
var boss_em_teste := false
var painel_desenvolvedor: PainelDesenvolvedor
var controles_mobile: ControlesMobile
var musica_partida_padrao: AudioStream
var musica_boss_ativa := false
var escala_fundo_original := Vector2.ONE
var estado_visual_boss_pausa: Array[Dictionary] = []
var jogadores_rede: Dictionary = {}
var tempo_nova_solicitacao_rede := 0.0
var aviso_rede: Label
var texto_aguardando_morte: Label
var painel_morte_local_exibido := false
var renascimentos_pendentes: Dictionary = {}
var aguardando_renascimento_local := false
var tempo_renascimento_local := 0.0
var preservar_conexao_ao_sair := false
var disparos_visuais_rede: Dictionary = {}
var tempo_combo_restante := 0.0
var combo_observado := 0
var tamanhos_viewport_rede: Dictionary = {}
var limite_arena_coop: LimiteArenaCoop
var tempo_posicoes_rede := 0.0
var cristais_coop_acumulados := 0
var cristais_coop_aplicados := 0
var area_coop_recebida := false
var tempo_reenvio_viewport := 0.0
var area_visual_coop := Rect2(Vector2.ZERO, Global.TAMANHO_BASE_JOGO)


func _ready() -> void:
	get_tree().paused = false
	Global.limpar_area_multiplayer()
	_configurar_spawners_multiplayer()
	_configurar_jogadores_multiplayer()
	_configurar_area_coop()
	Global.definir_cursor_interface(false)
	Global.Pontos = 0
	Global.Combo = 0
	pontos = 0.0
	timer = TIMER_MAX
	game_over = false
	tempo_asteroide = randf_range(intervalo_asteroide_min, intervalo_asteroide_max)
	caixa_gameover.visible = false
	_criar_aviso_rede()
	escala_fundo_original = fundo_original.scale
	get_viewport().size_changed.connect(_on_tamanho_viewport_alterado)
	call_deferred("_atualizar_area_responsiva")
	if tela_upgrades.has_signal("estado_alterado"):
		tela_upgrades.connect("estado_alterado", _on_menu_upgrades_estado_alterado)
	criar_visual_setor()
	aplicar_setor(&"vazio_inicial")
	if Global.modo_desenvolvedor:
		painel_desenvolvedor = PainelDesenvolvedorCena.new()
		painel_desenvolvedor.name = "PainelDesenvolvedor"
		add_child(painel_desenvolvedor)
		painel_desenvolvedor.configurar(self, player)
	if Global.deve_exibir_controles_toque():
		controles_mobile = ControlesMobileCena.new()
		controles_mobile.name = "ControlesMobile"
		add_child(controles_mobile)
		controles_mobile.configurar(self, player)

	musica_partida_padrao = tocarmusica.stream
	if not tocarmusica.playing:
		tocarmusica.play()

	var dados: Dictionary = GerenciadorDeSave.carregar()
	var tutorial_concluido: bool = dados.get("tutorialconcluido", false) == true
	if not tutorial_concluido:
		tutorial_ativo = true
		limpar_inimigos_sem_recompensa()
		astro.call_deferred("iniciar_tutorial", player)
	else:
		tutorial_ativo = false
		if is_instance_valid(astro):
			astro.queue_free()

	if testar_boss_ao_iniciar:
		proximo_nivel_boss = 1


func _exit_tree() -> void:
	Global.salvar_conquistas()
	Global.limpar_controle_toque()
	Global.definir_cursor_interface(true)
	Global.limpar_area_multiplayer()
	if Rede.modo_multiplayer and not preservar_conexao_ao_sair:
		Rede.encerrar_lobby()


func _configurar_jogadores_multiplayer() -> void:
	if not Rede.modo_multiplayer:
		return
	if not Rede.jogador_desconectado.is_connected(_on_jogador_rede_desconectado):
		Rede.jogador_desconectado.connect(_on_jogador_rede_desconectado)
	if not Rede.desconexao_detectada.is_connected(_on_desconexao_detectada):
		Rede.desconexao_detectada.connect(_on_desconexao_detectada)
	player.configurar_jogador_multiplayer(
		1,
		str(Rede.jogadores.get(1, "PILOTO")),
		Rede.obter_configuracao_nave_local() if multiplayer.is_server() else {}
	)
	player.global_position = _posicao_inicial_peer(1)
	jogadores_rede[1] = player
	if multiplayer.is_server():
		player.call_deferred("aplicar_configuracao_visual_rede")
	else:
		_enviar_solicitacao_entrada()
	call_deferred("_vincular_jogador_local")


func _configurar_spawners_multiplayer() -> void:
	player_spawner.spawn_function = _instanciar_jogador_rede
	for cena in INIMIGOS.values():
		world_spawner.add_spawnable_scene((cena as PackedScene).resource_path)
	for cena in BOSSES.values():
		world_spawner.add_spawnable_scene((cena as PackedScene).resource_path)
	for caminho in [
		"res://Entities/AsteroideBonus.tscn",
		"res://Entities/ProjetilInimigo.tscn",
		"res://Entities/EspinhoPrimaveril.tscn",
		"res://Entities/PetalaBumerangue.tscn",
		"res://Entities/VinhaEspinhosa.tscn",
	]:
		if ResourceLoader.exists(caminho):
			world_spawner.add_spawnable_scene(caminho)


func conceder_cristais_coop(quantidade: int) -> void:
	if quantidade <= 0:
		return
	# Jogar acompanhado rende +10% por companheiro: +10% com 2 pilotos,
	# +20% com 3 e +30% com 4. O host distribui o mesmo total a todos.
	var quantidade_jogadores := clampi(Rede.jogadores.size(), 2, 4)
	var bonus_coop := 1.0 + (
		float(quantidade_jogadores - 1) * BONUS_CRISTAIS_COOP_POR_COMPANHEIRO
	)
	quantidade = maxi(roundi(float(quantidade) * bonus_coop), 1)
	Global.adicionar_cristais(quantidade)
	if Rede.esta_conectado() and multiplayer.is_server():
		cristais_coop_acumulados += quantidade
		_receber_cristais_coop.rpc(cristais_coop_acumulados)


@rpc("authority", "call_remote", "reliable", 0)
func _receber_cristais_coop(total_sessao: int) -> void:
	_aplicar_total_cristais_coop(total_sessao)


func _aplicar_total_cristais_coop(total_sessao: int) -> void:
	var total_seguro := maxi(total_sessao, 0)
	if total_seguro <= cristais_coop_aplicados:
		return
	var diferenca := total_seguro - cristais_coop_aplicados
	cristais_coop_aplicados = total_seguro
	Global.adicionar_cristais(clampi(diferenca, 0, 1000))


func _posicao_inicial_peer(id: int) -> Vector2:
	var posicoes := [
		Vector2(210.0, 190.0), Vector2(750.0, 350.0),
		Vector2(750.0, 190.0), Vector2(210.0, 350.0),
	]
	var ids: Array = Rede.jogadores.keys()
	ids.sort()
	var indice := ids.find(id)
	if indice < 0:
		indice = 0 if id == 1 else mini(ids.size(), posicoes.size() - 1)
	return posicoes[clampi(indice, 0, posicoes.size() - 1)]


func _enviar_solicitacao_entrada() -> void:
	tempo_nova_solicitacao_rede = 0.5
	_solicitar_entrada_partida.rpc_id(
		1, Rede.nickname_local, Rede.obter_configuracao_nave_local()
	)


@rpc("any_peer", "call_remote", "reliable")
func _solicitar_entrada_partida(nickname: String, configuracao: Dictionary) -> void:
	if not multiplayer.is_server():
		return
	var id := multiplayer.get_remote_sender_id()
	if id <= 1 or is_instance_valid(_obter_jogador_rede(id)):
		return
	_configurar_player_host.rpc_id(
		id,
		str(Rede.jogadores.get(1, Rede.nickname_local)),
		Rede.obter_configuracao_nave_local()
	)
	var novo := player_spawner.spawn({
		"peer_id": id,
		"nickname": Rede.sanitizar_nickname(nickname),
		"configuracao": configuracao.duplicate(true),
		"posicao_spawn": _posicao_inicial_peer(id),
	}) as Player
	if is_instance_valid(novo):
		jogadores_rede[id] = novo


@rpc("authority", "call_remote", "reliable")
func _configurar_player_host(nickname: String, configuracao: Dictionary) -> void:
	player.configurar_jogador_multiplayer(1, nickname, configuracao)
	player.aplicar_configuracao_visual_rede()


func _instanciar_jogador_rede(dados: Variant) -> Node:
	if not dados is Dictionary:
		return null
	var id := int(dados.get("peer_id", 0))
	if id <= 1:
		return null
	var novo := JOGADOR_CENA.instantiate() as Player
	novo.name = "Player_%d" % id
	novo.configurar_jogador_multiplayer(
		id,
		str(dados.get("nickname", "PILOTO")),
		Dictionary(dados.get("configuracao", {}))
	)
	novo.position = Vector2(dados.get("posicao_spawn", _posicao_inicial_peer(id)))
	novo.set_multiplayer_authority(id, true)
	jogadores_rede[id] = novo
	call_deferred("_vincular_jogador_local")
	return novo


func replicar_disparo_player(dados: Dictionary) -> void:
	if not Rede.esta_conectado():
		return
	if multiplayer.is_server():
		_enviar_disparo_visual_para_outros(dados, 1)
	else:
		_encaminhar_disparo_visual.rpc_id(1, dados)


@rpc("any_peer", "call_remote", "reliable")
func _encaminhar_disparo_visual(dados: Dictionary) -> void:
	if not multiplayer.is_server():
		return
	var remetente := multiplayer.get_remote_sender_id()
	if remetente <= 1 or not Rede.jogadores.has(remetente):
		return
	dados["peer_id"] = remetente
	_criar_disparo_visual_rede(dados)
	_enviar_disparo_visual_para_outros(dados, remetente)


func _enviar_disparo_visual_para_outros(dados: Dictionary, remetente: int) -> void:
	for chave in Rede.jogadores:
		var id := int(chave)
		if id != 1 and id != remetente:
			_receber_disparo_visual.rpc_id(id, dados)


@rpc("authority", "call_remote", "reliable")
func _receber_disparo_visual(dados: Dictionary) -> void:
	_criar_disparo_visual_rede(dados)


func _criar_disparo_visual_rede(dados: Dictionary) -> void:
	var caminho := str(dados.get("cena", "res://Entities/fireball.tscn"))
	if caminho != "res://Entities/fireball.tscn":
		return
	var id_disparo := str(dados.get("id_disparo", ""))
	if id_disparo.is_empty() or is_instance_valid(_obter_disparo_visual(id_disparo)):
		return
	var cena := load(caminho) as PackedScene
	if not cena:
		return
	var projetil := cena.instantiate() as Area2D
	projetil.name = "TiroVisual_%s" % id_disparo.replace(":", "_")
	projetil.set_meta("apenas_visual_rede", true)
	projetil.set_meta("id_disparo_rede", id_disparo)
	projetil.collision_layer = 0
	projetil.collision_mask = 0
	projetil.monitoring = false
	projetil.monitorable = false
	add_child(projetil, true)
	disparos_visuais_rede[id_disparo] = projetil
	projetil.tree_exiting.connect(_remover_referencia_disparo.bind(id_disparo))
	projetil.global_position = Vector2(dados.get("posicao", Vector2.ZERO))
	projetil.global_rotation = float(dados.get("rotacao", 0.0))
	projetil.scale = Vector2(dados.get("escala", Vector2.ONE))
	projetil.set("velocidade", clampf(float(dados.get("velocidade", 1000.0)), 0.0, 2400.0))
	projetil.set("tempo_vida", clampf(float(dados.get("tempo_vida", 5.0)), 0.05, 15.0))
	projetil.set("eh_fragmento", bool(dados.get("fragmento", false)))
	projetil.set("eh_critico", bool(dados.get("critico", false)))
	projetil.set("dono_player", _obter_jogador_rede(int(dados.get("peer_id", 0))))
	if bool(dados.get("fragmento", false)):
		var visual_fragmento := projetil.get_node_or_null("Polygon2D") as Polygon2D
		var luz_fragmento := projetil.get_node_or_null("PointLight2D") as PointLight2D
		if is_instance_valid(visual_fragmento):
			visual_fragmento.color = Color(0.92, 0.20, 1.0, 1.0)
		if is_instance_valid(luz_fragmento):
			luz_fragmento.color = Color(0.95, 0.30, 1.0, 1.0)
	var estilo := StringName(str(dados.get("estilo", "")))
	var cor := Color(dados.get("cor", Color.WHITE))
	var config_variant: Variant = dados.get("config", {})
	var config: Dictionary = config_variant if config_variant is Dictionary else {}
	if not estilo.is_empty() and projetil.has_method("configurar_estilo_monthly"):
		projetil.call("configurar_estilo_monthly", estilo, cor, config)
	if projetil.has_method("configurar_id_disparo_rede"):
		projetil.call("configurar_id_disparo_rede", id_disparo, true)


func replicar_estado_disparo(dados: Dictionary) -> void:
	if not Rede.esta_conectado():
		return
	if multiplayer.is_server():
		_enviar_estado_disparo_para_outros(dados, 1)
	else:
		_encaminhar_estado_disparo.rpc_id(1, dados)


@rpc("any_peer", "call_remote", "unreliable_ordered", 2)
func _encaminhar_estado_disparo(dados: Dictionary) -> void:
	if not multiplayer.is_server():
		return
	var remetente := multiplayer.get_remote_sender_id()
	if remetente <= 1 or not Rede.jogadores.has(remetente):
		return
	dados["peer_id"] = remetente
	_aplicar_estado_disparo_visual(dados)
	_enviar_estado_disparo_para_outros(dados, remetente)


func _enviar_estado_disparo_para_outros(dados: Dictionary, remetente: int) -> void:
	for chave in Rede.jogadores:
		var id := int(chave)
		if id != 1 and id != remetente:
			_receber_estado_disparo.rpc_id(id, dados)


@rpc("authority", "call_remote", "unreliable_ordered", 2)
func _receber_estado_disparo(dados: Dictionary) -> void:
	_aplicar_estado_disparo_visual(dados)


func _aplicar_estado_disparo_visual(dados: Dictionary) -> void:
	var id_disparo := str(dados.get("id_disparo", ""))
	var projetil := _obter_disparo_visual(id_disparo)
	if not is_instance_valid(projetil):
		return
	if projetil.has_method("aplicar_estado_visual_rede"):
		projetil.call(
			"aplicar_estado_visual_rede",
			Vector2(dados.get("posicao", projetil.global_position)),
			float(dados.get("rotacao", projetil.global_rotation)),
			Vector2(dados.get("escala", projetil.scale)),
			bool(dados.get("visivel", projetil.visible)),
			Color(dados.get("cor", Color.TRANSPARENT))
		)


func finalizar_disparo_rede(id_disparo: String) -> void:
	if id_disparo.is_empty() or not Rede.esta_conectado():
		return
	var dados := {"id_disparo": id_disparo}
	if multiplayer.is_server():
		_enviar_fim_disparo_para_outros(dados, 1)
	else:
		_encaminhar_fim_disparo.rpc_id(1, dados)


@rpc("any_peer", "call_remote", "reliable")
func _encaminhar_fim_disparo(dados: Dictionary) -> void:
	if not multiplayer.is_server():
		return
	var remetente := multiplayer.get_remote_sender_id()
	if remetente <= 1 or not Rede.jogadores.has(remetente):
		return
	_finalizar_disparo_visual(str(dados.get("id_disparo", "")))
	_enviar_fim_disparo_para_outros(dados, remetente)


func _enviar_fim_disparo_para_outros(dados: Dictionary, remetente: int) -> void:
	for chave in Rede.jogadores:
		var id := int(chave)
		if id != 1 and id != remetente:
			_receber_fim_disparo.rpc_id(id, dados)


@rpc("authority", "call_remote", "reliable")
func _receber_fim_disparo(dados: Dictionary) -> void:
	_finalizar_disparo_visual(str(dados.get("id_disparo", "")))


func _finalizar_disparo_visual(id_disparo: String) -> void:
	var candidato: Variant = disparos_visuais_rede.get(id_disparo)
	disparos_visuais_rede.erase(id_disparo)
	if is_instance_valid(candidato) and candidato is Node:
		var projetil := candidato as Node
		projetil.queue_free()


func _obter_disparo_visual(id_disparo: String) -> Node2D:
	var candidato: Variant = disparos_visuais_rede.get(id_disparo)
	if not is_instance_valid(candidato) or not candidato is Node2D:
		disparos_visuais_rede.erase(id_disparo)
		return null
	return candidato as Node2D


func _remover_referencia_disparo(id_disparo: String) -> void:
	disparos_visuais_rede.erase(id_disparo)


func _obter_jogador_rede(id: int) -> Player:
	var candidato: Variant = jogadores_rede.get(id)
	if not is_instance_valid(candidato) or not candidato is Player:
		jogadores_rede.erase(id)
		return null
	return candidato as Player


func replicar_habilidade_player(dados: Dictionary) -> void:
	if not Rede.esta_conectado():
		return
	if multiplayer.is_server():
		_enviar_habilidade_visual_para_outros(dados, 1)
	else:
		_encaminhar_habilidade_visual.rpc_id(1, dados)


@rpc("any_peer", "call_remote", "reliable")
func _encaminhar_habilidade_visual(dados: Dictionary) -> void:
	if not multiplayer.is_server():
		return
	var remetente := multiplayer.get_remote_sender_id()
	if remetente <= 1 or not Rede.jogadores.has(remetente):
		return
	dados["peer_id"] = remetente
	_criar_habilidade_visual_rede(dados)
	_enviar_habilidade_visual_para_outros(dados, remetente)


func _enviar_habilidade_visual_para_outros(dados: Dictionary, remetente: int) -> void:
	for chave in Rede.jogadores:
		var id := int(chave)
		if id != 1 and id != remetente:
			_receber_habilidade_visual.rpc_id(id, dados)


@rpc("authority", "call_remote", "reliable")
func _receber_habilidade_visual(dados: Dictionary) -> void:
	_criar_habilidade_visual_rede(dados)


func _criar_habilidade_visual_rede(dados: Dictionary) -> void:
	var id := int(dados.get("peer_id", 0))
	var alvo := _obter_jogador_rede(id)
	if not is_instance_valid(alvo):
		return
	var cor := Color(dados.get("cor", Color(0.55, 0.92, 1.0)))
	if bool(dados.get("monthly", false)):
		var config_variant: Variant = dados.get("config", {})
		var config: Dictionary = config_variant if config_variant is Dictionary else {}
		EfeitoMonthlyRedeCena.criar_visual_rede(
			self, alvo, StringName(str(dados.get("efeito_id", ""))), cor,
			clampf(float(dados.get("potencia", 1.0)), 0.25, 3.0), config
		)
	else:
		EfeitoHabilidadeRedeCena.criar(
			self, alvo, StringName(str(dados.get("habilidade_id", ""))),
			cor, str(dados.get("icone", "")), 1.0
		)
	ExplosaoMonthlyCena.criar(self, alvo.global_position, cor, 0.82, &"", -1, false)


func replicar_loadout_player(configuracao: Dictionary) -> void:
	if not Rede.esta_conectado():
		return
	var dados := {
		"peer_id": Rede.peer_local(),
		"configuracao": configuracao.duplicate(true),
	}
	if multiplayer.is_server():
		_enviar_loadout_para_outros(dados, 1)
	else:
		_encaminhar_loadout.rpc_id(1, dados)


@rpc("any_peer", "call_remote", "reliable")
func _encaminhar_loadout(dados: Dictionary) -> void:
	if not multiplayer.is_server():
		return
	var remetente := multiplayer.get_remote_sender_id()
	if remetente <= 1 or not Rede.jogadores.has(remetente):
		return
	dados["peer_id"] = remetente
	_aplicar_loadout_rede(dados)
	_enviar_loadout_para_outros(dados, remetente)


func _enviar_loadout_para_outros(dados: Dictionary, remetente: int) -> void:
	for chave in Rede.jogadores:
		var id := int(chave)
		if id != 1 and id != remetente:
			_receber_loadout.rpc_id(id, dados)


@rpc("authority", "call_remote", "reliable")
func _receber_loadout(dados: Dictionary) -> void:
	_aplicar_loadout_rede(dados)


func _aplicar_loadout_rede(dados: Dictionary) -> void:
	var id := int(dados.get("peer_id", 0))
	if id == Rede.peer_local():
		return
	var alvo := _obter_jogador_rede(id)
	var configuracao_variant: Variant = dados.get("configuracao", {})
	if is_instance_valid(alvo) and configuracao_variant is Dictionary:
		alvo.aplicar_estado_loadout_rede(configuracao_variant)


func replicar_feedback_visual(dados: Dictionary) -> void:
	if not Rede.esta_conectado():
		return
	if multiplayer.is_server():
		_enviar_feedback_para_outros(dados, 1)
	else:
		_encaminhar_feedback_visual.rpc_id(1, dados)


@rpc("any_peer", "call_remote", "reliable")
func _encaminhar_feedback_visual(dados: Dictionary) -> void:
	if not multiplayer.is_server():
		return
	var remetente := multiplayer.get_remote_sender_id()
	if remetente <= 1 or not Rede.jogadores.has(remetente):
		return
	_criar_feedback_visual_rede(dados)
	_enviar_feedback_para_outros(dados, remetente)


func _enviar_feedback_para_outros(dados: Dictionary, remetente: int) -> void:
	for chave in Rede.jogadores:
		var id := int(chave)
		if id != 1 and id != remetente:
			_receber_feedback_visual.rpc_id(id, dados)


@rpc("authority", "call_remote", "reliable")
func _receber_feedback_visual(dados: Dictionary) -> void:
	_criar_feedback_visual_rede(dados)


func _criar_feedback_visual_rede(dados: Dictionary) -> void:
	var classe := StringName(str(dados.get("classe", "")))
	var posicao := Vector2(dados.get("posicao", Vector2.ZERO))
	var cor := Color(dados.get("cor", Color.WHITE))
	var semente := int(dados.get("semente", 1))
	match classe:
		&"hitflash_inimigo":
			var caminho_alvo := NodePath(str(dados.get("alvo", "")))
			var alvo := get_node_or_null(caminho_alvo) as InimigoBase
			if is_instance_valid(alvo) and not alvo.is_queued_for_deletion():
				alvo.set_meta("hitflash_rede_recebido", true)
				alvo.reproduzir_hitflash_rede()
		&"efeito_combate":
			var tipo_efeito := clampi(int(dados.get("tipo", 0)), 0, EfeitoCombate.Tipo.size() - 1)
			var intensidade := clampf(float(dados.get("intensidade", 1.0)), 0.2, 4.0)
			var efeito := EfeitoCombateRedeCena.criar(
				self, posicao,
				tipo_efeito, cor, intensidade,
				Vector2(dados.get("direcao", Vector2.RIGHT)), semente, false
			)
			if is_instance_valid(efeito):
				efeito.set_meta("efeito_visual_rede", true)
			if tipo_efeito in [EfeitoCombate.Tipo.MORTE, EfeitoCombate.Tipo.DANO_PLAYER]:
				var camera := get_tree().get_first_node_in_group("camera") as Camera2D
				if is_instance_valid(camera) and camera.has_method("shake"):
					camera.shake(2.5 + intensidade * 1.5)
		&"monthly_burst":
			var explosao := ExplosaoMonthlyCena.criar(
				self, posicao, cor,
				clampf(float(dados.get("intensidade", 1.0)), 0.25, 4.0),
				StringName(str(dados.get("estilo", ""))), semente, false
			)
			if is_instance_valid(explosao):
				explosao.set_meta("efeito_visual_rede", true)
		&"indicador_dano":
			var indicador := IndicadorDanoRedeCena.criar(
				self, posicao, clampf(float(dados.get("dano", 0.0)), 0.0, 100000.0),
				cor, bool(dados.get("critico", false)), semente, false
			)
			if is_instance_valid(indicador):
				indicador.set_meta("efeito_visual_rede", true)
		&"particula_cena":
			var caminho := str(dados.get("cena", ""))
			if caminho not in [
				"res://FX/player_death_parts.tscn",
				"res://FX/ParticulasMorteInimigo.tscn",
			]:
				return
			var cena_particula := load(caminho) as PackedScene
			if not cena_particula:
				return
			var particula := cena_particula.instantiate() as Node2D
			if not particula:
				return
			add_child(particula)
			particula.global_position = posicao
			particula.global_rotation = float(dados.get("rotacao", 0.0))
			particula.modulate = cor
			particula.set_meta("efeito_visual_rede", true)
			if particula is GPUParticles2D:
				(particula as GPUParticles2D).emitting = true


func _vincular_jogador_local() -> void:
	if not Rede.modo_multiplayer:
		return
	var local := _obter_jogador_rede(Rede.peer_local())
	if not is_instance_valid(local):
		return
	player = local
	if $GUI.has_method("definir_player_local"):
		$GUI.definir_player_local(player)
	if tela_upgrades.has_method("definir_player_local"):
		tela_upgrades.definir_player_local(player)
	if is_instance_valid(controles_mobile):
		controles_mobile.configurar(self, player)
	_configurar_camera_local()
	player.call_deferred("atualizar_ui")


func _configurar_camera_local() -> void:
	var camera_local := get_node_or_null("Camera") as Camera2D
	if (
		Rede.modo_multiplayer
		and is_instance_valid(camera_local)
		and is_instance_valid(player)
		and camera_local.has_method("configurar_alvo")
	):
		var area_local := Global.calcular_retangulo_area_visivel(
			get_viewport().get_visible_rect().size
		)
		camera_local.call(
			"configurar_alvo", player, Global.obter_retangulo_area_visivel(),
			area_local.size
		)


func _on_jogador_rede_desconectado(id: int) -> void:
	if multiplayer.is_server():
		renascimentos_pendentes.erase(id)
	if multiplayer.is_server() and tamanhos_viewport_rede.has(id):
		tamanhos_viewport_rede.erase(id)
		_publicar_area_coop()
	if not jogadores_rede.has(id):
		return
	var remoto: Variant = jogadores_rede[id]
	var nome := "O OUTRO PILOTO"
	if is_instance_valid(remoto):
		nome = str((remoto as Node).get("nickname_rede"))
		(remoto as Node).queue_free()
	jogadores_rede.erase(id)
	_mostrar_aviso_rede("%s DESCONECTOU • A PARTIDA CONTINUA" % nome.to_upper(), false)


func _on_desconexao_detectada(mensagem: String, host_perdido: bool) -> void:
	_mostrar_aviso_rede(mensagem, true)
	if host_perdido:
		game_over = true
		painel_morte_local_exibido = true
		caixa_gameover.visible = true
		$"GUI/caixa gameover/Tentatdenovotext".text = "HOST DESCONECTADO"
		$"GUI/caixa gameover/Tentar de novo".visible = false
		$"GUI/caixa gameover/Voltarmenu2".text = "VOLTAR AO MENU"
		Global.definir_cursor_interface(true)


func _process(delta: float) -> void:
	_processar_combo(delta)
	if Rede.modo_multiplayer:
		_processar_posicoes_rede(delta)
		_processar_sincronizacao_area_coop(delta)
		_atualizar_hud_boss_cliente()
		_atualizar_estado_morte_multiplayer(delta)
	if game_over or escolha_setor_ativa:
		return
	atualizar_pontos(delta)
	if Rede.modo_multiplayer and not multiplayer.is_server():
		if not is_instance_valid(_obter_jogador_rede(Rede.peer_local())):
			tempo_nova_solicitacao_rede -= delta
			if tempo_nova_solicitacao_rede <= 0.0:
				_enviar_solicitacao_entrada()
		return
	if get_tree().get_nodes_in_group("player").is_empty():
		game_over = true
		Global.definir_cursor_interface(true)
		caixa_gameover.visible = true
		return
	if tutorial_ativo:
		return
	if spawns_pausados_desenvolvedor:
		return

	processar_asteroides(delta)
	if deve_invocar_boss():
		invocar_boss_do_setor()
		return
	if is_instance_valid(boss_ativo):
		return

	garantir_minimo_inimigos()

	timer -= delta
	if timer <= 0.0:
		spawnar_enemy()
		timer = calcular_tempo_spawn()


func _processar_posicoes_rede(delta: float) -> void:
	if not Rede.esta_conectado():
		return
	tempo_posicoes_rede -= delta
	if tempo_posicoes_rede > 0.0:
		return
	tempo_posicoes_rede = INTERVALO_POSICOES_REDE
	if multiplayer.is_server():
		_publicar_posicoes_mundo.rpc(_capturar_posicoes_mundo())
		return
	var jogador_local := _obter_jogador_rede(Rede.peer_local()) as Player
	if is_instance_valid(jogador_local):
		_receber_posicao_player.rpc_id(
			1, jogador_local.global_position, jogador_local.rotation,
			jogador_local.velocity
		)


@rpc("any_peer", "call_remote", "unreliable_ordered", 0)
func _receber_posicao_player(
	posicao: Vector2, rotacao: float, velocidade: Vector2
) -> void:
	if not multiplayer.is_server():
		return
	var remetente := multiplayer.get_remote_sender_id()
	var jogador_remoto := _obter_jogador_rede(remetente) as Player
	if not is_instance_valid(jogador_remoto):
		return
	jogador_remoto.global_position = posicao
	jogador_remoto.rotation = rotacao
	jogador_remoto.velocity = velocidade


func _capturar_posicoes_mundo() -> Dictionary:
	var posicoes_players: Dictionary = {}
	for candidato in get_tree().get_nodes_in_group("player"):
		if candidato is Player and is_instance_valid(candidato):
			var jogador := candidato as Player
			posicoes_players[jogador.peer_id_dono] = {
				"posicao": jogador.global_position,
				"rotacao": jogador.rotation,
				"velocidade": jogador.velocity,
			}
	var posicoes_inimigos: Array[Dictionary] = []
	for candidato in get_tree().get_nodes_in_group("inimigo"):
		if candidato is Node2D and is_ancestor_of(candidato):
			var inimigo := candidato as Node2D
			var velocidade_inimigo := Vector2.ZERO
			if inimigo is CharacterBody2D:
				velocidade_inimigo = (inimigo as CharacterBody2D).velocity
			posicoes_inimigos.append({
				"caminho": get_path_to(inimigo),
				"posicao": inimigo.global_position,
				"rotacao": inimigo.rotation,
				"velocidade": velocidade_inimigo,
			})
	return {
		"players": posicoes_players,
		"inimigos": posicoes_inimigos,
		"cristais_coop": cristais_coop_acumulados,
	}


@rpc("authority", "call_remote", "unreliable_ordered", 0)
func _publicar_posicoes_mundo(snapshot: Dictionary) -> void:
	if multiplayer.is_server():
		return
	_aplicar_total_cristais_coop(int(snapshot.get("cristais_coop", 0)))
	var posicoes_players: Dictionary = snapshot.get("players", {})
	for peer_variant in posicoes_players:
		var peer_id := int(peer_variant)
		# A nave local continua responsiva e é a fonte autoritativa enviada ao host.
		if peer_id == Rede.peer_local():
			continue
		var jogador := _obter_jogador_rede(peer_id) as Player
		if not is_instance_valid(jogador):
			continue
		var estado: Dictionary = posicoes_players[peer_variant]
		jogador.global_position = estado.get("posicao", jogador.global_position)
		jogador.rotation = float(estado.get("rotacao", jogador.rotation))
		jogador.velocity = estado.get("velocidade", jogador.velocity)
	for estado_variant in Array(snapshot.get("inimigos", [])):
		var estado := Dictionary(estado_variant)
		var inimigo := get_node_or_null(
			NodePath(str(estado.get("caminho", "")))
		) as Node2D
		if not is_instance_valid(inimigo):
			continue
		inimigo.global_position = estado.get("posicao", inimigo.global_position)
		inimigo.rotation = float(estado.get("rotacao", inimigo.rotation))
		if inimigo is CharacterBody2D:
			(inimigo as CharacterBody2D).velocity = Vector2(
				estado.get("velocidade", (inimigo as CharacterBody2D).velocity)
			)


func _atualizar_hud_boss_cliente() -> void:
	if not Rede.modo_multiplayer or multiplayer.is_server():
		return
	var encontrado: InimigoBase
	for candidato in get_tree().get_nodes_in_group("boss"):
		if candidato is InimigoBase and is_instance_valid(candidato) and not candidato.is_queued_for_deletion():
			encontrado = candidato as InimigoBase
			break
	if not is_instance_valid(encontrado):
		boss_ativo = null
		if is_instance_valid(boss_hud):
			boss_hud.queue_free()
		boss_hud = null
		return
	if boss_ativo != encontrado or not is_instance_valid(boss_hud):
		boss_ativo = encontrado
		boss_atual_id = _identificar_boss_rede(encontrado)
		setor_atual = _identificar_setor_do_boss(boss_atual_id)
		criar_hud_boss()
		_on_boss_fase_alterada((encontrado as BossMensal).fase if encontrado is BossMensal else 1)
		if encontrado.has_method("obter_subtitulo_boss"):
			_on_boss_subtitulo_alterado(str(encontrado.call("obter_subtitulo_boss")))
	var fase_rede := 1
	if encontrado._possui_propriedade_rede(&"fase"):
		fase_rede = int(encontrado.get("fase"))
	elif encontrado._possui_propriedade_rede(&"fase_atual"):
		fase_rede = int(encontrado.get("fase_atual")) + 1
	_on_boss_fase_alterada(fase_rede)
	if encontrado.has_method("obter_subtitulo_boss"):
		_on_boss_subtitulo_alterado(str(encontrado.call("obter_subtitulo_boss")))
	_on_boss_vida_alterada(encontrado.Vida, maxf(encontrado.VidaMaxima, encontrado.Vida))


func _identificar_boss_rede(alvo: InimigoBase) -> StringName:
	for id in BOSSES:
		var cena := BOSSES[id] as PackedScene
		if is_instance_valid(cena) and cena.resource_path == alvo.scene_file_path:
			return StringName(id)
	return &"pet0"


func _identificar_setor_do_boss(id_boss: StringName) -> StringName:
	for id_setor in DadosSetores.DADOS:
		if StringName(DadosSetores.DADOS[id_setor].get("boss", &"")) == id_boss:
			return StringName(id_setor)
	return setor_atual


func _processar_combo(delta: float) -> void:
	if Rede.modo_multiplayer and not multiplayer.is_server():
		return
	if Global.Combo != combo_observado:
		if Global.Combo > combo_observado:
			tempo_combo_restante = DURACAO_COMBO
		combo_observado = maxi(Global.Combo, 0)
		if combo_observado == 0:
			tempo_combo_restante = 0.0
		_publicar_combo_rede()
	if combo_observado <= 0:
		return
	tempo_combo_restante = maxf(tempo_combo_restante - delta, 0.0)
	if tempo_combo_restante <= 0.0:
		Global.Combo = 0
		combo_observado = 0
		_publicar_combo_rede()


func _publicar_combo_rede() -> void:
	if Rede.esta_conectado() and multiplayer.is_server():
		_receber_combo_rede.rpc(Global.Combo, tempo_combo_restante)


@rpc("authority", "call_remote", "reliable")
func _receber_combo_rede(valor: int, restante: float) -> void:
	Global.Combo = maxi(valor, 0)
	combo_observado = Global.Combo
	tempo_combo_restante = clampf(restante, 0.0, DURACAO_COMBO)


func _on_player_morreu(jogador: Player) -> void:
	if not Rede.modo_multiplayer or jogador.peer_id_dono != Rede.peer_local():
		return
	_mostrar_painel_morte_local()
	if multiplayer.is_server():
		_iniciar_espera_renascimento(jogador.peer_id_dono)
	else:
		_notificar_morte_ao_host.rpc_id(1)


@rpc("any_peer", "call_remote", "reliable")
func _notificar_morte_ao_host() -> void:
	if not multiplayer.is_server():
		return
	var remetente := multiplayer.get_remote_sender_id()
	if remetente <= 1 or not jogadores_rede.has(remetente):
		return
	var jogador := _obter_jogador_rede(remetente)
	if is_instance_valid(jogador):
		jogador.vivo = false
		jogador.vida = 0.0
		jogador.visible = false
	_iniciar_espera_renascimento(remetente)


func _iniciar_espera_renascimento(peer_id: int) -> void:
	if not multiplayer.is_server() or game_over or renascimentos_pendentes.has(peer_id):
		return
	renascimentos_pendentes[peer_id] = TEMPO_RENASCIMENTO_COOP
	if peer_id == Rede.peer_local():
		_iniciar_contagem_renascimento_local(TEMPO_RENASCIMENTO_COOP)
	else:
		_iniciar_contagem_renascimento_local.rpc_id(
			peer_id, TEMPO_RENASCIMENTO_COOP
		)


@rpc("authority", "call_remote", "reliable")
func _iniciar_contagem_renascimento_local(duracao: float) -> void:
	aguardando_renascimento_local = true
	tempo_renascimento_local = maxf(duracao, 0.0)
	_mostrar_painel_morte_local()
	_atualizar_texto_renascimento_local()


func _atualizar_estado_morte_multiplayer(delta: float) -> void:
	_atualizar_contagem_renascimento_local(delta)
	if is_instance_valid(player) and not player.vivo and not painel_morte_local_exibido:
		_mostrar_painel_morte_local()
	if not multiplayer.is_server():
		return

	var vivos := _quantidade_jogadores_vivos()
	if vivos == 0:
		if not game_over:
			game_over = true
			renascimentos_pendentes.clear()
			_encerrar_renascimentos_sem_sobreviventes.rpc()
		return
	if game_over:
		return

	for peer_variant in renascimentos_pendentes.keys():
		var peer_id := int(peer_variant)
		var jogador_morto := _obter_jogador_rede(peer_id)
		if not is_instance_valid(jogador_morto):
			renascimentos_pendentes.erase(peer_id)
			continue
		if jogador_morto.vivo:
			renascimentos_pendentes.erase(peer_id)
			continue
		var restante := maxf(
			float(renascimentos_pendentes.get(peer_id, 0.0)) - delta, 0.0
		)
		renascimentos_pendentes[peer_id] = restante
		if restante <= 0.0:
			renascimentos_pendentes.erase(peer_id)
			_reviver_peer(peer_id)


func _quantidade_jogadores_vivos() -> int:
	var vivos := 0
	for candidato in get_tree().get_nodes_in_group("player"):
		if candidato is Player and candidato.vivo and candidato.visible:
			vivos += 1
	return vivos


func _atualizar_contagem_renascimento_local(delta: float) -> void:
	if not aguardando_renascimento_local:
		return
	tempo_renascimento_local = maxf(tempo_renascimento_local - delta, 0.0)
	_atualizar_texto_renascimento_local()


func _atualizar_texto_renascimento_local() -> void:
	if not is_instance_valid(texto_aguardando_morte):
		return
	var vivos := _quantidade_jogadores_vivos()
	texto_aguardando_morte.text = (
		"RENASCIMENTO EM %.1f s  •  %d PILOTO(S) AINDA EM COMBATE"
		% [tempo_renascimento_local, vivos]
	)


func _reviver_peer(peer_id: int) -> void:
	if not multiplayer.is_server() or _quantidade_jogadores_vivos() <= 0:
		return
	var posicao_retorno := _posicao_inicial_peer(peer_id)
	if peer_id == Rede.peer_local():
		_executar_renascimento(posicao_retorno)
	else:
		_executar_renascimento.rpc_id(peer_id, posicao_retorno)


@rpc("authority", "call_remote", "reliable")
func _executar_renascimento(posicao_retorno: Vector2) -> void:
	var jogador_local := _obter_jogador_rede(Rede.peer_local()) as Player
	if not is_instance_valid(jogador_local):
		return
	jogador_local.reviver_multiplayer(posicao_retorno)
	aguardando_renascimento_local = false
	tempo_renascimento_local = 0.0
	painel_morte_local_exibido = false
	caixa_gameover.visible = false
	Global.definir_cursor_interface(false)


@rpc("authority", "call_local", "reliable")
func _encerrar_renascimentos_sem_sobreviventes() -> void:
	game_over = true
	aguardando_renascimento_local = false
	tempo_renascimento_local = 0.0
	caixa_gameover.visible = true
	$"GUI/caixa gameover/Tentatdenovotext".text = "TODA A EQUIPE FOI DESTRUÍDA"
	var botao_reiniciar := $"GUI/caixa gameover/Tentar de novo" as Button
	botao_reiniciar.visible = multiplayer.is_server()
	botao_reiniciar.text = "REINICIAR PARTIDA"
	$"GUI/caixa gameover/Voltarmenu2".text = "SAIR DA PARTIDA"
	if is_instance_valid(texto_aguardando_morte):
		texto_aguardando_morte.text = "NÃO HÁ PILOTOS VIVOS PARA GARANTIR O RENASCIMENTO"
	Global.definir_cursor_interface(true)


func _mostrar_painel_morte_local() -> void:
	painel_morte_local_exibido = true
	caixa_gameover.visible = true
	$"GUI/caixa gameover/Tentatdenovotext".text = "SUA NAVE FOI DESTRUÍDA"
	var botao_reiniciar := $"GUI/caixa gameover/Tentar de novo" as Button
	botao_reiniciar.visible = multiplayer.is_server()
	botao_reiniciar.text = "REINICIAR PARTIDA"
	$"GUI/caixa gameover/Voltarmenu2".text = "SAIR DA PARTIDA"
	if not is_instance_valid(texto_aguardando_morte):
		texto_aguardando_morte = Label.new()
		texto_aguardando_morte.name = "AguardandoOutroPiloto"
		texto_aguardando_morte.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		texto_aguardando_morte.add_theme_font_size_override("font_size", 15)
		texto_aguardando_morte.add_theme_color_override(
			"font_color", Color(0.55, 0.9, 1.0)
		)
		caixa_gameover.add_child(texto_aguardando_morte)
		caixa_gameover.move_child(texto_aguardando_morte, 1)
	if aguardando_renascimento_local:
		_atualizar_texto_renascimento_local()
	else:
		texto_aguardando_morte.text = "AGUARDANDO AUTORIZAÇÃO DE RENASCIMENTO DO HOST"
	Global.definir_cursor_interface(true)


func solicitar_reinicio_multiplayer() -> void:
	if not Rede.modo_multiplayer:
		get_tree().reload_current_scene()
		return
	if not multiplayer.is_server():
		_mostrar_aviso_rede("APENAS O HOST PODE REINICIAR A PARTIDA", false)
		return
	_reiniciar_partida_rede.rpc()


@rpc("authority", "call_local", "reliable")
func _reiniciar_partida_rede() -> void:
	preservar_conexao_ao_sair = true
	get_tree().paused = false
	Engine.time_scale = 1.0
	Global.Pontos = 0
	Global.Combo = 0
	get_tree().call_deferred("change_scene_to_file", "res://Rooms/Battle_area.tscn")


func _criar_aviso_rede() -> void:
	aviso_rede = Label.new()
	aviso_rede.name = "AvisoRede"
	aviso_rede.z_index = 80
	aviso_rede.visible = false
	aviso_rede.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	aviso_rede.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	aviso_rede.add_theme_font_size_override("font_size", 17)
	aviso_rede.add_theme_color_override("font_color", Color.WHITE)
	var fundo := StyleBoxFlat.new()
	fundo.bg_color = Color(0.05, 0.015, 0.08, 0.94)
	fundo.border_color = Color(1.0, 0.26, 0.48, 0.9)
	fundo.set_border_width_all(2)
	fundo.set_corner_radius_all(9)
	aviso_rede.add_theme_stylebox_override("normal", fundo)
	$GUI.add_child(aviso_rede)
	aviso_rede.set_anchors_preset(Control.PRESET_CENTER_TOP)
	aviso_rede.position = Vector2((float(get_window().size.x) / 2.0) - 520.0 / 2.0, 24.0)
	aviso_rede.size = Vector2(520.0, 48.0)


func _mostrar_aviso_rede(mensagem: String, persistente: bool) -> void:
	if not is_instance_valid(aviso_rede):
		return
	aviso_rede.text = mensagem
	aviso_rede.visible = true
	if persistente:
		return
	var token := Time.get_ticks_msec()
	aviso_rede.set_meta("token_aviso", token)
	_ocultar_aviso_rede_depois(token)


func _ocultar_aviso_rede_depois(token: int) -> void:
	await get_tree().create_timer(4.0).timeout
	if is_instance_valid(aviso_rede) and int(aviso_rede.get_meta("token_aviso", -1)) == token:
		aviso_rede.visible = false


func atualizar_pontos(delta: float) -> void:
	var pontos_alvo: float = Global.Pontos
	if pontos < pontos_alvo:
		pontos = move_toward(
			pontos,
			pontos_alvo,
			20.0 * maxi(Global.Combo, 1) * delta
		)
	contpontos.text = str(int(pontos)).pad_zeros(8)


func finalizar_tutorial() -> void:
	if not tutorial_ativo:
		return
	tutorial_ativo = false
	timer = TIMER_MAX
	print("BATTLE AREA: TUTORIAL TERMINOU")


func calcular_tempo_spawn() -> float:
	if not is_instance_valid(player):
		return TIMER_MAX
	var reducao := floori(maxi(player.nivel_atual - 1, 0) / 3.0) * 0.12
	return clampf(TIMER_MAX - reducao, TIMER_MIN, TIMER_MAX)


func spawnar_enemy() -> void:
	if tutorial_ativo or not is_instance_valid(player) or is_instance_valid(boss_ativo):
		return
	var spawners := get_tree().get_nodes_in_group("spawners")
	if spawners.is_empty():
		return
	if contar_inimigos_regulares() >= calcular_limite_inimigos():
		return

	var cena_escolhida := escolher_tipo_inimigo(player.nivel_atual)
	var inimigo := cena_escolhida.instantiate() as Node2D
	var spawner := spawners.pick_random() as Node2D
	if not is_instance_valid(inimigo) or not is_instance_valid(spawner):
		if is_instance_valid(inimigo):
			inimigo.queue_free()
		return
	# A posição precisa fazer parte do estado inicial recebido pelo
	# MultiplayerSpawner. Alterá-la depois de add_child fazia clientes exibirem
	# o inimigo por um frame na origem e podia divergir sob latência.
	inimigo.position = spawner.global_position
	add_child(inimigo, true)


func contar_inimigos_regulares() -> int:
	var quantidade := 0
	for inimigo in get_tree().get_nodes_in_group("inimigo"):
		if not is_instance_valid(inimigo):
			continue
		if inimigo.is_queued_for_deletion():
			continue
		if inimigo.is_in_group("boss") or inimigo.is_in_group("asteroide_bonus"):
			continue
		quantidade += 1
	return quantidade


func garantir_minimo_inimigos() -> void:
	var faltantes := MIN_ENEMIES - contar_inimigos_regulares()
	for _indice in range(maxi(faltantes, 0)):
		spawnar_enemy()
	if faltantes > 0:
		timer = maxf(timer, 0.45)


func escolher_tipo_inimigo(nivel: int) -> PackedScene:
	# O setor inicial ensina uma ameaça por vez. Inimigos simples aparecem em
	# maior frequência para a primeira evolução chegar cedo sem lotar a arena.
	if setor_atual == &"vazio_inicial":
		var opcoes_originais: Array[PackedScene] = [
			INIMIGOS[&"seguidor"],
			INIMIGOS[&"seguidor"],
			INIMIGOS[&"seguidor"]
		]
		if nivel >= 3:
			opcoes_originais.append(INIMIGOS[&"seguidor"])
			opcoes_originais.append(INIMIGOS[&"melee"])
			opcoes_originais.append(INIMIGOS[&"melee"])
		if nivel >= 5:
			opcoes_originais.append(INIMIGOS[&"investida"])
		if nivel >= 6:
			opcoes_originais.append(INIMIGOS[&"atirador"])
		if nivel >= 7:
			opcoes_originais.append(INIMIGOS[&"tanque"])
		if nivel >= 8:
			opcoes_originais.append(INIMIGOS[&"atirador"])
			opcoes_originais.append(INIMIGOS[&"investida"])
		return opcoes_originais.pick_random()

	var composicao: Array = DadosSetores.obter(setor_atual).get("inimigos", [])
	if composicao.is_empty():
		return INIMIGOS[&"seguidor"]
	var peso_total := 0.0
	for entrada in composicao:
		peso_total += float(entrada[1])
	var alvo := randf() * peso_total
	for entrada in composicao:
		alvo -= float(entrada[1])
		if alvo <= 0.0:
			return INIMIGOS.get(StringName(entrada[0]), INIMIGOS[&"seguidor"])
	return INIMIGOS[&"seguidor"]


func calcular_limite_inimigos() -> int:
	if not is_instance_valid(player):
		return MAX_ENEMIES_BASE
	var limite := MAX_ENEMIES_BASE + floori(maxi(player.nivel_atual - 1, 0) / 4.0)
	return clampi(limite, MIN_ENEMIES, MAX_ENEMIES)


func processar_asteroides(delta: float) -> void:
	tempo_asteroide -= delta
	if tempo_asteroide > 0.0:
		return
	tempo_asteroide = randf_range(intervalo_asteroide_min, intervalo_asteroide_max)
	if max_asteroides <= 0 or randf() > chance_asteroide:
		return
	if get_tree().get_nodes_in_group("asteroide_bonus").size() < max_asteroides:
		spawnar_asteroide_bonus()


func spawnar_asteroide_bonus() -> void:
	if not is_instance_valid(player):
		return
	var spawners := get_tree().get_nodes_in_group("spawners")
	if spawners.is_empty():
		return
	var spawner := spawners.pick_random() as Node2D
	var asteroide := ASTEROIDE_BONUS.instantiate() as InimigoBase
	if not is_instance_valid(asteroide) or not is_instance_valid(spawner):
		return
	add_child(asteroide, true)
	asteroide.global_position = spawner.global_position
	if asteroide.has_method("configurar_movimento"):
		var destino := Global.obter_centro_area_visivel() + Vector2(
			randf_range(-180.0, 180.0),
			randf_range(-110.0, 110.0)
		)
		asteroide.configurar_movimento(destino)


func deve_invocar_boss() -> bool:
	return (
		ativar_bosses
		and setor_atual not in setores_concluidos
		and is_instance_valid(player)
		and not is_instance_valid(boss_ativo)
		and player.nivel_atual >= proximo_nivel_boss
	)


func invocar_boss_do_setor() -> void:
	if is_instance_valid(boss_ativo) or setor_atual in setores_concluidos:
		return
	limpar_inimigos_sem_recompensa()
	var dados_setor := DadosSetores.obter(setor_atual)
	_criar_boss(
		StringName(dados_setor.get("boss", &"pet0")),
		setores_concluidos.size() + 1,
		false
	)


func invocar_boss_teste(id: StringName) -> void:
	if not Global.modo_desenvolvedor or not BOSSES.has(id):
		return
	limpar_arena_teste()
	_criar_boss(id, 1, true)


func _criar_boss(id: StringName, dificuldade: int, em_teste: bool) -> void:
	boss_atual_id = id
	boss_em_teste = em_teste
	var cena: PackedScene = BOSSES.get(boss_atual_id, BOSSES[&"pet0"])
	boss_ativo = cena.instantiate() as InimigoBase
	if not is_instance_valid(boss_ativo):
		boss_em_teste = false
		push_error("Não foi possível criar o boss %s." % boss_atual_id)
		return
	var area := Global.obter_retangulo_area_visivel(70.0)
	var posicao_boss := Vector2(
		lerpf(area.position.x, area.end.x, 0.78), area.get_center().y
	)
	if player.global_position.distance_to(posicao_boss) < 220.0:
		posicao_boss.x = lerpf(area.position.x, area.end.x, 0.22)
	# Configure o estado de spawn antes de inserir o boss na árvore, para que
	# todos os peers recebam a mesma posição inicial.
	boss_ativo.position = posicao_boss
	add_child(boss_ativo, true)
	if boss_ativo.has_method("configurar_dificuldade"):
		boss_ativo.call("configurar_dificuldade", dificuldade)
	# Flor do Equinócio e PET-0 mantêm exatamente o dano anterior.
	if boss_atual_id not in BOSSES_DANO_PRESERVADO:
		boss_ativo.Dano *= MULTIPLICADOR_DANO_BOSSES_AJUSTADOS
	aplicar_musica_boss(id)

	criar_hud_boss()
	boss_ativo.vida_alterada.connect(_on_boss_vida_alterada)
	if boss_ativo.has_signal("fase_alterada"):
		boss_ativo.connect("fase_alterada", _on_boss_fase_alterada)
	if boss_ativo.has_signal("subtitulo_alterado"):
		boss_ativo.connect("subtitulo_alterado", _on_boss_subtitulo_alterado)
	if boss_ativo.has_signal("reciclagem_alterada"):
		boss_ativo.connect("reciclagem_alterada", _on_boss_reciclagem_alterada)
	boss_ativo.morreu.connect(_on_boss_morreu)
	_on_boss_vida_alterada(boss_ativo.Vida, boss_ativo.obter_vida_maxima_atual())
	_on_boss_fase_alterada(1)
	if boss_ativo.has_method("obter_subtitulo_boss"):
		_on_boss_subtitulo_alterado(str(boss_ativo.call("obter_subtitulo_boss")))
	if boss_atual_id == &"pet0":
		var pet0 := boss_ativo as BossPet0
		_on_boss_reciclagem_alterada(pet0.reciclagem_atual, pet0.meta_reciclagem)


func limpar_inimigos_sem_recompensa() -> void:
	for inimigo in get_tree().get_nodes_in_group("inimigo"):
		if is_instance_valid(inimigo):
			inimigo.queue_free()
	for grupo in [&"projetil_inimigo", &"residuo_pet0", &"minion_pet0"]:
		for node in get_tree().get_nodes_in_group(grupo):
			if is_instance_valid(node):
				node.queue_free()


func limpar_arena_teste() -> void:
	if not Global.modo_desenvolvedor:
		return
	limpar_inimigos_sem_recompensa()
	boss_ativo = null
	boss_em_teste = false
	if is_instance_valid(boss_hud):
		boss_hud.queue_free()
	boss_hud = null
	timer = TIMER_MAX
	restaurar_musica_partida()


func aplicar_musica_boss(id: StringName) -> void:
	var caminho := CAMINHO_LOTUS_DANCE if id == &"flor_equinocio" else CAMINHO_BATALHA_BOSS
	var faixa: AudioStream = null
	if ResourceLoader.exists(caminho):
		faixa = load(caminho) as AudioStream
	if not is_instance_valid(faixa):
		faixa = musica_partida_padrao
	if not is_instance_valid(faixa):
		return
	if faixa is AudioStreamMP3:
		(faixa as AudioStreamMP3).loop = true
	elif faixa is AudioStreamOggVorbis:
		(faixa as AudioStreamOggVorbis).loop = true
	tocarmusica.stop()
	tocarmusica.stream = faixa
	tocarmusica.play()
	musica_boss_ativa = true


func restaurar_musica_partida() -> void:
	if not musica_boss_ativa or not is_instance_valid(tocarmusica):
		return
	tocarmusica.stop()
	tocarmusica.stream = musica_partida_padrao
	if is_instance_valid(musica_partida_padrao):
		tocarmusica.play()
	musica_boss_ativa = false


func alternar_spawns_teste() -> bool:
	if not Global.modo_desenvolvedor:
		return false
	spawns_pausados_desenvolvedor = not spawns_pausados_desenvolvedor
	return spawns_pausados_desenvolvedor


func spawns_teste_estao_pausados() -> bool:
	return spawns_pausados_desenvolvedor


func pode_abrir_painel_desenvolvedor() -> bool:
	return (
		Global.modo_desenvolvedor
		and not game_over
		and not tutorial_ativo
		and not escolha_setor_ativa
		and is_instance_valid(player)
		and player.vivo
		and player.vida > 0.0
		and not player.UsandoHabilidade
		and not (
			tela_upgrades.has_method("esta_aberta")
			and bool(tela_upgrades.call("esta_aberta"))
		)
	)


func criar_hud_boss() -> void:
	if is_instance_valid(boss_hud):
		boss_hud.queue_free()
	var dados_setor := DadosSetores.obter(setor_atual)
	var cor: Color = dados_setor.get("cor_destaque", Color.WHITE)
	boss_hud = VBoxContainer.new()
	boss_hud.name = "HUD_Boss"
	boss_hud.add_theme_constant_override("separation", 3)
	$GUI.add_child(boss_hud)
	boss_hud.anchor_left = 0.5
	boss_hud.anchor_right = 0.5
	boss_hud.offset_left = -220.0
	boss_hud.offset_top = 66.0
	boss_hud.offset_right = 220.0
	boss_hud.offset_bottom = 154.0
	boss_hud.visible = not (
		tela_upgrades.has_method("esta_aberta")
		and bool(tela_upgrades.call("esta_aberta"))
	)

	boss_nome = Label.new()
	boss_nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_nome.add_theme_color_override("font_color", cor)
	boss_nome.add_theme_font_size_override("font_size", 17)
	boss_hud.add_child(boss_nome)
	boss_vida = ProgressBar.new()
	boss_vida.custom_minimum_size = Vector2(440.0, 18.0)
	boss_vida.show_percentage = false
	boss_vida.modulate = cor
	boss_hud.add_child(boss_vida)
	boss_detalhe_texto = Label.new()
	boss_detalhe_texto.text = str(dados_setor.get("subtitulo", ""))
	boss_detalhe_texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_detalhe_texto.add_theme_font_size_override("font_size", 11)
	boss_hud.add_child(boss_detalhe_texto)
	boss_detalhe = ProgressBar.new()
	boss_detalhe.custom_minimum_size = Vector2(440.0, 10.0)
	boss_detalhe.show_percentage = false
	boss_detalhe.visible = boss_atual_id == &"pet0"
	boss_detalhe.modulate = Color(1.0, 0.82, 0.18, 1.0)
	boss_hud.add_child(boss_detalhe)


func _on_menu_upgrades_estado_alterado(aberto: bool) -> void:
	if is_instance_valid(boss_hud):
		boss_hud.visible = not aberto


func registrar_visual_boss_antes_pausa() -> void:
	estado_visual_boss_pausa.clear()
	if not is_instance_valid(boss_ativo):
		return
	_registrar_canvas_item_boss(boss_ativo)
	for node in boss_ativo.find_children("*", "CanvasItem", true, false):
		if node is CanvasItem:
			_registrar_canvas_item_boss(node as CanvasItem)


func _registrar_canvas_item_boss(item: CanvasItem) -> void:
	estado_visual_boss_pausa.append({
		"item": item,
		"visible": item.visible,
		"modulate": item.modulate,
		"self_modulate": item.self_modulate,
	})


func restaurar_visual_boss_durante_pausa() -> void:
	# Alguns renderizadores mobile limpam o estado de CanvasItems/partículas ao
	# trocar o SceneTree para pausado. Reaplicar exatamente o estado anterior
	# mantém o boss visível sem revelar partes ocultas pelo ataque atual.
	for estado_visual in estado_visual_boss_pausa:
		var item = estado_visual.get("item")
		if not is_instance_valid(item) or not (item is CanvasItem):
			continue
		item.visible = bool(estado_visual.get("visible", true))
		item.modulate = Color(estado_visual.get("modulate", Color.WHITE))
		item.self_modulate = Color(estado_visual.get("self_modulate", Color.WHITE))
		item.queue_redraw()


func limpar_estado_visual_boss_pausa() -> void:
	estado_visual_boss_pausa.clear()


func _on_tamanho_viewport_alterado() -> void:
	if Rede.modo_multiplayer:
		_enviar_tamanho_viewport_local()
	call_deferred("_atualizar_area_responsiva")


func _configurar_area_coop() -> void:
	if not Rede.modo_multiplayer:
		return
	limite_arena_coop = LimiteArenaCoopCena.new()
	limite_arena_coop.name = "LimiteArenaCoop"
	add_child(limite_arena_coop)
	if multiplayer.is_server():
		_registrar_tamanho_viewport(1, get_viewport().get_visible_rect().size)
	else:
		call_deferred("_enviar_tamanho_viewport_local")


func _processar_sincronizacao_area_coop(delta: float) -> void:
	if multiplayer.is_server() or area_coop_recebida:
		return
	tempo_reenvio_viewport -= delta
	if tempo_reenvio_viewport <= 0.0:
		tempo_reenvio_viewport = 1.0
		_enviar_tamanho_viewport_local()


func _enviar_tamanho_viewport_local() -> void:
	if not Rede.modo_multiplayer:
		return
	var tamanho := get_viewport().get_visible_rect().size
	if multiplayer.is_server():
		_registrar_tamanho_viewport(1, tamanho)
	elif Rede.esta_conectado():
		_registrar_tamanho_viewport_remoto.rpc_id(1, tamanho)


@rpc("any_peer", "call_remote", "reliable")
func _registrar_tamanho_viewport_remoto(tamanho: Vector2) -> void:
	if not multiplayer.is_server():
		return
	var remetente := multiplayer.get_remote_sender_id()
	if remetente <= 1 or not Rede.jogadores.has(remetente):
		return
	_registrar_tamanho_viewport(remetente, tamanho)


func _registrar_tamanho_viewport(peer_id: int, tamanho: Vector2) -> void:
	if not multiplayer.is_server() or tamanho.x <= 0.0 or tamanho.y <= 0.0:
		return
	tamanhos_viewport_rede[peer_id] = tamanho
	_publicar_area_coop()


func _publicar_area_coop() -> void:
	# A arena é canônica e idêntica para todos. Cada peer adapta somente sua
	# própria câmera ao viewport local; nenhuma resolução cria vinhetas nos demais.
	var area_visual := Rect2(Vector2.ZERO, Global.TAMANHO_BASE_JOGO)
	var area := calcular_area_jogo(area_visual, Rede.jogadores.size())
	if Rede.esta_conectado():
		_receber_area_coop.rpc(
			area.position, area.size, false,
			area_visual.position, area_visual.size
		)
	else:
		_receber_area_coop(
			area.position, area.size, false,
			area_visual.position, area_visual.size
		)


@rpc("authority", "call_local", "reliable")
func _receber_area_coop(
	posicao: Vector2, tamanho: Vector2, _diferentes: bool,
	posicao_visual := Vector2.ZERO, tamanho_visual := Vector2.ZERO
) -> void:
	var area := Rect2(posicao, tamanho)
	area_visual_coop = (
		Rect2(posicao_visual, tamanho_visual)
		if tamanho_visual.x > 0.0 and tamanho_visual.y > 0.0
		else area
	)
	Global.definir_area_multiplayer(area)
	area_coop_recebida = true
	if is_instance_valid(limite_arena_coop):
		var area_local := Global.calcular_retangulo_area_visivel(get_viewport().get_visible_rect().size)
		limite_arena_coop.configurar(area_visual_coop, area_local, false)
		limite_arena_coop.visible = false
	_atualizar_area_responsiva()
	_configurar_camera_local()


static func calcular_area_comum(tamanhos_viewport: Array[Vector2]) -> Rect2:
	if tamanhos_viewport.is_empty():
		return Rect2(Vector2.ZERO, Global.TAMANHO_BASE_JOGO)
	var tamanho_comum := Vector2(INF, INF)
	for tamanho_viewport in tamanhos_viewport:
		var area_peer := Global.calcular_retangulo_area_visivel(tamanho_viewport)
		tamanho_comum.x = minf(tamanho_comum.x, area_peer.size.x)
		tamanho_comum.y = minf(tamanho_comum.y, area_peer.size.y)
	tamanho_comum.x = maxf(tamanho_comum.x, 320.0)
	tamanho_comum.y = maxf(tamanho_comum.y, 180.0)
	return Rect2((Global.TAMANHO_BASE_JOGO - tamanho_comum) * 0.5, tamanho_comum)


static func calcular_area_jogo(area_visual: Rect2, quantidade_jogadores: int) -> Rect2:
	var jogadores := clampi(quantidade_jogadores, 1, Rede.MAX_JOGADORES)
	var fator := 1.0
	match jogadores:
		2: fator = 1.20
		3: fator = 1.42
		4: fator = 1.68
	var tamanho := area_visual.size * fator
	return Rect2(Global.TAMANHO_BASE_JOGO * 0.5 - tamanho * 0.5, tamanho)


static func resolucoes_sao_diferentes(tamanhos_viewport: Array[Vector2]) -> bool:
	if tamanhos_viewport.size() < 2:
		return false
	var referencia := tamanhos_viewport[0]
	for tamanho in tamanhos_viewport.slice(1):
		if not tamanho.is_equal_approx(referencia):
			return true
	return false


func _atualizar_area_responsiva() -> void:
	var area := Global.obter_retangulo_area_visivel()
	if is_instance_valid(fundo_original):
		# O cenário preenche o viewport local; apenas as faixas do limitador
		# escondem a sobra. Escalar o fundo pela arena comum expunha o cinza do
		# clear color e criava o quadrado escuro visto na tela do host.
		var area_local := Global.calcular_retangulo_area_visivel(
			get_viewport().get_visible_rect().size
		)
		var area_fundo := area.merge(area_local)
		fundo_original.position = area_fundo.get_center()
		fundo_original.scale = Vector2(
			escala_fundo_original.x * area_fundo.size.x / Global.TAMANHO_BASE_JOGO.x,
			escala_fundo_original.y * area_fundo.size.y / Global.TAMANHO_BASE_JOGO.y
		)
	var posicoes := [
		Vector2(area.position.x + 30.0, area.position.y + 40.0),
		Vector2(area.end.x - 44.0, area.end.y - 46.0),
		Vector2(area.end.x - 30.0, area.position.y + 40.0),
		Vector2(area.position.x + 40.0, area.end.y - 31.0),
	]
	for indice in posicoes.size():
		var marcador := get_node_or_null("Node/spawner%d" % (indice + 1)) as Marker2D
		if is_instance_valid(marcador):
			marcador.position = posicoes[indice]


func _on_boss_vida_alterada(atual: float, maxima: float) -> void:
	if is_instance_valid(boss_vida):
		boss_vida.max_value = maxima
		boss_vida.value = atual


func _on_boss_fase_alterada(fase: int) -> void:
	if not is_instance_valid(boss_nome):
		return
	var nome := "PET-0: O RESÍDUO ETERNO"
	if is_instance_valid(boss_ativo) and boss_ativo.has_method("obter_nome_boss"):
		nome = str(boss_ativo.call("obter_nome_boss"))
	boss_nome.text = "%s — FASE %d" % [nome, fase]
	if is_instance_valid(boss_vida) and is_instance_valid(boss_ativo) and boss_ativo.has_method("obter_cor_fase"):
		boss_vida.modulate = boss_ativo.call("obter_cor_fase")


func _on_boss_subtitulo_alterado(texto: String) -> void:
	if is_instance_valid(boss_detalhe_texto):
		boss_detalhe_texto.text = texto


func _on_boss_reciclagem_alterada(atual: int, meta: int) -> void:
	if not is_instance_valid(boss_detalhe):
		return
	boss_detalhe.visible = true
	boss_detalhe.max_value = meta
	boss_detalhe.value = atual
	boss_detalhe_texto.text = (
		"RÓTULO RECICLADO — NÚCLEO EXPOSTO!"
		if atual >= meta
		else "RECICLE OS FRAGMENTOS: %d/%d" % [atual, meta]
	)


func _on_boss_morreu(_inimigo: InimigoBase) -> void:
	restaurar_musica_partida()
	if boss_em_teste:
		boss_em_teste = false
		boss_ativo = null
		timer = TIMER_MAX
		if is_instance_valid(boss_nome):
			boss_nome.text = "TESTE CONCLUÍDO"
		if is_instance_valid(boss_detalhe_texto):
			boss_detalhe_texto.text = "PROGRESSÃO DA PARTIDA PRESERVADA"
		if is_instance_valid(boss_hud):
			var tween_teste := create_tween()
			tween_teste.tween_interval(0.65)
			tween_teste.tween_property(boss_hud, "modulate:a", 0.0, 0.25)
			tween_teste.tween_callback(boss_hud.queue_free)
		return
	Global.registrar_boss_derrotado(boss_atual_id)
	if setor_atual not in setores_concluidos:
		setores_concluidos.append(setor_atual)
	boss_ativo = null
	proximo_nivel_boss += INTERVALO_BOSS
	timer = TIMER_MAX
	if is_instance_valid(boss_nome):
		boss_nome.text = "SETOR CONCLUÍDO"
	if is_instance_valid(boss_detalhe_texto):
		boss_detalhe_texto.text = str(DadosSetores.obter(setor_atual).get("nome", ""))
	if is_instance_valid(boss_hud):
		var tween := create_tween()
		tween.tween_interval(0.9)
		tween.tween_property(boss_hud, "modulate:a", 0.0, 0.35)
		tween.tween_callback(boss_hud.queue_free)
	await get_tree().create_timer(1.1).timeout
	if game_over:
		return
	var proximo_setor: StringName = DadosSetores.proximo_no_ciclo(setor_atual)
	if proximo_setor.is_empty():
		mostrar_vitoria()
	else:
		if Rede.modo_multiplayer and multiplayer.is_server():
			_apresentar_transicao_setor_remota.rpc(proximo_setor)
		await apresentar_transicao_setor(proximo_setor)
		aplicar_setor(proximo_setor)


@rpc("authority", "call_remote", "reliable")
func _apresentar_transicao_setor_remota(id: StringName) -> void:
	await apresentar_transicao_setor(id)
	aplicar_setor(id)


func apresentar_transicao_setor(id: StringName) -> void:
	# Progressão única: a pausa curta comunica a troca sem interromper a partida
	# com escolhas ou permitir múltiplos comandos durante a transição.
	escolha_setor_ativa = true
	var dados: Dictionary = DadosSetores.obter(id)
	var cor: Color = dados.get("cor_destaque", Color.WHITE)
	camada_escolha = CanvasLayer.new()
	camada_escolha.layer = 80
	add_child(camada_escolha)
	var fundo := ColorRect.new()
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fundo.color = Color(0.002, 0.004, 0.018, 0.0)
	fundo.mouse_filter = Control.MOUSE_FILTER_STOP
	camada_escolha.add_child(fundo)
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fundo.add_child(centro)
	var coluna := VBoxContainer.new()
	coluna.alignment = BoxContainer.ALIGNMENT_CENTER
	coluna.add_theme_constant_override("separation", 8)
	centro.add_child(coluna)
	var simbolo := Label.new()
	simbolo.text = str(dados.get("simbolo", "◇"))
	simbolo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	simbolo.add_theme_font_size_override("font_size", 52)
	simbolo.add_theme_color_override("font_color", cor)
	coluna.add_child(simbolo)
	var titulo := Label.new()
	titulo.text = str(dados.get("nome", "PRÓXIMO SETOR"))
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 25)
	titulo.add_theme_color_override("font_color", cor)
	coluna.add_child(titulo)
	var subtitulo := Label.new()
	subtitulo.text = str(dados.get("subtitulo", ""))
	subtitulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitulo.add_theme_font_size_override("font_size", 12)
	coluna.add_child(subtitulo)
	coluna.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(fundo, "color:a", 0.94, 0.32)
	tween.parallel().tween_property(coluna, "modulate:a", 1.0, 0.32)
	tween.tween_interval(1.05)
	tween.tween_property(coluna, "modulate:a", 0.0, 0.26)
	tween.parallel().tween_property(fundo, "color:a", 0.0, 0.26)
	await tween.finished
	camada_escolha.queue_free()
	camada_escolha = null
	escolha_setor_ativa = false


func criar_visual_setor() -> void:
	var camada := CanvasLayer.new()
	camada.layer = -100
	add_child(camada)
	fundo_setor = ColorRect.new()
	fundo_setor.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fundo_setor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fundo_setor.visible = false
	camada.add_child(fundo_setor)
	rotulo_setor = Label.new()
	rotulo_setor.position = Vector2(24.0, 76.0)
	rotulo_setor.add_theme_font_size_override("font_size", 11)
	rotulo_setor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$GUI.add_child(rotulo_setor)


func aplicar_setor(id: StringName) -> void:
	setor_atual = id
	var dados := DadosSetores.obter(id)
	var usar_original := bool(dados.get("usar_fundo_original", false))
	fundo_original.visible = usar_original
	fundo_setor.visible = not usar_original
	rotulo_setor.visible = not usar_original
	fundo_setor.color = dados.get("cor_fundo", Color(0.004, 0.006, 0.022))
	rotulo_setor.text = "%s  •  PRÓXIMO BOSS: LVL %d" % [
		dados.get("nome", "SETOR"), proximo_nivel_boss
	]
	var cor: Color = dados.get("cor_destaque", Color.WHITE)
	cor.a = 0.76
	rotulo_setor.add_theme_color_override("font_color", cor)
	timer = 0.8


func mostrar_escolha_setor(opcoes: Array[StringName]) -> void:
	var linha := iniciar_painel_escolha(
		"ESCOLHA O PRÓXIMO SETOR",
		"O primeiro setor foi concluído. A próxima escolha define inimigos, paleta e boss."
	)
	for id in opcoes:
		var dados := DadosSetores.obter(id)
		var botao := criar_cartao_setor(linha, dados)
		botao.pressed.connect(_on_setor_escolhido.bind(id))
	focar_primeiro_botao(linha)


func iniciar_painel_escolha(titulo: String, subtitulo: String) -> HBoxContainer:
	escolha_setor_ativa = true
	get_tree().paused = true
	Global.definir_cursor_interface(true)
	camada_escolha = CanvasLayer.new()
	camada_escolha.layer = 80
	camada_escolha.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(camada_escolha)
	var fundo := ColorRect.new()
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fundo.color = Color(0.004, 0.006, 0.020, 0.94)
	camada_escolha.add_child(fundo)
	var coluna := VBoxContainer.new()
	coluna.set_anchors_preset(Control.PRESET_CENTER)
	coluna.position = Vector2(-390.0, -180.0)
	coluna.size = Vector2(780.0, 360.0)
	coluna.add_theme_constant_override("separation", 12)
	fundo.add_child(coluna)
	var titulo_label := Label.new()
	titulo_label.text = titulo
	titulo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo_label.add_theme_font_size_override("font_size", 25)
	titulo_label.add_theme_color_override("font_color", Color(0.68, 0.94, 1.0))
	coluna.add_child(titulo_label)
	var subtitulo_label := Label.new()
	subtitulo_label.text = subtitulo
	subtitulo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitulo_label.add_theme_font_size_override("font_size", 11)
	subtitulo_label.add_theme_color_override("font_color", Color(0.58, 0.66, 0.80))
	coluna.add_child(subtitulo_label)
	var linha := HBoxContainer.new()
	linha.custom_minimum_size = Vector2(780.0, 278.0)
	linha.alignment = BoxContainer.ALIGNMENT_CENTER
	linha.add_theme_constant_override("separation", 18)
	coluna.add_child(linha)
	return linha


func criar_cartao_setor(pai: HBoxContainer, dados: Dictionary) -> Button:
	var cor: Color = dados.get("cor_destaque", Color.WHITE)
	var botao := Button.new()
	botao.custom_minimum_size = Vector2(300.0, 260.0)
	botao.text = "%s\n%s\n\n%s\n\n%s" % [
		dados.get("simbolo", "◇"),
		dados.get("nome", "SETOR"),
		dados.get("subtitulo", ""),
		dados.get("descricao", "")
	]
	botao.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	botao.add_theme_font_size_override("font_size", 13)
	botao.add_theme_color_override("font_color", Color(0.84, 0.90, 1.0))
	botao.add_theme_color_override("font_hover_color", cor)
	botao.add_theme_color_override("font_focus_color", cor)
	for estado in [&"normal", &"hover", &"pressed", &"focus"]:
		var estilo := StyleBoxFlat.new()
		estilo.bg_color = Color(0.018, 0.027, 0.070, 0.96)
		if estado != &"normal":
			estilo.bg_color = Color(cor.r * 0.10, cor.g * 0.10, cor.b * 0.14, 1.0)
		estilo.border_color = Color(cor, 0.48) if estado == &"normal" else cor
		estilo.set_border_width_all(2)
		estilo.set_corner_radius_all(12)
		estilo.shadow_color = Color(cor.r, cor.g, cor.b, 0.22)
		estilo.shadow_size = 10 if estado != &"normal" else 5
		estilo.content_margin_left = 18.0
		estilo.content_margin_right = 18.0
		estilo.content_margin_top = 20.0
		estilo.content_margin_bottom = 20.0
		botao.add_theme_stylebox_override(estado, estilo)
	pai.add_child(botao)
	return botao


func focar_primeiro_botao(linha: HBoxContainer) -> void:
	for child in linha.get_children():
		if child is Button:
			(child as Button).call_deferred("grab_focus")
			return


func _on_setor_escolhido(id: StringName) -> void:
	encerrar_escolha_setor()
	aplicar_setor(id)


func encerrar_escolha_setor() -> void:
	escolha_setor_ativa = false
	get_tree().paused = false
	Global.definir_cursor_interface(false)
	if is_instance_valid(camada_escolha):
		camada_escolha.queue_free()
	camada_escolha = null


func mostrar_vitoria() -> void:
	game_over = true
	Global.registrar_jogo_zerado()
	var linha := iniciar_painel_escolha(
		"CICLO DE SETORES CONCLUÍDO",
		"Todos os cinco bosses foram derrotados sem repetir setores."
	)
	var botao := criar_cartao_setor(linha, {
		"nome": "VOLTAR AO MENU",
		"subtitulo": "PONTUAÇÃO %s" % str(int(Global.Pontos)).pad_zeros(8),
		"descricao": "A tentativa foi concluída.",
		"cor_destaque": Color(0.42, 1.0, 0.68)
	})
	botao.pressed.connect(_on_vitoria_menu)
	botao.call_deferred("grab_focus")


func _on_vitoria_menu() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	Global.definir_cursor_interface(true)
	get_tree().change_scene_to_file("res://Rooms/TelaInicial.tscn")


func fadeout_tutorial() -> void:
	# Mantida porque a animação antiga da cena ainda chama este método.
	pass
