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
print("TESTE OK: contratos de projeteis, cores e diagnostico preservados")
