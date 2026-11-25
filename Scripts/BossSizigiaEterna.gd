extends "res://Scripts/ChefeBase.gd"
class_name BossSizigiaEterna


const SHADER_TRANSICAO = preload("res://FX/eclipse_transicao.gdshader")
const TEXTURA_LUA = preload("res://Assets/Bosses/SizigiaEterna/lua.svg")
const TEXTURA_SOL = preload("res://Assets/Bosses/SizigiaEterna/sol.svg")
const TEXTURA_ECLIPSE = preload("res://Assets/Bosses/SizigiaEterna/eclipse.svg")


signal fase_alterada(fase: int)
signal subtitulo_alterado(texto: String)


enum Fase {
	LUA = 1,
	SOL = 2,
	ECLIPSE = 3,
}

enum Estado {
	MOVENDO,
	AVISANDO,
	INVESTINDO,
	RECUPERANDO,
	TRANSICAO,
}


# No quinto setor (×1,64), uma nave com ~24 DPS efetivos leva 164 / 179 / 195 s.
const VIDA_BASE_FASES := [2400.0, 2625.0, 2850.0]
const DANO_RELATIVO_FASE := [1.0, 1.15, 1.35]
const MARGEM_FORA_TELA := 150.0
const CORES_FASES := [
	Color(0.58, 0.72, 1.0),
	Color(1.0, 0.56, 0.12),
	Color(0.88, 0.42, 1.0),
]


var fase_atual := Fase.LUA
var estado := Estado.MOVENDO
var vidas_fases := VIDA_BASE_FASES.duplicate()
var dificuldade_atual := 1
var tempo_ataque := 1.2
var tempo_animacao_visual := 0.0
var passo_rotacao := 0
var absoluto_usado := false
var direcao_investida := Vector2.RIGHT
var tempo_cinema := 0.0
var destino_fase := 0
var inicio_cinema := Vector2.ZERO
var centro_cinema := Vector2.ZERO
var progresso_fusao := 0.0
var visual_lua_transicao: Sprite2D
var visual_sol_transicao: Sprite2D
var desenhar_corona_transicao := false
var overlay_transicao: CanvasLayer
var material_transicao: ShaderMaterial
var protegidos: Array[Node2D] = []
var contato: Dictionary = {}
var impacto_fusao := false

@onready var visual_fase: Sprite2D = $VisualFase
@onready var golpes: SizigiaFinalController = $SizigiaFinalController


func _ready() -> void:
	super._ready()
	add_to_group("boss_sizigia")
	configurar_dificuldade(dificuldade_atual)
	escala_base_impacto = scale
	criar_visuais_transicao()
	atualizar_visual_fase()
	queue_redraw()


func configurar_dificuldade(nivel_dificuldade: int) -> void:
	dificuldade_atual = maxi(nivel_dificuldade, 1)
	var fator_vida := 1.0 + float(dificuldade_atual - 1) * 0.16
	var fator_dano := 1.0 + float(dificuldade_atual - 1) * 0.09
	# Fixa o orçamento de vida no início. Morte e renascimento não recarregam a barra.
	var participantes := clampi(golpes.pilotos_vivos().size(), 1, 4) if Rede.modo_multiplayer else 1
	vidas_fases = []
	for vida_base in VIDA_BASE_FASES:
		vidas_fases.append(roundf(float(vida_base) * fator_vida * participantes))
	Dano = 42.0 * fator_dano * float(DANO_RELATIVO_FASE[fase_atual - 1])
	VidaMaxima = vidas_fases[fase_atual - 1]
	Vida = VidaMaxima
	vida_alterada.emit(Vida, VidaMaxima)


func obter_vida_maxima_atual() -> float:
	return VidaMaxima


func obter_nome_boss() -> String:
	match fase_atual:
		Fase.LUA:
			return "LUA DA SIZÍGIA"
		Fase.SOL:
			return "SOL DA SIZÍGIA"
		_:
			return "SIZÍGIA ETERNA — ECLIPSE ABSOLUTO"


func obter_subtitulo_boss() -> String:
	if is_instance_valid(golpes) and golpes.tipo != golpes.Golpe.NENHUM:
		return golpes.NOMES[golpes.tipo]
	match fase_atual:
		Fase.LUA:
			return "MARÉS, CRATERAS E A FACE OCULTA"
		Fase.SOL:
			return "CORONA INCANDESCENTE — QUEIMADURA NÃO ACUMULA"
		_:
			return "TOTALIDADE — SOBREVIVA À UNIÃO DOS ASTROS"


func obter_cor_fase() -> Color:
	return CORES_FASES[fase_atual - 1]


func tomarDano(valor: float) -> void:
	if Rede.modo_multiplayer and not multiplayer.is_server():
		_solicitar_dano_ao_host.rpc_id(1, clampf(valor, 0.0, 10000.0))
		return
	if morto or estado == Estado.TRANSICAO or valor <= 0.0:
		return
	if golpes.absorvendo():
		golpes.energia = minf(golpes.energia + valor, 40.0)
		return
	var dano_final := maxf(valor * bonus_marca * multiplicador_dano_recebido, 0.0)
	Vida = maxf(Vida - dano_final, 0.0)
	vida_alterada.emit(Vida, obter_vida_maxima_atual())
	reproduzir_impacto(dano_final)
	if Vida > 0.0:
		return
	if fase_atual < Fase.ECLIPSE:
		iniciar_transicao(fase_atual + 1)
	else:
		morrer()


func obter_velocidade_maxima() -> float:
	return 560.0 if estado == Estado.INVESTINDO else Velocidade


func Mover(delta: float) -> void:
	tempo_animacao_visual += delta
	if destino_fase != 0:
		velocity = Vector2.ZERO
		return
	atualizar_animacao_visual(delta)
	golpes.registrar_trajetorias(delta)
	if golpes.tipo != golpes.Golpe.NENHUM:
		golpes.avancar(delta)
		velocity = Vector2.ZERO
		if estado == Estado.INVESTINDO:
			var limite := Global.obter_retangulo_area_visivel().grow(-2.0)
			var proxima := global_position + direcao_investida * 560.0 * delta
			velocity = (proxima.clamp(limite.position, limite.end) - global_position) / maxf(delta, 0.0001)
	else:
		estado = Estado.MOVENDO
		if is_instance_valid(player):
			var radial := global_position.direction_to(player.global_position)
			var distancia := global_position.distance_to(player.global_position)
			velocity = (radial * clampf((distancia - 270.0) / 90.0, -1, 1) + radial.orthogonal() * 0.45).normalized() * Velocidade
		tempo_ataque -= delta
		if tempo_ataque <= 0 and is_instance_valid(player):
			golpes.escolher()
	for piloto in golpes.pilotos_vivos():
		var chave := piloto.get_instance_id()
		contato[chave] = maxf(float(contato.get(chave, 0.0)) - delta, 0.0)
		var raio := 74.0 if fase_atual == Fase.ECLIPSE else 62.0
		if piloto.global_position.distance_to(global_position) <= raio:
			ao_colidir_com_player(piloto)
	queue_redraw()


func ao_colidir_com_player(piloto: Node) -> void:
	if not piloto is Node2D or destino_fase or morto or golpes.exposto() or (Rede.modo_multiplayer and not multiplayer.is_server()):
		return
	var chave := piloto.get_instance_id()
	if float(contato.get(chave, 0.0)) <= 0.0:
		contato[chave] = 0.85
		golpes.ferir(piloto, Dano * 0.64, global_position)


func _capturar_snapshot_visual_boss(seq: int = 0) -> Dictionary:
	var pacote := super._capturar_snapshot_visual_boss(seq)
	pacote["golpe"] = golpes.snapshot()
	pacote["sombra"] = golpes.snapshot_sombra()
	pacote["cinema"] = [destino_fase, tempo_cinema, inicio_cinema, centro_cinema]
	return pacote


@rpc("authority", "call_remote", "unreliable_ordered", 0)
func _aplicar_snapshot_visual_boss(pacote: Dictionary) -> void:
	if multiplayer.is_server() or int(pacote.get("sequencia", 0)) <= ultima_sequencia_snapshot_visual_rede:
		return
	super._aplicar_snapshot_visual_boss(pacote)
	if pacote.has("golpe"):
		golpes.receber(pacote.golpe)
	if pacote.has("sombra"):
		golpes.receber_sombra(pacote.sombra)
	if pacote.has("cinema"):
		var dados: Array = pacote.cinema
		var anterior := destino_fase
		destino_fase = dados[0]
		tempo_cinema = dados[1]
		inicio_cinema = dados[2]
		centro_cinema = dados[3]
		if anterior != destino_fase:
			impacto_fusao = false
			proteger_player(destino_fase != 0)
		if destino_fase:
			desenhar_cinema()
		elif anterior:
			visual_fase.position = Vector2.ZERO
			remover_overlay_transicao()
			atualizar_visual_fase()
	queue_redraw()


func iniciar_transicao(proxima_fase: int) -> void:
	golpes.encerrar()
	impacto_fusao = false
	destino_fase = proxima_fase
	tempo_cinema = 0
	estado = Estado.TRANSICAO
	velocity = Vector2.ZERO
	inicio_cinema = global_position
	var area := Global.obter_retangulo_area_visivel()
	centro_cinema = area.position + area.size * Vector2(0.5, 188.0 / 540.0)
	for piloto in golpes.pilotos_vivos():
		if piloto.has_method("conceder_cura_rede"):
			piloto.conceder_cura_rede(float(piloto.VIDA_MAXIMA) * 0.10)
		elif piloto.has_method("curar"):
			piloto.curar(float(piloto.VIDA_MAXIMA) * 0.10)
	proteger_player(true)
	desenhar_cinema()


func proteger_player(ativar: bool) -> void:
	if ativar:
		for piloto in golpes.pilotos_vivos():
			if Rede.modo_multiplayer and not piloto.is_multiplayer_authority():
				continue
			if "protegido_por_sizigia" in piloto and not protegidos.has(piloto):
				protegidos.append(piloto)
				piloto.protegido_por_sizigia = true
	else:
		for piloto in protegidos:
			if is_instance_valid(piloto):
				piloto.protegido_por_sizigia = false
		protegidos.clear()


func _process(delta: float) -> void:
	super._process(delta)
	if destino_fase == 0:
		return
	tempo_cinema += delta
	desenhar_cinema()
	if Rede.modo_multiplayer and not multiplayer.is_server():
		return
	if destino_fase == Fase.SOL and tempo_cinema >= 2.65:
		concluir_transicao_para_sol()
	elif destino_fase == Fase.ECLIPSE and tempo_cinema >= 4.9:
		concluir_transicao_para_eclipse()


func desenhar_cinema() -> void:
	var area := Global.obter_retangulo_area_visivel()
	var esquerda := Vector2(area.position.x - MARGEM_FORA_TELA, centro_cinema.y)
	var direita := Vector2(area.end.x + MARGEM_FORA_TELA, centro_cinema.y)
	var t := tempo_cinema
	visual_fase.visible = false
	visual_lua_transicao.visible = true
	visual_sol_transicao.visible = true
	desenhar_corona_transicao = true
	var lua := visual_lua_transicao
	var sol := visual_sol_transicao
	if destino_fase == Fase.SOL:
		var partida := smoothstep(0.25, 1.2, t)
		lua.global_position = inicio_cinema.lerp(esquerda, partida) + Vector2.UP * sin(PI * partida) * 54.0
		lua.scale = Vector2(0.55 + partida * 0.20, 0.55 - partida * 0.26)
		lua.rotation = -partida * 0.45
		sol.global_position = direita.lerp(inicio_cinema, smoothstep(1.25, 2.6, t))
	else:
		if not is_instance_valid(overlay_transicao):
			criar_overlay_transicao()
		var recuo := smoothstep(0.08, 0.9, t)
		var encontro := smoothstep(0.95, 2.2, t)
		var uniao := smoothstep(2.25, 3.85, t)
		var asa := minf(area.size.x * 0.18, 145.0)
		var lateral := Vector2(asa * (1.0 - uniao), -sin(PI * uniao) * 42.0)
		sol.global_position = inicio_cinema.lerp(direita, recuo).lerp(centro_cinema + lateral, encontro)
		lua.global_position = esquerda.lerp(centro_cinema - lateral, encontro)
		lua.scale = Vector2.ONE * 0.51
		lua.rotation = -uniao * 0.28
		sol.rotation = recuo * (1.0 - encontro) * 0.8
		progresso_fusao = uniao
		material_transicao.set_shader_parameter("centro", (get_canvas_transform() * centro_cinema) / get_viewport_rect().size)
		var retorno := smoothstep(3.96, 4.9, t)
		atualizar_escuridao_shader(uniao * 0.89 * (1.0 - retorno))
		atualizar_flash_shader(0.74 * (1.0 - smoothstep(3.89, 4.10, t)) if t >= 3.85 else 0.0)
		atualizar_onda_shader(retorno)
		atualizar_forca_onda_shader(1.0 - retorno)
		if t >= 3.85 and not impacto_fusao:
			impacto_fusao = true
			preload("res://Scripts/AudioCombate.gd").tocar(self, &"explosoes", 0.0, 0.68, 0.68, -7.0)
			Global.vibrar_controle(0.65, 0.85, 0.20)
			var camera_transicao := get_viewport().get_camera_2d()
			if is_instance_valid(camera_transicao) and camera_transicao.has_method("shake"):
				camera_transicao.shake(12.0, true)
		if t >= 3.89:
			lua.hide()
			sol.hide()
			visual_fase.texture = TEXTURA_ECLIPSE
			visual_fase.scale = Vector2.ONE * (0.53 + 0.045 * (1.0 - retorno))
			visual_fase.global_position = centro_cinema
			visual_fase.show()
	queue_redraw()


func concluir_transicao_para_sol() -> void:
	finalizar_fase(Fase.SOL)


func concluir_transicao_para_eclipse() -> void:
	global_position = centro_cinema
	visual_fase.position = Vector2.ZERO
	finalizar_fase(Fase.ECLIPSE)


func finalizar_fase(fase: int) -> void:
	destino_fase = 0
	remover_overlay_transicao()
	# Preserva os multiplicadores de setor e da arena aplicados ao chefe na criação.
	Dano *= float(DANO_RELATIVO_FASE[fase - 1]) / float(DANO_RELATIVO_FASE[fase_atual - 1])
	fase_atual = fase
	VidaMaxima = vidas_fases[fase - 1]
	Vida = VidaMaxima
	Velocidade = 118.0 if fase == Fase.SOL else 128.0
	estado = Estado.MOVENDO
	passo_rotacao = 0
	tempo_ataque = 1.25
	proteger_player(false)
	atualizar_visual_fase()
	fase_alterada.emit(fase)
	subtitulo_alterado.emit(obter_subtitulo_boss())
	vida_alterada.emit(Vida, VidaMaxima)


func criar_overlay_transicao() -> void:
	# Limpa somente uma camada antiga. Durante a fusão, remover também os
	# visuais de transição criava um quadro vazio justamente quando a tela
	# começava a escurecer.
	if is_instance_valid(overlay_transicao):
		overlay_transicao.queue_free()
	overlay_transicao = null
	material_transicao = null
	overlay_transicao = CanvasLayer.new()
	overlay_transicao.layer = 70
	get_tree().current_scene.add_child(overlay_transicao)
	var tela := ColorRect.new()
	tela.mouse_filter = Control.MOUSE_FILTER_IGNORE
	material_transicao = ShaderMaterial.new()
	material_transicao.shader = SHADER_TRANSICAO

	tela.material = material_transicao
	overlay_transicao.add_child(tela)
	tela.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	atualizar_escuridao_shader(0.0)
	atualizar_onda_shader(0.0)
	atualizar_forca_onda_shader(0.0)
	atualizar_flash_shader(0.0)


func atualizar_onda_shader(valor: float) -> void:
	if is_instance_valid(material_transicao):
		material_transicao.set_shader_parameter("onda_progresso", valor)


func atualizar_escuridao_shader(valor: float) -> void:
	if is_instance_valid(material_transicao):
		material_transicao.set_shader_parameter("escuridao", valor)


func atualizar_forca_onda_shader(valor: float) -> void:
	if is_instance_valid(material_transicao):
		material_transicao.set_shader_parameter("onda_forca", valor)


func atualizar_flash_shader(valor: float) -> void:
	if is_instance_valid(material_transicao):
		material_transicao.set_shader_parameter("flash", valor)


func remover_overlay_transicao() -> void:
	if is_instance_valid(overlay_transicao):
		overlay_transicao.queue_free()
	overlay_transicao = null
	material_transicao = null
	ocultar_visuais_transicao()


func atualizar_colisao_visual() -> void:
	var circulo := $CollisionShape2D.shape as CircleShape2D
	var raio_textura := 108.0
	if visual_fase.texture == TEXTURA_SOL:
		raio_textura = 124.0
	elif visual_fase.texture == TEXTURA_ECLIPSE:
		raio_textura = 126.0
	circulo.radius = raio_textura * visual_fase.scale.x


func morrer() -> void:
	if Rede.modo_multiplayer and not multiplayer.is_server():
		return
	if Vida > 0.0:
		return
	set_meta("som_morte_personalizado", true)
	preload("res://Scripts/AudioCombate.gd").tocar_posicional(
		get_tree().current_scene,
		global_position,
		&"morte_sizigia",
		0.0,
		0.96,
		1.04,
		0.0
	)
	golpes.encerrar()
	proteger_player(false)
	remover_overlay_transicao()
	super.morrer()


func _exit_tree() -> void:
	golpes.encerrar()
	if fase_atual == Fase.ECLIPSE or estado == Estado.TRANSICAO:
		proteger_player(false)
	remover_overlay_transicao()
	for sprite in [visual_lua_transicao, visual_sol_transicao]:
		if is_instance_valid(sprite):
			sprite.queue_free()


func _draw() -> void:
	if destino_fase == 0 and fase_atual == Fase.SOL and visual_fase.visible:
		desenhar_corona_sol(Vector2.ZERO, 1.0, 1.0)
	if (
		desenhar_corona_transicao
		and is_instance_valid(visual_sol_transicao)
		and visual_sol_transicao.visible
	):
		desenhar_corona_sol(to_local(visual_sol_transicao.global_position), 0.96, 0.82)
	if destino_fase:
		var t := tempo_cinema
		var solar := destino_fase == Fase.ECLIPSE
		var centro := to_local(inicio_cinema)
		var partida := clampf(t / 1.05, 0, 1)
		for i in 12:
			var eixo := Vector2.from_angle(TAU * i / 12.0 + partida * 0.45)
			var ponta := centro + eixo * (52 + partida * 98)
			var cor := Color(1, 0.62, 0.20, 1.0 - partida) if solar else Color(0.64, 0.85, 1, 1.0 - partida)
			draw_line(ponta - eixo * (4 + partida * 15), ponta, cor, 2.5, true)
		if solar and t >= 2.2 and t < 4.4:
			var uniao := smoothstep(2.2, 3.85, t)
			var cor := Color(1, 0.80, 0.51, uniao * (1.0 - smoothstep(3.85, 4.4, t)))
			for i in 3:
				var a := i * TAU / 3 + uniao * 2.8
				draw_arc(to_local(centro_cinema), 106 - uniao * 43 + i * 3, a, a + 1.8, 32, cor, 2, true)


func atualizar_visual_fase() -> void:
	if not is_instance_valid(visual_fase):
		return
	match fase_atual:
		Fase.LUA:
			visual_fase.texture = TEXTURA_LUA
			visual_fase.scale = Vector2.ONE * 0.55
		Fase.SOL:
			visual_fase.texture = TEXTURA_SOL
			visual_fase.scale = Vector2.ONE * 0.51
		_:
			visual_fase.texture = TEXTURA_ECLIPSE
			visual_fase.scale = Vector2.ONE * 0.53
	visual_fase.visible = true
	atualizar_colisao_visual()
	visual_fase.self_modulate = (
		Color(1.92, 1.58, 2.14, 1.0)
		if fase_atual == Fase.ECLIPSE
		else Color(1.42, 1.42, 1.42, 1.0)
	)


func atualizar_animacao_visual(delta: float) -> void:
	queue_redraw()
	if not is_instance_valid(visual_fase) or not visual_fase.visible:
		return
	var escala_base := 0.55 if fase_atual == Fase.LUA else (0.51 if fase_atual == Fase.SOL else 0.53)
	var velocidade_pulso := 3.8 if fase_atual == Fase.SOL else 3.2
	var amplitude_pulso := 0.032 if fase_atual == Fase.SOL else 0.018
	var pulso := 1.0 + sin(tempo_animacao_visual * velocidade_pulso) * amplitude_pulso
	visual_fase.scale = Vector2.ONE * escala_base * pulso
	atualizar_colisao_visual()
	if fase_atual == Fase.SOL:
		# O núcleo pontudo novo permanece legível enquanto a coroa externa gira e
		# pulsa como na versão antiga.
		visual_fase.rotation = sin(tempo_animacao_visual * 0.72) * 0.035
	elif fase_atual == Fase.ECLIPSE:
		visual_fase.rotation -= 0.10 * delta


func desenhar_corona_sol(posicao: Vector2, escala: float, alpha: float) -> void:
	# Recupera a animação geométrica antiga: raios independentes, tamanhos
	# oscilantes, dois sentidos de rotação e halo pulsante. O centro é o SVG novo.
	var pulso := 1.0 + sin(tempo_animacao_visual * 2.1) * 0.055
	draw_circle(posicao, 69.0 * escala * pulso, Color(1.0, 0.30, 0.035, 0.10 * alpha))
	for indice in 16:
		var angulo := TAU * float(indice) / 16.0 + tempo_animacao_visual * 0.18
		var tamanho := 67.0 + sin(tempo_animacao_visual * 2.1 + float(indice)) * 7.0
		draw_line(
			posicao + Vector2.from_angle(angulo) * 54.0 * escala,
			posicao + Vector2.from_angle(angulo) * tamanho * escala,
			Color(1.0, 0.36, 0.06, 0.70 * alpha),
			4.0 * escala,
			true
		)
	for indice in 8:
		var angulo_interno := TAU * float(indice) / 8.0 - tempo_animacao_visual * 0.11
		var inicio := posicao + Vector2.from_angle(angulo_interno) * 58.0 * escala
		var fim := posicao + Vector2.from_angle(angulo_interno) * 72.0 * escala
		draw_line(inicio, fim, Color(1.0, 0.76, 0.18, 0.34 * alpha), 2.0 * escala, true)
	draw_arc(
		posicao,
		57.0 * escala * pulso,
		0.0,
		TAU,
		48,
		Color(1.0, 0.91, 0.42, 0.62 * alpha),
		2.5 * escala,
		true
	)


func criar_visuais_transicao() -> void:
	visual_lua_transicao = criar_sprite_transicao(TEXTURA_LUA, 0.55)
	visual_sol_transicao = criar_sprite_transicao(TEXTURA_SOL, 0.51)
	visual_lua_transicao.z_index = 7


func criar_sprite_transicao(textura: Texture2D, escala: float) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = textura
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.scale = Vector2.ONE * escala
	sprite.self_modulate = Color(1.42, 1.42, 1.42, 1.0)
	sprite.z_index = 5
	sprite.visible = false
	get_tree().current_scene.add_child(sprite)
	return sprite


func ocultar_visuais_transicao() -> void:
	desenhar_corona_transicao = false
	for sprite in [visual_lua_transicao, visual_sol_transicao]:
		if is_instance_valid(sprite):
			sprite.visible = false
	queue_redraw()

