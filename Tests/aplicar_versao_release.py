#!/usr/bin/env python3
"""Aplica a versão da tag aos metadados exportados pelo Godot."""

from __future__ import annotations

import re
import sys
from pathlib import Path


PADRAO_TAG = re.compile(r"^v(\d+)\.(\d+)\.(\d+)(?:-(alpha|beta|rc)\.(\d+))?$")


def substituir_unico(texto: str, padrao: str, novo: str, arquivo: Path) -> str:
    resultado, quantidade = re.subn(padrao, novo, texto, count=1, flags=re.MULTILINE)
    if quantidade != 1:
        raise RuntimeError(f"Não foi possível atualizar {arquivo}: {padrao}")
    return resultado


def main() -> int:
    if len(sys.argv) != 3:
        print("Uso: aplicar_versao_release.py vX.Y.Z[-beta.N] VERSION_CODE")
        return 2

    tag = sys.argv[1]
    correspondencia = PADRAO_TAG.fullmatch(tag)
    if not correspondencia:
        print(f"Tag inválida: {tag}")
        return 2

    version_code = int(sys.argv[2])
    if version_code <= 0:
        print("VERSION_CODE deve ser maior que zero.")
        return 2

    versao = tag.removeprefix("v")
    projeto = Path("project.godot")
    presets = Path("export_presets.cfg")

    texto_projeto = substituir_unico(
        projeto.read_text(encoding="utf-8"),
        r'^config/version="[^"]*"$',
        f'config/version="{versao}"',
        projeto,
    )
    projeto.write_text(texto_projeto, encoding="utf-8")

    texto_presets = presets.read_text(encoding="utf-8")
    inicio_android = texto_presets.index('[preset.2.options]')
    prefixo = texto_presets[:inicio_android]
    bloco_android = texto_presets[inicio_android:]
    bloco_android = substituir_unico(
        bloco_android,
        r'^version/code=\d+$',
        f'version/code={version_code}',
        presets,
    )
    bloco_android = substituir_unico(
        bloco_android,
        r'^version/name="[^"]*"$',
        f'version/name="{versao}"',
        presets,
    )
    presets.write_text(prefixo + bloco_android, encoding="utf-8")
    print(f"Versão aplicada: {versao} (Android code {version_code})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
