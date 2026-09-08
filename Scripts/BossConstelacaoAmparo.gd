extends BossMensal
class_name BossConstelacaoAmparo

const Perigo := preload("res://Scripts/PerigoSetorial.gd")
var satelites := [42.0,42.0,42.0]
var angulos := [0.0,TAU/3.0,TAU*2.0/3.0]
var alvo_satelite:=0
var exposto:=false
var tempo_exposto:=0.0
var abraco:=false
var tempo_abraco:=0.0
var raio_seguro:=360.0

func _ready()->void:
	super._ready(); multiplicador_dano_recebido=0.0

func Mover(delta:float)->void:
	for i in 3: angulos[i]+=delta*(.48+i*.07)*(-1.0 if i==1 else 1.0)
	if exposto:
		tempo_exposto-=delta
		if tempo_exposto<=0: _reformar()
	if abraco: _comprimir(delta)
	super.Mover(delta)

func executar_sentinela(indice:int)->void:
	match indice:
		0: _lasers()
		1: _protecao_cruzada()
		2: _trocar_prioridade()
		_: _abraco()
	iniciar_recuperacao(.82)

func _pos(i:int)->Vector2: return global_position+Vector2.from_angle(angulos[i])*78
func _lasers()->void:
	for i in 3:
		if satelites[i]<=0: continue
		var origem:=_pos(i); var dir:=origem.direction_to(player.global_position)
		Perigo.criar(get_tree().current_scene,Perigo.Forma.LINHA,origem,origem+dir*1100,cor_principal,.82,.2,Dano*.72,18)
func _protecao_cruzada()->void:
	for i in 3:
		if satelites[i]>0: Perigo.criar(get_tree().current_scene,Perigo.Forma.LINHA,_pos(i),_pos((i+1)%3),cor_secundaria,.7,.55,Dano*.45,13)
func _trocar_prioridade()->void:
	alvo_satelite=_proximo(alvo_satelite+1)
	for i in 3:
		if i!=alvo_satelite and satelites[i]>0: Perigo.criar(get_tree().current_scene,Perigo.Forma.LINHA,_pos(i),_pos(alvo_satelite),cor_principal,.65,.6,Dano*.4,14)
func _abraco()->void:
	abraco=true; tempo_abraco=3.8; raio_seguro=minf(Global.obter_retangulo_area_visivel().size.x,Global.obter_retangulo_area_visivel().size.y)*.42
func _comprimir(delta:float)->void:
	tempo_abraco-=delta; raio_seguro=maxf(105,raio_seguro-54*delta)
	if player.global_position.distance_to(Global.obter_centro_area_visivel())>raio_seguro and int(tempo_abraco*5)!=int((tempo_abraco+delta)*5): player.tomar_dano(Dano*.24)
	if tempo_abraco<=0: abraco=false

func tomarDano(valor:float)->void:
	if not exposto and _vivos()>0:
		alvo_satelite=_proximo(alvo_satelite); satelites[alvo_satelite]=maxf(0,satelites[alvo_satelite]-valor)
		EfeitoCombateCena.criar(get_tree().current_scene,_pos(alvo_satelite),EfeitoCombate.Tipo.ACERTO,cor_principal,1)
		if satelites[alvo_satelite]<=0: alvo_satelite=_proximo(alvo_satelite+1)
		if _vivos()==0: exposto=true; tempo_exposto=4.2; multiplicador_dano_recebido=1.28; aplicar_atordoamento(.75)
		queue_redraw(); return
	super.tomarDano(valor)
func _vivos()->int:
	var n:=0; for v in satelites: n+=1 if v>0 else 0
	return n
func _proximo(inicio:int)->int:
	for passo in 3:
		var i:=posmod(inicio+passo,3)
		if satelites[i]>0:return i
	return 0
func _reformar()->void:
	exposto=false; multiplicador_dano_recebido=0
	for i in 3:satelites[i]=25+fase*6
func _draw()->void:
	var forma:=PackedVector2Array(); for i in 6: forma.append(Vector2.from_angle(i*TAU/6)*31)
	draw_colored_polygon(forma,cor_principal if exposto else Color(.16,.09,.015)); draw_circle(Vector2.ZERO,13,cor_secundaria if exposto else Color.WHITE)
	for i in 3:
		if satelites[i]<=0:continue
		var p:=Vector2.from_angle(angulos[i])*78; draw_line(p,Vector2.from_angle(angulos[(i+1)%3])*78,Color(cor_principal,.45),3); draw_circle(p,13 if i==alvo_satelite else 10,cor_principal); draw_circle(p,4,Color.WHITE)
	if abraco:draw_arc(Global.obter_centro_area_visivel()-global_position,raio_seguro,0,TAU,96,Color(cor_principal,.85),8)
func morrer()->void:
	if Vida>0:return
	for i in 3:EfeitoCombateCena.criar(get_tree().current_scene,_pos(i),EfeitoCombate.Tipo.MORTE,cor_principal,1.4)
	super.morrer()
