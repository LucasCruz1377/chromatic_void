extends Node2D
class_name ProjetilJogadorRemoto


var direcao := Vector2.RIGHT
var velocidade := 900.0
var tempo_restante := 1.15
var cor := Color("65d8ff")
var estilo: StringName = &""


static func criar(parent: Node, dados: Dictionary) -> ProjetilJogadorRemoto:
	var projetil := ProjetilJogadorRemoto.new()
	parent.add_child(projetil)
	var origem: Variant = dados.get("posicao", Vector2.ZERO)
	if origem is Vector2:
		projetil.global_position = origem
	var angulo := float(dados.get("angulo", 0.0))
	projetil.rotation = angulo
	projetil.direcao = Vector2.from_angle(angulo)
	projetil.velocidade = clampf(float(dados.get("velocidade", 900.0)), 120.0, 1600.0)
	var nova_cor: Variant = dados.get("cor", projetil.cor)
	if nova_cor is Color:
		projetil.cor = nova_cor
	projetil.estilo = StringName(dados.get("estilo", &""))
	projetil.z_index = 3
	projetil.process_mode = Node.PROCESS_MODE_ALWAYS
	projetil.queue_redraw()
	return projetil


func _process(delta: float) -> void:
	global_position += direcao * velocidade * delta
	tempo_restante -= delta
	if tempo_restante <= 0.0:
		queue_free()


func _draw() -> void:
	var comprimento := 18.0 if estilo in [&"beam", &"sniper"] else 11.0
	var espessura := 4.0 if estilo in [&"missile", &"torpedo"] else 2.5
	draw_line(Vector2(-comprimento, 0), Vector2(comprimento, 0), Color(cor, 0.22), espessura * 3.0)
	draw_line(Vector2(-comprimento, 0), Vector2(comprimento, 0), cor, espessura)
	draw_circle(Vector2(comprimento, 0), espessura, cor.lightened(0.45))
