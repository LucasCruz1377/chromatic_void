extends Node

var falhas: Array[String] = []


func verificar(condicao: bool, mensagem: String) -> void:
	if condicao:
		return
	falhas.append(mensagem)
	push_error("VISUAL MOBILE 0.7.1: " + mensagem)


func _ready() -> void:
	verificar(
		is_equal_approx(Global.FATOR_PARTICULAS_MOBILE, 0.55)
		and Global.LIMITE_PARTICULAS_MOBILE == 90
		and Global.LIMITE_PARTICULAS_FUNDO_MOBILE == 55
		and Global.FPS_PARTICULAS_MOBILE == 30,
		"limites de partículas diferentes da release 0.7.1"
	)

	var particulas := GPUParticles2D.new()
	particulas.name = "FundoReferencia071"
	particulas.amount = 200
	particulas.lifetime = 10.0
	particulas.preprocess = 10.0
	particulas.trail_enabled = true
	Global._otimizar_particulas_mobile(particulas)
	verificar(particulas.amount == 55, "o fundo mobile não mantém as 55 partículas da 0.7.1")
	verificar(particulas.fixed_fps == 30, "a simulação mobile não usa os 30 FPS da 0.7.1")
	verificar(not particulas.interpolate and not particulas.fract_delta, "a simulação econômica deixou de ser determinística")
	verificar(not particulas.trail_enabled, "as trilhas instáveis voltaram a formar teias")
	verificar(is_equal_approx(particulas.lifetime, 10.0), "a vida das partículas ainda está encurtada")
	verificar(particulas.preprocess <= 1.5, "o pico de preprocess voltou ao mobile")
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
		print("TESTE OK: perfil visual mobile equivalente à release 0.7.1")
	get_tree().quit(0 if falhas.is_empty() else 1)

