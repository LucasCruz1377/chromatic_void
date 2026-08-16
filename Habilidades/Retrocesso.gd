extends Habilidade
class_name HabilidadeRetrocesso


@export_category("Retrocesso")
@export var intervalo_memorias: float = 0.01
@export var max_memoria: int = 90
@export var intervalo_rastro_rewind: int = 3
@export var cura_final: float = 0.0
@export var efeito_tela: PackedScene

var memoria: Array[Dictionary] = []
var recordando := false
var efeito_tela_ativo: Node


func pode_ativar(player) -> bool:
	return super(player) and not recordando and not memoria.is_empty()


func executar(player) -> void:
	recordando = true
	iniciar_efeito_tela(player)
	player.BloquearGiro()
	player.BloquearControle()
	player.IniciarHabilidade(true)
	player.velocity = Vector2.ZERO
	rewind(player)


func atualizar(player, _delta: float) -> void:
	if recordando or not is_instance_valid(player):
		return
	if memoria.size() >= max_memoria:
		memoria.pop_front()
	memoria.append({
		"posicao": player.global_position,
		"rotacao": player.rotation,
		"vida": player.vida,
	})


func rewind(player) -> void:
	if memoria.is_empty():
		finalizar_rewind(player)
		return
	for indice in range(memoria.size() - 1, -1, -1):
		if not recordando or not is_instance_valid(player):
			recordando = false
			encerrar_efeito_tela(true)
			return
		while player.get_tree().paused:
			await player.get_tree().process_frame
		var estado: Dictionary = memoria[indice]
		player.global_position = estado["posicao"]
		player.rotation = estado["rotacao"]
		var vida_salva: float = estado["vida"]
		if vida_salva > player.vida:
			player.vida = minf(vida_salva, player.VIDA_MAXIMA)
		player.modulate.a = 0.55 + 0.45 * absf(sin(Time.get_ticks_msec() / 80.0))
		if indice % intervalo_rastro_rewind == 0:
			criar_rastros(player)
		await player.get_tree().create_timer(intervalo_memorias).timeout
	finalizar_rewind(player)


func finalizar_rewind(player) -> void:
	if not recordando:
		return
	recordando = false
	memoria.clear()
	encerrar_efeito_tela(false)
	if not is_instance_valid(player):
		return
	player.modulate = Color.WHITE
	player.curar(cura_final)
	player.EncerrarHabilidade()
	player.DesbloquearGiro()
	player.DesbloquearControle()
	var camera = player.get_tree().get_first_node_in_group("camera")
	if camera and camera.has_method("shake"):
		camera.shake(1.5)


func iniciar_efeito_tela(player) -> void:
	if not efeito_tela or not is_instance_valid(player):
		return
	encerrar_efeito_tela(true)
	efeito_tela_ativo = efeito_tela.instantiate()
	player.get_tree().current_scene.add_child(efeito_tela_ativo)
	if efeito_tela_ativo.has_method("iniciar"):
		efeito_tela_ativo.iniciar()


func encerrar_efeito_tela(imediato: bool) -> void:
	if not is_instance_valid(efeito_tela_ativo):
		efeito_tela_ativo = null
		return
	if imediato:
		efeito_tela_ativo.queue_free()
	elif efeito_tela_ativo.has_method("finalizar"):
		efeito_tela_ativo.finalizar()
	else:
		efeito_tela_ativo.queue_free()
	efeito_tela_ativo = null


func criar_rastros(player) -> void:
	for poligono in player.find_children("*", "Polygon2D", true, false):
		criar_rastro_temporal(player, poligono)


func criar_rastro_temporal(player, poligono_original: Polygon2D) -> void:
	if not is_instance_valid(poligono_original):
		return
	var copia := poligono_original.duplicate() as Polygon2D
	if not copia:
		return
	player.get_parent().add_child(copia)
	copia.global_position = poligono_original.global_position
	copia.global_rotation = poligono_original.global_rotation
	copia.global_scale = poligono_original.global_scale
	copia.modulate = Color(0.8, 0.0, 1.0, 0.6)
	var tween := copia.create_tween()
	tween.tween_property(copia, "modulate:a", 0.0, 0.15)
	tween.tween_callback(copia.queue_free)


func ao_desequipar(player) -> void:
	encerrar_efeito_tela(true)
	if not recordando:
		memoria.clear()
		return
	recordando = false
	memoria.clear()
	if is_instance_valid(player):
		player.modulate = Color.WHITE
		player.EncerrarHabilidade()
		player.DesbloquearGiro()
		player.DesbloquearControle()


func reiniciar_estado() -> void:
	super()
	memoria.clear()
	recordando = false
	efeito_tela_ativo = null


func obter_upgrades_especificos() -> Dictionary:
	var icone := "res://Habilidades/Icones/retrocesso.svg"
	var cor := Color(0.72, 0.28, 1.0)
	return {
		&"retrocesso_memoria": criar_carta_upgrade("MEMÓRIA AMPLIADA", "+30 estados registrados para voltar mais longe.", icone, cor, Nome, 3, [&"distancia"]),
		&"retrocesso_cura": criar_carta_upgrade("SEGUNDA CHANCE", "+8 de cura ao concluir o retorno.", icone, cor, Nome, 3, [&"cura"]),
		&"retrocesso_recarga": criar_carta_upgrade("ATALHO TEMPORAL", "Recarga 12% mais rápida.", icone, cor, Nome, 3, [&"cooldown"]),
	}


func aplicar_upgrade_especifico(id: StringName, _nivel: int) -> bool:
	match id:
		&"retrocesso_memoria": max_memoria += 30
		&"retrocesso_cura": cura_final += 8.0
		&"retrocesso_recarga": reduzir_cooldown(0.88)
		_: return false
	return true
