extends BossMensal
class_name BossNoAmetista

const Perigo:=preload("res://Scripts/PerigoSetorial.gd")
var amarras:=[34.0,34.0,34.0,34.0]
var rompidas:=0
var giro:=1.0
var contracao:=0.0

func _ready()->void: super._ready(); multiplicador_dano_recebido=.3
func Mover(delta:float)->void: contracao=maxf(0,contracao-delta*2); super.Mover(delta)
func executar_ruptura(indice:int)->void:
	match indice:
		0:_corredores()
		1:_fitas_guiadas()
		2:_pulso()
		_:_espiral()
	iniciar_recuperacao(.88)
func _corredores()->void:
	var area:=Global.obter_retangulo_area_visivel(26); var centro:=clampf(player.global_position.x,area.position.x+120,area.end.x-120)
	for x in [centro-118,centro+118]:Perigo.criar(get_tree().current_scene,Perigo.Forma.LINHA,Vector2(x,area.position.y),Vector2(x+80*giro,area.end.y),cor_principal,.9,.72,Dano*.52,22)
func _fitas_guiadas()->void:
	var base:=global_position.direction_to(player.global_position)
	for off in [-.36,0.0,.36]:Perigo.criar(get_tree().current_scene,Perigo.Forma.LINHA,global_position,global_position+base.rotated(off)*1050,cor_secundaria,1.05,.42,Dano*.46,16)
func _pulso()->void:
	contracao=1
	for raio in [58.0,112.0,166.0]:Perigo.criar(get_tree().current_scene,Perigo.Forma.CIRCULO,global_position,global_position,cor_secundaria,.65+raio/420,.14,Dano*.42,raio)
func _espiral()->void:
	giro*=-1; var qtd:=10+rompidas*2
	for i in qtd:criar_projetil(Vector2.from_angle(angulo_visual+giro*TAU*i/qtd),175+(i%3)*28,.32)
func tomarDano(valor:float)->void:
	var i:=_proxima()
	if i>=0:
		amarras[i]=maxf(0,amarras[i]-valor); EfeitoCombateCena.criar(get_tree().current_scene,global_position+Vector2.from_angle(i*TAU/4+angulo_visual)*62,EfeitoCombate.Tipo.ACERTO,cor_principal,1)
		if amarras[i]<=0:rompidas+=1;multiplicador_dano_recebido=.3+rompidas*.175;aplicar_atordoamento(.45)
		queue_redraw();return
	super.tomarDano(valor)
func _proxima()->int:
	for i in 4:
		if amarras[i]>0:return i
	return -1
func _draw()->void:
	draw_colored_polygon(PackedVector2Array([Vector2(0,-24),Vector2(18,0),Vector2(0,28),Vector2(-18,0)]),cor_secundaria.lerp(Color.WHITE,contracao*.55))
	for i in 4:
		if amarras[i]<=0:continue
		var a:=angulo_visual*(1 if i%2==0 else -1)+i*TAU/4;var p:=Vector2.from_angle(a)*62
		draw_polyline(PackedVector2Array([p,p.rotated(.35)*.72,p.rotated(-.28)*.38,Vector2.ZERO]),cor_principal,9,true);draw_circle(p,10,Color.WHITE)
	for r in [34.0,45.0]:draw_arc(Vector2.ZERO,r,angulo_visual,angulo_visual+4.9,42,Color(cor_principal,.7),4)
func morrer()->void:
	if Vida>0:return
	for i in 4:EfeitoCombateCena.criar(get_tree().current_scene,global_position+Vector2.from_angle(i*TAU/4)*70,EfeitoCombate.Tipo.MORTE,cor_principal,1.3)
	super.morrer()
