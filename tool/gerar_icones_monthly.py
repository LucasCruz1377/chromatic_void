#!/usr/bin/env python3
"""Gera os SVGs exclusivos do catálogo Monthly Colors."""

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DESTINO = ROOT / "Habilidades" / "Icones" / "monthly"

ICONES = {
    "p01_ovo_surpresa": '<ellipse cx="64" cy="65" rx="30" ry="42"/><path d="M45 61l13 8 11-15 14 10"/><path class="a" d="M51 86l13-8 13 8"/>',
    "p02_clone_enganador": '<path d="M27 75l45-28-9 22 9 22z"/><path class="a" d="M55 63l45-28-9 22 9 22z"/>',
    "p03_renascimento": '<path d="M64 108V57"/><path class="a" d="M64 69C38 68 31 48 34 31c21 2 34 13 30 38Z"/><path d="M64 78c24-1 33-18 31-34-19 1-30 11-31 34Z"/><ellipse cx="64" cy="108" rx="19" ry="8"/>',
    "p04_espirito_protetor": '<path d="M64 20l34 13v25c0 25-15 40-34 50-19-10-34-25-34-50V33Z"/><path class="a" d="M64 40l6 13 15 2-11 10 3 15-13-8-13 8 3-15-11-10 15-2Z"/>',
    "p05_florescimento": '<circle cx="64" cy="64" r="12"/><ellipse class="a" cx="64" cy="34" rx="11" ry="20"/><ellipse cx="64" cy="94" rx="11" ry="20"/><ellipse cx="34" cy="64" rx="20" ry="11"/><ellipse cx="94" cy="64" rx="20" ry="11"/>',
    "p06_rosa_espinhosa": '<path class="a" d="M64 29c23 0 34 26 18 42-13 14-40 5-36-14 3-14 22-18 29-7"/><path d="M64 78v34M64 91l-15-9M64 101l16-10M37 39l-8-11M91 39l8-11"/>',
    "p07_forma_fantasma": '<path class="a" d="M35 103V57c0-24 13-39 29-39s29 15 29 39v46L80 92l-16 12-16-12Z"/><circle cx="53" cy="57" r="4"/><circle cx="75" cy="57" r="4"/>',
    "p08_presente_misterioso": '<rect x="27" y="51" width="74" height="57" rx="5"/><path d="M64 51v57M23 51h82v-14H23Z"/><path class="a" d="M64 37c-22 0-25-25-8-25 10 0 8 14 8 25Zm0 0c22 0 25-25 8-25-10 0-8 14-8 25Z"/>',
    "p09_recomeco": '<path d="M64 20v25M51 31l13 14 13-14M32 52l17 13M24 70l22 3M96 52L79 65M104 70l-22 3"/><path class="a" d="M64 58l8 17 18 2-14 12 5 18-17-9-17 9 5-18-14-12 18-2Z"/>',
    "p10_laco_uniao": '<ellipse cx="45" cy="64" rx="25" ry="17" transform="rotate(-32 45 64)"/><ellipse class="a" cx="83" cy="64" rx="25" ry="17" transform="rotate(-32 83 64)"/><path d="M55 70l18-12"/>',
    "p11_imaginacao": '<path d="M24 82l24-42 24 42Z"/><circle class="a" cx="86" cy="45" r="18"/><rect x="68" y="73" width="35" height="35" rx="5" transform="rotate(12 85 90)"/>',
    "p12_furia_natureza": '<path d="M19 103l27-42 15 21 17-31 31 52Z"/><path class="a" d="M64 78V36M64 50L49 39M64 58l17-14M38 103l8-20M91 103l-10-22"/>',
    "p13_onda_gigante": '<path class="a" d="M16 82c24-3 20-35 47-37 21-2 34 13 49 34-18-12-31-10-38 1-10 17-31 27-58 17Z"/><path d="M30 81c13 1 19-8 22-18"/>',
    "p14_tempestade_verde": '<path d="M64 64c-25-25-44-10-45 12 20 6 38 0 45-12Z"/><path class="a" d="M64 64c25-25 44-10 45 12-20 6-38 0-45-12Z"/><path d="M64 64c-5-34 11-43 29-35-2 21-12 34-29 35ZM64 64v42"/>',
    "p15_determinacao": '<path class="a" d="M64 17l31 18v29c0 22-13 36-31 47-18-11-31-25-31-47V35Z"/><path d="M64 91V39M45 58l19-19 19 19"/>',
    "a01_espingarda_lua_rosa": '<path d="M19 64h30M49 64l48-34M49 64l58-17M49 64h62M49 64l58 17M49 64l48 34"/><circle class="a" cx="43" cy="64" r="8"/>',
    "a02_rifle_cacador": '<path class="a" d="M17 64h94M30 54v20M91 48v32"/><path d="M60 46h24v36H60M104 57l8 7-8 7"/>',
    "a03_alcateia_misseis": '<path d="M34 78l-9 22 22-9 19-28-13-13Z"/><path class="a" d="M62 54l-3-23 20 12 17 30-16 9Z"/><path d="M76 88l10 20 13-19-1-29-16-2Z"/>',
    "a04_canhao_esturjao": '<path d="M18 70h49l22-17v34L67 70"/><path class="a" d="M88 49c14 6 22 17 24 31-14-8-24-7-33 2"/><path d="M26 55v30"/>',
    "a05_minas_castor": '<path class="a" d="M64 18l48 84H16Z"/><path d="M64 45v29M64 89v2"/><path d="M28 106h72"/>',
    "a06_feixe_perielio": '<circle class="a" cx="37" cy="64" r="19"/><path d="M37 34V19M37 109V94M7 64h15M52 64h60M23 43 12 32M23 85 12 96"/><path d="M72 54l22 10-22 10"/>',
    "a07_foice_colheita": '<path class="a" d="M91 20c-43 6-61 35-44 60 13 19 39 20 58 5-13 29-52 39-77 13C-2 67 23 20 64 15c10-1 19 1 27 5Z"/><path d="M84 82l23 26"/>',
    "a08_torpedo_subterraneo": '<path d="M15 82h98M25 82c15 0 16 19 31 19s17-19 32-19"/><path class="a" d="M64 86V37M49 51l15-14 15 14"/><circle cx="64" cy="64" r="8"/>',
    "a09_morteiro_fogueira": '<path d="M22 94c18-42 38-54 68-57"/><path class="a" d="M91 24l21 13-21 13-13-13Z"/><path d="M46 105c-10-13 2-22 9-33 2 12 12 14 12 26 3-8 10-13 15-22 8 15 9 31-18 36-8 0-14-2-18-7Z"/>',
    "a10_rajada_morango": '<path class="a" d="M64 39c25-18 43 5 37 29-5 22-22 37-37 44-15-7-32-22-37-44-6-24 12-47 37-29Z"/><path d="M50 35c6-14 22-14 28 0M46 59h1M64 54h1M82 59h1M55 75h1M74 77h1M64 94h1"/>',
    "a11_projetor_nevasca": '<path d="M18 48h34v32H18Z"/><path class="a" d="M52 54l60-25v70L52 74Z"/><path d="M73 48v32M92 40v48M81 64h22"/>',
    "a12_jardim_orbital": '<circle cx="64" cy="64" r="14"/><ellipse class="a" cx="64" cy="25" rx="8" ry="16"/><ellipse cx="64" cy="103" rx="8" ry="16"/><ellipse cx="25" cy="64" rx="16" ry="8"/><ellipse cx="103" cy="64" rx="16" ry="8"/><path d="M35 35l12 12M93 93l-12-12M93 35 81 47M35 93l12-12"/>',
    "a13_canhao_lua_fria": '<circle class="a" cx="64" cy="64" r="31"/><path d="M64 20v88M26 42l76 44M26 86l76-44M64 33l-10-8M64 33l10-8M64 95l-10 8M64 95l10 8"/>',
    "n01_reflexos_rapidos": '<path class="a" d="M29 70l43-27-9 21 9 21Z"/><path d="M28 36C12 54 15 86 37 99M25 33l18 2-5 17"/>',
    "n02_luz_vital": '<path class="a" d="M64 106S25 82 25 50c0-23 30-31 39-10 9-21 39-13 39 10 0 32-39 56-39 56Z"/><path d="M22 64h24l8-15 13 31 9-16h30"/>',
    "n03_rede_apoio": '<path d="M20 91c24-3 25-41 52-41h17"/><path class="a" d="M89 32l24 9v20c0 18-10 29-24 37-14-8-24-19-24-37V41Z"/><circle cx="20" cy="91" r="7"/>',
    "n04_armadura_aco": '<path class="a" d="M64 18l38 15v29c0 28-16 43-38 55-22-12-38-27-38-55V33Z"/><path d="M64 18v99M28 48h72M35 82h58"/>',
    "n05_reserva_solidaria": '<circle class="a" cx="64" cy="64" r="17"/><rect x="56" y="49" width="16" height="30" rx="4"/><path d="M64 19v17M64 92v17M19 64h17M92 64h17M32 32l12 12M96 32 84 44M32 96l12-12M96 96 84 84"/>',
    "n06_scanner_preventivo": '<path class="a" d="M25 95V33l79 31Z"/><path d="M38 84V45l49 19Z"/><circle cx="98" cy="39" r="6"/><circle cx="98" cy="89" r="6"/><path d="M82 29l8 8M82 99l8-8"/>',
    "n07_propulsor_janus": '<path class="a" d="M64 28l35 36-35 36-35-36Z"/><path d="M64 28v72M20 64h88M26 50 12 64l14 14M102 50l14 14-14 14"/>',
    "n08_motor_maia": '<path d="M64 108V61M64 75 45 58M64 66l19-19"/><path class="a" d="M64 61c-25-2-37-17-34-37 21-1 35 11 34 37Zm0 0c25-2 37-17 34-37-21-1-35 11-34 37Z"/><path d="M42 108h44l-8-18H50Z"/>',
    "n09_familia_satelites": '<circle class="a" cx="64" cy="64" r="17"/><circle cx="64" cy="21" r="9"/><circle cx="27" cy="86" r="9"/><circle cx="101" cy="86" r="9"/><path d="M64 30v17M35 81l16-9M93 81l-16-9"/>',
    "n10_chassi_equinocio": '<circle cx="64" cy="64" r="40"/><path class="a" d="M64 24a40 40 0 0 1 0 80c17-19 17-61 0-80Z"/><path d="M64 13v11M64 104v11M13 64h11M104 64h11"/>',
    "u01_alcateia_lunar": '<path class="a" d="M64 29 48 17l-4 21-13 16 8 39 25 18 25-18 8-39-13-16-4-21Z"/><path d="M50 65h1M77 65h1M56 84l8 6 8-6M23 47l-10 17 12 16M105 47l10 17-12 16"/>',
    "u02_cobertura_neve": '<path d="M64 20v70M34 37l60 36M34 73l60-36M64 20l-8 12M64 20l8 12M34 37l15 1M34 37l7 13"/><path class="a" d="M18 98c18-13 31 8 46-3 16-12 28 9 46-4v20H18Z"/>',
    "u03_retorno_subterraneo": '<path d="M15 83h98M25 83c8 25 26 25 34 0s26-25 34 0"/><path class="a" d="M43 51h43M74 39l12 12-12 12"/><circle cx="25" cy="83" r="5"/><circle cx="93" cy="83" r="5"/>',
    "u04_floracao_rosa": '<circle class="a" cx="64" cy="64" r="10"/><path d="M64 54V17M74 58l30-22M74 70l30 22M64 74v37M54 70 24 92M54 58 24 36"/><circle cx="64" cy="17" r="7"/><circle cx="104" cy="36" r="7"/><circle cx="104" cy="92" r="7"/><circle cx="64" cy="111" r="7"/><circle cx="24" cy="92" r="7"/><circle cx="24" cy="36" r="7"/>',
    "u05_jardim_crescente": '<path d="M27 105V79M64 105V57M101 105V37"/><path class="a" d="M27 80c-15-3-20-14-17-25 13 0 21 8 17 25Zm0 0c15-3 20-14 17-25-13 0-21 8-17 25ZM64 58c-15-3-20-14-17-25 13 0 21 8 17 25Zm0 0c15-3 20-14 17-25-13 0-21 8-17 25ZM101 38c-12-2-17-11-14-20 10 0 17 7 14 20Z"/>',
    "u06_sementes_vermelhas": '<path class="a" d="M40 35h48v71H40Z"/><path d="M53 23h22v12M64 49v43M52 62h24M52 78h24"/><circle cx="28" cy="47" r="5"/><circle cx="100" cy="61" r="5"/><circle cx="25" cy="84" r="5"/>',
    "u07_galhos_lunares": '<path class="a" d="M64 109V63M64 78 42 58M42 58 27 38M42 58 22 64M64 68l23-22M87 46l15-22M87 46l19 5M64 88l-19 14M64 88l19 14"/>',
    "u08_corrente_esturjao": '<path class="a" d="M15 75c18-25 34 25 52 0s34 25 52 0"/><path d="M18 52h80M87 40l14 12-14 12M34 91h73M96 79l14 12-14 12"/>',
    "u09_colheita_cromatica": '<path d="M64 109V38M64 54 47 42M64 66 81 51M64 78 45 66M64 90l19-13"/><path class="a" d="M31 24h14v14H31ZM87 23h14v14H87ZM22 86h14v14H22ZM93 87h14v14H93Z"/><path d="M37 31c14 4 22 8 27 17M94 30C80 34 72 39 66 48"/>',
    "u10_marca_cacador": '<path class="a" d="M19 64c14-23 29-34 45-34s31 11 45 34c-14 23-29 34-45 34S33 87 19 64Z"/><path d="M42 64h44M64 42v44M91 28l15-10M91 100l15 10"/><circle cx="64" cy="64" r="9"/>',
    "u11_barragem_castor": '<path class="a" d="M21 42l17-11 69 55-17 11ZM18 68l17-11 57 46-17 11ZM51 24l17-10 43 34-17 11Z"/><path d="M22 105h88"/>',
    "u12_noite_congelada": '<path class="a" d="M82 19c-31 5-45 27-35 47 9 18 31 24 49 12-9 25-42 34-63 13-25-26-4-67 31-73 6-1 12-1 18 1Z"/><path d="M82 62v45M63 73l38 23M63 96l38-23M82 74l-8-7M82 74l8-7"/>',
}


MOLDURAS = {
    "p": '<circle cx="64" cy="64" r="53"/>',
    "a": '<path d="M64 9l46 27v56l-46 27-46-27V36Z"/>',
    "n": '<path d="M64 9l47 23v48c0 20-22 33-47 40-25-7-47-20-47-40V32Z"/>',
    "u": '<path d="M64 8l55 56-55 56L9 64Z"/>',
}


def gerar_svg(identificador: str, corpo: str) -> str:
    moldura = MOLDURAS[identificador[0]]
    return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128">
  <defs><filter id="glow" x="-35%" y="-35%" width="170%" height="170%"><feGaussianBlur stdDeviation="2.2" result="b"/><feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge></filter></defs>
  <g fill="#17213d" stroke="#dff8ff" stroke-width="5" stroke-linecap="round" stroke-linejoin="round" filter="url(#glow)">{moldura}</g>
  <g fill="none" stroke="#f8fdff" stroke-width="5" stroke-linecap="round" stroke-linejoin="round"><style>.a{{fill:#78eaff;fill-opacity:.72}}</style>{corpo}</g>
</svg>
'''


def main() -> None:
    DESTINO.mkdir(parents=True, exist_ok=True)
    for identificador, corpo in ICONES.items():
        (DESTINO / f"{identificador}.svg").write_text(
            gerar_svg(identificador, corpo), encoding="utf-8"
        )
    print(f"Ícones exclusivos gerados: {len(ICONES)}")


if __name__ == "__main__":
    main()
