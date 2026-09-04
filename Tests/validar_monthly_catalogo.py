#!/usr/bin/env python3
"""Validação estática do catálogo Monthly Colors e das recompensas."""

from pathlib import Path
import re


ROOT = Path(__file__).resolve().parents[1]
CATALOGO = (ROOT / "Scripts/MonthlyCatalog.gd").read_text(encoding="utf-8")
GLOBAL = (ROOT / "Scripts/Global.gd").read_text(encoding="utf-8")
PLAYER = (ROOT / "Scripts/player.gd").read_text(encoding="utf-8")

ids = re.findall(r'_item\(&"([pan u]\d\d_[^"]+)"'.replace(" ", ""), CATALOGO)
esperados = {"p": 15, "a": 13, "n": 10, "u": 12}
for prefixo, total in esperados.items():
    encontrados = [item for item in ids if item.startswith(prefixo)]
    assert len(encontrados) == total, (prefixo, len(encontrados), total)

assert len(ids) == 50, f"Esperados 50 itens; encontrados {len(ids)}"
assert len(set(ids)) == len(ids), "Há IDs duplicados no catálogo"

recompensas = re.findall(r'&"([panu]\d\d_[^"]+)"', GLOBAL)
for recompensa in recompensas:
    assert recompensa in ids, f"Recompensa inexistente: {recompensa}"

obrigatorias_por_conquista = {
    "p05_florescimento",
    "a06_feixe_perielio",
    "a12_jardim_orbital",
    "a13_canhao_lua_fria",
    "u01_alcateia_lunar",
    "u04_floracao_rosa",
    "u05_jardim_crescente",
    "u08_corrente_esturjao",
    "u10_marca_cacador",
    "u12_noite_congelada",
}
for item in obrigatorias_por_conquista:
    assert item in recompensas, f"Item de boss sem conquista: {item}"

for indice in range(1, 16):
    recurso = ROOT / "Habilidades" / f"monthly_p{indice:02d}.tres"
    assert recurso.exists(), f"Recurso ativo ausente: {recurso.name}"

for item in [i for i in ids if i.startswith(("a", "n", "u"))]:
    assert item in PLAYER, f"Item não conectado à jogabilidade: {item}"

print("Catálogo Monthly Colors verificado: 50 itens, conquistas e runtime conectados.")
