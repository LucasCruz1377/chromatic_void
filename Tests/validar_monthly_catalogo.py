#!/usr/bin/env python3
"""Validação estática do catálogo Monthly Colors e das recompensas."""

from pathlib import Path
import hashlib
import re
import xml.etree.ElementTree as ET


ROOT = Path(__file__).resolve().parents[1]
CATALOGO = (ROOT / "Scripts/MonthlyCatalog.gd").read_text(encoding="utf-8")
GLOBAL = (ROOT / "Scripts/Global.gd").read_text(encoding="utf-8")
PLAYER = (ROOT / "Scripts/player.gd").read_text(encoding="utf-8")

ids = re.findall(r'_item\(&"([pan u]\d\d_[^"]+)"'.replace(" ", ""), CATALOGO)
esperados = {"p": 15, "a": 12, "n": 10, "u": 12}
for prefixo, total in esperados.items():
    encontrados = [item for item in ids if item.startswith(prefixo)]
    assert len(encontrados) == total, (prefixo, len(encontrados), total)

assert len(ids) == 49, f"Esperados 49 itens após a fusão das armas; encontrados {len(ids)}"
assert len(set(ids)) == len(ids), "Há IDs duplicados no catálogo"
assert '"icone": "res://Habilidades/Icones/monthly/%s.svg" % String(id)' in CATALOGO

diretorio_icones = ROOT / "Habilidades" / "Icones" / "monthly"
icones = sorted(diretorio_icones.glob("*.svg"))
assert len(icones) >= len(ids), f"Ícones insuficientes; encontrados {len(icones)}"
for item in ids:
    caminho_icone = diretorio_icones / f"{item}.svg"
    assert caminho_icone.exists(), f"Ícone ausente para {item}"
    ET.parse(caminho_icone)
hashes = {hashlib.sha256(icone.read_bytes()).hexdigest() for icone in icones}
assert len(hashes) == len(icones), "Há ícones SVG repetidos no catálogo"

# O catálogo só pode usar as doze luas que o site apresenta. Uma delas também
# pode nomear uma arma, desde que não invente uma décima terceira Lua.
bloco_armas = CATALOGO.split("static func armas()", 1)[1].split("static func naves()", 1)[0]
bloco_upgrades = CATALOGO.split("static func upgrades()", 1)[1].split("static func personalizacao()", 1)[0]
for lua in [
    "LUA DO LOBO", "LUA DA NEVE", "LUA DO VERME", "LUA ROSA",
    "LUA DAS FLORES", "LUA DE MORANGO", "LUA DOS CERVOS",
    "LUA DO ESTURJÃO", "LUA DA COLHEITA", "LUA DO CAÇADOR",
    "LUA DO CASTOR", "LUA FRIA",
]:
    assert lua in bloco_upgrades, f"Lua anual ausente dos upgrades: {lua}"

assert '&"a02_rifle_cacador"' not in bloco_armas, "a sniper antiga ainda aparece na loja"
assert 'CANHÃO DO ESTURJÃO' in bloco_armas
assert 'const FONTES_SITE' in CATALOGO
assert 'func _somente_itens_do_site' in CATALOGO
bloco_fontes = CATALOGO.split("const FONTES_SITE", 1)[1].split("static func ativos", 1)[0]
for item in ids:
    assert f'&"{item}"' in bloco_fontes, f"Item sem fonte positiva do site: {item}"

assert '"id": &"c01_modelo_padrao"' in CATALOGO
assert CATALOGO.count('"em_breve": true') == 1
assert CATALOGO.count('"grupo_personalizacao": &"modelo"') == 5
assert CATALOGO.count('"grupo_personalizacao": &"cor"') == 1  # As outras cores usam _cor().
assert CATALOGO.count('_cor(&"c1') == 6
assert '4: return personalizacao()' in CATALOGO

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

print("Catálogo verificado: 49 equipamentos, 12 luas, fontes do site e migração da arma.")
