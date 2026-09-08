extends Node

var falhas: Array[String] = []


func verificar(condicao: bool, mensagem: String) -> void:
	if condicao:
		return
	falhas.append(mensagem)
	push_error("VISUAL MOBILE 0.7.1: " + mensagem)


func _ready() -> void:
	var particulas := GPUParticles2D.new()
	particulas.name = "FundoReferencia071"
	particulas.amount = 200
	particulas.lifetime = 10.0
	particulas.preprocess = 10.0
	particulas.trail_enabled = true
	particulas.fixed_fps = 30
	particulas.interpolate = true
	add_child(particulas)
	await get_tree().process_frame
	verificar(particulas.amount == 200, "o mobile reduziu a densidade definida pela cena")
	verificar(particulas.fixed_fps == 30, "o mobile alterou o FPS definido pela cena")
	verificar(particulas.interpolate and particulas.fract_delta, "o mobile reduziu a suavidade das partículas")
	verificar(particulas.trail_enabled, "o mobile removeu trilhas presentes no PC")
	verificar(is_equal_approx(particulas.lifetime, 10.0), "a vida das partículas ainda está encurtada")
	verificar(is_equal_approx(particulas.preprocess, 10.0), "o preprocess difere do PC")
	particulas.free()

	var menu := (load("res://Rooms/TelaInicial.tscn") as PackedScene).instantiate()
	var configuracoes := (load("res://Rooms/configuracoes.tscn") as PackedScene).instantiate()
	var loja := (load("res://Rooms/Loja.tscn") as PackedScene).instantiate()
	verificar((menu.get_node("parts_fundo") as GPUParticles2D).amount == 200, "densidade-base do menu não foi restaurada")
	verificar((configuracoes.get_node("parts_fundo") as GPUParticles2D).amount == 120, "densidade-base das configurações não foi restaurada")
	verificar((loja.get_node("ParticulasFundo") as GPUParticles2D).amount == 85, "densidade-base da loja mudou")
	menu.free()
	configuracoes.free()
	loja.free()

	var ambiente := (load("res://FX/Shader.tscn") as PackedScene).instantiate() as WorldEnvironment
	verificar(ambiente.environment.glow_enabled, "o glow global está desligado")
	verificar(is_equal_approx(ambiente.environment.glow_intensity, 1.0), "a intensidade-base do neon difere da 0.7.1")
	verificar(is_equal_approx(ambiente.environment.glow_bloom, 0.12), "o bloom-base difere da 0.7.1")
	ambiente.free()

	verificar(
		str(ProjectSettings.get_setting("rendering/renderer/rendering_method")) == "mobile"
		and bool(ProjectSettings.get_setting("rendering/rendering_device/fallback_to_opengl3")),
		"renderer Mobile sem fallback seguro para OpenGL"
	)
	var presets := FileAccess.get_file_as_string("res://export_presets.cfg")
	verificar(
		'command_line/extra_args="--rendering-method gl_compatibility"' not in presets,
		"o preset Android ainda força o renderer que reduz o neon"
	)

	if falhas.is_empty():
		print("TESTE OK: partículas, shaders e neon mobile equivalentes ao PC")
	get_tree().quit(0 if falhas.is_empty() else 1)
