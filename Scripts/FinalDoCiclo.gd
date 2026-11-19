extends Node2D

signal voltar_ao_menu

const approach_gradient := preload("res://Assets/Final/aproximacao.png")
const blast_glow := preload("res://Assets/Final/blast_glow.png")
const plume := preload("res://Assets/Final/plume_profile.png")
const ship_texture := preload("res://UI/modelo_o.svg")
const reward_icons := [
	preload("res://Habilidades/Icones/monthly/n05_reserva_solidaria.svg"),
	preload("res://Habilidades/Icones/monthly/u01_alcateia_lunar.svg"),
	preload("res://Habilidades/Icones/monthly/p15_determinacao.svg")
]

var cor_fundo: Color = ProjectSettings.get_setting("rendering/environment/defaults/default_clear_color")
var pontuacao := 0
var recorde_anterior := 0
var maior_combo := 0
var nivel := 1
var duracao := 0
var conquistas: Array[StringName] = []
var stars: Array[Vector4] = []
var font := ThemeDB.fallback_font
var t := 0.0
var inicio_ms := 0
@onready var rolagem_build: ScrollContainer = $RolagemBuild
@onready var voltar: Button = $Voltar

func _ready() -> void:
	ajustar_tamanho()
	get_viewport().size_changed.connect(ajustar_tamanho)
	voltar.pressed.connect(func(): voltar_ao_menu.emit())
	inicio_ms = Time.get_ticks_msec()
	$Audio.play()
	var rng := RandomNumberGenerator.new()
	rng.seed = 1377
	for i in range(255):
		stars.append(Vector4(rng.randf_range(0, 960), rng.randf_range(0, 540), rng.randf_range(0.2, 1.0), rng.randf_range(0, TAU)))

func capturar_build(jogador: Player) -> void:
	$RolagemBuild/Build.capturar(jogador)


func ajustar_tamanho() -> void:
	var area := get_viewport_rect().size
	scale = Vector2.ONE * minf(area.x / 960.0, area.y / 540.0)
	position = (area - Vector2(960,540)*scale)*0.5

func _process(_delta: float) -> void:
	var elapsed := (Time.get_ticks_msec()-inicio_ms)/1000.0
	t = minf(elapsed,11.2)*(12.0/11.2) + maxf(elapsed-11.2,0.0)
	rolagem_build.visible = t >= 12.0
	rolagem_build.modulate.a = blend_time(12.0, 13.2, t)
	if t >= 18.0 and not voltar.visible:
		voltar.show()
		voltar.grab_focus()
	voltar.modulate.a = blend_time(18.0,19.0,t)
	queue_redraw()

func blend_time(a: float, b: float, value: float) -> float:
	var p := clampf((value - a) / (b - a), 0.0, 1.0)
	return p * p * (3.0 - 2.0 * p)


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	draw_rect(Rect2(0, 0, 960, 540), cor_fundo)
	var arrival := blend_time(3.3, 7.3, t)
	var absorption := blend_time(9.2, 10.6, t)
	var hole := Vector2(480, lerpf(-180, 156, arrival))
	var approach := blend_time(3.8, 9.4, t) * (1.0 - blend_time(10.5, 11.8, t))
	draw_texture_rect(approach_gradient, Rect2(0,0,960,540), false, Color(1,1,1,approach))
	if t >= 12.0:
		draw_results()
		return
	if arrival > 0.0:
		for i in range(18, 0, -1):
			draw_circle(hole, float(i) * 15.0, Color(0.3, 0.06, 0.55, 0.014 * arrival))
	var speed := 18.0 + 120.0 * blend_time(0.8, 5.8, t)
	var travel := t * 55.0 + 72.0 * pow(clampf(t,0,3.2),2.0) + 460.8 * maxf(t-3.2,0.0)
	for star in stars:
		var pos := Vector2(star.x, fposmod(star.y + travel * pow(star.z,2.4), 760.0) - 150.0)
		var alpha := (0.16 + star.z * 0.55) * (1.0 - 0.65 * absorption)
		var c := Color(0.48 + star.z * 0.28, 0.58 + star.z * 0.22, 0.96, alpha)
		var distance := pos.distance_to(hole)
		if arrival > 0.0 and distance < 165.0:
			var influence := arrival * pow(1.0 - distance / 165.0, 2.0)
			pos = hole + (pos - hole).rotated(influence * 0.65) * (1.0 + influence * 0.14)
		if star.z < 0.90:
			draw_circle(pos, 0.35 + star.z * 0.6, c)
			if star.z > 0.70:
				draw_line(pos - Vector2(2,0), pos + Vector2(2,0), Color(c, alpha * 0.6), 0.6, true)
				draw_line(pos - Vector2(0,2), pos + Vector2(0,2), Color(c, alpha * 0.6), 0.6, true)
		else:
			var streak := 6.0 + speed * 0.72 * pow(star.z, 3.0) * blend_time(1.1, 4.2, t)
			draw_line(pos, pos + Vector2(0, streak), Color(0.38,0.24,0.85,alpha * 0.12), 4.0, true)
			draw_line(pos, pos + Vector2(0, streak), Color(0.64,0.51,1.0,alpha * 0.7), 0.8, true)
	if arrival > 0.0:
		draw_black_hole(hole, arrival, false)
	# A pequena resistencia inicial cede a uma puxada curva e acelerada.
	var ship_pos := ship_position(t, hole)
	var swallowed := blend_time(9.35, 10.52, t)
	var ship_scale := 1.0 - pow(swallowed, 2.2)
	var pull := blend_time(7.0, 10.4, t)
	if ship_scale > 0.003:
		var tangent := ship_position(t + 0.025, hole) - ship_position(t - 0.025, hole)
		var bank := clampf(tangent.x * 0.045, -0.18, 0.18) * pull + turbulence(t) * sin(t*6.3)*0.023
		var stretch := 1.0 + sin(swallowed * PI) * 1.15
		draw_set_transform(ship_pos, bank, Vector2.ONE)
		draw_ship(ship_pos, hole, bank, ship_scale, stretch)
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	if arrival > 0.0:
		draw_black_hole(hole, arrival, true)
	draw_impact(hole, t - 10.52)
	var black := maxf(1.0 - blend_time(0.0, 0.7, t), blend_time(11.0, 12.0, t))
	draw_rect(Rect2(0, 0, 960, 540), Color(0, 0, 0, black))


func ship_position(moment: float, hole: Vector2) -> Vector2:
	var cruise := lerpf(443.0, 374.0, blend_time(0.0, 2.0, moment))
	var capture := blend_time(6.5, 10.52, moment)
	var angle := capture * TAU * 0.78
	var sway := sin(angle) * 51.0 * sin(capture * PI)
	var y := lerpf(cruise, hole.y, pow(capture, 1.7))
	var strength := turbulence(moment)
	var shake := Vector2(sin(moment*5.8)*3.8+sin(moment*9.1)*1.4,sin(moment*6.6)*1.8)*strength
	return Vector2(480.0 + sin(moment * 0.85) * 2.0 * (1.0-capture) + sway, y) + shake


func draw_black_hole(center: Vector2, opacity: float, front: bool) -> void:
	var pull := blend_time(7.0, 10.5, t)
	var gulp := sin(PI * blend_time(10.35, 10.95, t))
	var radius := 58.0 + sin(t * 2.5) * 0.7 + gulp * 3.0
	# Disco de acrecao em camadas, com trechos mais quentes viajando pelo anel.
	for band in range(5):
		var points := PackedVector2Array()
		var rx := 106.0 + float(band) * 4.3
		var ry := 23.0 + float(band) * 1.6
		for i in range(101):
			var angle := PI * float(i) / 100.0 + (0.0 if front else PI)
			var wobble := sin(angle * 3.0 - t * 2.1) * (1.0 + pull)
			points.append(center + Vector2(cos(angle)*(rx+wobble), sin(angle)*ry).rotated(-0.13))
		var alpha := (0.16 if band != 2 else 0.8) * opacity
		draw_polyline(points, Color(0.60+float(band)*0.035,0.26,0.89,alpha), 2.5 if band != 2 else 2.0, true)
	if not front:
		# Fios curvos tornam a direcao de succao visivel sem cobrir a nave.
		for lane in range(19):
			var phase := fposmod(t * (0.18 + pull * 0.12) + float(lane) / 19.0, 1.0)
			var points := PackedVector2Array()
			var light := sin(PI * phase) * opacity * (0.12 + pull*0.28)
			for j in range(22):
				var u := clampf(phase + float(j) * 0.0035, 0.0, 1.0)
				var r := lerpf(178.0, radius + 2.0, u)
				var angle := float(lane)*2.39996 + u*2.2 - t*0.7
				points.append(center + Vector2.from_angle(angle)*Vector2(r,r*0.76))
			draw_polyline(points,Color(0.60,0.37,0.94,light),1.0,true)
		for i in range(9, 0, -1):
			draw_arc(center, radius+float(i)*1.6,0,TAU,160,Color(0.50,0.18,0.84,0.025*opacity),5,true)
		draw_circle(center,radius,Color(0.002,0.002,0.009,opacity))
		draw_arc(center,radius+0.7,0,TAU,160,Color(0.72,0.44,1.0,0.86*opacity),1.7,true)
		# Arcs courbes asymetriques evoquent un tourbillon, pas une roue rigide.
		for i in range(3):
			var angle := -t*(0.8+pull*0.6)+float(i)*TAU/3.0
			draw_arc(center,radius+4+float(i)*3,angle,angle+0.65,36,Color(0.81,0.58,1.0,opacity*0.45),1.2,true)
	else:
		for i in range(8):
			var angle := t*(1.1+pull*0.7)+TAU*float(i)/8.0
			if sin(angle) < 0.0:
				continue
			var streak := PackedVector2Array()
			for j in range(15):
				var a := angle-float(j)*0.013
				streak.append(center+Vector2(cos(a)*115,sin(a)*28).rotated(-0.13))
			draw_polyline(streak,Color(0.91,0.62,1,opacity*0.7),1.5,true)


func draw_ship(ship_pos: Vector2, hole: Vector2, bank: float, scale_factor: float, stretch: float) -> void:
	var force := blend_time(1.0, 8.6, t)
	var length := lerpf(55.0, 106.0, force) * scale_factor
	var width := lerpf(17.0, 25.0, force) * scale_factor
	var nozzle := 8.0 * scale_factor * stretch
	var previous := Vector2(0, nozzle)
	for segment in range(1,33):
		var u := float(segment) / 32.0
		var history := ship_position(t - u * 0.24, hole) - ship_pos
		var lateral := history.rotated(-bank).x * scale_factor
		var next := Vector2(lateral + sin(t*4.1-u*3.0)*u*u*1.6*scale_factor, nozzle+u*length)
		var v := float(segment-1)/32.0
		var edge := Vector2(width,0)
		draw_primitive(PackedVector2Array([previous-edge, previous+edge, next+edge, next-edge]), PackedColorArray([Color.WHITE]), PackedVector2Array([Vector2(0,v), Vector2(1,v), Vector2(1,u), Vector2(0,u)]), plume)
		previous = next
	var dimensions := Vector2(64.0/sqrt(stretch),64.0*stretch)*scale_factor
	draw_texture_rect(ship_texture,Rect2(-dimensions*0.5,dimensions),false)


func label_at(pos: Vector2, message: String, font_size: int, color: Color) -> void:
	draw_string(font, pos, tr(message), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func hex_icon(center: Vector2, icon: Texture2D, color: Color, opacity: float, radius := 20.0) -> void:
	var points := PackedVector2Array()
	for i in range(6):
		points.append(center + Vector2.from_angle(TAU * float(i) / 6.0 - PI/2) * radius)
	draw_colored_polygon(points, Color(0.06,0.04,0.13,opacity))
	points.append(points[0])
	draw_polyline(points, Color(color, opacity * 0.8), 1.0, true)
	draw_texture_rect(icon, Rect2(center-Vector2.ONE*radius*0.65,Vector2.ONE*radius*1.3),false,Color(1,1,1,opacity))


func draw_results() -> void:
	var a := blend_time(12.0,13.2,t)
	# Estrelas suaves permanecem no fundo da tela de resultados.
	for star in stars:
		var pos := Vector2(star.x, fposmod(star.y + t * star.z * 2.0, 540.0))
		draw_circle(pos, 0.45, Color(0.6,0.65,0.9,star.z*0.35))
	var white := Color(0.85,0.86,0.96,a)
	var muted := Color(0.48,0.48,0.65,a)
	var accent := Color(0.65,0.6,0.95,a)
	label_center(57, "P A R T I D A", 23, white)
	label_center(80, "CICLO CONCLUÍDO", 10, accent)
	var count := blend_time(12.9,15.1,t)
	var labels_left := ["Modo", "Tempo de partida", "Nível alcançado", "Chefes derrotados"]
	var values_left := [tr("Cooperativo") if Rede.modo_multiplayer else tr("Progressão"), "%02d:%02d" % [floori(duracao/60.0),duracao%60], str(nivel), "5 / 5"]
	var labels_right := ["Pontuação", "Recorde anterior", "Novo recorde", "Maior combo"]
	var values_right := [str(int(pontuacao * count)).pad_zeros(8), str(recorde_anterior).pad_zeros(8), str(maxi(pontuacao,recorde_anterior)).pad_zeros(8), str(maior_combo)]
	for i in range(4):
		var y := 117.0 + float(i) * 21.0
		label_at(Vector2(255,y),labels_left[i],11,muted)
		label_at(Vector2(389,y),values_left[i],11,white)
		label_at(Vector2(535,y),labels_right[i],11,muted)
		label_at(Vector2(681,y),values_right[i],11,Color(0.88,0.78,0.48,a) if i==2 else white)
	var record_a := blend_time(15.0,15.6,t) if pontuacao > recorde_anterior else 0.0
	label_center(218,"NOVO RECORDE",12,Color(0.91,0.78,0.47,record_a))
	draw_line(Vector2(240,241),Vector2(720,241),Color(0.55,0.5,0.77,a*0.25),1,true)
	label_center(266,"PROGRESSO",14,white)
	label_center(289,"Setores concluídos: 5 / 5",11,muted)
	var bar := bevel_bar(Vector2(480,303), Vector2(306,12), 6.0)
	var inside := bevel_bar(Vector2(480,303), Vector2(300,6), 3.0)
	draw_colored_polygon(bar,Color(0.15,0.12,0.25,a*0.8))
	var progress := blend_time(14.0,15.6,t)
	if progress > 0.0:
		var clip := PackedVector2Array([Vector2(330,294),Vector2(330+300*progress,294),Vector2(330+300*progress,312),Vector2(330,312)])
		for polygon in Geometry2D.intersect_polygons(inside,clip):
			draw_colored_polygon(polygon,Color(0.79,0.74,0.96,a*0.95))
	var outline := bar.duplicate()
	outline.append(outline[0])
	draw_polyline(outline,Color(0.72,0.68,0.88,a*0.85),1.5,true)
	label_center(338,"CONQUISTAS DESTA PARTIDA",10,muted)
	if conquistas.is_empty():
		label_center(378,tr("Nenhuma nova conquista"),11,muted)
	var paginas := maxi(1,ceili(conquistas.size()/3.0))
	var pagina := floori(maxf(0,t-17.7)/6.0) % paginas
	for i in range(mini(3,conquistas.size()-pagina*3)):
		var dados: Dictionary = Global.CONQUISTAS[conquistas[pagina*3+i]]
		var opacity := blend_time(15.7+i*0.7,16.3+i*0.7,t)
		var y := 369.0+i*43.0
		hex_icon(Vector2(352,y),reward_icons[i],Color(0.65,0.5,0.94),opacity,17)
		label_at(Vector2(380,y-3),tr(dados.nome),10,Color(0.84,0.78,1,opacity))
		label_at(Vector2(380,y+12),tr(dados.descricao),9,Color(0.53,0.53,0.69,opacity))
	draw_rect(Rect2(0,0,960,540),Color(0,0,0,1-a))


func label_center(y: float, message: String, font_size: int, color: Color) -> void:
	var width := font.get_string_size(tr(message),HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
	label_at(Vector2(480.0-width*0.5,y),message,font_size,color)


func bevel_bar(center: Vector2, size: Vector2, cut: float) -> PackedVector2Array:
	var h := size*0.5
	return PackedVector2Array([center+Vector2(-h.x,0),center+Vector2(-h.x+cut,-h.y),center+Vector2(h.x-cut,-h.y),center+Vector2(h.x,0),center+Vector2(h.x-cut,h.y),center+Vector2(-h.x+cut,h.y)])


func turbulence(moment: float) -> float:
	return blend_time(1.8,9.0,moment)*(1.0-blend_time(9.7,10.52,moment))


func glow_at(center: Vector2, radius: Vector2, tint: Color) -> void:
	draw_texture_rect(blast_glow, Rect2(center - radius, radius * 2.0), false, tint)


func draw_impact(center: Vector2, age: float) -> void:
	if age <= 0.0 or age >= 1.25:
		return
	var expansion := 1.0 - exp(-age * 4.2)
	var attack := minf(age / 0.032, 1.0)
	var fade := 1.0 - blend_time(0.30, 1.25, age)
	var hot := attack * exp(-age * 5.0)
	var radius := 6.0 + 158.0 * expansion
	glow_at(center, Vector2.ONE * (42.0 + 123.0 * expansion), Color(0.98,0.20,0.55,0.85*fade))
	for i in range(9):
		var angle := TAU * float(i) / 9.0 + 0.18 * sin(i*5.2)
		var offset := Vector2.from_angle(angle) * expansion * (28.0 + 9.0 * sin(i*2.6))
		var cloud := Vector2.ONE * (14.0 + 52.0 * expansion)
		glow_at(center + offset, cloud, Color(1.0,0.32+0.16*sin(i),0.33,attack*fade*0.75))
	glow_at(center, Vector2.ONE * (26.0+65.0*expansion), Color(1.0,0.88,0.62,attack*exp(-age*2.8)))
	glow_at(center, Vector2(145.0,13.0)*(0.5+expansion),Color(1.0,0.93,0.80,hot))
	draw_arc(center, radius, 0, TAU, 144, Color(1.0,0.59,0.72,0.72*attack*fade), lerpf(4.0,1.0,expansion), true)
	for i in range(21):
		var angle := float(i)*2.39996 + 0.12*sin(i*4.7)
		var distance := expansion*(72.0+75.0*(0.5+0.5*sin(i*3.42)))
		var axis := Vector2.from_angle(angle)
		var end := center+axis*distance
		draw_line(end-axis*(2.0+11.0*(1.0-expansion)),end,Color(1.0,0.76,0.60,attack*fade),1.6,true)
