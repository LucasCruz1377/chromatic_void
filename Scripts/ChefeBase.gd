extends "res://Scripts/InimigoBase.gd"
class_name ChefeBase

## Estado e replicacao visual comuns; cada chefe conserva seus ataques e desenho.
var tempo_snapshot_visual_rede := 0.0
var sequencia_snapshot_visual_rede := 0
var ultima_sequencia_snapshot_visual_rede := -1

const INTERVALO_SNAPSHOT_BOSS_REDE := 0.08
const ESTADOS_BOSS_REDE: Array[StringName] = [
	&"fase",
	&"fase_atual",
	&"estado",
	&"tempo_estado",
	&"ataque_pendente",
	&"angulo_visual",
	&"progresso_fusao",
	&"tempo_animacao_visual",
	&"reciclagem_atual",
	&"rotulo_removido",
	&"direcao_investida",
	&"escudo_ativo",
	&"petalas_em_voo",
	&"tempo_janela_vulneravel",
]


## Liga a forma física à peça desenhada, inclusive quando ela gira ou desaparece.
func vincular_colisao_visual(peca: Node2D, forma: Shape2D) -> void:
	var colisao := CollisionShape2D.new()
	colisao.shape = forma
	add_child(colisao)
	colisao.global_transform = peca.global_transform
	var vinculo := RemoteTransform2D.new()
	peca.add_child(vinculo)
	vinculo.remote_path = vinculo.get_path_to(colisao)
	colisao.disabled = not peca.is_visible_in_tree()
	peca.visibility_changed.connect(func():
		if is_instance_valid(colisao):
			colisao.set_deferred("disabled", morto or not peca.is_visible_in_tree())
	)


func _process(delta: float) -> void:
	if Rede.modo_multiplayer and not multiplayer.is_server():
		# Consistencia acima de fluidez: somente snapshots autoritativos
		# alteram a posicao remota. Nao extrapolar velocidades antigas.
		return
	if not Rede.modo_multiplayer or not is_in_group("boss") or morto:
		return
	tempo_snapshot_visual_rede -= delta
	if tempo_snapshot_visual_rede > 0.0:
		return
	tempo_snapshot_visual_rede = INTERVALO_SNAPSHOT_BOSS_REDE
	sequencia_snapshot_visual_rede += 1
	# O RPC sai da arena (que permanece na arvore), nao do boss que pode ter
	# sido destruido ou ainda nao ter sido replicado no cliente.
	var arena := _obter_cena_combate()
	if is_instance_valid(arena) and arena.has_method("replicar_snapshot_visual_boss"):
		arena.call(
			"replicar_snapshot_visual_boss",
			self,
			_capturar_snapshot_visual_boss(sequencia_snapshot_visual_rede)
		)


func _capturar_snapshot_visual_boss(sequencia: int = 0) -> Dictionary:
	var estados: Dictionary = {}
	for propriedade in ESTADOS_BOSS_REDE:
		if _possui_propriedade_rede(propriedade):
			estados[propriedade] = get(propriedade)
	var visuais: Array[Dictionary] = []
	for candidato in find_children("*", "CanvasItem", true, false):
		var item := candidato as CanvasItem
		if not is_instance_valid(item) or item is CollisionShape2D or item is RemoteTransform2D:
			continue
		if item.is_in_group("visual_boss_local"):
			continue # A pose e o material do clone são reconstruídos no renderizador local.
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
		if item is Polygon2D:
			dados["color"] = (item as Polygon2D).color
		if item is Line2D:
			dados["default_color"] = (item as Line2D).default_color
		if item is Sprite2D and (item as Sprite2D).texture:
			dados["textura"] = (item as Sprite2D).texture.resource_path
		if item is AnimatedSprite2D:
			var sprite := item as AnimatedSprite2D
			dados["sprite_animacao"] = sprite.animation
			dados["sprite_frame"] = sprite.frame
			dados["sprite_progresso"] = sprite.frame_progress
			dados["sprite_tocando"] = sprite.is_playing()
		if item.material is ShaderMaterial:
			var shader_material := item.material as ShaderMaterial
			var parametros: Dictionary = {}
			if shader_material.shader:
				for uniforme in shader_material.shader.get_shader_uniform_list():
					var nome: StringName = uniforme.get("name", &"")
					if not nome.is_empty():
						var valor: Variant = shader_material.get_shader_parameter(nome)
						if (
							typeof(valor)
							in [
								TYPE_BOOL,
								TYPE_INT,
								TYPE_FLOAT,
								TYPE_VECTOR2,
								TYPE_VECTOR3,
								TYPE_VECTOR4,
								TYPE_COLOR
							]
						):
							parametros[nome] = valor
			dados["shader_parametros"] = parametros
		if item is GPUParticles2D:
			dados["emitting"] = (item as GPUParticles2D).emitting
		if item is Line2D:
			dados["points"] = (item as Line2D).points
		visuais.append(dados)
	var animacoes: Array[Dictionary] = []
	for candidato in find_children("*", "AnimationPlayer", true, false):
		var reprodutor := candidato as AnimationPlayer
		if is_instance_valid(reprodutor) and not reprodutor.current_animation.is_empty():
			(
				animacoes
				. append(
					{
						"caminho": get_path_to(reprodutor),
						"animacao": reprodutor.current_animation,
						"posicao": reprodutor.current_animation_position,
						"tocando": reprodutor.is_playing(),
					}
				)
			)
	var pacote := {
		"sequencia": sequencia, "estados": estados, "visuais": visuais, "animacoes": animacoes
	}
	return pacote


@rpc("authority", "call_remote", "unreliable_ordered", 0)
func _aplicar_snapshot_visual_boss(snapshot: Dictionary) -> void:
	if multiplayer.is_server():
		return
	var sequencia := int(snapshot.get("sequencia", 0))
	if sequencia > 0 and sequencia <= ultima_sequencia_snapshot_visual_rede:
		return
	if sequencia > 0:
		ultima_sequencia_snapshot_visual_rede = sequencia
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
		if item is Polygon2D and dados.has("color"):
			(item as Polygon2D).color = dados["color"]
		if item is Line2D and dados.has("default_color"):
			(item as Line2D).default_color = dados["default_color"]
		if item is Sprite2D and dados.has("textura"):
			var caminho_textura := str(dados["textura"])
			if caminho_textura.begins_with("res://") and ResourceLoader.exists(caminho_textura):
				(item as Sprite2D).texture = load(caminho_textura) as Texture2D
		if item is AnimatedSprite2D and dados.has("sprite_animacao"):
			var sprite := item as AnimatedSprite2D
			var nome_animacao: StringName = dados["sprite_animacao"]
			if sprite.sprite_frames and sprite.sprite_frames.has_animation(nome_animacao):
				if sprite.animation != nome_animacao:
					sprite.animation = nome_animacao
				var total_quadros := sprite.sprite_frames.get_frame_count(nome_animacao)
				var quadro := clampi(
					int(dados.get("sprite_frame", 0)), 0, maxi(total_quadros - 1, 0)
				)
				sprite.set_frame_and_progress(quadro, float(dados.get("sprite_progresso", 0.0)))
				if bool(dados.get("sprite_tocando", false)):
					if not sprite.is_playing():
						sprite.play()
				elif sprite.is_playing():
					sprite.pause()
		if item.material is ShaderMaterial and dados.has("shader_parametros"):
			var shader_material := item.material as ShaderMaterial
			for parametro in Dictionary(dados["shader_parametros"]):
				shader_material.set_shader_parameter(
					parametro, dados["shader_parametros"][parametro]
				)
		if item is GPUParticles2D and dados.has("emitting"):
			(item as GPUParticles2D).emitting = bool(dados["emitting"])
		if item is Line2D and dados.has("points"):
			(item as Line2D).points = dados["points"]
	for dados_variant in Array(snapshot.get("animacoes", [])):
		var dados := Dictionary(dados_variant)
		var reprodutor := (
			get_node_or_null(NodePath(str(dados.get("caminho", "")))) as AnimationPlayer
		)
		if not is_instance_valid(reprodutor):
			continue
		var animacao := StringName(dados.get("animacao", &""))
		if bool(dados.get("tocando", false)):
			if reprodutor.current_animation != animacao or not reprodutor.is_playing():
				reprodutor.play(animacao)
		elif reprodutor.is_playing():
			reprodutor.pause()
		var posicao := float(dados.get("posicao", 0.0))
		if absf(reprodutor.current_animation_position - posicao) > 0.16:
			reprodutor.seek(posicao, true)
	queue_redraw()


func _possui_propriedade_rede(nome: StringName) -> bool:
	return nome in self


# Cada datagrama fica abaixo do MTU, inclusive quando uma Line2D tem muitos pontos.
# Quadros incompletos expiram ao chegar uma sequencia mais nova.
const LIMITE_SNAPSHOT_BYTES := 900
const MAX_PARTES_SNAPSHOT := 256
var partes_snapshot: Dictionary = {}
var sequencia_em_montagem := -1
var total_partes_esperado := 0


func dividir_snapshot_visual(snapshot: Dictionary) -> Array[Dictionary]:
	var partes: Array[Dictionary] = []
	var bytes := var_to_bytes(snapshot).compress(FileAccess.COMPRESSION_DEFLATE)
	var total := ceili(float(bytes.size()) / LIMITE_SNAPSHOT_BYTES)
	if total > MAX_PARTES_SNAPSHOT:
		push_warning("Snapshot visual excede o limite de seguranca")
		return partes
	for indice in total:
		(
			partes
			. append(
				{
					"sequencia": snapshot["sequencia"],
					"indice": indice,
					"total": total,
					"bytes":
					bytes.slice(
						indice * LIMITE_SNAPSHOT_BYTES, (indice + 1) * LIMITE_SNAPSHOT_BYTES
					),
				}
			)
		)
	return partes


func receber_parte_snapshot_visual(pacote: Dictionary) -> void:
	if multiplayer.is_server():
		return
	var sequencia := int(pacote.get("sequencia", -1))
	var indice := int(pacote.get("indice", -1))
	var total := int(pacote.get("total", 0))
	var bytes: PackedByteArray = pacote.get("bytes", PackedByteArray())
	if total < 1 or total > MAX_PARTES_SNAPSHOT or indice < 0 or indice >= total:
		return
	if bytes.size() > LIMITE_SNAPSHOT_BYTES or sequencia <= ultima_sequencia_snapshot_visual_rede:
		return
	if sequencia < sequencia_em_montagem:
		return
	if sequencia > sequencia_em_montagem:
		partes_snapshot.clear()
		sequencia_em_montagem = sequencia
		total_partes_esperado = total
	if total != total_partes_esperado:
		return
	partes_snapshot[indice] = bytes
	if partes_snapshot.size() != total:
		return
	var completo := PackedByteArray()
	for i in total:
		completo.append_array(partes_snapshot[i])
	partes_snapshot.clear()
	var descompactado := completo.decompress_dynamic(4 * 1024 * 1024, FileAccess.COMPRESSION_DEFLATE)
	if descompactado.is_empty():
		return
	var snapshot: Variant = bytes_to_var(descompactado)
	if snapshot is Dictionary and int(snapshot.get("sequencia", -1)) == sequencia:
		_aplicar_snapshot_visual_boss(snapshot)
