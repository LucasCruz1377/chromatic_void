extends Node2D
class_name CloneLunar

## Retrato congelado no instante em que a Lua escolhe o piloto.
## Só o casco é copiado. O clone não possui controles, inventário ou colisores da nave.
var modelo: Dictionary
const HALO := preload("res://FX/HaloCloneLunar.tres")
var textura: Texture2D
var cor_aura := Color.WHITE


static func capturar(nave: Player) -> Dictionary:
	var dados := {"id": nave.modelo_visual_nave, "cor": nave.obter_cor_personalizacao(), "escala": nave.global_scale,
		"boca": nave.PontaArma.position * nave.global_scale}
	var sprite: Sprite2D = nave.sprites_modelos_exclusivos.get(nave.modelo_visual_nave, nave.sprite_modelo_o)
	if is_instance_valid(sprite) and sprite.visible:
		dados["transform"] = sprite.transform
	else:
		var partes := []
		for parte: Polygon2D in [nave.corpo_visual, nave.detalhe_visual]:
			partes.append([parte.transform * parte.polygon, parte.color])
		dados["partes"] = partes
	return dados


func configurar(dados: Dictionary) -> void:
	add_to_group("visual_boss_local")
	modelo = dados
	scale = dados.escala
	var equipada: Color = dados.cor
	cor_aura = equipada.inverted().lerp(Color.WHITE, 0.16)
	if not dados.has("partes"):
		var tinta := ShaderMaterial.new()
		match StringName(dados.id):
			&"c07_modelo_o": textura = Player.TEXTURA_MODELO_O
			&"c08_modelo_spectrum": textura = Player.TEXTURA_MODELO_SPECTRUM
			&"c09_modelo_fspeed": textura = Player.TEXTURA_MODELO_FSPEED
		if textura == Player.TEXTURA_MODELO_SPECTRUM:
			tinta.shader = Player.SHADER_SPECTRUM
		else:
			tinta.shader = Player.SHADER_COR_MODELO_O
			tinta.set_shader_parameter("cor_estrela", dados.cor)
		tinta.set_shader_parameter("inverter_cores", true)
		tinta.set_shader_parameter("hdr_lunar", get_viewport().use_hdr_2d and RenderingServer.get_current_rendering_method() != "gl_compatibility")
		material = tinta
	queue_redraw()


static func intensidade_aura() -> float:
	return 0.8 * Global.neon / Global.NEON_BASE + 0.2 * Global.bloom / Global.BLOOM_BASE


func _draw() -> void:
	if modelo.has("partes"):
		for parte in modelo.partes:
			var cor: Color = parte[1]
			draw_colored_polygon(parte[0], cor.inverted())
	elif textura:
		draw_set_transform_matrix(modelo.transform)
		draw_texture(textura, -textura.get_size() * 0.5)
