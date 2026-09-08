extends RefCounted

const SONS := {
 &"retrocesso": preload("res://sounds/SFX/Retrocesso.wav"),
 &"petalas": preload("res://sounds/SFX/petalas_boomerang.wav"),
 &"investida": preload("res://sounds/SFX/inimigo_investida.wav"),
 &"dash": preload("res://sounds/SFX/Player_dash.wav"),
 &"cura": preload("res://sounds/SFX/Curar.wav"),
}

static func tocar(emissor: Node, id: StringName, intervalo: float = 0.12) -> void:
 if not is_instance_valid(emissor) or not emissor.is_inside_tree(): return
 var chave := "som_" + str(id)
 var agora := Time.get_ticks_msec()
 if agora < int(emissor.get_meta(chave, 0)): return
 emissor.set_meta(chave, agora + int(intervalo * 1000.0))
 var som := AudioStreamPlayer.new()
 som.stream = SONS[id]
 som.bus = &"Sound"
 som.volume_db = -9.0
 emissor.add_child(som)
 som.finished.connect(som.queue_free)
 som.play()
