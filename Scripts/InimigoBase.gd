extends CharacterBody2D
class_name InimigoBase


const EfeitoCombateCena = preload("res://Scripts/EfeitoCombate.gd")
const IndicadorDanoCena = preload("res://Scripts/IndicadorDano.gd")
const ExplosaoMonthlyCena = preload("res://Scripts/MonthlyBurst.gd")
const ShaderHitflash = preload("res://FX/canvas_shader/enemy.gdshader")
const MorteBossCena = preload("res://Scripts/MorteBossFX.gd")

# AJUSTE GLOBAL DO BRILHO DOS INIMIGOS.
# 1.35 recupera o neon alto antigo. Para regular, tente entre 0.80 e 1.60.
# Também é possível sobrescrever "brilho_visual" em cada cena pelo Inspector.
const BRILHO_INIMIGOS_PADRAO := 1.35

signal vida_alterada(atual: float, maxima: float)
signal morreu(inimigo: InimigoBase)


@export_category("Atributos")
@export var VidaMaxima: float = 100.0
@export var Dano: float = 2.0
@export var ValorXP: float = 1.0
@export var Velocidade: float = 30.0
@export_range(0.0, 2.0, 0.05) var multiplicador_dano_recebido: float = 1.0
@export_range(0.0, 1.0, 0.05) var resistencia_empurrao: float = 0.0

@export_category("Comportamento")
@export var usa_wrap: bool = true
@export var morre_ao_colidir_player: bool = true
@export var concede_recompensa: bool = true
@export var pontos_base: int = 100
@export_range(0, 1000, 1) var valor_cristais: int = 8

@export_category("Efeitos opcionais")
@export var particulas_morte: PackedScene
@export_range(0.0, 1.0, 0.05) var intensidade_flash: float = 0.35
@export_range(0.6, 2.0, 0.05) var brilho_visual: float = BRILHO_INIMIGOS_PADRAO
@export_range(0.0, 18.0, 0.5) var tremor_morte: float = 0.0


var Vida: float = 0.0
var tempo_atordoado: float = 0.0
var morto: bool = false
var tween_impacto: Tween
var modulacao_base := Color.WHITE
var escala_base_impacto := Vector2.ONE
var materiais_hitflash: Array[ShaderMaterial] = []
var _poligono_feedback: Polygon2D
var _feedback_localizado := false
var _feedback_com_poligono := false
var indice_setor_dificuldade := 0
var camadas_gelo := 0
var tempo_decaimento_gelo := 0.0
var congelado_totalmente := false
var tempo_morte_congelado := 0.0
var tempo_pulso_abaixo_zero := 0.0
var nevasca_ao_quebrar := false
var abaixo_zero_ativo := false
var tempo_snapshot_visual_rede := 0.0

const INTERVALO_SNAPSHOT_BOSS_REDE := 0.08
const ESTADOS_BOSS_REDE: Array[StringName] = [
	&"fase", &"fase_atual", &"estado", &"tempo_estado", &"ataque_pendente",
	&"angulo_visual", &"progresso_fusao", &"tempo_animacao_visual",
]

@onready var player = get_tree().get_first_node_in_group("player")
@onready var anim: AnimationPlayer = get_node_or_null("anim") as AnimationPlayer
@onready var dmg_taken_audio: AudioStreamPlayer2D = (
	get_node_or_null("dmg_taken_audio") as AudioStreamPlayer2D
)
@onready var camera: Camera2D = get_tree().get_first_node_in_group("camera") as Camera2D


func _ready() -> void:
	_configurar_sincronizador_multiplayer()
	if is_in_group("boss"):
		# Bosses preservam todo o balanceamento existente e recebem 175% da
		# vida que possuíam antes deste ajuste.
		VidaMaxima *= 1.75
	elif not is_in_group("asteroide_bonus"):
		var cena := get_tree().current_scene
		if is_instance_valid(cena) and cena.get("setor_atual") != null:
			indice_setor_dificuldade = maxi(
				preload("res://Scripts/SectorData.gd").ORDEM_CICLO.find(
					StringName(cena.get("setor_atual"))
				),
				0
			)
		VidaMaxima *= 1.0 + 0.18 * indice_setor_dificuldade
		Dano *= 1.0 + 0.30 * indice_setor_dificuldade
		Velocidade *= 1.0 + 0.05 * indice_setor_dificuldade

	escala_base_impacto = scale
	modulacao_base = Color(
		minf(modulate.r, 1.0),
		minf(modulate.g, 1.0),
		minf(modulate.b, 1.0),
		modulate.a
	)
	modulate = modulacao_base
	normalizar_brilho_visual()
	preparar_materiais_hitflash()

	var bonus_vida := 0.0
	if is_instance_valid(player):
		var nivel = player.get("nivel_atual")
		if nivel != null:
			bonus_vida = float(int(nivel / 5))

	Vida = VidaMaxima + bonus_vida
	vida_alterada.emit(Vida, VidaMaxima + bonus_vida)
	if Rede.modo_multiplayer and not multiplayer.is_server():
		set_physics_process(false)


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
		NodePath(".:velocity"),
	]
	var propriedades_estado: Array[NodePath] = [
		NodePath(".:Vida"),
		NodePath(".:VidaMaxima"),
		NodePath(".:morto"),
		NodePath(".:visible"),
		NodePath(".:self_modulate"),
		NodePath(".:camadas_gelo"),
		NodePath(".:congelado_totalmente"),
	]
	for caminho in propriedades_movimento:
		configuracao.add_property(caminho)
		configuracao.property_set_spawn(caminho, true)
		configuracao.property_set_replication_mode(
			caminho, SceneReplicationConfig.REPLICATION_MODE_ALWAYS
		)
	for caminho in propriedades_estado:
		configuracao.add_property(caminho)
		configuracao.property_set_spawn(caminho, true)
		configuracao.property_set_replication_mode(
			caminho, SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE
		)
	sincronizador.replication_config = configuracao
	# Movimento chega quinze vezes por segundo; vida, congelamento e visibilidade
	# só ocupam banda quando mudam. Isso preserva os snapshots de posição sob carga.
	sincronizador.replication_interval = 0.066
	add_child(sincronizador)


func _process(delta: float) -> void:
	if Rede.modo_multiplayer and not multiplayer.is_server():
		# O cliente não executa IA, dano nem colisões. Apenas prolonga visualmente
		# a última velocidade conhecida até o próximo snapshot do host.
		if not morto and visible:
			global_position += velocity * delta
		return
	if (
		not Rede.modo_multiplayer
		or not is_in_group("boss")
		or morto
	):
		return
	tempo_snapshot_visual_rede -= delta
	if tempo_snapshot_visual_rede > 0.0:
		return
	tempo_snapshot_visual_rede = INTERVALO_SNAPSHOT_BOSS_REDE
	_aplicar_snapshot_visual_boss.rpc(_capturar_snapshot_visual_boss())


func _capturar_snapshot_visual_boss() -> Dictionary:
	var estados: Dictionary = {}
	for propriedade in ESTADOS_BOSS_REDE:
		if _possui_propriedade_rede(propriedade):
			estados[propriedade] = get(propriedade)
	var visuais: Array[Dictionary] = []
	for candidato in find_children("*", "CanvasItem", true, false):
		var item := candidato as CanvasItem
		if not is_instance_valid(item):
			continue
		var dados: Dictionary = {
			"caminho": get_path_to(item),
			"visible": item.visible,
			"modulate": item.modulate,
			"self_modulate": item.self_modulate,
		}
		if item is Node2D:
			var node_2d := item as Node2D
			dados["position"] = node_2d.position
			dados["rotation"] = node_2d.rotation
			dados["scale"] = node_2d.scale
		if item is GPUParticles2D:
			dados["emitting"] = (item as GPUParticles2D).emitting
		if item is Line2D:
			dados["points"] = (item as Line2D).points
		visuais.append(dados)
	var animacoes: Array[Dictionary] = []
	for candidato in find_children("*", "AnimationPlayer", true, false):
		var reprodutor := candidato as AnimationPlayer
		if is_instance_valid(reprodutor) and not reprodutor.current_animation.is_empty():
			animacoes.append({
				"caminho": get_path_to(reprodutor),
				"animacao": reprodutor.current_animation,
				"posicao": reprodutor.current_animation_position,
				"tocando": reprodutor.is_playing(),
			})
	return {"estados": estados, "visuais": visuais, "animacoes": animacoes}


@rpc("authority", "call_remote", "unreliable_ordered", 0)
func _aplicar_snapshot_visual_boss(snapshot: Dictionary) -> void:
	if multiplayer.is_server():
		return
	var estados: Dictionary = snapshot.get("estados", {})
	for propriedade in estados:
		var nome := StringName(propriedade)
		if _possui_propriedade_rede(nome):
			set(nome, estados[propriedade])
	for dados_variant in Array(snapshot.get("visuais", [])):
		var dados := Dictionary(dados_variant)
		var item := get_node_or_null(NodePath(str(dados.get("caminho", "")))) as CanvasItem
		if not is_instance_valid(item):
			continue
		item.visible = bool(dados.get("visible", item.visible))
		item.modulate = dados.get("modulate", item.modulate)
		item.self_modulate = dados.get("self_modulate", item.self_modulate)
		if item is Node2D:
			var node_2d := item as Node2D
			node_2d.position = dados.get("position", node_2d.position)
			node_2d.rotation = float(dados.get("rotation", node_2d.rotation))
			node_2d.scale = dados.get("scale", node_2d.scale)
		if item is GPUParticles2D and dados.has("emitting"):
			(item as GPUParticles2D).emitting = bool(dados["emitting"])
		if item is Line2D and dados.has("points"):
			(item as Line2D).points = dados["points"]
	for dados_variant in Array(snapshot.get("animacoes", [])):
		var dados := Dictionary(dados_variant)
		var reprodutor := get_node_or_null(
			NodePath(str(dados.get("caminho", "")))
		) as AnimationPlayer
		if not is_instance_valid(reprodutor):
			continue
		var animacao := StringName(dados.get("animacao", &""))
		if bool(dados.get("tocando", false)) and reprodutor.current_animation != animacao:
			reprodutor.play(animacao)
		var posicao := float(dados.get("posicao", 0.0))
		if absf(reprodutor.current_animation_position - posicao) > 0.16:
			reprodutor.seek(posicao, true)
	queue_redraw()


func _possui_propriedade_rede(nome: StringName) -> bool:
	for dados in get_property_list():
		if StringName(dados.get("name", "")) == nome:
			return true
	return false


func _physics_process(delta: float) -> void:
	if Rede.modo_multiplayer and not multiplayer.is_server():
		return
	if morto:
		return

	atualizar_estados(delta)
	_atualizar_estado_gelo(delta)
	if morto:
		return
	atualizar_referencia_player()

	var atraido_pelo_presente := _mover_para_presente_misterioso(delta)
	if atraido_pelo_presente:
		pass
	elif esta_atordoado():
		velocity = velocity.move_toward(Vector2.ZERO, Velocidade * 4.0 * delta)
	else:
		Mover(delta)

	var velocidade_limite := obter_velocidade_maxima() * _fator_velocidade_gelo()
	if atraido_pelo_presente:
		velocidade_limite = maxf(velocidade_limite * 1.8, 320.0)
	velocity = velocity.limit_length(velocidade_limite)
	move_and_slide()

	if usa_wrap:
		aplicar_wrap()


func atualizar_referencia_player() -> void:
	var melhor: Node2D
	var melhor_distancia := INF
	for candidato in get_tree().get_nodes_in_group("player"):
		if not is_instance_valid(candidato) or not candidato is Node2D:
			continue
		if candidato.get("vivo") == false or not (candidato as Node2D).visible:
			continue
		var distancia := global_position.distance_squared_to((candidato as Node2D).global_position)
		if distancia < melhor_distancia:
			melhor_distancia = distancia
			melhor = candidato as Node2D
	player = melhor


func atrair_para_presente_misterioso(presente: Node2D) -> void:
	if morto or not is_instance_valid(presente):
		return
	set_meta("presente_misterioso_alvo", presente)


func _mover_para_presente_misterioso(delta: float) -> bool:
	if not has_meta("presente_misterioso_alvo"):
		return false
	var presente = get_meta("presente_misterioso_alvo")
	if not is_instance_valid(presente) or not presente is Node2D:
		remove_meta("presente_misterioso_alvo")
		return false
	var destino := (presente as Node2D).global_position
	var distancia := global_position.distance_to(destino)
	if distancia <= 22.0:
		velocity = velocity.move_toward(Vector2.ZERO, 1200.0 * delta)
	else:
		var velocidade_atracao := maxf(Velocidade * 1.8, 320.0)
		var desejada := global_position.direction_to(destino) * velocidade_atracao
		velocity = velocity.move_toward(desejada, 1500.0 * delta)
	return true


func atualizar_estados(delta: float) -> void:
	if tempo_atordoado > 0.0:
		tempo_atordoado = maxf(tempo_atordoado - delta, 0.0)


func aplicar_camada_gelo(
	quantidade := 1, ativar_nevasca := false, ativar_abaixo_zero := false
) -> void:
	if Rede.modo_multiplayer and not multiplayer.is_server():
		_solicitar_camada_gelo.rpc_id(
			1, clampi(quantidade, 1, 2), ativar_nevasca, ativar_abaixo_zero
		)
		return
	_aplicar_camada_gelo_autoritativa(quantidade, ativar_nevasca, ativar_abaixo_zero)


@rpc("any_peer", "call_remote", "reliable")
func _solicitar_camada_gelo(
	quantidade: int, ativar_nevasca: bool, ativar_abaixo_zero: bool
) -> void:
	if not multiplayer.is_server():
		return
	var remetente := multiplayer.get_remote_sender_id()
	if remetente <= 1 or not Rede.jogadores.has(remetente):
		return
	_aplicar_camada_gelo_autoritativa(
		clampi(quantidade, 1, 2), ativar_nevasca, ativar_abaixo_zero
	)


func _aplicar_camada_gelo_autoritativa(
	quantidade: int, ativar_nevasca: bool, ativar_abaixo_zero: bool
) -> void:
	if morto or congelado_totalmente:
		return
	nevasca_ao_quebrar = nevasca_ao_quebrar or ativar_nevasca
	abaixo_zero_ativo = abaixo_zero_ativo or ativar_abaixo_zero
	var limite := 4 if is_in_group("boss") else 5
	camadas_gelo = clampi(camadas_gelo + maxi(quantidade, 1), 0, limite)
	tempo_decaimento_gelo = 5.0
	_atualizar_visual_gelo()
	var cena_combate := _obter_cena_combate()
	if is_instance_valid(cena_combate):
		EfeitoCombateCena.criar(
			cena_combate, global_position, EfeitoCombate.Tipo.ACERTO,
			Color(0.48, 0.86, 1.0), 0.55 + float(camadas_gelo) * 0.08
		)
	if camadas_gelo >= 5:
		congelado_totalmente = true
		tempo_morte_congelado = 5.0 if abaixo_zero_ativo else 3.0
		tempo_pulso_abaixo_zero = 1.0
		velocity = Vector2.ZERO
		aplicar_atordoamento(tempo_morte_congelado + 0.1)


func _atualizar_estado_gelo(delta: float) -> void:
	if congelado_totalmente:
		velocity = Vector2.ZERO
		tempo_morte_congelado = maxf(tempo_morte_congelado - delta, 0.0)
		if abaixo_zero_ativo:
			tempo_pulso_abaixo_zero -= delta
			if tempo_pulso_abaixo_zero <= 0.0:
				tempo_pulso_abaixo_zero = 1.0
				_espalhar_camadas_gelo(1, 250.0)
		if tempo_morte_congelado <= 0.0:
			_quebrar_congelado()
		return
	if camadas_gelo <= 0:
		return
	tempo_decaimento_gelo -= delta
	if tempo_decaimento_gelo <= 0.0:
		camadas_gelo = maxi(camadas_gelo - 1, 0)
		tempo_decaimento_gelo = 5.0 if camadas_gelo > 0 else 0.0
		_atualizar_visual_gelo()


func _fator_velocidade_gelo() -> float:
	if congelado_totalmente:
		return 0.0
	return maxf(1.0 - float(camadas_gelo) * 0.10, 0.50)


func _atualizar_visual_gelo() -> void:
	var intensidade := float(camadas_gelo) / 5.0
	self_modulate = Color.WHITE.lerp(Color(0.40, 0.86, 1.0), intensidade)
	for material_gelo in materiais_hitflash:
		if is_instance_valid(material_gelo) and material_gelo.get_shader_parameter("freeze_amount") != null:
			material_gelo.set_shader_parameter("freeze_amount", intensidade)


func _espalhar_camadas_gelo(quantidade: int, raio: float) -> void:
	var cena := _obter_cena_combate()
	if is_instance_valid(cena):
		ExplosaoMonthlyCena.criar(cena, global_position, Color(0.42, 0.84, 1.0), raio / 210.0)
	for candidato in get_tree().get_nodes_in_group("inimigo"):
		if (
			not is_instance_valid(candidato)
			or candidato == self
			or not candidato is Node2D
			or not candidato.has_method("aplicar_camada_gelo")
		):
			continue
		if global_position.distance_to((candidato as Node2D).global_position) <= raio:
			candidato.call(
				"aplicar_camada_gelo", quantidade, nevasca_ao_quebrar, abaixo_zero_ativo
			)


func _quebrar_congelado() -> void:
	if morto:
		return
	if nevasca_ao_quebrar:
		_espalhar_camadas_gelo(2, 250.0)
	Vida = 0.0
	morrer()


func aplicar_atordoamento(duracao: float) -> void:
	if morto:
		return
	tempo_atordoado = maxf(tempo_atordoado, duracao)


func esta_atordoado() -> bool:
	return tempo_atordoado > 0.0


func aplicar_empurrao(forca: Vector2) -> void:
	velocity += forca * (1.0 - resistencia_empurrao)


func aplicar_wrap() -> void:
	var area := Global.obter_retangulo_area_visivel()
	global_position.x = wrapf(global_position.x, area.position.x, area.end.x)
	global_position.y = wrapf(global_position.y, area.position.y, area.end.y)


func obter_velocidade_maxima() -> float:
	return Velocidade


func Mover(_delta: float) -> void:
	pass


func tomarDano(valor: float) -> void:
	if Rede.modo_multiplayer and not multiplayer.is_server():
		_solicitar_dano_ao_host.rpc_id(1, clampf(valor, 0.0, 10000.0))
		return
	if morto or valor <= 0.0:
		return

	var dano_final := maxf(valor * multiplicador_dano_recebido, 0.0)
	Vida = maxf(Vida - dano_final, 0.0)
	vida_alterada.emit(Vida, obter_vida_maxima_atual())
	reproduzir_impacto(dano_final)
	if has_meta("laco_parceiro") and Time.get_ticks_msec() <= int(get_meta("laco_expira", 0)):
		var parceiro = get_meta("laco_parceiro")
		if is_instance_valid(parceiro) and parceiro.has_method("receber_eco_laco"):
			parceiro.call("receber_eco_laco", dano_final * 0.38)

	if Vida <= 0.0:
		morrer()


@rpc("any_peer", "call_remote", "reliable")
func _solicitar_dano_ao_host(valor: float) -> void:
	if not multiplayer.is_server():
		return
	var remetente := multiplayer.get_remote_sender_id()
	if remetente <= 1 or not Rede.jogadores.has(remetente):
		return
	tomarDano(clampf(valor, 0.0, 10000.0))


func receber_eco_laco(valor: float) -> void:
	if morto or valor <= 0.0:
		return
	Vida = maxf(Vida - valor * multiplicador_dano_recebido, 0.0)
	vida_alterada.emit(Vida, obter_vida_maxima_atual())
	var cena := get_tree().current_scene
	if is_instance_valid(cena):
		EfeitoCombateCena.criar(cena, global_position, EfeitoCombate.Tipo.ACERTO, Color(1.0, 0.34, 0.58), 0.65)
		IndicadorDanoCena.criar(cena, global_position, valor * multiplicador_dano_recebido, Color(1.0, 0.42, 0.68))
	if Vida <= 0.0:
		morrer()


func obter_vida_maxima_atual() -> float:
	var bonus_vida := 0.0
	if is_instance_valid(player):
		var nivel = player.get("nivel_atual")
		if nivel != null:
			bonus_vida = float(int(nivel / 5))
	return VidaMaxima + bonus_vida


func reproduzir_impacto(dano_exibido: float = 0.0) -> void:
	_reproduzir_hitflash_local()
	var cena := _obter_cena_combate()
	if Rede.esta_conectado() and multiplayer.is_server() and is_instance_valid(cena) and cena.has_method("replicar_feedback_visual"):
		cena.call("replicar_feedback_visual", {
			"classe": &"hitflash_inimigo",
			"alvo": str(cena.get_path_to(self)),
		})

	if is_instance_valid(cena):
		EfeitoCombateCena.criar(
			cena,
			global_position,
			EfeitoCombate.Tipo.ACERTO,
			obter_cor_feedback(),
			clampf(0.72 + sqrt(maxf(VidaMaxima, 1.0)) * 0.035, 0.8, 1.45)
		)
		if dano_exibido > 0.0:
			IndicadorDanoCena.criar(
				cena, global_position, dano_exibido, Color(1.0, 0.82, 0.24) if bool(get_meta("impacto_critico", false)) else obter_cor_feedback(),
				bool(get_meta("impacto_critico", false))
			)


func reproduzir_hitflash_rede() -> void:
	_reproduzir_hitflash_local()


func _reproduzir_hitflash_local() -> void:
	if is_instance_valid(dmg_taken_audio):
		dmg_taken_audio.pitch_scale = randf_range(0.92, 1.08)
		dmg_taken_audio.play()

	# O flash antigo usava HDR acima de 1.0 e somava com o bloom. Em impactos
	# rápidos a animação recomeçava no pico, criando o clarão acumulado.
	if is_instance_valid(anim) and anim.current_animation == "flash-in":
		anim.stop()
	_definir_hitflash_shader(0.0)

	if tween_impacto and tween_impacto.is_valid():
		tween_impacto.kill()
	# Um tween interrompido podia deixar a escala ampliada como ponto inicial
	# do próximo impacto, fazendo bosses crescerem a cada tiro recebido.
	scale = escala_base_impacto

	var forca_flash := clampf(maxf(intensidade_flash, 0.76), 0.76, 1.0)
	var cor_impacto := modulacao_base.lerp(Color(1.45, 1.45, 1.45, modulacao_base.a), 0.72)
	modulate = cor_impacto
	tween_impacto = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween_impacto.set_parallel(true)
	_definir_hitflash_shader(forca_flash)
	tween_impacto.tween_method(_definir_hitflash_shader, forca_flash, 0.0, 0.13)
	tween_impacto.tween_property(self, "modulate", modulacao_base, 0.13)
	# Bosses já possuem silhuetas e animações próprias; o feedback de acerto não
	# altera seu tamanho. Inimigos comuns conservam uma pulsação leve e limitada.
	if not is_in_group("boss"):
		tween_impacto.tween_property(
			self, "scale", escala_base_impacto * 1.035, 0.04
		)
		tween_impacto.chain().tween_property(
			self, "scale", escala_base_impacto, 0.065
		)

func normalizar_brilho_visual() -> void:
	for node in find_children("*", "CanvasItem", true, false):
		var item := node as CanvasItem
		if not item:
			continue
		# Ajusta apenas nós que realmente desenham. Modificar Node2D intermediários
		# faria o valor se multiplicar em cascata e apagaria o inimigo.
		if (
			item is Polygon2D
			or item is Line2D
			or item is Sprite2D
			or item is AnimatedSprite2D
		):
			var alpha := item.self_modulate.a
			var intensidade := clampf(brilho_visual, 0.6, 2.0)
			item.self_modulate = Color(intensidade, intensidade, intensidade, alpha)
	zerar_brilho_dos_materiais()


func preparar_materiais_hitflash() -> void:
	materiais_hitflash.clear()
	for node in find_children("*", "CanvasItem", true, false):
		var item := node as CanvasItem
		if not item or not (
			item is Polygon2D
			or item is Line2D
			or item is Sprite2D
			or item is AnimatedSprite2D
		):
			continue
		var material_hitflash: ShaderMaterial
		if item.material is ShaderMaterial:
			var material_existente := item.material as ShaderMaterial
			if material_existente.get_shader_parameter("brightness") == null:
				continue
			material_hitflash = material_existente.duplicate(true) as ShaderMaterial
		elif item.material == null:
			material_hitflash = ShaderMaterial.new()
			material_hitflash.shader = ShaderHitflash
		if not is_instance_valid(material_hitflash):
			continue
		material_hitflash.set_shader_parameter("brightness", 0.0)
		item.material = material_hitflash
		materiais_hitflash.append(material_hitflash)


func _definir_hitflash_shader(valor: float) -> void:
	for material_flash in materiais_hitflash:
		if is_instance_valid(material_flash):
			material_flash.set_shader_parameter("brightness", clampf(valor, 0.0, 1.0))


func zerar_brilho_dos_materiais() -> void:
	for node in find_children("*", "CanvasItem", true, false):
		var item := node as CanvasItem
		if not item or not (item.material is ShaderMaterial):
			continue
		var shader_material := item.material as ShaderMaterial
		if shader_material.get_shader_parameter("brightness") != null:
			shader_material.set_shader_parameter("brightness", 0.0)


func ao_colidir_com_player(alvo: Node) -> void:
	if Rede.modo_multiplayer and not multiplayer.is_server():
		return
	if morto or not is_instance_valid(alvo):
		return

	if alvo.has_method("tomar_dano"):
		alvo.tomar_dano(Dano)

	if morre_ao_colidir_player:
		morrer()


func morrer() -> void:
	if morto:
		return
	# Mantém compatibilidade com o Player antigo, que chama morrer() em todo
	# inimigo tocado. Inimigos persistentes só morrem quando a vida chega a zero.
	if Vida > 0.0 and not morre_ao_colidir_player:
		return

	morto = true
	velocity = Vector2.ZERO
	set_physics_process(false)
	collision_layer = 0
	collision_mask = 0
	for forma in find_children("*", "CollisionShape2D", true, false):
		(forma as CollisionShape2D).set_deferred("disabled", true)
	morreu.emit(self)
	if not is_in_group("boss"):
		preload("res://Scripts/AudioCombate.gd").tocar(
			get_tree().current_scene, &"morte_inimigo", 0.04
		)

	if is_instance_valid(camera) and camera.has_method("shake"):
		camera.shake(obter_tremor_morte(), is_in_group("boss"))

	var cena := get_tree().current_scene
	if is_instance_valid(cena):
		EfeitoCombateCena.criar(
			cena,
			global_position,
			EfeitoCombate.Tipo.MORTE,
			obter_cor_feedback(),
			clampf(0.75 + sqrt(maxf(VidaMaxima, 1.0)) * 0.05, 0.9, 2.1),
			velocity.normalized()
		)
		if is_in_group("boss"):
			MorteBossCena.criar(cena, global_position, obter_cor_feedback())

	criar_particulas_morte()

	if concede_recompensa:
		conceder_recompensa()

	queue_free()


func obter_cor_feedback() -> Color:
	if not _feedback_localizado or (_feedback_com_poligono and not is_instance_valid(_poligono_feedback)):
		_feedback_localizado = true
		_poligono_feedback = null
		_feedback_com_poligono = false
		for node in find_children("*", "Polygon2D", true, false):
			_poligono_feedback = node as Polygon2D
			if is_instance_valid(_poligono_feedback):
				_feedback_com_poligono = true
				break
	if is_instance_valid(_poligono_feedback):
		return _poligono_feedback.color.lightened(0.18)
	return Color(0.55, 0.9, 1.0)


func obter_tremor_morte() -> float:
	if tremor_morte > 0.0:
		return tremor_morte
	# Inimigos leves fazem um toque curto; tanques e chefes usam a própria
	# vida máxima para produzir um impacto mais forte, sem estourar a câmera.
	return clampf(2.4 + sqrt(maxf(VidaMaxima, 1.0)) * 0.82, 3.0, 14.0)


func criar_particulas_morte() -> void:
	if not particulas_morte:
		return

	var cena := _obter_cena_combate()
	if not is_instance_valid(cena):
		return
	var partes := particulas_morte.instantiate() as Node2D
	if not partes:
		return
	partes.global_position = global_position
	partes.global_rotation = global_rotation
	var cor_particulas := (
		Color(0.40, 0.88, 1.0)
		if camadas_gelo > 0
		else obter_cor_feedback()
	)
	partes.modulate = cor_particulas
	cena.add_child(partes)

	if partes is GPUParticles2D:
		var particulas := partes as GPUParticles2D
		particulas.emitting = true
	if Rede.esta_conectado() and cena.has_method("replicar_feedback_visual"):
		cena.call("replicar_feedback_visual", {
			"classe": &"particula_cena",
			"cena": particulas_morte.resource_path,
			"posicao": global_position,
			"rotacao": global_rotation,
			"cor": cor_particulas,
		})


func calcular_intervalo_ataque(valor_base: float) -> float:
	if indice_setor_dificuldade <= 0:
		return maxf(valor_base, 0.5)
	return maxf(valor_base * pow(0.76, indice_setor_dificuldade), 0.5)


func _obter_cena_combate() -> Node:
	# Testes, transições e MultiplayerSpawner podem manter a batalha abaixo da
	# current_scene. Subir pela árvore garante que o evento saia do nó que tem
	# os RPCs, tanto no jogo exportado quanto nas integrações host/client.
	var cursor := get_parent()
	while is_instance_valid(cursor):
		if cursor.has_method("replicar_feedback_visual"):
			return cursor
		cursor = cursor.get_parent()
	return get_tree().current_scene


func conceder_recompensa() -> void:
	var combo_apos_abate := Global.Combo + 1
	# A recompensa base recebe +12%; a curva histórica de combo/setor permanece
	# intacta para não desbalancear melhorias ou conquistas relacionadas.
	var recompensa_xp := ValorXP * 1.12 * calcular_fator_xp_combo(
		combo_apos_abate, indice_setor_dificuldade
	)
	for jogador in get_tree().get_nodes_in_group("player"):
		if is_instance_valid(jogador) and jogador.has_method("conceder_xp_rede"):
			jogador.call("conceder_xp_rede", recompensa_xp)

	Global.registrar_kill()
	Global.Combo += 1
	Global.Pontos += pontos_base + (pontos_base * (Global.Combo - 1))
	Global.registrar_recordes_partida(Global.Combo, Global.Pontos)
	var cena_combate := _obter_cena_combate()
	if (
		Rede.modo_multiplayer
		and multiplayer.is_server()
		and is_instance_valid(cena_combate)
		and cena_combate.has_method("conceder_cristais_coop")
	):
		cena_combate.call("conceder_cristais_coop", valor_cristais)
	else:
		Global.adicionar_cristais(valor_cristais)


static func calcular_fator_xp_combo(combo: int, indice_setor: int = 0) -> float:
	# 20x concede exatamente +10%. A raiz quadrada premia cadeias maiores sem
	# converter o multiplicador bruto em XP; o bônus de combo para em +50%.
	var cadeia := maxi(combo, 0)
	var bonus_combo := minf(0.10 * sqrt(float(cadeia) / 20.0), 0.50)
	var bonus_setor := clampf(float(maxi(indice_setor, 0)) * 0.05, 0.0, 0.25)
	return 1.0 + bonus_combo + bonus_setor
