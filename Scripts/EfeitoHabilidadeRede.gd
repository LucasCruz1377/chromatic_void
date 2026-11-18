extends Node2D
class_name EfeitoHabilidadeRede


var alvo: Player
var habilidade_id: StringName
var cor := Color(0.45, 0.9, 1.0)
var icone: Texture2D
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
	queue_redraw()
	if tempo >= duracao:
		queue_free()


func _draw() -> void:
	var progresso := clampf(tempo / duracao, 0.0, 1.0)
	var alpha := pow(1.0 - progresso, 1.4)
	var raio := lerpf(26.0, 72.0, progresso)
	draw_circle(Vector2.ZERO, raio, Color(cor.r, cor.g, cor.b, alpha * 0.10))
	match habilidade_id:
		&"hiperdash":
			for indice in 4:
				var y := float(indice - 2) * 9.0
				draw_line(Vector2(-95.0 - indice * 12.0, y), Vector2(-20.0, y), Color(cor.r, cor.g, cor.b, alpha), 4.0 - indice * 0.55, true)
		&"foco_absoluto":
			for indice in 3:
				draw_arc(Vector2.ZERO, raio - indice * 12.0, progresso * TAU + indice, progresso * TAU + indice + PI * 1.4, 28, Color(cor.r, cor.g, cor.b, alpha), 2.5, true)
		&"transfusao":
			for indice in 3:
				draw_arc(Vector2.ZERO, 30.0 + indice * 8.0, -PI * 0.8, PI * 0.8, 24, Color(cor.r, cor.g, cor.b, alpha), 3.0, true)
		&"escudo_protetor":
			draw_circle(Vector2.ZERO, 43.0, Color(cor.r, cor.g, cor.b, alpha * 0.15))
			draw_arc(Vector2.ZERO, 43.0, 0.0, TAU, 48, Color(cor.r, cor.g, cor.b, alpha), 4.0, true)
		&"abraco_materno", &"aura_serenidade":
			draw_arc(Vector2.ZERO, raio, 0.0, TAU, 48, Color(cor.r, cor.g, cor.b, alpha), 3.0, true)
			draw_line(Vector2(-11, 0), Vector2(11, 0), Color(1, 1, 1, alpha), 4.0)
			draw_line(Vector2(0, -11), Vector2(0, 11), Color(1, 1, 1, alpha), 4.0)
		_:
			draw_arc(Vector2.ZERO, raio, 0.0, TAU, 48, Color(cor.r, cor.g, cor.b, alpha), 3.0, true)
	if is_instance_valid(icone):
		var tamanho := 34.0 * (1.0 + sin(progresso * PI) * 0.18)
		draw_texture_rect(
			icone,
			Rect2(Vector2(-tamanho * 0.5, -70.0 - tamanho * 0.5), Vector2.ONE * tamanho),
			false,
			Color(1.0, 1.0, 1.0, alpha)
		)
