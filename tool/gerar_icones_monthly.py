#!/usr/bin/env python3
"""Redesenha do zero os ícones posteriores ao conjunto original f69845a."""

from pathlib import Path
import colorsys
import re

ROOT = Path(__file__).resolve().parents[1]
DESTINO = ROOT / "Habilidades" / "Icones" / "monthly"

# Glifos exclusivos e centrais. Nenhum deles contém selo de categoria ou card.
ICONES = {
    "p01_ovo_surpresa": '<path class="base" d="M64 13C42 29 31 51 34 75c2 22 14 37 30 37s28-15 30-37c3-24-8-46-30-62Z"/><path class="accent" d="m45 63 12 8 10-16 16 10-10 12 9 8-18 11-20-13 9-10Z"/><circle class="dot" cx="64" cy="38" r="5"/>',
    "p02_clone_enganador": '<path class="ghost" d="m20 70 43-28-8 22 9 18Z"/><path class="base" d="m49 67 50-32-10 26 19 13-59 20 10-17Z"/><path class="accent" d="m70 64 17-11-4 12 8 5-21 7 4-7Z"/><path class="line" d="M20 96h33"/>',
    "p03_renascimento": '<path class="line" d="M64 111V60"/><path class="base" d="M62 72C39 70 27 55 31 32c22-1 36 13 31 40Z"/><path class="fill" d="M66 79c22-2 33-15 31-34-20 0-32 12-31 34Z"/><path class="accent" d="m64 104-12-8 12-10 12 10Z"/>',
    "p04_espirito_protetor": '<path class="base" d="M64 14 101 31v31c0 26-16 42-37 53C43 104 27 88 27 62V31Z"/><path class="fill" d="M64 31 84 42v18c0 15-8 25-20 33-12-8-20-18-20-33V42Z"/><path class="accent" d="m64 45 5 11 12 2-9 8 3 12-11-6-11 6 3-12-9-8 12-2Z"/>',
    "p05_florescimento": '<circle class="dot" cx="64" cy="65" r="10"/><path class="fill" d="M64 54C45 46 43 29 51 17c14 5 21 18 13 37Zm0 0c19-8 21-25 13-37-14 5-21 18-13 37ZM53 65c-8-19-25-21-37-13 5 14 18 21 37 13Zm22 0c8-19 25-21 37-13-5 14-18 21-37 13ZM57 75c-17 8-19 25-11 36 13-5 20-18 11-36Zm14 0c17 8 19 25 11 36-13-5-20-18-11-36Z"/><path class="line" d="M64 75v40"/>',
    "p06_rosa_espinhosa": '<path class="base" d="M64 24c25 0 39 24 25 44-11 16-37 15-43-2-5-14 6-28 20-27 12 1 18 14 11 23"/><path class="line" d="M64 79v35M64 91 48 80m16 23 17-13M42 38 29 23m57 17 14-15"/><path class="fill" d="m30 23 9 2-7 7Zm70 2-2 9-7-7ZM48 80l-2 11 10-5Zm33 10 1 11-10-6Z"/>',
    "p07_forma_fantasma": '<path class="base" d="M32 105V57c0-27 14-44 32-44s32 17 32 44v48L84 94l-10 11-10-11-10 11-10-11Z"/><path class="accent" d="M45 58c5-9 13-9 18 0-5 8-13 8-18 0Zm22 0c5-9 13-9 18 0-5 8-13 8-18 0Z"/><path class="line" d="M18 86h18m56-48h18"/>',
    "p08_presente_misterioso": '<path class="base" d="M24 49h80v62H24Z"/><path class="fill" d="M58 49h12v62H58Z"/><path class="accent" d="M64 48C43 45 36 28 45 21c10-7 18 8 19 27Zm0 0c21-3 28-20 19-27-10-7-18 8-19 27Z"/><path class="line" d="M18 49h92V36H18Z"/><circle class="dot" cx="64" cy="78" r="7"/>',
    "p09_recomeco": '<path class="base" d="M91 38A42 42 0 1 0 98 82"/><path class="fill" d="m91 17 4 30-29-8Z"/><path class="accent" d="m64 49 7 14 16 2-12 11 4 16-15-8-15 8 4-16-12-11 16-2Z"/><path class="line" d="M22 25 13 14m92 11 9-11"/>',
    "p10_laco_uniao": '<path class="base" d="M55 76 43 88c-9 9-23 9-31 0s-8-22 1-31l18-18c9-9 23-9 31 0 5 5 7 12 5 19"/><path class="base" d="m73 52 12-12c9-9 23-9 31 0s8 22-1 31L97 89c-9 9-23 9-31 0-5-5-7-12-5-19"/><path class="accent" d="M45 64h38"/><circle class="dot" cx="45" cy="64" r="5"/><circle class="dot" cx="83" cy="64" r="5"/>',
    "p11_imaginacao": '<path class="base" d="m20 89 23-48 23 48Z"/><circle class="fill" cx="88" cy="43" r="19"/><path class="base" d="m68 76 32-8 8 32-32 8Z"/><path class="accent" d="m44 58 6 13H37Zm44-24v18m-9-9h18M84 83l9 9m0-9-9 9"/>',
    "p12_furia_natureza": '<path class="base" d="m13 106 27-49 18 25 18-42 39 66Z"/><path class="fill" d="m46 105 18-31 12 31Z"/><path class="line" d="M65 69V29m0 13L50 31m15 22 18-17"/><path class="accent" d="m64 18 7 11-7 9-7-9Z"/>',
    "p13_onda_gigante": '<path class="base" d="M13 82c28-2 27-41 55-43 22-2 39 16 48 39-17-10-32-9-41 4-13 20-38 28-62 17Z"/><path class="fill" d="M33 82c13-2 15-19 27-23 11-4 20 2 25 11-13-2-19 13-31 16-8 3-15 1-21-4Z"/><path class="accent" d="m92 39 9-13 4 16Z"/>',
    "p14_tempestade_verde": '<path class="base" d="M64 64C47 38 29 38 17 51c9 19 25 24 47 13Zm0 0c17-26 35-26 47-13-9 19-25 24-47 13Zm0 0c-8-29 4-44 22-46 9 19 2 35-22 46Z"/><path class="line" d="M64 64v47m0-25-18 12m18-22 20 12"/><path class="accent" d="m64 64 8 12-8 12-8-12Z"/>',
    "p15_determinacao": '<path class="base" d="M64 13 98 32v34c0 24-14 39-34 50-20-11-34-26-34-50V32Z"/><path class="accent" d="M64 92V39m0 0L45 59m19-20 19 20"/><path class="fill" d="m64 29 8 12-8 10-8-10Z"/><path class="line" d="M43 95h42"/>',
    "a01_espingarda_lua_rosa": '<path class="base" d="M18 52h39l18-13v50L57 76H18Z"/><path class="fill" d="m75 50 34-19-23 29 28 4-28 5 23 28-34-18Z"/><circle class="dot" cx="57" cy="64" r="7"/>',
    "a02_rifle_cacador": '<path class="base" d="M15 54h67l15-12v14h16v16H97v14L82 74H52l-13 18H24l9-18H15Z"/><path class="accent" d="M61 45h22v19H61Z"/><path class="line" d="M103 38v18m-9-9h18"/>',
    "a03_alcateia_misseis": '<path class="base" d="m30 82 9-38 16-13 11 18-13 17Z"/><path class="base" d="m62 91 9-45 17-12 12 20-14 19Z"/><path class="fill" d="m32 83-16 20 25-9Zm34 9-13 20 25-11Z"/><path class="accent" d="M47 47h2m32 4h2"/>',
    "a04_canhao_esturjao": '<path class="base" d="M14 48h51l19-13v15h19l12 14-12 14H84v15L65 80H14Z"/><path class="accent" d="M30 58h37v12H30Z"/><path class="line" d="M87 64h25m-13-12 13 12-13 12"/>',
    "a05_minas_castor": '<path class="base" d="m64 16 49 89H15Z"/><path class="accent" d="M64 43v33"/><circle class="dot" cx="64" cy="91" r="6"/><path class="line" d="M31 105h66M43 31l-15-9m57 9 15-9"/>',
    "a06_feixe_perielio": '<circle class="base" cx="34" cy="64" r="20"/><circle class="fill" cx="34" cy="64" r="9"/><path class="accent" d="M55 53h54L93 64l16 11H55Z"/><path class="line" d="M34 31V17m0 94V97M1 64h13M14 43 5 34m9 51-9 9"/>',
    "a07_foice_colheita": '<path class="base" d="M103 25C69 14 34 32 28 63c-6 29 17 51 46 48 18-2 31-12 39-27-14 10-32 12-45 2-18-14-12-43 9-52 8-4 17-5 26-3Z"/><path class="accent" d="m83 84 29 28"/><path class="fill" d="m96 97 11 11-9 7-11-11Z"/>',
    "a08_torpedo_subterraneo": '<path class="line" d="M13 87h102M21 87c13 0 15 23 29 23s16-23 30-23 16 23 29 23"/><path class="base" d="m64 18 20 23-9 35H53l-9-35Z"/><path class="accent" d="M64 28v37m-9-14 9 14 9-14"/>',
    "a09_morteiro_fogueira": '<path class="base" d="M18 100c13-36 34-57 65-66l7 17C64 59 48 77 39 107Z"/><path class="accent" d="m88 21 23 13-20 18-14-16Z"/><path class="fill" d="M64 108c-15-8-14-21-4-33 1 9 9 10 8 19 5-5 7-10 8-16 10 13 5 26-12 30Z"/>',
    "a10_rajada_morango": '<path class="base" d="M64 32c25-17 43 6 35 31-6 20-22 37-35 47-13-10-29-27-35-47-8-25 10-48 35-31Z"/><path class="fill" d="m42 33 13-17 9 14 10-14 13 17"/><circle class="dot" cx="50" cy="57" r="4"/><circle class="dot" cx="75" cy="55" r="4"/><circle class="dot" cx="62" cy="76" r="4"/><circle class="dot" cx="78" cy="82" r="4"/>',
    "a11_projetor_nevasca": '<path class="base" d="M16 45h39v38H16Z"/><path class="fill" d="m55 51 57-28v82L55 77Z"/><path class="accent" d="M80 43v42m-14-21h32m-27-15 18 30m0-30L71 79"/>',
    "a12_jardim_orbital": '<circle class="base" cx="64" cy="64" r="18"/><path class="line" d="M64 15c34 0 49 15 49 49s-15 49-49 49-49-15-49-49 15-49 49-49Z"/><path class="fill" d="M64 15c12 8 12 18 0 27-12-9-12-19 0-27Zm49 49c-8 12-18 12-27 0 9-12 19-12 27 0Zm-49 49c-12-8-12-18 0-27 12 9 12 19 0 27ZM15 64c8-12 18-12 27 0-9 12-19 12-27 0Z"/><circle class="dot" cx="64" cy="64" r="7"/>',
    "a13_canhao_lua_fria": '<path class="base" d="M20 45h38l16-12v18h25l15 13-15 13H74v18L58 83H20Z"/><circle class="fill" cx="88" cy="64" r="23"/><path class="accent" d="M88 45v38M71 54l34 20m-34 0 34-20"/>',
    "n01_reflexos_rapidos": '<path class="base" d="m22 66 46-31-8 22 20 9-20 9 8 22Z"/><path class="line" d="M28 31C9 49 9 82 29 99m-4-73 13 2-3 14"/><path class="accent" d="m56 57 17 9-17 9 5-9Z"/>',
    "n02_luz_vital": '<path class="base" d="M64 109S24 84 24 51c0-24 29-33 40-10 11-23 40-14 40 10 0 33-40 58-40 58Z"/><path class="accent" d="M19 65h25l9-17 13 34 10-17h33"/><circle class="fill" cx="64" cy="42" r="6"/>',
    "n03_rede_apoio": '<path class="base" d="M82 26 111 38v24c0 21-12 34-29 44-17-10-29-23-29-44V38Z"/><path class="accent" d="m82 45 7 14 15 2-11 10 3 15-14-7-14 7 3-15-11-10 15-2Z"/><path class="line" d="M17 96c24 0 24-34 43-34"/><circle class="fill" cx="17" cy="96" r="8"/>',
    "n04_armadura_aco": '<path class="base" d="M64 14 104 31v32c0 29-17 45-40 57-23-12-40-28-40-57V31Z"/><path class="fill" d="m64 30 23 10v22c0 18-9 29-23 38Z"/><path class="line" d="M64 30v70M28 58h72"/><path class="accent" d="m41 42 10-5v18l-10 5Z"/>',
    "n05_reserva_solidaria": '<circle class="base" cx="64" cy="64" r="23"/><path class="accent" d="M64 47v34M47 64h34"/><path class="fill" d="m64 13 9 13-9 13-9-13Zm0 76 9 13-9 13-9-13ZM13 64l13-9 13 9-13 9Zm76 0 13-9 13 9-13 9Z"/>',
    "n06_scanner_preventivo": '<path class="base" d="M18 99V29l91 35Z"/><path class="line" d="M35 85V44l54 20Z"/><path class="accent" d="M54 70c6-13 18-13 24 0-6 12-18 12-24 0Z"/><circle class="dot" cx="66" cy="70" r="4"/><path class="line" d="M93 32h18m-9-9v18"/>',
    "n07_propulsor_janus": '<path class="base" d="m64 22 35 42-35 42-35-42Z"/><path class="fill" d="m64 39 19 25-19 25Z"/><path class="accent" d="M18 64h92M28 51 15 64l13 13m72-26 13 13-13 13"/>',
    "n08_motor_maia": '<path class="base" d="M64 64C39 61 28 43 34 22c22 1 34 16 30 42Zm0 0c25-3 36-21 30-42-22 1-34 16-30 42Z"/><path class="line" d="M64 64v46M64 82 46 67m18 26 19-16"/><path class="accent" d="m47 109 6-19h22l6 19Z"/>',
    "n09_familia_satelites": '<circle class="base" cx="64" cy="64" r="19"/><circle class="fill" cx="64" cy="18" r="10"/><circle class="fill" cx="24" cy="88" r="10"/><circle class="fill" cx="104" cy="88" r="10"/><path class="accent" d="M64 28v17M33 83l15-9m47 9-15-9"/><circle class="dot" cx="64" cy="64" r="6"/>',
    "n10_chassi_equinocio": '<circle class="base" cx="64" cy="64" r="44"/><path class="fill" d="M64 20a44 44 0 0 1 0 88c15-18 15-70 0-88Z"/><path class="accent" d="M64 20v88M13 64h14m74 0h14M64 13v14m0 74v14"/><circle class="dot" cx="64" cy="64" r="7"/>',
    "u01_alcateia_lunar": '<path class="base" d="m64 21-17-9-5 20-16 16 10 45 28 22 28-22 10-45-16-16-5-20Z"/><path class="fill" d="m45 60 12 5-7 10Zm38 0-12 5 7 10Z"/><path class="accent" d="m54 88 10 7 10-7M22 48 12 64l12 16m80-32 10 16-10 16"/>',
    "u02_cobertura_neve": '<path class="accent" d="M64 15v64M36 31l56 33M36 64l56-33M64 15l-9 13m9-13 9 13M36 31l15 1m-15-1 7 13"/><path class="base" d="M14 90c17-15 31 7 49-4 17-11 31 10 51-4v31H14Z"/><path class="fill" d="M28 98c13-7 22 6 34-1 13-8 24 6 37 0"/>',
    "u03_retorno_subterraneo": '<path class="line" d="M13 87h102M20 87c8 27 27 27 35 0s27-27 35 0"/><path class="base" d="M36 40h52v25H36Z"/><path class="accent" d="M46 52h32m-10-11 12 11-12 11"/><circle class="fill" cx="20" cy="87" r="7"/><circle class="fill" cx="90" cy="87" r="7"/>',
    "u04_floracao_rosa": '<circle class="base" cx="64" cy="64" r="12"/><path class="line" d="M64 52V15m10 43 31-20M75 70l30 20M64 76v37M53 70 23 90M53 58 23 38"/><path class="fill" d="m64 14 8 11-8 10-8-10Zm42 23 2 13-13 2-3-12Zm0 54-11-3 1-13 13 4ZM64 114l-8-11 8-10 8 10ZM22 91l-2-13 13-2 3 12Zm0-54 11 3-1 13-13-4Z"/>',
    "u05_jardim_crescente": '<path class="line" d="M27 112V76m37 36V54m37 58V32"/><path class="base" d="M27 77C9 72 9 55 18 45c13 4 17 16 9 32Zm0 0c18-5 18-22 9-32-13 4-17 16-9 32Zm37-22c-18-5-18-22-9-32 13 4 17 16 9 32Zm0 0c18-5 18-22 9-32-13 4-17 16-9 32Zm37-22c-14-4-15-17-7-25 10 3 13 13 7 25Z"/><path class="accent" d="M18 112h92"/>',
    "u06_sementes_vermelhas": '<path class="base" d="M39 29h50v78H39Z"/><path class="fill" d="m50 29 5-15h18l5 15Z"/><path class="accent" d="M64 47v43M52 61h24M52 77h24"/><path class="line" d="m22 43 9 5-9 5m84 5-9 5 9 5M25 87l9 5-9 5"/>',
    "u07_galhos_lunares": '<path class="accent" d="M64 113V61m0 17L42 58 25 35m17 23-23 7m45 5 23-24 16-24M87 46l22 5M64 91l-22 15m22-15 22 15"/><path class="base" d="m25 35-4-18 16 9Zm78-13 5-13 8 13Zm-61 84-11 7 3-13Zm44 0 11 7-3-13Z"/>',
    "u08_corrente_esturjao": '<path class="base" d="M13 72c17-29 34 29 51 0s34 29 51 0"/><path class="line" d="M18 43h78m-12-12 14 12-14 12M32 101h74M94 89l14 12-14 12"/><path class="accent" d="m57 72 7-10 7 10-7 10Z"/>',
    "u09_colheita_cromatica": '<path class="line" d="M64 114V38m0 17L46 41m18 27 19-15M64 82 43 68m21 28 21-17"/><path class="base" d="M26 18h19v19H26Zm58 0h19v19H84ZM17 85h19v19H17Zm75 2h19v19H92Z"/><path class="accent" d="M35 27c16 3 25 9 29 21m29-21C79 31 71 38 66 48"/>',
    "u10_marca_cacador": '<path class="base" d="M13 64c14-25 31-38 51-38s37 13 51 38c-14 25-31 38-51 38S27 89 13 64Z"/><circle class="fill" cx="64" cy="64" r="18"/><circle class="dot" cx="64" cy="64" r="7"/><path class="accent" d="M64 34v16m0 28v16M34 64h16m28 0h16M93 31l17-11m-17 77 17 11"/>',
    "u11_barragem_castor": '<path class="base" d="m18 40 17-12 77 58-18 13Zm-4 29 17-12 61 47-18 12Zm39-49 17-11 44 34-17 12Z"/><path class="accent" d="M18 111h96"/><path class="fill" d="m35 28 12 9-17 12-12-9Zm35-19 12 9-17 12-12-10Z"/>',
    "u12_noite_congelada": '<path class="base" d="M88 17C56 17 34 40 39 65c5 25 35 36 57 19-10 28-47 37-70 13C-2 68 20 20 64 15c9-1 17 0 24 2Z"/><path class="accent" d="M85 58v52M63 71l44 26M63 97l44-26M85 58l-9 13m9-13 9 13M85 110l-9-13m9 13 9-13"/><circle class="fill" cx="85" cy="84" r="6"/>',
}

CORES_PADRAO = {"p": "#ff67c7", "a": "#ffb84a", "n": "#72efff", "u": "#b889ff"}

def carregar_cores_catalogo() -> dict[str, str]:
    texto = (ROOT / "Scripts" / "MonthlyCatalog.gd").read_text(encoding="utf-8")
    return {identificador: f"#{hexadecimal}" for identificador, hexadecimal in re.findall(r'_item\(&"([panu]\d\d_[^"]+)".*?Color\("([0-9a-fA-F]{6})"\)', texto)}

def clarear(cor: str, fator: float = .62) -> str:
    r, g, b = (int(cor[i:i + 2], 16) / 255 for i in (1, 3, 5))
    h, l, s = colorsys.rgb_to_hls(r, g, b)
    r, g, b = colorsys.hls_to_rgb(h, min(.94, l + (1 - l) * fator), min(1, s * .82))
    return f"#{round(r * 255):02x}{round(g * 255):02x}{round(b * 255):02x}"

CORES_CATALOGO = carregar_cores_catalogo()

def gerar_svg(identificador: str, corpo: str) -> str:
    cor = CORES_CATALOGO.get(identificador, CORES_PADRAO[identificador[0]])
    luz = clarear(cor)
    return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128">
  <style>
    .base{{fill:#10162e;stroke:{cor};stroke-width:7}}
    .fill{{fill:{cor};stroke:{cor};stroke-width:5}}
    .ghost{{fill:#10162e;stroke:{cor};stroke-width:6;opacity:.45}}
    .accent,.line{{fill:none;stroke:{luz};stroke-width:6}}
    .accent{{fill:{luz};fill-opacity:.22}}
    .dot{{fill:{luz};stroke:{cor};stroke-width:3}}
    path,circle,ellipse,rect{{stroke-linecap:round;stroke-linejoin:round}}
  </style>
  {corpo}
</svg>
'''

def main() -> None:
    DESTINO.mkdir(parents=True, exist_ok=True)
    existentes = {p.stem for p in DESTINO.glob("*.svg")}
    obsoletos = existentes - ICONES.keys()
    if obsoletos:
        raise RuntimeError(f"SVGs sem desenho novo: {sorted(obsoletos)}")
    for identificador, corpo in ICONES.items():
        (DESTINO / f"{identificador}.svg").write_text(gerar_svg(identificador, corpo), encoding="utf-8")
    print(f"Ícones mensais redesenhados do zero: {len(ICONES)}")

if __name__ == "__main__":
    main()
