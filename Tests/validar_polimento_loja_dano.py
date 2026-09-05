#!/usr/bin/env python3
"""Valida as conexões do polimento de loja, mina e feedback de dano."""

from pathlib import Path
import hashlib


ROOT = Path(__file__).resolve().parents[1]
SHOP = (ROOT / "Scripts/shopcontroler.gd").read_text(encoding="utf-8")
PLAYER = (ROOT / "Scripts/player.gd").read_text(encoding="utf-8")
PROJECTILE = (ROOT / "Scripts/fireball.gd").read_text(encoding="utf-8")
ENEMY = (ROOT / "Scripts/InimigoBase.gd").read_text(encoding="utf-8")
EFFECT = (ROOT / "Scripts/EfeitoCombate.gd").read_text(encoding="utf-8")
INDICATOR = (ROOT / "Scripts/IndicadorDano.gd").read_text(encoding="utf-8")
HITFLASH_SHADER = (ROOT / "FX/canvas_shader/enemy.gdshader").read_text(encoding="utf-8")
SIZIGIA = (ROOT / "Scripts/BossSizigiaEterna.gd").read_text(encoding="utf-8")
PROJECT = (ROOT / "project.godot").read_text(encoding="utf-8")
UPGRADES = (ROOT / "Scripts/UpgradeData.gd").read_text(encoding="utf-8")
CAMERA = (ROOT / "Scripts/camera.gd").read_text(encoding="utf-8")

assert '"PERSONALIZAÇÃO"' in SHOP
assert 'botao_acao.clip_text = true' in SHOP
assert 'func _aplicar_layout_responsivo()' in SHOP
assert 'grade.columns = colunas' in SHOP
assert 'func _on_acao_personalizacao(item: Dictionary)' in SHOP
assert '"personalizacao_nave": personalizacao_nave' in SHOP
assert '"MODELOS"' in SHOP and '"CORES"' in SHOP and '"RASTROS"' in SHOP
assert 'func obter_itens_categoria_atual()' in SHOP
assert 'filtro_personalizacao' in SHOP
assert 'window/stretch/aspect="expand"' in PROJECT

assert '&"a05_minas_castor"' in PLAYER
assert '"explosao": 1.2' in PLAYER
assert 'RAIO_ATIVACAO_SINALIZADOR := 132.0' in PROJECTILE
assert 'TEMPO_ARMAR_SINALIZADOR := 0.30' in PROJECTILE
assert 'aplicar_onda_de_impacto(null)' in PROJECTILE
assert 'forma_mina.radius = 22.0' in PROJECTILE
assert 'duracao_mina_total := 5.0' in PROJECTILE
assert 'modo_mina: StringName = &"tempo"' in PROJECTILE
assert 'func detonar_mina()' in PROJECTILE
assert 'tempo_detonacao := maxf(5.0' in PLAYER
assert '"tempo_vida": 0.26' in PLAYER
assert '&"harvest_boomerang"' in PLAYER
assert 'func _processar_bumerangue_colheita' in PROJECTILE
assert 'func _atingir_com_bumerangue' in PROJECTILE
assert 'bumerangue_alvos_retorno' in PROJECTILE
assert (ROOT / "Assets/Armas/arco_colheita.svg").exists()

assert 'IndicadorDanoCena.criar' in ENEMY
assert 'reproduzir_impacto(dano_final)' in ENEMY
assert 'reproduzir_impacto(dano_final)' in SIZIGIA
assert 'preparar_materiais_hitflash()' in ENEMY
assert 'tween_method(_definir_hitflash_shader' in ENEMY
assert 'clamp(brightness, 0.0, 1.0)' in HITFLASH_SHADER
assert 'func _draw()' not in INDICATOR
assert 'draw_arc(Vector2.ZERO, raio' not in EFFECT
assert 'func _desenhar_carga_arma()' in PLAYER
assert 'PontaArma.position + Vector2(5.0, 0.0)' in PLAYER
assert (ROOT / "Scripts/IndicadorDano.gd").exists()
assert (ROOT / "UI/nave_padrao_preview.svg").exists()
assert (ROOT / "UI/personalizacao_em_breve.svg").exists()
for nome in [
    "nave_asa_delta.svg", "nave_nucleo_orbital.svg",
    "nave_dardo.svg", "nave_interceptor.svg", "cor_nave_preview.svg",
]:
    assert (ROOT / "UI" / nome).exists(), nome
assert 'func aplicar_personalizacao_nave()' in (ROOT / "Scripts/player.gd").read_text(encoding="utf-8")

assert 'const DADOS_ARMAS' in UPGRADES
assert UPGRADES.count('"arma_exclusiva":') == 25
assert 'func _compativel_com_arma' in UPGRADES
assert 'especificos_arma' in UPGRADES
icones_upgrades = sorted((ROOT / "Habilidades/Icones/upgrades_armas").glob("*.svg"))
assert len(icones_upgrades) == 25
hashes_upgrades = {hashlib.sha256(icone.read_bytes()).hexdigest() for icone in icones_upgrades}
assert len(hashes_upgrades) == 25, "Há ícones repetidos nas melhorias específicas"

assert 'ForcaShake = maxf(ForcaShake, alvo)' in CAMERA
assert 'ForcaShake + magnitude' not in CAMERA
assert 'camera_transicao.shake(18.0, true)' in SIZIGIA
assert 'camera.shake(obter_tremor_morte(), is_in_group("boss"))' in ENEMY

print("Polimento verificado: loja, filtros, skins, sinalizador, efeitos e hitflash.")
