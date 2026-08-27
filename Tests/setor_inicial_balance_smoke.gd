extends Node


const Batalha = preload("res://Scripts/battle_area.gd")
const Seguidor = preload("res://Entities/InimigoSeguidor.tscn")
const Melee = preload("res://Entities/InimigoMelee.tscn")
const Investida = preload("res://Entities/InimigoInvestida.tscn")
const Atirador = preload("res://Entities/InimigoAtirador.tscn")
const Tanque = preload("res://Entities/InimigoTanque.tscn")

var falhas: Array[String] = []


func verificar(condicao: bool, mensagem: String) -> void:
	if condicao:
		return
	falhas.append(mensagem)
	push_error("SETOR INICIAL: " + mensagem)


func _ready() -> void:
	testar_inicio_legivel()
	testar_atributos_iniciais()
	testar_avisos_visuais()
	if falhas.is_empty():
		print("TESTE OK: progressão e leitura do setor inicial")
		get_tree().quit(0)
	else:
		get_tree().quit(1)


func testar_inicio_legivel() -> void:
	var batalha := Batalha.new()
	for _tentativa in 30:
		verificar(
			batalha.escolher_tipo_inimigo(1) == Seguidor,
			"o nível 1 ofereceu uma ameaça avançada"
		)
		verificar(
			batalha.escolher_tipo_inimigo(2) == Seguidor,
			"o nível 2 ofereceu uma ameaça avançada"
		)
	var tipos_nivel_tres := {}
	for _tentativa in 60:
		tipos_nivel_tres[batalha.escolher_tipo_inimigo(3)] = true
	verificar(Investida not in tipos_nivel_tres, "a investida surgiu antes do nível 5")
	verificar(Atirador not in tipos_nivel_tres, "o atirador surgiu antes do nível 6")
	verificar(Tanque not in tipos_nivel_tres, "o tanque surgiu antes do nível 7")
	batalha.free()


func testar_atributos_iniciais() -> void:
	var seguidor := Seguidor.instantiate() as InimigoBase
	var melee := Melee.instantiate() as InimigoBase
	var investida := Investida.instantiate() as InimigoBase
	var atirador := Atirador.instantiate() as InimigoBase
	var tanque := Tanque.instantiate() as InimigoBase
	verificar(seguidor.VidaMaxima <= 2.5, "o seguidor inicial voltou a ser resistente demais")
	verificar(seguidor.Dano <= 12.0, "o dano do seguidor inicial está excessivo")
	verificar(melee.ValorXP >= 2.0, "o melee não recompensa sua ameaça")
	verificar(investida.ValorXP >= 2.5, "a investida não recompensa seu risco")
	verificar(atirador.ValorXP >= 2.5, "o atirador não recompensa seu risco")
	verificar(tanque.ValorXP >= 4.0, "o tanque não recompensa sua resistência")
	for inimigo in [seguidor, melee, investida, atirador, tanque]:
		inimigo.free()


func testar_avisos_visuais() -> void:
	var investida := Investida.instantiate()
	var melee := Melee.instantiate()
	var atirador := Atirador.instantiate()
	verificar(investida.has_node("LinhaAviso"), "a investida não possui linha de aviso")
	verificar(melee.has_node("Golpe"), "o melee não possui área legível de golpe")
	verificar(atirador.has_node("LinhaAviso"), "o atirador não possui linha de mira")
	investida.free()
	melee.free()
	atirador.free()
