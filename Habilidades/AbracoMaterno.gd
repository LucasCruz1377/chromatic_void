extends Habilidade
class_name HabilidadeAbracoMaterno


@export_category("Abraço Materno")
@export var cura: float = 32.0
@export var duracao_resistencia: float = 6.0
@export_range(0.1, 1.0, 0.05) var multiplicador_dano: float = 0.55


func em_uso() -> bool:
	return is_instance_valid(piloto_ativacao) and piloto_ativacao.tempo_resistencia_temporaria > 0.0


func executar(player) -> void:
	player.curar(cura)
	player.aplicar_resistencia_temporaria(
		multiplicador_dano,
		duracao_resistencia
	)
	criar_aura(player)


func criar_aura(player) -> void:
	var aura := Line2D.new()
	aura.width = 5.0
	aura.default_color = Color(1.0, 0.42, 0.68, 0.9)
	aura.closed = true
	aura.antialiased = true
	aura.z_index = 6

	for indice in range(48):
		var angulo := TAU * float(indice) / 48.0
		aura.add_point(Vector2.from_angle(angulo) * 28.0)

	player.get_tree().current_scene.add_child(aura)
	aura.global_position = player.global_position
	var tween := aura.create_tween().set_parallel(true)
	tween.tween_property(aura, "scale", Vector2.ONE * 2.6, 0.55)
	tween.tween_property(aura, "modulate:a", 0.0, 0.55)
	tween.chain().tween_callback(aura.queue_free)


func obter_upgrades_especificos() -> Dictionary:
	var icone := "res://Habilidades/Icones/abraco_materno.svg"
	var cor := Color(1.0, 0.42, 0.68)
	return {
		&"abraco_cura": criar_carta_upgrade("ACOLHIMENTO", "Sua habilidade recupera mais vida.", icone, cor, Nome, 3, [&"cura"]),
		&"abraco_duracao": criar_carta_upgrade("CUIDADO DURADOURO", "Sua proteção dura mais tempo.", icone, cor, Nome, 3, [&"duracao"]),
		&"abraco_resistencia": criar_carta_upgrade("PROTEÇÃO MATERNA", "Sua proteção reduz ainda mais o dano recebido.", icone, cor, Nome, 3, [&"defesa"]),
	}


func aplicar_upgrade_especifico(id: StringName, _nivel: int) -> bool:
	match id:
		&"abraco_cura": cura += 8.0
		&"abraco_duracao": duracao_resistencia += 1.0
		&"abraco_resistencia": multiplicador_dano = maxf(multiplicador_dano - 0.08, 0.25)
		_: return false
	return true
