extends Node2D
class_name RastroExclusivo


const CORES_ARCO_IRIS := [
	Color("ff4f68"), Color("ffb83f"), Color("fff45a"),
	Color("58f58b"), Color("42dfff"), Color("7280ff"), Color("db59ff"),
]

var alvo: Node2D
var tipo: StringName = &""
var cor_base := Color.WHITE
var ativo := false
var pontos: Array[Dictionary] = []
var acumulador := 0.0
var duracao := 0.9


func configurar(novo_alvo: Node2D, novo_tipo: StringName, nova_cor: Color) -> void:
	if tipo != novo_tipo:
		pontos.clear()
	alvo = novo_alvo
	tipo = novo_tipo
	cor_base = nova_cor
	duracao = 1.15 if tipo == &"fspeed" else 0.82
	set_as_top_level(true)
	global_position = Vector2.ZERO
	z_index = 2
	process_mode = Node.PROCESS_MODE_ALWAYS


func definir_estado(novo_ativo: bool, nova_cor: Color) -> void:
	ativo = novo_ativo
	cor_base = nova_cor


func _process(delta: float) -> void:
	if not is_instance_valid(alvo):
		queue_free()
		return
	for ponto in pontos:
		ponto["idade"] = float(ponto.get("idade", 0.0)) + delta
	while not pontos.is_empty() and float(pontos[0].get("idade", 0.0)) > duracao:
		pontos.pop_front()
	acumulador += delta
	if ativo and alvo.visible and acumulador >= 0.035:
		acumulador = 0.0
		var origem := alvo.global_position - Vector2(25.0, 0.0).rotated(alvo.global_rotation)
		if pontos.is_empty() or Vector2(pontos.back()["posicao"]).distance_to(origem) >= 3.0:
			pontos.append({"posicao": origem, "idade": 0.0})
			if pontos.size() > 42:
				pontos.pop_front()
	queue_redraw()


func _draw() -> void:
	if pontos.size() < 2:
		return
	for indice in range(1, pontos.size()):
		var anterior := Vector2(pontos[indice - 1]["posicao"])
		var atual := Vector2(pontos[indice]["posicao"])
		if anterior.distance_to(atual) > 110.0:
			continue
		var idade := float(pontos[indice]["idade"])
		var alpha := clampf(1.0 - idade / duracao, 0.0, 1.0)
		var direcao := (atual - anterior).normalized()
		var normal := Vector2(-direcao.y, direcao.x)
		if tipo == &"spectrum":
			for faixa in CORES_ARCO_IRIS.size():
				var deslocamento := (float(faixa) - 3.0) * 2.25
				var cor := CORES_ARCO_IRIS[faixa]
				cor.a = alpha * 0.88
				draw_line(anterior + normal * deslocamento, atual + normal * deslocamento, cor, 3.2, true)
		else:
			if indice % 3 == 0:
				continue
			var marca := cor_base.darkened(0.62)
			marca.a = alpha * 0.78
			for lado in [-1.0, 1.0]:
				draw_line(anterior + normal * 8.0 * lado, atual + normal * 8.0 * lado, marca, 4.2, true)
