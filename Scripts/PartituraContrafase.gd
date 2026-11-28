extends Node2D
class_name PartituraContrafase

signal fim_da_frase

const Frase = preload("res://Scripts/FraseContrafase.gd")
const COLCHEIA = preload("res://Assets/Bosses/Contrafase/colcheia.svg")
const SEMINIMA = preload("res://Assets/Bosses/Contrafase/seminima.svg")
const CLAVE = preload("res://Assets/Bosses/Contrafase/clave_sol.svg")
const CORDA = preload("res://sounds/Bosses/contrafase_corda.wav")
const BUMBO = preload("res://sounds/Bosses/contrafase_bumbo.wav")
const TINTAS := [Color("#ff9ccc"), Color("#dac1ff"), Color("#8bebed"), Color("#ffce88")]
const ROSA := Color("#f285bb")
const MARFIM := Color("#ffe3ba")
const ORDEM_CAIXAS := [0, 3, 1, 2]
const FECHAMENTO := 0.64
const ANCORAGEM := Vector2(8, 25)

var frase := Frase.new(1)
var ativa := false
var volta := 0
var tempo := 0.0
var origem := Vector2.ZERO
var dano := 0.0
var area := Rect2()
var ajuste_relogio := 0.0
var voz: AudioStreamPlayer
var bumbo: AudioStreamPlayer
var musica: AudioStreamPlayer2D
var volume_anterior := 0.0
var nota_soando := -1
var ultimo_grave := -1
var atingidos: Dictionary = {}
var encostados: Dictionary = {}
var protegido_ate: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	voz = AudioStreamPlayer.new()
	bumbo = AudioStreamPlayer.new()
	voz.stream = CORDA
	bumbo.stream = BUMBO
	voz.bus = &"Music"
	bumbo.bus = &"Music"
	bumbo.volume_db = -8.0
	add_child(voz)
	add_child(bumbo)
	set_physics_process(false)


func iniciar(numero: int, fase: int, pos: Vector2, dano_nota: float, instante: float) -> void:
	if ativa:
		encerrar()
	volta = numero
	frase = Frase.new(fase)
	origem = pos
	dano = dano_nota
	tempo = clampf(instante, 0.0, frase.duracao)
	area = Global.obter_retangulo_area_visivel()
	ajuste_relogio = 0.0
	nota_soando = -1
	ultimo_grave = -1
	atingidos.clear()
	encostados.clear()
	protegido_ate.clear()
	if is_instance_valid(owner) and is_instance_valid(owner.get_parent()):
		musica = owner.get_parent().get_node_or_null("tocarmusica") as AudioStreamPlayer2D
	if is_instance_valid(musica):
		volume_anterior = musica.volume_db
		musica.volume_db -= 26.0
	ativa = true
	show()
	add_to_group(&"partitura_ativa")
	set_physics_process(true)
	queue_redraw()


func encerrar() -> void:
	ativa = false
	if is_in_group(&"partitura_ativa"):
		remove_from_group(&"partitura_ativa")
	voz.stop()
	bumbo.stop()
	_restaurar_musica()
	set_physics_process(false)
	hide()


func _exit_tree() -> void:
	_restaurar_musica()


func _restaurar_musica() -> void:
	if is_instance_valid(musica):
		musica.volume_db = volume_anterior
	musica = null


func corrigir_tempo(instante: float) -> void:
	# Corrigir o desvio sem tocar novamente uma nota que já passou.
	var erro := instante - tempo
	if erro > 0.25:
		tempo = instante
		ajuste_relogio = 0.0
	else:
		ajuste_relogio = erro


func _physics_process(delta: float) -> void:
	if not ativa or Rede.pausa_do_host:
		return
	area = Global.obter_retangulo_area_visivel()
	var ajuste := clampf(ajuste_relogio, -delta * 0.16, delta * 0.16)
	ajuste_relogio -= ajuste
	tempo = minf(tempo + delta + ajuste, frase.duracao)
	var autoridade := not Rede.modo_multiplayer or multiplayer.is_server()
	if tempo >= frase.duracao:
		if autoridade:
			fim_da_frase.emit()
		return
	_tocar_frase()
	if autoridade:
		_testar_colisoes(delta)
	queue_redraw()


func _tocar_frase() -> void:
	var atual := -1
	for i in frase.notas.size():
		var nota := frase.notas[i]
		var idade := tempo - frase.inicio(nota.x)
		if idade < 0.0:
			break
		if idade < nota.z * frase.batida:
			atual = i
			var pitch := Frase.pitch(Frase.altura(nota, idade, volta))
			voz.pitch_scale = maxf(0.01, pitch * Engine.time_scale)
			var restante := nota.z * frase.batida - idade
			voz.volume_db = -5.0 + linear_to_db(clampf(restante / 0.055, 0.01, 1.0))
			if atual != nota_soando:
				voz.play(idade * pitch)
			break
	if atual == -1 and nota_soando >= 0:
		voz.stop()
	nota_soando = atual
	for i in range(ultimo_grave + 1, frase.graves.size()):
		var idade := tempo - frase.inicio(frase.graves[i])
		if idade < 0.0:
			break
		ultimo_grave = i
		if idade < 0.12:
			bumbo.pitch_scale = maxf(0.01, Engine.time_scale)
			bumbo.play(idade)


func _abertura() -> float:
	return minf(smoothstep(0.0, FECHAMENTO, tempo), smoothstep(0.0, 0.45, frase.duracao - tempo))


func limites_nave() -> Rect2:
	var margem := Frase.RAIO_NAVE
	var profundidade := Frase.fundo_caixa(area) * _abertura()
	return area.grow_individual(-margem, -margem - profundidade, -margem, -margem - profundidade)


func _caixa(canto: int) -> Rect2:
	var tamanho := Vector2(clampf(area.size.x * 0.15, 80.0, 168.0), Frase.fundo_caixa(area))
	var x := area.position.x if canto % 2 == 0 else area.end.x - tamanho.x
	var topo := area.position.y - tamanho.y * (1.0 - _abertura())
	var fundo := area.end.y - tamanho.y * _abertura()
	return Rect2(Vector2(x, topo if canto < 2 else fundo), tamanho)


func _canto_da_batida(i: int) -> int:
	return ORDEM_CAIXAS[(i + volta - 1) % 4]


func conter_nave(nave: CharacterBody2D, delta: float) -> void:
	var limites := limites_nave()
	var p := nave.global_position
	if delta > 0.0 and (not Rede.modo_multiplayer or nave.is_multiplayer_authority()):
		var esquerda := 1.0 - smoothstep(0.0, 42.0, p.x - limites.position.x)
		var direita := 1.0 - smoothstep(0.0, 42.0, limites.end.x - p.x)
		nave.velocity.x += (esquerda - direita) * 680.0 * delta
		for i in frase.graves.size():
			var idade := tempo - frase.inicio(frase.graves[i])
			if idade < 0.0 or idade >= 0.22:
				continue
			var canto := _canto_da_batida(i)
			var caixa := _caixa(canto)
			var alcance := absf(p.x - caixa.get_center().x) / (caixa.size.x * 0.92)
			var distancia := absf(p.y - (caixa.end.y if canto < 2 else caixa.position.y))
			var forca := (1.0 - smoothstep(0.45, 1.0, alcance)) * (1.0 - smoothstep(52.0, 180.0, distancia))
			p.y += (1.0 if canto < 2 else -1.0) * forca * sin(PI * idade / 0.22) * 105.0 * delta
	if p.x < limites.position.x:
		nave.velocity.x = maxf(0.0, nave.velocity.x)
	elif p.x > limites.end.x:
		nave.velocity.x = minf(0.0, nave.velocity.x)
	if p.y < limites.position.y:
		nave.velocity.y = maxf(64.0, nave.velocity.y)
	elif p.y > limites.end.y:
		nave.velocity.y = minf(-64.0, nave.velocity.y)
	nave.global_position = p.clamp(limites.position, limites.end)


func _testar_colisoes(delta: float) -> void:
	var pilotos: Array[Player] = []
	var limites := limites_nave()
	for candidato in get_tree().get_nodes_in_group(&"player"):
		if not candidato is Player or not candidato.vivo or candidato.is_queued_for_deletion():
			continue
		var nave := candidato as Player
		pilotos.append(nave)
		var id := nave.get_instance_id()
		var distancia := minf(nave.global_position.y - limites.position.y, limites.end.y - nave.global_position.y)
		if distancia <= 3.0 and not encostados.has(id):
			encostados[id] = true
			if tempo > FECHAMENTO + 0.12 and tempo < frase.duracao - 0.45:
				protegido_ate[id] = tempo + 0.60
				nave.tomar_dano(nave.VIDA_MAXIMA * 0.03)
		elif distancia > 7.0:
			encostados.erase(id)
	for i in frase.notas.size():
		var nota := frase.notas[i]
		var idade := tempo - frase.inicio(nota.x)
		if idade < 0.0:
			break
		if idade > frase.travessia + frase.cauda(nota) + delta:
			continue
		var caminho := frase.trecho(area, nota, idade, volta, delta)
		if caminho.is_empty():
			continue
		for nave in pilotos:
			var id := nave.get_instance_id()
			var chave := Vector2i(nave.peer_id_dono, i)
			if atingidos.has(chave) or tempo < float(protegido_ate.get(id, 0.0)):
				continue
			if _atinge(nave.global_position, caminho, nota, idade):
				atingidos[chave] = true
				protegido_ate[id] = tempo + 0.35
				nave.tomar_dano(dano, caminho[-1])


func _atinge(p: Vector2, caminho: PackedVector2Array, nota: Vector4, idade: float) -> bool:
	var escala := Frase.escala_nota(area)
	var raio := Frase.RAIO_NAVE + (3.0 if frase.cauda(nota) > 0.0 else 6.0 * escala)
	for i in range(1, caminho.size()):
		var a := caminho[i - 1]
		var b := caminho[i]
		var proximo := a if a.is_equal_approx(b) else Geometry2D.get_closest_point_to_segment(p, a, b)
		if p.distance_squared_to(proximo) <= raio * raio:
			return true
	if idade > frase.travessia:
		return false
	var cabeca := caminho[-1]
	var haste := Geometry2D.get_closest_point_to_segment(p, cabeca + Vector2(6, 0) * escala, cabeca + Vector2(6, -22) * escala)
	if p.distance_to(cabeca) <= Frase.RAIO_NAVE + 6.0 * escala or p.distance_to(haste) <= Frase.RAIO_NAVE + 1.4 * escala:
		return true
	if nota.z >= 1.0:
		return false
	var bandeira := Geometry2D.get_closest_point_to_segment(p, cabeca + Vector2(6, -21) * escala, cabeca + Vector2(12, -13) * escala)
	return p.distance_to(bandeira) <= Frase.RAIO_NAVE + 2.0 * escala


func _draw() -> void:
	if not ativa:
		return
	var abertura := _abertura()
	var inicio_x := lerpf(area.end.x, area.position.x, abertura)
	for linha in 5:
		var y := Frase.y_do_grau(area, linha * 2.0)
		draw_line(Vector2(inicio_x, y), Vector2(area.end.x, y), Color(0.72, 0.62, 0.78, 0.44 * abertura), 1.4, true)
	_desenhar_caixas()
	_desenhar_vento()
	if tempo < frase.entrada:
		var altura := (Frase.y_do_grau(area, 0) - Frase.y_do_grau(area, 8)) * 0.65
		var tamanho := Vector2(altura * 40.0 / 104.0, altura)
		var pos := Vector2(inicio_x - tamanho.x * 0.5, area.get_center().y - altura * 0.5)
		draw_texture_rect(CLAVE, Rect2(pos, tamanho), false, Color(Color.WHITE, 1.0 - smoothstep(0.8, frase.entrada, tempo)))
	for nota in frase.notas:
		var idade := tempo - frase.inicio(nota.x)
		if idade < -frase.aviso(nota):
			continue
		if idade < 0.0:
			_desenhar_aviso(nota, idade)
		elif idade <= frase.travessia + frase.cauda(nota):
			_desenhar_nota(nota, idade)
	if tempo < 0.48 or tempo > frase.duracao - 0.45:
		var progresso := tempo / 0.48 if tempo < 0.48 else (frase.duracao - tempo) / 0.45
		_desenhar_teleporte(clampf(progresso, 0.0, 1.0))


func _desenhar_aviso(nota: Vector4, idade: float) -> void:
	var y := Frase.y_do_grau(area, Frase.grau_base(nota, volta))
	var intensidade := lerpf(0.28, 1.0, smoothstep(-frase.aviso(nota), -0.05, idade))
	var pontos := PackedVector2Array()
	var segmentos := maxi(16, ceili(area.size.x / 12.0))
	for i in segmentos + 1:
		var t := float(i) / segmentos
		var x := lerpf(area.position.x, area.end.x, t)
		var onda := sin(x * 0.064 - tempo * 29.0) * (1.5 + 3.5 * t) * intensidade
		pontos.append(Vector2(x, y + onda))
	draw_polyline(pontos, Color(MARFIM, 0.14 + 0.62 * intensidade), 1.7, true)
	if int(nota.w) != Frase.Articulacao.RETA:
		var curva := PackedVector2Array()
		for i in 18:
			curva.append(frase.ponto(area, nota, i * 0.032, volta))
		draw_polyline(curva, Color(ROSA, 0.33 * intensidade), 1.5, true)


func _desenhar_nota(nota: Vector4, idade: float) -> void:
	var longa := nota.z >= 1.0
	if longa:
		var caminho := frase.trecho(area, nota, idade, volta)
		if caminho.size() >= 2 and not caminho[0].is_equal_approx(caminho[-1]):
			draw_polyline(caminho, Color(ROSA, 0.25), 10.0, true)
			draw_polyline(caminho, ROSA, 6.0, true)
			draw_polyline(caminho, Color("#ffe2ef"), 1.8, true)
	if idade <= frase.travessia:
		var cabeca := frase.ponto(area, nota, idade, volta)
		var sprite := SEMINIMA if longa else COLCHEIA
		var escala := Frase.escala_nota(area)
		var destino := Rect2(cabeca - ANCORAGEM * escala, sprite.get_size() * escala)
		draw_texture_rect(sprite, destino, false, MARFIM if longa else Color("#f7acdf"))


func _desenhar_caixas() -> void:
	var abertura := _abertura()
	var prof := Frase.fundo_caixa(area) * abertura
	for borda in 2:
		var face := area.position.y + prof if borda == 0 else area.end.y - prof
		var topo := area.position.y if borda == 0 else face
		draw_rect(Rect2(area.position.x, topo, area.size.x, prof), Color(0.10, 0.07, 0.15, 0.55 * abertura))
		draw_line(Vector2(area.position.x, face), Vector2(area.end.x, face), Color(ROSA, 0.63 * abertura), 2.0, true)
	for canto in 4:
		var caixa := _caixa(canto)
		var aviso := 0.0
		var pulso := 0.0
		for i in frase.graves.size():
			if _canto_da_batida(i) != canto:
				continue
			var idade := tempo - frase.inicio(frase.graves[i])
			if idade >= -0.46 and idade < 0.0:
				aviso = smoothstep(-0.46, 0.0, idade)
			elif idade >= 0.0 and idade < 0.28:
				pulso = 1.0 - idade / 0.28
		var tinta := ROSA.lerp(MARFIM, maxf(aviso, pulso))
		draw_rect(caixa.grow(-1.5), Color("#201828"))
		draw_rect(caixa.grow(-2.0), Color(tinta, 0.88), false, 2.0, true)
		for j in 2:
			var centro := caixa.position + caixa.size * Vector2(0.30 + j * 0.40, 0.5)
			var r := caixa.size.y * (0.34 - 0.045 * aviso + 0.08 * pulso)
			draw_circle(centro, r, Color("#493044"), true, -1.0, true)
			draw_arc(centro, r, 0, TAU, 32, tinta, 2.1, true)
			draw_circle(centro, r * 0.40, tinta, true, -1.0, true)
		if pulso > 0.0:
			var frente := Vector2.DOWN if canto < 2 else Vector2.UP
			var centro := caixa.get_center() + frente * caixa.size.y * 0.38
			var raio := caixa.size.y * 0.28 + (1.0 - pulso) * 95.0
			draw_arc(centro, raio, frente.angle() - 0.92, frente.angle() + 0.92, 24, Color(MARFIM, pulso * 0.75), 2.5, true)


func _desenhar_vento() -> void:
	for lado in 2:
		var sinal := 1.0 if lado == 0 else -1.0
		var borda := area.position.x if lado == 0 else area.end.x
		for i in 5:
			var fase := fposmod(tempo * 0.90 + i * 0.19, 1.0)
			var y := lerpf(area.position.y, area.end.y, (i + 1.0) / 6.0)
			var ponta := Vector2(borda + sinal * (5.0 + fase * 23.0), y)
			draw_line(ponta - Vector2(sinal * 7.0, 0), ponta, Color(MARFIM, sin(PI * fase) * 0.37 * _abertura()), 1.5, true)


func _desenhar_teleporte(t: float) -> void:
	for i in 14:
		var angulo := i * 2.39996 + volta * 0.41
		var distancia := (24.0 + (i % 4) * 11.0) * (1.0 - pow(1.0 - t, 2))
		draw_set_transform(origem + Vector2.from_angle(angulo) * distancia, angulo + t * 1.4, Vector2.ONE * (0.47 - 0.14 * t))
		draw_texture(COLCHEIA, -ANCORAGEM, Color(TINTAS[i % TINTAS.size()], 1.0 - t))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
