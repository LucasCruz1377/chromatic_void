#!/usr/bin/env python3
"""Valida referências literais res:// antes de abrir o projeto no Godot."""

from __future__ import annotations

import re
import sys
from pathlib import Path


RAIZ = Path(__file__).resolve().parents[1]
EXTENSOES_TEXTO = {".gd", ".gdshader", ".godot", ".tres", ".tscn"}
PASTAS_IGNORADAS = {".git", ".godot"}
REFERENCIA = re.compile(r'["\'](res://[^"\'\n]+)["\']')


def arquivos_do_projeto() -> list[Path]:
    return sorted(
        caminho
        for caminho in RAIZ.rglob("*")
        if caminho.is_file()
        and caminho.suffix in EXTENSOES_TEXTO
        and not PASTAS_IGNORADAS.intersection(caminho.parts)
    )


def referencia_literal(valor: str) -> bool:
    return "%" not in valor and "{" not in valor and "}" not in valor


def main() -> int:
    ausentes: dict[str, set[str]] = {}
    verificadas: set[str] = set()

    for origem in arquivos_do_projeto():
        conteudo = origem.read_text(encoding="utf-8")
        for referencia in REFERENCIA.findall(conteudo):
            if not referencia_literal(referencia):
                continue
            verificadas.add(referencia)
            destino = RAIZ / referencia.removeprefix("res://")
            if not destino.exists():
                ausentes.setdefault(referencia, set()).add(
                    origem.relative_to(RAIZ).as_posix()
                )

    if ausentes:
        print("Referências ausentes:", file=sys.stderr)
        for referencia, origens in sorted(ausentes.items()):
            print(f"- {referencia}", file=sys.stderr)
            for origem in sorted(origens):
                print(f"  usada em: {origem}", file=sys.stderr)
        return 1

    print(f"Referências res:// verificadas: {len(verificadas)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
