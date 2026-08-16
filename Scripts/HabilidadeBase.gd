extends Resource
class_name Habilidade


@export_category("Identidade")
@export var Id: StringName = &""
@export var Nome: String = "Habilidade"
@export_multiline var Descricao: String = ""
@export var Icone: Texture2D

@export_category("Monthly Colors")
@export var MonthlyColorsSelo: String = ""
@export_multiline var MonthlyColorsContexto: String = ""
@export var MonthlyColorsUrl: String = "https://tami4lvess.github.io/Monthly-Colors/"

@export_category("Recarga")
@export var Cooldown: float = 1.0

var cooldown_atual: float = 0.0


func activate(player) -> bool:
	if not pode_ativar(player):
		return false

	cooldown_atual = maxf(Cooldown, 0.0)
	executar(player)
	return true


func update(player, delta: float) -> void:
	if cooldown_atual > 0.0:
		cooldown_atual = maxf(cooldown_atual - delta, 0.0)

	atualizar(player, delta)


func pode_ativar(player) -> bool:
	return (
		is_instance_valid(player)
		and player.vivo
		and cooldown_atual <= 0.0
	)


func executar(_player) -> void:
	pass


func atualizar(_player, _delta: float) -> void:
	pass


func ao_equipar(_player) -> void:
	pass


func ao_desequipar(_player) -> void:
	pass


func reiniciar_estado() -> void:
	cooldown_atual = 0.0


func reduzir_cooldown(fator: float) -> void:
	if fator <= 0.0:
		return

	Cooldown = maxf(Cooldown * fator, 0.05)
	cooldown_atual = minf(cooldown_atual, Cooldown)


func reduzir_cooldown_atual(segundos: float) -> void:
	if segundos <= 0.0:
		return
	cooldown_atual = maxf(cooldown_atual - segundos, 0.0)


func cooldown_pronto() -> bool:
	return cooldown_atual <= 0.0


# Cada habilidade pode expor cartas exclusivas sem aumentar o catálogo global.
# O Player chama aplicar_upgrade_especifico somente para a habilidade equipada.
func obter_upgrades_especificos() -> Dictionary:
	return {}


func aplicar_upgrade_especifico(_id: StringName, _nivel: int) -> bool:
	return false


func criar_carta_upgrade(
	nome: String,
	descricao: String,
	caminho_icone: String,
	cor: Color,
	categoria: String,
	max_nivel := 3,
	tags_extras: Array = []
) -> Dictionary:
	var tags: Array = [&"habilidade", &"habilidade_especifica"]
	tags.append_array(tags_extras)
	return {
		"nome": nome,
		"descricao": descricao,
		"icone": caminho_icone,
		"categoria": categoria.to_upper() + " • HABILIDADE",
		"raridade": "ESPECÍFICA",
		"cor": cor,
		"max_nivel": max_nivel,
		"peso": 1.4,
		"requisitos": {},
		"tags": tags,
	}
