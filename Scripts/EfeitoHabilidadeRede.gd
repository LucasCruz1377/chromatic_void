extends Node2D
class_name EfeitoHabilidadeRede


var alvo: Player
var habilidade_id: StringName
var cor := Color(0.45, 0.9, 1.0)
var icone: Texture2D
var poses: Array[Transform2D] = []
var intervalo_pose := 0.0
var tempo := 0.0
var duracao := 0.9


static func criar(
	pai: Node, player_ref: Player, id_ref: StringName, cor_ref: Color,
	caminho_icone: String = "", duracao_ref: float = 0.9
) -> EfeitoHabilidadeRede:
	var efeito := EfeitoHabilidadeRede.new()
	efeito.alvo = player_ref
	efeito.habilidade_id = id_ref
	efeito.cor = cor_ref
	efeito.duracao = maxf(duracao_ref, 0.35)
	if not caminho_icone.is_empty() and ResourceLoader.exists(caminho_icone):
		efeito.icone = load(caminho_icone) as Texture2D
	pai.add_child(efeito)
	efeito.z_index = 30
	efeito.global_position = player_ref.global_position
	return efeito


func _process(delta: float) -> void:
	tempo += delta
	if is_instance_valid(alvo):
		global_position = alvo.global_position
		if habilidade_id in [&"hiperdash", &"retrocesso", &"fevereiro_carnaval"]:
			intervalo_pose -= delta
			if intervalo_pose <= 0.0:
				intervalo_pose = 0.055
				if poses.is_empty() or poses.back().origin.distance_to(global_position) > 100.0:
					poses.clear()
				poses.append(alvo.global_transform)
				if poses.size() > (2 if habilidade_id == &"hiperdash" else 5):
					poses.pop_front()
	queue_redraw()
	if tempo >= duracao:
		queue_free()


func _draw() -> void:
	var progresso := clampf(tempo / duracao, 0.0, 1.0)
	var alpha := pow(1.0 - progresso, 1.4)
	var raio := lerpf(26.0, 72.0, progresso)
	var tinta := Color(cor, alpha)
	match habilidade_id:
		&"retrocesso", &"hiperdash", &"fevereiro_carnaval":
			for i in poses.size():
				var pose := poses[i]
				var centro := to_local(pose.origin)
				var eixo := pose.x.normalized()
				var lateral := eixo.orthogonal()
				var pontos := PackedVector2Array([centro - eixo * 8 + lateral * 6, centro + eixo * 12, centro - eixo * 8 - lateral * 6])
				draw_polyline(pontos, Color(cor, alpha * (i + 1.0) / poses.size()), 1.5, true)
		&"abril_azul":
			for i in 4:
				var angulo := i * PI / 2.0
				draw_arc(Vector2.ZERO, lerpf(52, 22, progresso), angulo - 0.2, angulo + 0.2, 8, tinta, 1.5, true)
		&"junho_vermelho":
			for i in 3:
				draw_arc(Vector2.ZERO, 10 + fposmod(1.0 - progresso + i / 3.0, 1.0) * 24, -0.8, 0.8, 12, tinta, 2, true)
		&"marco_lilas", &"dia_das_maes":
			for i in 2:
				var centro := PI * i
				var abertura := lerpf(0.15, PI * 0.48, progresso)
				draw_arc(Vector2.ZERO, 26 + 12 * (1.0 - progresso), centro - abertura, centro + abertura, 24, tinta, 2, true)
		&"janeiro_branco":
			draw_arc(Vector2.ZERO, 30 + 3 * sin(progresso * PI), 0, TAU, 42, Color(cor, alpha * 0.55), 1, true)
		&"festa_junina":
			for i in 3:
				draw_line(Vector2((i - 1) * 8, -8 - progresso * 18), Vector2((i - 1) * 10, -13 - progresso * 23), tinta, 2, true)
		&"onda_choque":
			draw_arc(Vector2.ZERO, raio, 0, TAU, 48, tinta, 2, true)
			draw_arc(Vector2.ZERO, raio - 5, 0, TAU, 48, Color(cor, alpha * 0.16), 5, true)
	if is_instance_valid(icone):
		var tamanho := 34.0 * (1.0 + sin(progresso * PI) * 0.18)
		draw_texture_rect(
			icone,
			Rect2(Vector2(-tamanho * 0.5, -70.0 - tamanho * 0.5), Vector2.ONE * tamanho),
			false,
			Color(1.0, 1.0, 1.0, alpha)
		)
