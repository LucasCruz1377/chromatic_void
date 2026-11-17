#!/usr/bin/env python3
"""Regression guard for the extracted projectile math and network visual setup."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
player = (ROOT / "Scripts/player.gd").read_text(encoding="utf-8")
rules = (ROOT / "Scripts/RegrasProjetil.gd").read_text(encoding="utf-8")
panel = (ROOT / "Scripts/PainelDesenvolvedor.gd").read_text(encoding="utf-8")
diagnostics = (ROOT / "Scripts/DiagnosticoDesempenho.gd").read_text(encoding="utf-8")

assert 'const RegrasProjetil = preload("res://Scripts/RegrasProjetil.gd")' in player
assert 'RegrasProjetil.padrao_multitiro(indice, quantidade, dispersao_graus, formacao_convergente)' in player
assert "RegrasProjetil.multiplicar_dano(dano, [" in player
assert "static func padrao_multitiro(" in rules
assert "static func multiplicar_dano(" in rules
assert 'particles.has_meta("material_rastro_individual")' in player
assert 'material_particulas.color = cor_nave' in player
assert 'preload("res://Scripts/DiagnosticoDesempenho.gd").new()' in panel
assert "Performance.get_monitor(Performance.OBJECT_COUNT)" in diagnostics
assert "KEY_F3" in diagnostics
projectile = (ROOT / "Scripts/ProjetilInimigo.gd").read_text(encoding="utf-8")
assert "configuracao.property_set_sync(caminho, caminho in propriedades_movimento)" in projectile
assert "NodePath(\".:modulate\")" in projectile
assert "NodePath(\".:rebotes_max\")" in projectile
assert "O MultiplayerSpawner remove a copia" in projectile
assert "var prazo_visual_iniciado := false" in projectile
assert "prazo_visual_rede -= delta" in projectile
assert "if not prazo_visual_iniciado:" in projectile
boss = (ROOT / "Scripts/BossPet0.gd").read_text(encoding="utf-8")
assert "_replicar_projetil_pet0.rpc(" not in boss
assert "func _replicar_projetil_pet0(" not in boss
assert "_replicar_minion_pet0.rpc(" not in boss
assert "func _replicar_minion_pet0(" not in boss
for metodo in ("escolher_ataque", "disparar_tampinhas", "liberar_pressao", "invocar_microplasticos", "criar_fragmento", "registrar_reciclagem"):
    trecho = boss.split("func " + metodo + "(", 1)[1].split("\n", 4)
    assert "if Rede.modo_multiplayer and not multiplayer.is_server():" in "\n".join(trecho), metodo
assert "func atualizar_fase() -> void:\n\tif Rede.modo_multiplayer and not multiplayer.is_server():" in boss
assert "func morrer() -> void:\n\tif Rede.modo_multiplayer and not multiplayer.is_server():" in boss
assert "func remover_rotulo() -> void:\n\tif Rede.modo_multiplayer and not multiplayer.is_server():" in boss
fragmento = (ROOT / "Scripts/FragmentoReciclavel.gd").read_text(encoding="utf-8")
assert "tempo_restante -= delta" in fragmento
assert "if tempo_restante <= 0.0:" in fragmento
assert "_replicar_fragmento_pet0.rpc(" not in boss
assert "func _replicar_fragmento_pet0(" not in boss
assert "fragmento.global_position = global_position + deslocamento" in boss
assert "get_tree().current_scene.add_child(fragmento, true)" in boss
arena = (ROOT / "Scripts/battle_area.gd").read_text(encoding="utf-8")
assert '"res://Entities/FragmentoReciclavel.tscn"' in arena
assert '"res://Entities/InimigoMinion.tscn"' in arena
assert '@rpc("authority", "call_remote", "reliable", 3)\\nfunc _publicar_posicoes_mundo' in arena
assert "global_position += direcao_visual.normalized() * velocidade * delta" not in projectile
inimigo_base = (ROOT / "Scripts/InimigoBase.gd").read_text(encoding="utf-8")
assert "global_position += velocity * delta" not in inimigo_base
assert 'for grupo in [&"residuo_pet0", &"minion_pet0"]:' in arena
assert "var emitindo_rastro := propulsao_acionada" in player
assert "var propulsao_acionada := false" in player
assert "velocity.length_squared() > 64.0" not in player
print("TESTE OK: contratos de projeteis, cores, propulsao e diagnostico preservados")
