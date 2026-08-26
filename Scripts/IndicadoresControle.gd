extends RefCounted
class_name IndicadoresControle


const PASTA_ICONES := "res://Assets/UI/IndicadoresControle/"

const ICONES_XBOX := {
	JOY_BUTTON_A: "A.svg",
	JOY_BUTTON_B: "B.svg",
	JOY_BUTTON_X: "X.svg",
	JOY_BUTTON_Y: "Y.svg",
	JOY_BUTTON_LEFT_SHOULDER: "LB.svg",
	JOY_BUTTON_RIGHT_SHOULDER: "RB.svg",
}

const ICONES_PLAYSTATION := {
	JOY_BUTTON_A: "xis.svg",
	JOY_BUTTON_B: "bola.svg",
	JOY_BUTTON_X: "quad.svg",
	JOY_BUTTON_Y: "tri.svg",
	JOY_BUTTON_LEFT_SHOULDER: "L1.svg",
	JOY_BUTTON_RIGHT_SHOULDER: "R1.svg",
}

static var _cache_texturas: Dictionary = {}


static func usa_layout_playstation() -> bool:
	var controles := Input.get_connected_joypads()
	if controles.is_empty():
		return false
	var dispositivo: int = controles[0]
	if controles.has(Global.ultimo_controle_id):
		dispositivo = Global.ultimo_controle_id
	var nome := Input.get_joy_name(dispositivo).strip_edges().to_lower()
	return (
		"playstation" in nome
		or "dualshock" in nome
		or "dualsense" in nome
		or "sony" in nome
		or "ps4" in nome
		or "ps5" in nome
		or nome == "wireless controller"
	)


static func caminho_para_evento(evento: InputEvent) -> String:
	if evento is InputEventJoypadButton:
		var icones := ICONES_PLAYSTATION if usa_layout_playstation() else ICONES_XBOX
		var arquivo := str(icones.get(evento.button_index, ""))
		return PASTA_ICONES + arquivo if not arquivo.is_empty() else ""

	if evento is InputEventJoypadMotion:
		var arquivo := ""
		if evento.axis == JOY_AXIS_TRIGGER_LEFT:
			arquivo = "L2.svg" if usa_layout_playstation() else "LT.svg"
		elif evento.axis == JOY_AXIS_TRIGGER_RIGHT:
			arquivo = "R2.svg" if usa_layout_playstation() else "RT.svg"
		return PASTA_ICONES + arquivo if not arquivo.is_empty() else ""

	return ""


static func textura_para_evento(evento: InputEvent) -> Texture2D:
	if evento == null:
		return null
	var caminho := caminho_para_evento(evento)
	if caminho.is_empty() or not ResourceLoader.exists(caminho):
		return null
	if not _cache_texturas.has(caminho):
		_cache_texturas[caminho] = load(caminho) as Texture2D
	return _cache_texturas[caminho] as Texture2D


static func evento_controle_para_acao(acao: StringName) -> InputEvent:
	if Global.obter_acoes_remapeaveis().has(acao):
		for slot in Global.MAX_SLOTS_CONTROLE:
			var evento := Global.obter_evento_mapeado(acao, slot)
			if evento != null and not caminho_para_evento(evento).is_empty():
				return evento
		return null

	if not InputMap.has_action(acao):
		return null
	for evento in InputMap.action_get_events(acao):
		if not caminho_para_evento(evento).is_empty():
			return evento
	return null


static func textura_para_acao(acao: StringName) -> Texture2D:
	return textura_para_evento(evento_controle_para_acao(acao))


static func caminho_para_acao(acao: StringName) -> String:
	var evento := evento_controle_para_acao(acao)
	return caminho_para_evento(evento) if evento != null else ""
