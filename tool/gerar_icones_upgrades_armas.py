#!/usr/bin/env python3
"""Ícones totalmente novos das melhorias específicas de armas."""

from pathlib import Path
import colorsys

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "Habilidades" / "Icones" / "upgrades_armas"

# Cor e composição própria. Os símbolos representam o efeito, não a categoria.
ICONES = {
    "rosa_petalas_extras": ("#ff7eb7", '<circle class="base" cx="64" cy="64" r="10"/><path class="fill" d="M64 51C51 40 54 24 64 17c10 7 13 23 0 34Zm13 8c4-17 20-21 30-14 0 12-11 24-30 14Zm-5 15c17 0 24 14 20 25-12 4-26-4-20-25Zm-16 0c-17 0-24 14-20 25 12 4 26-4 20-25Zm-5-15c-4-17-20-21-30-14 0 12 11 24 30 14Z"/><path class="accent" d="m64 55 6 9-6 9-6-9Z"/>'),
    "rosa_cano_curto": ("#ff5f9f", '<path class="base" d="M16 49h47l19-14v18h29v22H82v18L63 79H16Z"/><path class="fill" d="m63 49 19-14v18H63Z"/><path class="accent" d="M84 64h29M32 59h30v11H32Z"/>'),
    "fogos_formacao": ("#e7edff", '<path class="base" d="m26 92 12-47 15-13 12 18-15 19Z"/><path class="base" d="m64 96 12-55 16-13 13 20-16 22Z"/><path class="fill" d="m28 92-13 20 24-10Zm39 4-10 20 23-12Z"/><path class="accent" d="M45 48h2m39-3h2"/>'),
    "fogos_estouro": ("#b8c8ff", '<path class="base" d="m64 12 9 34 29-20-17 30 34 7-34 8 18 30-30-19-9 34-9-34-30 19 18-30-34-8 34-7-17-30 29 20Z"/><circle class="dot" cx="64" cy="64" r="10"/><path class="accent" d="M64 45v38M45 64h38"/>'),
    "esturjao_correnteza": ("#54c6ff", '<path class="base" d="M12 44c17-24 35 24 52 0s35 24 52 0v24c-17 24-35-24-52 0S29 44 12 68Z"/><path class="line" d="M17 91h88m-13-13 14 13-14 13"/><path class="accent" d="m57 56 7-10 7 10-7 10Z"/>'),
    "esturjao_perfurante": ("#309fe8", '<circle class="base" cx="36" cy="64" r="20"/><circle class="base" cx="78" cy="64" r="20"/><path class="accent" d="M12 64h103m-17-15 17 15-17 15"/><circle class="dot" cx="36" cy="64" r="6"/><circle class="dot" cx="78" cy="64" r="6"/>'),
    "mina_pavio_curto": ("#ffd447", '<circle class="base" cx="64" cy="70" r="39"/><path class="fill" d="M51 22h26v13H51Z"/><path class="accent" d="M64 47v25l18 11"/><path class="line" d="M46 16h36M31 34 20 23m77 11 11-11"/><circle class="dot" cx="64" cy="70" r="6"/>'),
    "mina_sensor_proximidade": ("#fff06a", '<circle class="base" cx="64" cy="64" r="13"/><circle class="dot" cx="64" cy="64" r="5"/><path class="accent" d="M44 44a29 29 0 0 0 0 40m40-40a29 29 0 0 1 0 40M29 29a50 50 0 0 0 0 70m70-70a50 50 0 0 1 0 70"/>'),
    "mina_comando_remoto": ("#ffb52e", '<path class="base" d="M30 50h68v62H30Z"/><path class="fill" d="M50 68h28v26H50Z"/><path class="accent" d="M64 50V30m-13-9 13 9 13-9M43 81h42"/><circle class="dot" cx="64" cy="81" r="7"/>'),
    "perielio_resfriamento": ("#ffcf45", '<circle class="base" cx="40" cy="47" r="23"/><path class="line" d="M40 13V5m0 84v-8M6 47h9m50 0h9M16 23l7 7m34 34 7 7"/><path class="fill" d="m77 54-20 36h18l-9 31 42-48H88l15-19Z"/><path class="accent" d="m78 69-8 15h13l-5 15 17-20H83l7-10Z"/>'),
    "perielio_foco": ("#ff9f2f", '<circle class="base" cx="28" cy="64" r="17"/><path class="fill" d="m46 51 66-23-28 36 28 36-66-23Z"/><path class="accent" d="M47 64h67M28 53v22"/><circle class="dot" cx="28" cy="64" r="5"/>'),
    "colheita_dupla": ("#ffb34d", '<path class="base" d="M104 24C70 13 38 29 31 56c-5 20 7 37 26 42-31 3-49-23-41-50 11-35 53-49 88-24Z"/><path class="base" d="M24 104c34 11 66-5 73-32 5-20-7-37-26-42 31-3 49 23 41 50-11 35-53 49-88 24Z"/><path class="accent" d="M43 88 88 43"/>'),
    "colheita_retorno": ("#ff8f35", '<path class="base" d="M29 94c-16-25-5-59 22-72 24-11 53-1 66 22l-5-22-18 16 22 7-18 15c-8-17-29-24-46-15-17 8-23 29-14 45"/><path class="accent" d="m29 94 3-19 16 10Z"/><circle class="dot" cx="64" cy="64" r="7"/>'),
    "terra_raizes_gemeas": ("#8ae878", '<path class="base" d="M43 113V67c0-20-10-31-27-42m27 57L22 63m63 50V67c0-20 10-31 27-42M85 82l21-19"/><path class="fill" d="m16 25 4-13 11 9Zm96 0-4-13-11 9Z"/><path class="accent" d="M13 113h102M43 96l-15 11m57-11 15 11"/>'),
    "terra_ruptura": ("#5fcf69", '<path class="base" d="M10 104h108L98 73 83 86 67 37 53 78 39 61Z"/><path class="fill" d="m67 18 9 18-9 13-9-13Z"/><path class="accent" d="M17 104h94M67 49 55 64m12-15 14 16"/>'),
    "fogueira_brasas": ("#ff6f32", '<path class="base" d="M64 111c-25 0-39-16-33-38 5-17 21-25 22-49 21 13 31 31 24 48 10-7 20-4 21 11 1 17-13 28-34 28Z"/><path class="fill" d="M64 100c-12 0-19-8-15-18 3-8 11-11 12-22 10 7 14 15 10 23 5-3 10-1 9 7-1 6-6 10-16 10Z"/><circle class="dot" cx="26" cy="29" r="6"/><circle class="dot" cx="100" cy="34" r="5"/><circle class="dot" cx="18" cy="57" r="4"/>'),
    "fogueira_circulo": ("#ff4224", '<circle class="base" cx="64" cy="64" r="49"/><path class="fill" d="M64 96c-18 0-28-12-23-27 4-12 15-17 16-34 15 9 22 22 17 34 8-5 15-2 15 8 0 12-10 19-25 19Z"/><path class="accent" d="M64 15v13m0 72v13M15 64h13m72 0h13"/>'),
    "morango_cacho": ("#ff405f", '<path class="base" d="M64 30c29-16 46 10 35 37-8 21-23 36-35 45-12-9-27-24-35-45-11-27 6-53 35-37Z"/><path class="fill" d="m39 33 16-20 9 16 11-16 15 20"/><path class="accent" d="m48 55 4 6m20-8 4 6M58 76l4 6m17-5 4 6"/><circle class="dot" cx="64" cy="54" r="4"/>'),
    "morango_sementes": ("#ff2448", '<path class="base" d="M64 22c18 0 29 18 25 37-5 23-17 42-25 51-8-9-20-28-25-51-4-19 7-37 25-37Z"/><path class="fill" d="m23 31 8-11 8 11-8 11Zm74 0 8-11 8 11-8 11ZM18 85l8-11 8 11-8 11Zm76 0 8-11 8 11-8 11Z"/><path class="accent" d="M56 48h1m15 12h1M56 75h1"/>'),
    "roxo_neblina": ("#bd8cff", '<path class="base" d="M13 41c15-18 30 18 45 0s30 18 45 0c6-7 11-8 14-7v52c-15 18-30-18-45 0s-30-18-45 0c-6 7-11 8-14 7Z"/><path class="accent" d="M18 61c14-15 27 15 41 0s27 15 41 0M29 103c12-11 23 11 35 0s23 11 35 0"/><circle class="dot" cx="64" cy="64" r="6"/>'),
    "roxo_persistencia": ("#9562e8", '<path class="base" d="M64 13 77 40l29-18-17 29 28 13-28 13 17 29-29-18-13 27-13-27-29 18 17-29-28-13 28-13-17-29 29 18Z"/><circle class="fill" cx="64" cy="64" r="18"/><path class="accent" d="M64 13v102M13 64h102"/><circle class="dot" cx="64" cy="64" r="6"/>'),
    "jardim_petalas": ("#ff67b3", '<circle class="base" cx="64" cy="64" r="14"/><path class="fill" d="M64 48c-14-9-14-24 0-34 14 10 14 25 0 34Zm16 16c9-14 24-14 34 0-10 14-25 14-34 0ZM64 80c14 9 14 24 0 34-14-10-14-25 0-34ZM48 64c-9 14-24 14-34 0 10-14 25-14 34 0Z"/><path class="line" d="M31 31 45 45m38 38 14 14m0-66L83 45M45 83 31 97"/><circle class="dot" cx="64" cy="64" r="6"/>'),
    "jardim_sincronia": ("#f04491", '<circle class="base" cx="64" cy="64" r="24"/><path class="fill" d="m64 13 10 14-10 13-10-13Zm0 75 10 13-10 14-10-14ZM13 64l14-10 13 10-13 10Zm75 0 13-10 14 10-14 10Z"/><path class="accent" d="M64 40v48M40 64h48M29 29l18 18m34 34 18 18m0-70L81 47M47 81 29 99"/>'),
    "solsticio_nucleo": ("#90caff", '<circle class="base" cx="64" cy="64" r="36"/><circle class="fill" cx="64" cy="64" r="14"/><path class="accent" d="M64 8v20m0 72v20M8 64h20m72 0h20M24 24l15 15m50 50 15 15m0-80L89 39M39 89l-15 15"/><circle class="dot" cx="64" cy="64" r="6"/>'),
    "solsticio_absorcao": ("#67a8ff", '<path class="base" d="M64 13 105 30v36c0 29-17 45-41 57-24-12-41-28-41-57V30Z"/><circle class="fill" cx="64" cy="65" r="22"/><path class="accent" d="M64 43v44M42 65h44m-53-38 11 15m51-15-11 15"/><circle class="dot" cx="64" cy="65" r="7"/>'),
}

def clarear(cor: str, fator: float = .62) -> str:
    r, g, b = (int(cor[i:i + 2], 16) / 255 for i in (1, 3, 5))
    h, l, s = colorsys.rgb_to_hls(r, g, b)
    r, g, b = colorsys.hls_to_rgb(h, min(.94, l + (1 - l) * fator), min(1, s * .82))
    return f"#{round(r * 255):02x}{round(g * 255):02x}{round(b * 255):02x}"

def svg(cor: str, corpo: str) -> str:
    luz = clarear(cor)
    return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128">
  <style>
    .base{{fill:#10162e;stroke:{cor};stroke-width:7}}
    .fill{{fill:{cor};stroke:{cor};stroke-width:5}}
    .accent,.line{{fill:none;stroke:{luz};stroke-width:6}}
    .accent{{fill:{luz};fill-opacity:.22}}
    .dot{{fill:{luz};stroke:{cor};stroke-width:3}}
    path,circle,ellipse,rect{{stroke-linecap:round;stroke-linejoin:round}}
  </style>
  {corpo}
</svg>
'''

def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    existentes = {p.stem for p in OUT.glob("*.svg")}
    obsoletos = existentes - ICONES.keys()
    if obsoletos:
        raise RuntimeError(f"SVGs sem desenho novo: {sorted(obsoletos)}")
    for nome, (cor, corpo) in ICONES.items():
        (OUT / f"{nome}.svg").write_text(svg(cor, corpo), encoding="utf-8")
    print(f"Ícones de melhorias redesenhados do zero: {len(ICONES)}")

if __name__ == "__main__":
    main()
