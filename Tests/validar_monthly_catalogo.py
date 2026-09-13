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
esperados = {"p": 14, "a": 12, "n": 10, "u": 13}
for prefixo, total in esperados.items():
    encontrados = [item for item in ids if item.startswith(prefixo)]
    assert len(encontrados) == total, (prefixo, len(encontrados), total)

assert len(ids) == 49, f"Esperados 49 itens após adicionar Dobro de Experiência; encontrados {len(ids)}"
assert 'p09_recomeco' not in ids, "Recomeço voltou ao catálogo ativo"
assert len(set(ids)) == len(ids), "Há IDs duplicados no catálogo"
assert '"icone": "res://Habilidades/Icones/monthly/%s.svg" % String(id)' in CATALOGO

diretorio_icones = ROOT / "Habilidades" / "Icones" / "monthly"
icones = sorted(diretorio_icones.glob("*.svg"))
assert len(icones) >= len(ids), f"Ícones insuficientes; encontrados {len(icones)}"
for item in ids:
    caminho_icone = diretorio_icones / f"{item}.svg"
    assert caminho_icone.exists(), f"Ícone ausente para {item}"
    ET.parse(caminho_icone)
    svg = caminho_icone.read_text(encoding="utf-8")
    assert 'cx="18" cy="108"' not in svg, f"Marcador de poder reapareceu em {item}"
    assert 'M13 108l10-10' not in svg, f"Marcador de upgrade reapareceu em {item}"
    assert "<filter" not in svg, f"Filtro borrado reapareceu em {item}"
    assert ".base{" in svg and ".accent" in svg, f"Linguagem visual nova ausente em {item}"
hashes = {hashlib.sha256(icone.read_bytes()).hexdigest() for icone in icones}
assert len(hashes) == len(icones), "Há ícones SVG repetidos no catálogo"

for caminho_icone in sorted((ROOT / "Habilidades" / "Icones" / "upgrades_armas").glob("*.svg")):
    ET.parse(caminho_icone)
    svg = caminho_icone.read_text(encoding="utf-8")
    assert "<filter" not in svg, f"Filtro borrado reapareceu em {caminho_icone.name}"
    assert ".base{" in svg and ".accent" in svg, f"Estilo antigo ausente em {caminho_icone.name}"

# Protege exatamente o conjunto original introduzido em f69845a.
icones_originais = {
    "abraco_materno.svg": "0c96dd7d5b3d744730b714a021bafcaec019e6aab642225bcc7c1d18cbe09eb7",
    "aura_serenidade.svg": "5fe502bcc860f5a286a33cd0e8f1ea3adfc0578e21f907f7cea8ac9e692da67c",
    "cooldown_relogio.svg": "22c46d0c1f63f6c0b1aa2809e8dea23b8c1ebab8df5927f52adfcbe88ab16a18",
    "escudo_protetor.svg": "625843a5791fefa15b7126b54548c3d872edebd69a2f9d45fbb93e78db0b619d",
    "foco_absoluto.svg": "a2d8d19caaf27f8a0453cb7825d2a1dd9ce23dc4ce730b539ec16fc8cfd6f2f8",
    "fogueira_ardente.svg": "c553272105c5bda3f5132e7312c31f109fcfb711d12d35bbc4fcf8217d87bd72",
    "frenesi_carnavalesco.svg": "24bf9100af50d45cba2944d19ac729920d48f018d405a8d2c97ec24c787cafb8",
    "hiperdash.svg": "8ef2794c99621577ef6e5166ff6df3807831b2c11fa142f6225773d2e5e417c1",
    "onda_choque.svg": "9bc7eaf0b8ab562e8618d59f7bda331212bfb53aba3928a29f63f1ff5656bc1b",
    "retrocesso.svg": "1c249fb895b5d5945dabb879a5ac8b6f7a77b27521a10ab0b4827ed598db5605",
    "transfusao.svg": "d00de77208f6b7cd197458a68854f5e978abda154d2c9b3d0f4410634a522f29",
}
for nome, hash_esperado in icones_originais.items():
    caminho = ROOT / "Habilidades" / "Icones" / nome
    assert hashlib.sha256(caminho.read_bytes()).hexdigest() == hash_esperado, f"Ícone original alterado: {nome}"

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
assert CATALOGO.count('"em_breve": true') == 0
assert CATALOGO.count('"grupo_personalizacao": &"modelo"') == 9
assert CATALOGO.count('"grupo_personalizacao": &"cor"') == 1  # As outras cores usam _cor().
assert CATALOGO.count('"grupo_personalizacao": &"rastro"') == 4
assert '&"c07_modelo_o"' in CATALOGO
assert '&"c21_rastro_estelar_o"' in CATALOGO
assert '"requer_modelo": &"c07_modelo_o"' in CATALOGO
assert '&"c08_modelo_spectrum"' in CATALOGO
assert '&"c09_modelo_fspeed"' in CATALOGO
assert '"requer_modelo": &"c08_modelo_spectrum"' in CATALOGO
assert '"requer_modelo": &"c09_modelo_fspeed"' in CATALOGO
assert CATALOGO.count('_cor(&"c1') == 6
assert '4: return personalizacao()' in CATALOGO

recompensas = re.findall(r'&"([panu]\d\d_[^"]+)"', GLOBAL)
for recompensa in recompensas:
    assert recompensa in ids, f"Recompensa inexistente: {recompensa}"

obrigatorias_por_conquista = {
    "p05_florescimento",
    "a06_feixe_perielio",
    "a12_jardim_orbital",
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
    if indice == 9:
        continue
    recurso = ROOT / "Habilidades" / f"monthly_p{indice:02d}.tres"
    assert recurso.exists(), f"Recurso ativo ausente: {recurso.name}"
    if indice > 1:
        texto = recurso.read_text(encoding="utf-8")
        assert "monthly_cristal.svg" not in texto, f"{recurso.name} ainda usa o ícone genérico"
        assert f"Icones/monthly/p{indice:02d}_" in texto, f"{recurso.name} não aponta para seu ícone"

for item in [i for i in ids if i.startswith(("a", "n", "u"))]:
    assert item in PLAYER, f"Item não conectado à jogabilidade: {item}"

print("Catálogo verificado: 49 equipamentos, Dobro de Experiência e 12 luas preservadas.")
