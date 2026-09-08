extends InimigoBase
class_name InimigoSetorial

const PROJETIL := preload("res://Entities/ProjetilInimigo.tscn")
const Perigo := preload("res://Scripts/PerigoSetorial.gd")
const Crescente := preload("res://Scripts/CrescenteBumerangue.gd")

enum Estilo { ESTILHACO, GUARDA, ECO, BROTO, ORBITAL, CENTELHA_GUIA, ELO_DOURADO, PRISMA_AMPARO, SATELITE_BERCO, PULSO_SOLAR, FITA_VIOLETA, NO_FLUTUANTE, ECO_AMETISTA, LAMINA_IRIS, CASULO_PRISMATICO, BROTO_PRIMAVERIL, SEMENTE_CANHAO, POLEN_ERRANTE, CIPO_ESPIRAL, FRUTO_EXPLOSIVO, FRAGMENTO_LUNAR, CENTELHA_SOLAR, METEORO_JOVEM, ECO_GRAVITACIONAL, SATELITE_COROA }

@export var estilo: Estilo = Estilo.CENTELHA_GUIA
@export var cor_setor := Color(0.45, 1.0, 0.68)
@export var intervalo_acao := 2.8

var visual: CanvasItem
var tempo := 0.0
var recarga := 1.0
var preparando := false
var preparo := 0.0
var direcao := Vector2.RIGHT
var direcao_memorizada := Vector2.RIGHT
var destino := Vector2.ZERO
var parceiro: InimigoBase
var protegido: InimigoBase
var fechado := false
var drones_liberados := false
var trilha := Vector2.ZERO
var tempo_trilha := 0.0
var angulo_orbita := 0.0

func _ready() -> void:
	visual = self; trilha = global_position; recarga = randf_range(0.4, intervalo_acao)
	super._ready(); queue_redraw()

func Mover(delta: float) -> void:
	if not is_instance_valid(player): return
	tempo += delta; tempo_trilha -= delta; _manter_vinculos()
	if player.velocity.length_squared() > 20.0: direcao_memorizada = player.velocity.normalized()
	if preparando:
		velocity = velocity.move_toward(Vector2.ZERO, 420.0 * delta); preparo -= delta
		if preparo <= 0.0: preparando = false; _executar(); recarga = intervalo_acao * randf_range(0.9, 1.12)
		queue_redraw(); return
	var ate := global_position.direction_to(player.global_position)
	var distancia := global_position.distance_to(player.global_position)
	direcao = ate
	match estilo:
		Estilo.CENTELHA_GUIA: _mover_para_aliado(ate, distancia, delta)
		Estilo.ELO_DOURADO, Estilo.NO_FLUTUANTE: _mover_formacao(ate, distancia, delta)
		Estilo.PRISMA_AMPARO: velocity = velocity.move_toward(_distancia(ate, distancia, 230.0) * Velocidade, 190.0 * delta)
		Estilo.SATELITE_BERCO: velocity = velocity.move_toward(_distancia(ate, distancia, 310.0) * Velocidade, 160.0 * delta)
		Estilo.PULSO_SOLAR: velocity = velocity.move_toward(_distancia(ate, distancia, 250.0) * Velocidade, 220.0 * delta)
		Estilo.FITA_VIOLETA:
			velocity = velocity.move_toward(ate.rotated(sin(tempo * 2.5) * 0.92) * Velocidade, 270.0 * delta)
			if tempo_trilha <= 0.0 and global_position.distance_to(trilha) > 30.0:
				Perigo.criar(get_tree().current_scene, Perigo.Forma.LINHA, trilha, global_position, cor_setor, 0.08, 0.55, Dano * 0.35, 10.0); trilha = global_position; tempo_trilha = 0.15
		Estilo.ECO_AMETISTA: velocity = velocity.move_toward(_distancia(ate, distancia, 290.0) * Velocidade, 220.0 * delta)
		Estilo.LAMINA_IRIS: velocity = velocity.move_toward(ate.orthogonal() * Velocidade, 250.0 * delta)
		Estilo.CASULO_PRISMATICO: velocity = velocity.move_toward(_distancia(ate, distancia, 265.0) * Velocidade, 150.0 * delta)
		Estilo.BROTO_PRIMAVERIL: velocity = velocity.move_toward(Vector2.ZERO, 350.0 * delta)
		Estilo.SEMENTE_CANHAO: velocity = velocity.move_toward(_distancia(ate, distancia, 355.0) * Velocidade, 200.0 * delta)
		Estilo.POLEN_ERRANTE: velocity = velocity.move_toward(ate.rotated(sin(tempo * 1.6) * 0.75) * Velocidade, 150.0 * delta)
		Estilo.CIPO_ESPIRAL: velocity = velocity.move_toward(ate.rotated(1.1 + sin(tempo * 2.0) * 0.25) * Velocidade, 230.0 * delta)
		Estilo.FRUTO_EXPLOSIVO: velocity = velocity.move_toward(ate * Velocidade, 120.0 * delta)
		Estilo.FRAGMENTO_LUNAR, Estilo.CENTELHA_SOLAR: velocity = velocity.move_toward(_distancia(ate, distancia, 330.0) * Velocidade, 210.0 * delta)
		Estilo.METEORO_JOVEM: velocity = velocity.move_toward(ate.orthogonal() * Velocidade, 170.0 * delta)
		Estilo.ECO_GRAVITACIONAL: velocity = velocity.move_toward(_distancia(ate, distancia, 320.0) * Velocidade, 150.0 * delta)
		Estilo.SATELITE_COROA: _orbitar_aliado(ate, delta)
		_: velocity = velocity.move_toward(ate * Velocidade, 220.0 * delta)
	recarga -= delta
	if recarga <= 0.0: _preparar()
	queue_redraw()

func _distancia(ate: Vector2, atual: float, ideal: float) -> Vector2:
	if atual < ideal - 35.0: return -ate
	if atual > ideal + 35.0: return ate
	return ate.orthogonal()

func _mover_para_aliado(ate: Vector2, distancia: float, delta: float) -> void:
	var aliado := _mais_proximo(false)
	if aliado:
		var d := global_position.distance_to(aliado.global_position)
		velocity = velocity.move_toward(_distancia(global_position.direction_to(aliado.global_position), d, 105.0) * Velocidade, 250.0 * delta)
	else: velocity = velocity.move_toward(_distancia(ate, distancia, 290.0) * Velocidade, 210.0 * delta)

func _mover_formacao(ate: Vector2, distancia: float, delta: float) -> void:
	if parceiro:
		var centro: Vector2 = (parceiro.global_position + Vector2(player.global_position)) * 0.5
		velocity = velocity.move_toward(global_position.direction_to(centro) * Velocidade, 180.0 * delta)
	else: velocity = velocity.move_toward(_distancia(ate, distancia, 250.0) * Velocidade, 180.0 * delta)

func _orbitar_aliado(ate: Vector2, delta: float) -> void:
	if not parceiro: parceiro = _mais_proximo(false)
	if parceiro:
		angulo_orbita += delta * 1.5
		var alvo := parceiro.global_position + Vector2.from_angle(angulo_orbita) * 72.0
		velocity = velocity.move_toward(global_position.direction_to(alvo) * Velocidade * 1.4, 310.0 * delta)
	else: velocity = velocity.move_toward(ate.orthogonal() * Velocidade, 180.0 * delta)

func _preparar() -> void:
	preparando = true; direcao = global_position.direction_to(player.global_position)
	preparo = {Estilo.PULSO_SOLAR:0.85, Estilo.LAMINA_IRIS:0.72, Estilo.BROTO_PRIMAVERIL:0.72, Estilo.FRUTO_EXPLOSIVO:1.05, Estilo.CENTELHA_SOLAR:0.8, Estilo.METEORO_JOVEM:0.85}.get(estilo, 0.58)
	_destino_e_aviso()

func _destino_e_aviso() -> void:
	var cena := get_tree().current_scene
	if estilo in [Estilo.PULSO_SOLAR, Estilo.LAMINA_IRIS, Estilo.CENTELHA_SOLAR]:
		Perigo.criar(cena, Perigo.Forma.LINHA, global_position, global_position + direcao * 1100.0, cor_setor, preparo, 0.16, Dano * 0.75, 20.0 if estilo != Estilo.CENTELHA_SOLAR else 11.0)
	elif estilo == Estilo.BROTO_PRIMAVERIL:
		destino = player.global_position + player.velocity * 0.35; visible = false
		Perigo.criar(cena, Perigo.Forma.CIRCULO, destino, destino, cor_setor, preparo, 0.2, Dano, 42.0)
	elif estilo == Estilo.METEORO_JOVEM:
		destino = player.global_position + player.velocity * 0.45
		Perigo.criar(cena, Perigo.Forma.CIRCULO, destino, destino, cor_setor, preparo, 0.22, Dano, 58.0)
	elif estilo == Estilo.FRUTO_EXPLOSIVO: Perigo.criar(cena, Perigo.Forma.CIRCULO, global_position, global_position, cor_setor, preparo, 0.22, Dano, 96.0)
	elif estilo == Estilo.ECO_GRAVITACIONAL: Perigo.criar(cena, Perigo.Forma.PUXAO, global_position, global_position, cor_setor, preparo, 0.95, Dano*0.2, 150.0, 58.0)
	elif estilo == Estilo.POLEN_ERRANTE: Perigo.criar(cena, Perigo.Forma.PUXAO, global_position, global_position, cor_setor, preparo, 1.15, Dano*0.12, 92.0, -1.0)
	else: EfeitoCombateCena.criar(cena, global_position, EfeitoCombate.Tipo.AVISO, cor_setor, 0.85, direcao)

func _executar() -> void:
	EfeitoCombateCena.criar(get_tree().current_scene, global_position, EfeitoCombate.Tipo.ACERTO, cor_setor, 0.55, direcao)
	match estilo:
		Estilo.CENTELHA_GUIA: _escudar()
		Estilo.ELO_DOURADO: _ligar(true)
		Estilo.PRISMA_AMPARO: fechado = true; multiplicador_dano_recebido = 0.22; get_tree().create_timer(1.1).timeout.connect(_abrir_prisma)
		Estilo.SATELITE_BERCO: pass
		Estilo.PULSO_SOLAR, Estilo.LAMINA_IRIS: velocity = direcao * Velocidade * 3.2
		Estilo.FITA_VIOLETA: velocity = direcao.rotated(0.68) * Velocidade * 2.0
		Estilo.NO_FLUTUANTE: _ligar(false)
		Estilo.ECO_AMETISTA: _disparar(direcao_memorizada, 360.0, Dano * 0.75)
		Estilo.CASULO_PRISMATICO:
			fechado = not fechado; multiplicador_dano_recebido = 0.08 if fechado else 1.0
			if not fechado: _radial(8, 235.0, Dano * 0.4)
		Estilo.BROTO_PRIMAVERIL: global_position = destino; visible = true
		Estilo.SEMENTE_CANHAO: _leque(3, 0.28, 315.0, Dano * 0.58)
		Estilo.CIPO_ESPIRAL: velocity = direcao.rotated(0.52) * Velocidade * 2.4
		Estilo.FRUTO_EXPLOSIVO: _radial(8, 230.0, Dano * 0.36); Vida = 0; morrer()
		Estilo.FRAGMENTO_LUNAR: Crescente.criar(get_tree().current_scene, self, direcao, Dano * 0.7, cor_setor)
		Estilo.SATELITE_COROA: _disparar(parceiro.global_position.direction_to(global_position) if parceiro else -direcao, 340.0, Dano*0.68)

func _escudar() -> void:
	protegido = _mais_proximo(false)
	if protegido: protegido.multiplicador_dano_recebido = 0.48; protegido.set_meta("escudo_guia", self)

func _ligar(mesmo: bool) -> void:
	parceiro = _mais_proximo(mesmo)
	if not parceiro: return
	if mesmo:
		set_meta("laco_parceiro", parceiro); set_meta("laco_expira", Time.get_ticks_msec()+5000)
		parceiro.set_meta("laco_parceiro", self); parceiro.set_meta("laco_expira", Time.get_ticks_msec()+5000)
	else: parceiro.multiplicador_dano_recebido = 0.52; parceiro.set_meta("no_protetor", self)

func _manter_vinculos() -> void:
	if protegido and global_position.distance_to(protegido.global_position)>185: _limpar_escudo()
	if estilo == Estilo.NO_FLUTUANTE and parceiro and global_position.distance_to(parceiro.global_position)>205: parceiro.multiplicador_dano_recebido=1.0; parceiro=null

func _limpar_escudo() -> void:
	if protegido and protegido.has_meta("escudo_guia") and protegido.get_meta("escudo_guia")==self: protegido.multiplicador_dano_recebido=1.0; protegido.remove_meta("escudo_guia")
	protegido=null

func _mais_proximo(mesmo: bool) -> InimigoBase:
	var melhor: InimigoBase; var menor:=INF
	for n in get_tree().get_nodes_in_group("inimigo"):
		if n==self or not n is InimigoBase or n.is_in_group("boss"): continue
		if mesmo and (not n is InimigoSetorial or n.estilo!=estilo): continue
		var d:=global_position.distance_squared_to(n.global_position)
		if d<menor: menor=d; melhor=n
	return melhor

func _abrir_prisma() -> void:
	if is_instance_valid(self): fechado=false; multiplicador_dano_recebido=1.0; _leque(3,0.3,260,Dano*0.4)

func _leque(q:int, abertura:float, vel:float, dano_tiro:float)->void:
	for i in q: _disparar(direcao.rotated((float(i)-float(q-1)*0.5)*abertura),vel,dano_tiro)
func _radial(q:int,vel:float,dano_tiro:float)->void:
	for i in q: _disparar(Vector2.from_angle(TAU*float(i)/float(q)),vel,dano_tiro)
func _disparar(dir:Vector2,vel:float,dano_tiro:float)->void:
	var p:=PROJETIL.instantiate() as ProjetilInimigo; get_tree().current_scene.add_child(p); p.global_position=global_position+dir*24
	var forma:=p.get_node_or_null("Visual") as Polygon2D
	if forma: forma.color=cor_setor
	p.configurar(dir,dano_tiro,vel,0)

func tomarDano(valor:float)->void:
	if estilo==Estilo.SATELITE_BERCO and not drones_liberados: _soltar_drones()
	if estilo==Estilo.PRISMA_AMPARO: multiplicador_dano_recebido=0.22 if global_position.direction_to(player.global_position).dot(direcao)>0.25 else 1.35
	super.tomarDano(valor)

func _soltar_drones()->void:
	drones_liberados=true; var cena:=load("res://Entities/InimigoCentelhaGuia.tscn") as PackedScene
	for lado in [-1.0,1.0]:
		var d:=cena.instantiate() as InimigoBase; get_tree().current_scene.add_child(d); d.global_position=global_position+Vector2(30*lado,10); d.VidaMaxima*=0.5; d.ValorXP=0.25

func morrer()->void:
	_limpar_escudo()
	if estilo==Estilo.NO_FLUTUANTE and parceiro: parceiro.multiplicador_dano_recebido=1.0
	super.morrer()

func _draw()->void:
	var c:=cor_setor.lightened(0.1)
	match estilo:
		Estilo.CENTELHA_GUIA: draw_circle(Vector2.ZERO,8,c); draw_arc(Vector2.ZERO,17,0,TAU,24,c,3)
		Estilo.ELO_DOURADO: draw_arc(Vector2(-7,0),11,-2.2,2.2,18,c,5); draw_arc(Vector2(7,0),11,.94,5.34,18,c,5)
		Estilo.PRISMA_AMPARO: draw_colored_polygon(PackedVector2Array([Vector2(22,0),Vector2(0,-17),Vector2(-15,0),Vector2(0,17)]),c); draw_line(Vector2(17,-18),Vector2(17,18),Color.WHITE,4)
		Estilo.SATELITE_BERCO: draw_arc(Vector2.ZERO,18,.35,TAU-.35,28,c,6); draw_circle(Vector2(-8,0),5,Color.WHITE); draw_circle(Vector2(8,0),5,Color.WHITE)
		Estilo.PULSO_SOLAR: draw_circle(Vector2.ZERO,12,c); for i in 8: draw_line(Vector2.from_angle(i*TAU/8)*16,Vector2.from_angle(i*TAU/8)*24,c,3)
		Estilo.FITA_VIOLETA: draw_polyline(PackedVector2Array([Vector2(-24,0),Vector2(-12,-9),Vector2(0,8),Vector2(12,-8),Vector2(24,0)]),c,7,true)
		Estilo.NO_FLUTUANTE: draw_arc(Vector2(-5,0),13,-1.2,4.2,24,c,5); draw_arc(Vector2(5,0),13,1.9,7.3,24,Color.WHITE,4)
		Estilo.ECO_AMETISTA: draw_polyline(PackedVector2Array([Vector2(-16,-15),Vector2(0,0),Vector2(-16,15)]),c,5)
		Estilo.LAMINA_IRIS: draw_colored_polygon(PackedVector2Array([Vector2(25,0),Vector2(-18,-6),Vector2(-8,0),Vector2(-18,6)]),c)
		Estilo.CASULO_PRISMATICO: draw_colored_polygon(PackedVector2Array([Vector2(0,-22),Vector2(15,0),Vector2(0,22),Vector2(-15,0)]),c); draw_arc(Vector2.ZERO,20,0,TAU,28,Color.WHITE,3)
		Estilo.BROTO_PRIMAVERIL: draw_circle(Vector2.ZERO,10,c); draw_colored_polygon(PackedVector2Array([Vector2(0,-22),Vector2(9,-7),Vector2(-9,-7)]),Color(.45,1,.55))
		Estilo.SEMENTE_CANHAO: draw_circle(Vector2.ZERO,14,c); draw_line(Vector2.ZERO,direcao*26,Color.WHITE,8)
		Estilo.POLEN_ERRANTE: for i in 7: draw_circle(Vector2.from_angle(i*2.4+tempo)*float(5+i*2),3.5,c)
		Estilo.CIPO_ESPIRAL: draw_arc(Vector2.ZERO,18,tempo,tempo+5.2,32,c,6)
		Estilo.FRUTO_EXPLOSIVO: draw_circle(Vector2.ZERO,16+sin(tempo*7)*2,c); draw_arc(Vector2.ZERO,22,0,TAU,28,Color.WHITE,2)
		Estilo.FRAGMENTO_LUNAR: draw_arc(Vector2.ZERO,20,-1.3,1.3,24,c,7); draw_circle(Vector2(7,0),15,Color(.01,.02,.08))
		Estilo.CENTELHA_SOLAR: draw_circle(Vector2.ZERO,9,c); draw_line(Vector2(-18,0),Vector2(18,0),Color.WHITE,3)
		Estilo.METEORO_JOVEM: draw_colored_polygon(PackedVector2Array([Vector2(17,-8),Vector2(12,13),Vector2(-8,18),Vector2(-19,2),Vector2(-8,-16)]),c)
		Estilo.ECO_GRAVITACIONAL: draw_circle(Vector2.ZERO,8,Color(.02,.01,.08)); draw_arc(Vector2.ZERO,18,-tempo,TAU-tempo,28,c,5)
		Estilo.SATELITE_COROA: draw_arc(Vector2.ZERO,18,0,TAU,28,c,4); for i in 4: draw_circle(Vector2.from_angle(i*TAU/4)*18,5,Color.WHITE)
	match estilo:
		Estilo.BROTO_PRIMAVERIL, Estilo.SEMENTE_CANHAO:
			for lado in [-1.0, 1.0]:
				var folha := PackedVector2Array([Vector2(-5,0), Vector2(-19, lado*13), Vector2(-20,lado*3)])
				draw_colored_polygon(folha, cor_setor.darkened(0.3))
				draw_line(Vector2(-6,0), Vector2(-18,lado*8), cor_setor.lightened(0.4), 1.5, true)
		Estilo.METEORO_JOVEM:
			draw_polyline(PackedVector2Array([Vector2(-9,-11), Vector2(0,-3), Vector2(-4,5), Vector2(8,12)]), Color(1.0,0.7,0.25), 2.0, true)
		Estilo.LAMINA_IRIS, Estilo.ECO_AMETISTA:
			draw_line(Vector2(-12,-4), Vector2(12,0), Color.WHITE, 1.5, true)
			draw_line(Vector2(-12,4), Vector2(12,0), cor_setor.darkened(0.4), 2.0, true)
		Estilo.PRISMA_AMPARO, Estilo.CASULO_PRISMATICO:
			draw_line(Vector2(0,-12), Vector2(8,0), cor_setor.darkened(0.5), 2.0, true)
			draw_line(Vector2(8,0), Vector2(0,12), cor_setor.darkened(0.5), 2.0, true)
	# Núcleo e partículas de carga preservam a silhueta de cada espécie.
	draw_circle(Vector2.ZERO, 4.0, Color(0.03, 0.04, 0.10))
	draw_circle(direcao * 2.0, 1.8, Color.WHITE)
	if preparando:
		for i in 5:
			var ponto := Vector2.from_angle(float(i) * TAU / 5.0 + tempo) * (12.0 + maxf(preparo, 0.0) * 22.0)
			draw_circle(ponto, 2.0, cor_setor.lightened(0.4))
	if protegido: draw_line(Vector2.ZERO,protegido.global_position-global_position,Color(c,.55),3)
	if parceiro: draw_line(Vector2.ZERO,parceiro.global_position-global_position,Color(c,.5),3)
