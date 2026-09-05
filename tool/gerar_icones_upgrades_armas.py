#!/usr/bin/env python3
"""Gera ícones SVG exclusivos para as melhorias próprias de cada arma."""

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "Habilidades" / "Icones" / "upgrades_armas"

ICONES = {
    "rosa_petalas_extras": ('#ff7eb7', '<g fill="none" stroke="white" stroke-width="7"><circle cx="64" cy="64" r="9"/><ellipse cx="64" cy="38" rx="10" ry="17"/><ellipse cx="88" cy="57" rx="10" ry="17" transform="rotate(72 88 57)"/><ellipse cx="79" cy="86" rx="10" ry="17" transform="rotate(144 79 86)"/><ellipse cx="49" cy="86" rx="10" ry="17" transform="rotate(216 49 86)"/><ellipse cx="40" cy="57" rx="10" ry="17" transform="rotate(288 40 57)"/></g>'),
    "rosa_cano_curto": ('#ff5f9f', '<path d="M25 38L65 56L104 49L104 79L65 72L25 90L46 64Z" fill="none" stroke="white" stroke-width="8" stroke-linejoin="round"/><path d="M75 64H108" stroke="white" stroke-width="7"/>'),
    "fogos_formacao": ('#e7edff', '<g fill="none" stroke="white" stroke-width="7" stroke-linejoin="round"><path d="M32 91L45 52L58 91L45 84Z"/><path d="M70 78L83 39L96 78L83 71Z"/><path d="M38 99L30 111M52 99L60 111M76 86L68 98M90 86L98 98"/></g>'),
    "fogos_estouro": ('#b8c8ff', '<path d="M64 18L73 47L101 32L83 57L111 65L82 72L99 99L72 82L63 111L56 82L28 98L45 72L17 63L46 56L29 29L57 46Z" fill="none" stroke="white" stroke-width="7" stroke-linejoin="round"/>'),
    "esturjao_correnteza": ('#54c6ff', '<g fill="none" stroke="white" stroke-width="7" stroke-linecap="round"><path d="M18 46C37 29 49 63 67 46S96 29 111 46"/><path d="M18 75C37 58 49 92 67 75S96 58 111 75"/><path d="M83 96L108 75L84 58"/></g>'),
    "esturjao_perfurante": ('#309fe8', '<g fill="none" stroke="white" stroke-width="7"><circle cx="39" cy="64" r="17"/><circle cx="82" cy="64" r="17"/><path d="M17 64H108M91 50L108 64L91 78" stroke-linejoin="round"/></g>'),
    "mina_pavio_curto": ('#ffd447', '<g fill="none" stroke="white" stroke-width="7"><circle cx="64" cy="69" r="35"/><path d="M64 69V45M64 69L84 79" stroke-linecap="round"/><path d="M49 25H79M64 25V34"/></g>'),
    "mina_sensor_proximidade": ('#fff06a', '<g fill="none" stroke="white" stroke-width="7"><circle cx="64" cy="64" r="10" fill="white"/><path d="M43 43A30 30 0 010 85 43M29 29A50 50 0 010 99 29" stroke-linecap="round"/></g>'),
    "mina_comando_remoto": ('#ffb52e', '<g fill="none" stroke="white" stroke-width="7" stroke-linecap="round"><rect x="34" y="51" width="60" height="55" rx="12"/><path d="M64 51V30M52 21L64 30L76 21"/><circle cx="64" cy="76" r="10"/></g>'),
    "perielio_resfriamento": ('#ffcf45', '<g fill="none" stroke="white" stroke-width="7"><circle cx="45" cy="49" r="20"/><path d="M45 17V8M45 90V81M13 49H4M86 49H77M22 26L15 19M68 72L75 79"/><path d="M77 61L62 89H78L68 112L99 78H82L94 61Z"/></g>'),
    "perielio_foco": ('#ff9f2f', '<g fill="none" stroke="white" stroke-width="7" stroke-linejoin="round"><circle cx="32" cy="64" r="15"/><path d="M48 54L101 37L82 64L101 91L48 74Z"/><path d="M57 64H108"/></g>'),
    "colheita_dupla": ('#ffb34d', '<g fill="none" stroke="white" stroke-width="8" stroke-linecap="round"><path d="M22 38C50 15 80 27 91 55C72 44 50 49 34 69"/><path d="M37 83C61 106 91 96 105 68C84 79 63 72 49 53"/></g>'),
    "colheita_retorno": ('#ff8f35', '<path d="M28 45C49 22 86 26 100 55L109 41V78L75 63L91 58C80 42 55 39 41 54C31 65 31 82 41 94" fill="none" stroke="white" stroke-width="8" stroke-linecap="round" stroke-linejoin="round"/>'),
    "terra_raizes_gemeas": ('#8ae878', '<g fill="none" stroke="white" stroke-width="7" stroke-linecap="round"><path d="M49 108V65C49 45 37 37 23 28M49 76L27 60M79 108V65C79 45 91 37 105 28M79 76L101 60"/><path d="M19 108H109"/></g>'),
    "terra_ruptura": ('#5fcf69', '<g fill="none" stroke="white" stroke-width="7" stroke-linejoin="round"><path d="M15 94H113"/><path d="M24 94L43 61L54 76L66 35L78 73L91 52L106 94"/><path d="M54 27L64 13L73 28"/></g>'),
    "fogueira_brasas": ('#ff6f32', '<g fill="none" stroke="white" stroke-width="7"><path d="M64 105C38 105 27 89 34 70C40 55 55 51 55 30C76 43 81 57 75 71C86 64 94 69 95 81C96 96 82 105 64 105Z"/><circle cx="26" cy="35" r="7"/><circle cx="96" cy="31" r="6"/></g>'),
    "fogueira_circulo": ('#ff4224', '<g fill="none" stroke="white" stroke-width="7"><circle cx="64" cy="66" r="43"/><path d="M64 91C47 91 41 79 47 67C51 58 61 54 60 39C75 49 82 60 77 71C86 68 88 78 82 85C78 89 72 91 64 91Z"/></g>'),
    "morango_cacho": ('#ff405f', '<g fill="none" stroke="white" stroke-width="6"><path d="M64 35C37 28 25 46 34 70C41 89 54 103 64 111C74 103 87 89 94 70C103 46 91 28 64 35Z"/><path d="M42 35L54 18L64 32L74 18L87 35"/><circle cx="50" cy="60" r="3" fill="white"/><circle cx="74" cy="58" r="3" fill="white"/><circle cx="62" cy="78" r="3" fill="white"/></g>'),
    "morango_sementes": ('#ff2448', '<g fill="none" stroke="white" stroke-width="6"><ellipse cx="64" cy="64" rx="17" ry="29"/><ellipse cx="29" cy="45" rx="7" ry="12" transform="rotate(-35 29 45)"/><ellipse cx="99" cy="45" rx="7" ry="12" transform="rotate(35 99 45)"/><ellipse cx="35" cy="91" rx="7" ry="12" transform="rotate(35 35 91)"/><ellipse cx="93" cy="91" rx="7" ry="12" transform="rotate(-35 93 91)"/></g>'),
    "roxo_neblina": ('#bd8cff', '<g fill="none" stroke="white" stroke-width="7" stroke-linecap="round"><path d="M18 46C29 34 42 34 54 46S79 58 91 46S106 34 112 42"/><path d="M18 69C31 57 44 57 57 69S83 81 96 69"/><path d="M25 92C37 83 49 83 61 92S85 101 97 92"/></g>'),
    "roxo_persistencia": ('#9562e8', '<g fill="none" stroke="white" stroke-width="7"><path d="M64 19V109M25 42L103 86M103 42L25 86"/><circle cx="64" cy="64" r="17"/><path d="M64 19L54 31M64 19L74 31M64 109L54 97M64 109L74 97"/></g>'),
    "jardim_petalas": ('#ff67b3', '<g fill="none" stroke="white" stroke-width="6"><circle cx="64" cy="64" r="12"/><circle cx="64" cy="64" r="43" stroke-dasharray="7 9"/><ellipse cx="64" cy="22" rx="8" ry="14"/><ellipse cx="106" cy="64" rx="14" ry="8"/><ellipse cx="64" cy="106" rx="8" ry="14"/><ellipse cx="22" cy="64" rx="14" ry="8"/></g>'),
    "jardim_sincronia": ('#f04491', '<g fill="none" stroke="white" stroke-width="7"><circle cx="64" cy="64" r="18"/><path d="M64 13V38M64 90V115M13 64H38M90 64H115M28 28L46 46M82 82L100 100M100 28L82 46M46 82L28 100"/></g>'),
    "solsticio_nucleo": ('#90caff', '<g fill="none" stroke="white" stroke-width="7"><circle cx="64" cy="64" r="30"/><circle cx="64" cy="64" r="10" fill="white"/><path d="M64 9V25M64 103V119M9 64H25M103 64H119M25 25L37 37M91 91L103 103"/></g>'),
    "solsticio_absorcao": ('#67a8ff', '<g fill="none" stroke="white" stroke-width="7"><path d="M25 31V74C25 95 42 108 64 114C86 108 103 95 103 74V31L64 17Z"/><circle cx="64" cy="63" r="20"/><path d="M64 43V83M44 63H84"/></g>'),
}


def svg(cor: str, glifo: str) -> str:
    return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128">
  <defs><filter id="g" x="-40%" y="-40%" width="180%" height="180%"><feGaussianBlur stdDeviation="4" result="b"/><feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge></filter></defs>
  <rect x="7" y="7" width="114" height="114" rx="24" fill="#07101f" stroke="{cor}" stroke-width="5" opacity=".96"/>
  <g filter="url(#g)" stroke="{cor}" stroke-linecap="round" stroke-linejoin="round">{glifo}</g>
</svg>'''


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for nome, (cor, glifo) in ICONES.items():
        (OUT / f"{nome}.svg").write_text(svg(cor, glifo), encoding="utf-8")
    print(f"Ícones de upgrades gerados: {len(ICONES)}")


if __name__ == "__main__":
    main()
