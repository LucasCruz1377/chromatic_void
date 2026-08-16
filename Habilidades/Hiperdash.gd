extends Habilidade
class_name HabilidadeHiperdash


@export_category("Hiperdash")
@export var velocidade_dash: float = 1100.0
@export_range(0.0, 1.0, 0.05) var desaceleracao: float = 0.2
@export_range(0.1, 1.0, 0.05) var desaceleracao_tempo: float = 0.5
@export var intervalo_preparo: float = 0.2
@export var duracao_dash: float = 0.25
@export var intervalo_rastro: float = 0.03
@export var dano_dash: float = 4.0

var ativo := false


func pode_ativar(player) -> bool:
	return super(player) and not ativo


func executar(player) -> void:
	ativo = true
	player.BloquearControle()
	Engine.time_scale = desaceleracao_tempo
	executar_dash(player)


func executar_dash(player) -> void:
	await player.get_tree().create_timer(intervalo_preparo * desaceleracao_tempo).timeout
	if not ativo or not is_instance_valid(player):
		Engine.time_scale = 1.0
		ativo = false
		return
	Engine.time_scale = 1.0
	player.BloquearGiro()
	player.IniciarHabilidade(true)
	player.dano_colisao_habilidade = dano_dash
	player.velocity = player.transform.x * velocidade_dash
	var camera = player.get_tree().get_first_node_in_group("camera")
	if camera and camera.has_method("shake"):
		camera.shake(5.0)
	gerar_loop_de_rastros(player)
	await player.get_tree().create_timer(duracao_dash).timeout
	if not ativo or not is_instance_valid(player):
		return
	player.velocity *= desaceleracao
	finalizar(player)


func gerar_loop_de_rastros(player) -> void:
	while ativo and is_instance_valid(player) and player.velocity.length() > 100.0:
		criar_copia_poligono(player, player.get_node_or_null("corpo") as Polygon2D)
		criar_copia_poligono(player, player.get_node_or_null("corpo2") as Polygon2D)
		await player.get_tree().create_timer(intervalo_rastro).timeout


func criar_copia_poligono(player, poligono_original: Polygon2D) -> void:
	if not is_instance_valid(poligono_original):
		return
	var copia := poligono_original.duplicate() as Polygon2D
	if not copia:
		return
	player.get_parent().add_child(copia)
	copia.global_position = poligono_original.global_position
	copia.global_rotation = poligono_original.global_rotation
	copia.global_scale = poligono_original.global_scale
	copia.modulate = Color(0.0, 0.7, 1.0, 0.5)
	var tween := copia.create_tween()
	tween.tween_property(copia, "modulate:a", 0.0, 0.3)
	tween.tween_callback(copia.queue_free)


func finalizar(player) -> void:
	if not ativo:
		return
	ativo = false
	Engine.time_scale = 1.0
	if is_instance_valid(player):
		player.EncerrarHabilidade()
		player.DesbloquearControle()
		player.DesbloquearGiro()


func ao_desequipar(player) -> void:
	finalizar(player)


func reiniciar_estado() -> void:
	super()
	ativo = false


func obter_upgrades_especificos() -> Dictionary:
	var icone := "res://Habilidades/Icones/hiperdash.svg"
	var cor := Color(0.12, 0.88, 1.0)
	return {
		&"hiperdash_impacto": criar_carta_upgrade("IMPACTO CINÉTICO", "+2 de dano ao atravessar inimigos.", icone, cor, Nome, 3, [&"dano"]),
		&"hiperdash_distancia": criar_carta_upgrade("ROTA ESTENDIDA", "+0,08 s de duração e +8% de velocidade.", icone, cor, Nome, 3, [&"distancia"]),
		&"hiperdash_recarga": criar_carta_upgrade("VETOR PRONTO", "Recarga 12% mais rápida.", icone, cor, Nome, 3, [&"cooldown"]),
	}


func aplicar_upgrade_especifico(id: StringName, _nivel: int) -> bool:
	match id:
		&"hiperdash_impacto": dano_dash += 2.0
		&"hiperdash_distancia":
			duracao_dash += 0.08
			velocidade_dash *= 1.08
		&"hiperdash_recarga": reduzir_cooldown(0.88)
		_: return false
	return true
