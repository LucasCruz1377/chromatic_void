#!/usr/bin/env python3

"""Aplica a versão da tag aos metadados exportados pelo Godot."""

from __future__ import annotations

import re
import sys
from pathlib import Path


PADRAO_TAG = re.compile(
    r"^v(\d+)\.(\d+)\.(\d+)(?:-(alpha|beta|rc)\.(\d+))?$"
)


def substituir_unico(
    texto: str,
    padrao: str,
    novo: str,
    arquivo: Path,
) -> str:
    resultado, quantidade = re.subn(
        padrao,
        novo,
        texto,
        count=1,
        flags=re.MULTILINE,
    )

    if quantidade != 1:
        raise RuntimeError(
            f"Não foi possível atualizar {arquivo}: {padrao}"
        )

    return resultado


def encontrar_preset_android(texto: str) -> tuple[int, int]:
    """
    Localiza o bloco do preset cujo name é 'Android APK'.

    Retorna:
        (início_do_bloco, fim_do_bloco)
    """

    padrao = re.compile(
        r'^\[preset\.(\d+)\]\n'
        r'.*?^name="Android APK"\n'
        r'.*?'
        r'(?=^\[preset\.\d+\]|\Z)',
        re.MULTILINE | re.DOTALL,
    )

    correspondencia = padrao.search(texto)

    if not correspondencia:
        raise RuntimeError(
            "Não foi encontrado um preset chamado 'Android APK' "
            "em export_presets.cfg."
        )

    inicio = correspondencia.start()
    fim = correspondencia.end()

    return inicio, fim


def atualizar_opcoes_android(
    bloco_preset: str,
    version_code: int,
    versao: str,
) -> str:
    """
    Atualiza version/code e version/name dentro do bloco Android.
    """

    resultado = substituir_unico(
        bloco_preset,
        r'^version/code=\d+$',
        f"version/code={version_code}",
        Path("export_presets.cfg"),
    )

    resultado = substituir_unico(
        resultado,
        r'^version/name="[^"]*"$',
        f'version/name="{versao}"',
        Path("export_presets.cfg"),
    )

    return resultado


def main() -> int:
    if len(sys.argv) != 3:
        print(
            "Uso: aplicar_versao_release.py "
            "vX.Y.Z[-alpha.N|-beta.N|-rc.N] VERSION_CODE"
        )
        return 2

    tag = sys.argv[1]

    correspondencia = PADRAO_TAG.fullmatch(tag)

    if not correspondencia:
        print(f"Tag inválida: {tag}")
        return 2

    try:
        version_code = int(sys.argv[2])
    except ValueError:
        print("VERSION_CODE deve ser um número inteiro.")
        return 2

    if version_code <= 0:
        print("VERSION_CODE deve ser maior que zero.")
        return 2

    versao = tag.removeprefix("v")

    projeto = Path("project.godot")
    presets = Path("export_presets.cfg")

    if not projeto.exists():
        raise RuntimeError("project.godot não foi encontrado.")

    if not presets.exists():
        raise RuntimeError("export_presets.cfg não foi encontrado.")

    # ==========================================================
    # PROJECT.GODOT
    # ==========================================================

    texto_projeto = projeto.read_text(encoding="utf-8")

    texto_projeto = substituir_unico(
        texto_projeto,
        r'^config/version="[^"]*"$',
        f'config/version="{versao}"',
        projeto,
    )

    projeto.write_text(
        texto_projeto,
        encoding="utf-8",
    )

    # ==========================================================
    # EXPORT_PRESETS.CFG
    # ==========================================================

    texto_presets = presets.read_text(encoding="utf-8")

    inicio, fim = encontrar_preset_android(texto_presets)

    bloco_android = texto_presets[inicio:fim]

    bloco_android = atualizar_opcoes_android(
        bloco_android,
        version_code,
        versao,
    )

    texto_presets = (
        texto_presets[:inicio]
        + bloco_android
        + texto_presets[fim:]
    )

    presets.write_text(
        texto_presets,
        encoding="utf-8",
    )

    print("==========================================")
    print("VERSÃO APLICADA")
    print("==========================================")
    print(f"Versão:       {versao}")
    print(f"Android code: {version_code}")
    print("==========================================")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
