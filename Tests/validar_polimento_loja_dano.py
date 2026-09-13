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
GLOBAL = (ROOT / "Scripts/Global.gd").read_text(encoding="utf-8")
SETORES = (ROOT / "Scripts/SectorData.gd").read_text(encoding="utf-8")
BATALHA = (ROOT / "Scripts/battle_area.gd").read_text(encoding="utf-8")
CATALOGO = (ROOT / "Scripts/MonthlyCatalog.gd").read_text(encoding="utf-8")
MENU = (ROOT / "Scripts/tela_inicial.gd").read_text(encoding="utf-8")
REDE = (ROOT / "Scripts/GerenciadorMultiplayer.gd").read_text(encoding="utf-8")
RASTRO_EXCLUSIVO = (ROOT / "Scripts/RastroExclusivo.gd").read_text(encoding="utf-8")
SIZIGIA_FINAL = (ROOT / "Scripts/SizigiaFinalController.gd").read_text(encoding="utf-8")
FLOR = (ROOT / "Scripts/BossCaosPrimaveril.gd").read_text(encoding="utf-8")
BOSS_PET = (ROOT / "Entities/BossPet0.tscn").read_text(encoding="utf-8")
BOSS_AMPARO = (ROOT / "Entities/BossConstelacaoAmparo.tscn").read_text(encoding="utf-8")
BOSS_AMETISTA = (ROOT / "Entities/BossNoAmetista.tscn").read_text(encoding="utf-8")
BOSS_FLOR = (ROOT / "Entities/BossFlorEquinocio.tscn").read_text(encoding="utf-8")
BOSS_SIZIGIA = (ROOT / "Entities/BossEclipseColheita.tscn").read_text(encoding="utf-8")

assert '"PERSONALIZAÇÃO"' in SHOP
assert 'botao_acao.clip_text = false' in SHOP
assert 'func _aplicar_layout_responsivo(' in SHOP
assert 'func _ajustar_largura_coluna_detalhes()' in SHOP
assert 'func _ajustar_fonte_botao_acao()' in SHOP
assert 'grade.columns = colunas' in SHOP
assert 'conteudo_principal.vertical = false' in SHOP
assert 'CatalogoMonthly.habilidades_base()' in SHOP
assert 'habilidadeFrenesiCarnavalesco.tres' in CATALOGO
assert ', 15000, Color("ff3dc2")' in CATALOGO
assert 'detalhe_icone.custom_minimum_size = Vector2(78, 78)' in SHOP
assert 'detalhe_contexto.custom_minimum_size' in SHOP
assert 'detalhe_contexto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART' in SHOP
assert 'var linha_icone := HBoxContainer.new()' in SHOP
assert 'detalhe_descricao.custom_minimum_size = Vector2(0, 72)' in SHOP
assert 'estrutura_detalhes.add_child(preco_box)' in SHOP
assert 'estrutura_detalhes.add_child(botao_acao)' in SHOP
assert 'VISITAR MONTHLY COLORS' in SHOP
assert 'detalhe_recarga.autowrap_mode' in SHOP
assert 'InputEventScreenDrag' in SHOP
assert '"DESEQUIPAR"' in SHOP
assert 'func _on_acao_personalizacao(item: Dictionary)' in SHOP
assert 'func requisito_compra_atendido(item: Dictionary)' in SHOP
assert 'requisito in Global.conquistas_desbloqueadas' in SHOP
assert 'BLOQUEADO • CONQUISTA SECRETA' in SHOP
assert '"personalizacao_nave": personalizacao_nave' in SHOP
assert '"MODELOS"' in SHOP and '"CORES"' in SHOP and '"RASTROS"' in SHOP
assert 'func obter_itens_categoria_atual()' in SHOP
assert 'filtro_personalizacao' in SHOP
assert 'window/stretch/aspect="expand"' in PROJECT
assert 'opcoes.name = "OpcoesMultiplayer"' in MENU
assert 'painel_lobbies.name = "PainelLobbiesLan"' in MENU
assert '_atualizar_lista_lobbies_lan(_lobbies)' in MENU
assert 'Vector2(760.0, 470.0)' in MENU
assert 'if ocupacao >= capacidade:' in REDE
assert '"jogadores": jogadores.size()' in REDE
assert 'func _dados_lobby_mudaram(' in REDE

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
    "nave_dardo.svg", "nave_interceptor.svg", "nave_estrela_rosa.svg",
    "cor_nave_preview.svg",
]:
    assert (ROOT / "UI" / nome).exists(), nome
for nome in ["modelo_o.svg", "rastro_estrela_modelo_o.svg", "rastro_sem.svg"]:
    assert (ROOT / "UI" / nome).exists(), nome
assert (ROOT / "FX/canvas_shader/modelo_o_cor.gdshader").exists()
assert 'func aplicar_personalizacao_nave()' in (ROOT / "Scripts/player.gd").read_text(encoding="utf-8")
assert 'func criar_visual_modelo_o()' in PLAYER
assert 'material_modelo_o.set_shader_parameter("cor_estrela", cor_nave)' in PLAYER
assert 'rastro_visual_nave == &"c21_rastro_estelar_o"' in PLAYER
assert 'material_rastro.scale_max = 0.075' in PLAYER
for nome in [
    "modelo_spectrum.svg", "modelo_fspeed.svg",
    "rastro_spectrum.svg", "rastro_fspeed.svg",
]:
    assert (ROOT / "UI" / nome).exists(), nome
assert (ROOT / "FX/canvas_shader/spectrum_rgb.gdshader").exists()
assert (ROOT / "Scripts/RastroExclusivo.gd").exists()
assert 'c08_modelo_spectrum' in PLAYER and 'c09_modelo_fspeed' in PLAYER
assert 'spectrum.scale = Vector2(0.40, 0.40)' in PLAYER
assert 'fspeed.scale = Vector2(0.30, 0.30)' in PLAYER
assert 'DISTANCIA_MAXIMA_ENTRE_AMOSTRAS := 110.0' in RASTRO_EXCLUSIVO
assert '_interromper_tracado()' in RASTRO_EXCLUSIVO
assert '_usa_rastro_modelo_o()' in PLAYER
assert 'BarraVidaRede' in PLAYER
assert 'PORTA_DESCOBERTA := 24568' in (ROOT / "Scripts/GerenciadorMultiplayer.gd").read_text(encoding="utf-8")
assert 'const MAX_JOGADORES := 4' in REDE
assert 'const MIN_JOGADORES_PARTIDA := 2' in REDE
assert 'Rede.jogadores.size() == 1' in MENU
assert 'calcular_area_comum' in BATALHA
assert 'calcular_area_jogo' in BATALHA
assert 'LimiteArenaCoop' in BATALHA
assert 'func conceder_cristais_coop' in BATALHA
assert 'cristais_coop_acumulados += quantidade' in BATALHA
assert '_receber_cristais_coop.rpc(cristais_coop_acumulados)' in BATALHA
assert 'func _aplicar_total_cristais_coop(total_sessao: int)' in BATALHA
assert '"cristais_coop": cristais_coop_acumulados' in BATALHA
assert 'func configurar_alvo(' in CAMERA
assert 'intervalo_melhoria = clampi(Rede.jogadores.size(), 1, Rede.MAX_JOGADORES)' in PLAYER
assert 'particulas_rastro_modelo_o.visible = usando_estrelas_modelo_o' in PLAYER
assert 'spectrum.scale = Vector2(0.40, 0.40)' in PLAYER
assert 'fspeed.scale = Vector2(0.30, 0.30)' in PLAYER

assert 'const DADOS_ARMAS' in UPGRADES
assert UPGRADES.count('"arma_exclusiva":') == 27
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
assert 'const ORDEM_CICLO' in SETORES
for setor in ["vazio_inicial", "constelacao_amparo", "no_ametista", "florescimento", "lua_colheita"]:
    assert f'&"{setor}"' in SETORES
for nome in ["CentelhaGuia", "EloDourado", "FitaVioleta", "NoFlutuante", "BrotoPrimaveril", "FragmentoLunar"]:
    assert (ROOT / "Entities" / f"Inimigo{nome}.tscn").exists(), nome
assert 'apresentar_transicao_setor(proximo_setor)' in BATALHA
assert 'mostrar_escolha_setor(opcoes)' not in BATALHA
for tipo in ['&"combo"', '&"pontos"', '&"sem_dano"']:
    assert tipo in GLOBAL, f"conquista ausente: {tipo}"
assert 'MorteBossCena.criar' in ENEMY
assert 'calcular_fator_xp_combo' in ENEMY
assert '0.10 * sqrt(float(cadeia) / 20.0)' in ENEMY
assert 'camadas_gelo' in ENEMY and 'tempo_decaimento_gelo = 5.0' in ENEMY
assert 'nevasca_ao_quebrar' in ENEMY and 'abaixo_zero_ativo' in ENEMY
assert '&"morte_inimigo"' in ENEMY
assert '&"ice_stack"' in PROJECTILE and '&"perielio_ray"' in PROJECTILE
assert 'monitoring = false' in PROJECTILE and 'linha_feixe' in PROJECTILE
assert 'func obter_dps_feixe_perielio()' in PLAYER
assert 'func obter_limite_uso_feixe_perielio()' in PLAYER
assert 'perielio_infinito' in UPGRADES and 'perielio_potencia' in UPGRADES
linha_solsticio = next(linha for linha in CATALOGO.splitlines() if '&"a13_canhao_lua_fria"' in linha and '_item(' in linha)
assert ', 16500, Color' in linha_solsticio
assert 'Dano *= 1.0 + 0.30 * indice_setor_dificuldade' in ENEMY
assert 'var multiplicador_dano := 1.0 + float(indice_dificuldade - 1) * 0.10' in FLOR
assert 'Dano = 42.0 * fator_dano' in SIZIGIA
assert 'ataques_desde_raio_solar < 3' in SIZIGIA
assert 'Dano * (0.84 if eclipse else 0.76)' in SIZIGIA
assert 'float(boss.get("Dano")) * (1.75 if suprema else 1.35)' in SIZIGIA_FINAL
assert '_encerrar_mecanica(13.0)' in SIZIGIA_FINAL
assert 'radius = 36.0\nheight = 142.0' in BOSS_PET
assert 'radius = 110.0' in BOSS_AMPARO
assert 'radius = 84.0' in BOSS_AMETISTA
assert 'radius = 82.0' in BOSS_FLOR and 'Dano = 48.0' in BOSS_FLOR
assert 'radius = 64.0' in BOSS_SIZIGIA and 'Dano = 42.0' in BOSS_SIZIGIA
assert 'return maxf(valor_base * pow(0.76, indice_setor_dificuldade), 0.5)' in ENEMY
assert '"cor": cor_particulas' in ENEMY
assert '&"hitflash_inimigo"' in BATALHA
assert '_atualizar_hud_boss_cliente()' in BATALHA
assert 'conceder_cura_rede' in PLAYER
for id_item, preco in [
    ("p03_renascimento", 22000),
    ("p08_presente_misterioso", 20000),
    ("p10_laco_uniao", 18000),
    ("p14_tempestade_verde", 18000),
    ("a03_alcateia_misseis", 28000),
]:
    linha = next(linha for linha in CATALOGO.splitlines() if f'&"{id_item}"' in linha and '_item(' in linha)
    assert f", {preco}, Color" in linha, f"preço incorreto: {id_item}"
assert 'const MAX_ENEMIES := 10' in BATALHA
assert 'const MIN_ENEMIES := 2' in BATALHA
assert '&"sinal_da_estrela"' in GLOBAL
assert '"secreta": true' in GLOBAL
assert '"requer_conquista": &"sinal_da_estrela"' in (ROOT / "Scripts/MonthlyCatalog.gd").read_text(encoding="utf-8")
assert '&"combo_213_spectrum"' in GLOBAL
assert '&"pontos_75000000_fspeed"' in GLOBAL

print("Polimento verificado: loja, filtros, skins, sinalizador, efeitos e hitflash.")
