extends Node

var setor_atual: StringName = &"vazio_inicial"
var falhas: Array[String] = []
const Criticos = preload("res://Scripts/Criticos.gd")
const Audio = preload("res://Scripts/AudioCombate.gd")

class Alvo:
	extends Node2D
	var recebido := 0.0
	var critico := false
	func tomarDano(valor: float) -> void:
		recebido += valor
		critico = bool(get_meta("impacto_critico", false))

func verificar(ok: bool, mensagem: String) -> void:
	if not ok: falhas.append(mensagem); push_error(mensagem)

func _ready() -> void:
	var base := Criticos.valores(&"a04_canhao_esturjao")
	var melhor := Criticos.valores(&"a04_canhao_esturjao", {&"precisao_critica":3, &"impacto_critico":3})
	verificar(is_equal_approx(base.x, 0.18) and is_equal_approx(base.y, 2.0), "Base crítica do canhão incorreta")
	verificar(is_equal_approx(melhor.x, 0.30) and is_equal_approx(melhor.y, 2.45), "Upgrades críticos incorretos")
	verificar(Criticos.valores(&"a06_feixe_perielio").x < base.x, "Arma rápida deve ter chance menor")
	verificar(not preload("res://Scripts/UpgradeData.gd").DADOS.has(&"capacitor_cinetico"), "Capacitor ainda oferecido")
	var alvo := Alvo.new()
	var tiro := preload("res://Scripts/fireball.gd").new()
	tiro.eh_critico = true
	tiro._aplicar_dano_critico(alvo, 20.0)
	verificar(alvo.recebido == 20.0 and alvo.critico and not alvo.has_meta("impacto_critico"), "Crítico deve propagar feedback sem contaminar próximo acerto")
	tiro.eh_critico = false
	tiro._aplicar_dano_critico(alvo, 10.0)
	verificar(alvo.recebido == 30.0 and not alvo.critico, "Acerto normal ficou crítico")
	tiro.free(); alvo.free()
	for indice in range(5):
		setor_atual = preload("res://Scripts/SectorData.gd").ORDEM_CICLO[indice]
		var inimigo := InimigoBase.new()
		inimigo.VidaMaxima = 100.0
		add_child(inimigo)
		verificar(is_equal_approx(inimigo.VidaMaxima, 100.0 * (1.0 + 0.18 * indice)), "Vida por setor incorreta")
		inimigo.free()
	var emissor := Node.new()
	add_child(emissor)
	Audio.tocar(emissor, &"petalas")
	Audio.tocar(emissor, &"petalas")
	verificar(emissor.get_child_count() == 1, "Áudio duplicado na mesma emissão")
	emissor.free()
	var flor := BossCaosPrimaveril.new()
	for fase in range(1,4):
		flor.fase = fase
		verificar(is_equal_approx(flor._duracao_janela_vulneravel(), 3.0 - (fase-1)*0.75), "Janela da flor incorreta")
	flor.free()
	if falhas.is_empty(): print("TESTE OK: críticos, progressão, áudio único e janelas 0.7.3")
	get_tree().quit(0 if falhas.is_empty() else 1)
