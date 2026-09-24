#!/usr/bin/env python3
"""Impede que novos textos de interface sejam publicados sem pt-BR e inglês."""

from __future__ import annotations

import csv
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CSV_PATH = ROOT / "Language" / "Language.csv"
DATA_FILES = (
    "Scripts/Global.gd",
    "Scripts/SectorData.gd",
    "Scripts/UpgradeData.gd",
    "Scripts/MonthlyCatalog.gd",
)


def monthly_candidates() -> set[str]:
    """Coleta também textos passados como argumentos em MonthlyCatalog.gd."""
    text = (ROOT / "Scripts/MonthlyCatalog.gd").read_text(encoding="utf-8")
    result: set[str] = set()
    for match in re.finditer(r'"((?:[^"\\]|\\.)*)"', text):
        value = match.group(1).replace(r"\n", "\n")
        if not any(char.isalpha() for char in value):
            continue
        if value.startswith(("res://", "http", "uid://", "#")):
            continue
        if re.fullmatch(r"[a-z0-9_./:-]+", value):
            continue
        result.add(value)
    return result


def add(candidates: set[str], value: str) -> None:
    value = value.replace(r"\n", "\n")
    if value and not value.startswith("res://") and any(char.isalpha() for char in value):
        candidates.add(value)


def collect_candidates() -> set[str]:
    candidates: set[str] = set()
    for path in ROOT.rglob("*.gd"):
        if "Tests" in path.parts or path.name == "adicionar_traducoes.py":
            continue
        text = path.read_text(encoding="utf-8")
        for match in re.finditer(r'\btr\("((?:[^"\\]|\\.)*)"\)', text):
            add(candidates, match.group(1))

    for relative in DATA_FILES:
        text = (ROOT / relative).read_text(encoding="utf-8")
        pattern = r'"(?:nome|descricao|categoria|raridade|subtitulo|contexto|selo)"\s*:\s*"((?:[^"\\]|\\.)*)"'
        for match in re.finditer(pattern, text):
            add(candidates, match.group(1))

    candidates.update(monthly_candidates())

    # Textos de botões e status criados por helpers, sem atribuição direta a
    # uma propriedade `text`, também precisam entrar no contrato do catálogo.
    helper_pattern = (
        r'\b(?:_adicionar_titulo_fluxo|_adicionar_botao_fluxo|iniciar_painel_escolha|'
        r'adicionar_secao|adicionar_botao|atualizar_status)\(\s*"((?:[^"\\]|\\.)*)"'
    )
    for path in ROOT.rglob("*.gd"):
        if "Tests" in path.parts:
            continue
        text = path.read_text(encoding="utf-8")
        for match in re.finditer(helper_pattern, text):
            add(candidates, match.group(1))

    # Cenas podem exibir o valor padrão antes de qualquer script atualizá-lo.
    # Ignora apenas números, símbolos, identificadores técnicos e o título do
    # jogo, que deliberadamente não deve ser traduzido.
    for path in ROOT.rglob("*.tscn"):
        if "Tests" in path.parts or "tool" in path.parts:
            continue
        text = path.read_text(encoding="utf-8")
        pattern = r'^(?:text|placeholder_text|tooltip_text) = "((?:[^"\\]|\\.)*)"'
        for match in re.finditer(pattern, text, re.MULTILINE):
            value = match.group(1)
            if not any(char.isalpha() for char in value):
                continue
            if "Chromatic[/rainbow] Void" in value or (
                value.startswith("[wave][rainbow]Chr[") and value.endswith("matic[/rainbow] Void")
            ):
                continue
            if value in {"PET-0", "LVL", "SkillDisplay", "0 dB", "1x"}:
                continue
            add(candidates, value)

        for match in re.finditer(
            r'^(?:nome_exibicao|selo_monthly_colors) = "((?:[^"\\]|\\.)*)"',
            text,
            re.MULTILINE,
        ):
            add(candidates, match.group(1))

    # Nomes, subtítulos e avisos dos bosses chegam ao HUD por sinais e por
    # métodos, portanto não aparecem como `tr("...")` no ponto de origem.
    for path in (ROOT / "Scripts").glob("Boss*.gd"):
        text = path.read_text(encoding="utf-8")
        for match in re.finditer(
            r'@export var (?:nome_exibicao|selo_monthly_colors)\s*:=\s*"((?:[^"\\]|\\.)*)"',
            text,
        ):
            add(candidates, match.group(1))
        for match in re.finditer(r'return\s+"((?:[^"\\]|\\.)*)"', text):
            add(candidates, match.group(1))
        for call in re.finditer(r'anunciar_ataque\((.*?)\)', text, re.DOTALL):
            for match in re.finditer(r'"((?:[^"\\]|\\.)*)"', call.group(1)):
                add(candidates, match.group(1))

    astro = (ROOT / "Scripts/AstroOAsteroide.gd").read_text(encoding="utf-8").split("func _ready")[0]
    for match in re.finditer(r'\t"((?:[^"\\]|\\.)*)"', astro):
        add(candidates, match.group(1))

    for path in (ROOT / "Habilidades").glob("*.gd"):
        text = path.read_text(encoding="utf-8")
        pattern = r'criar_carta_upgrade\("((?:[^"\\]|\\.)*)",\s*"((?:[^"\\]|\\.)*)"'
        for match in re.finditer(pattern, text):
            add(candidates, match.group(1))
            add(candidates, match.group(2))
    return candidates


def main() -> int:
    with CSV_PATH.open(encoding="utf-8", newline="") as stream:
        rows = list(csv.reader(stream))
    if rows[0] != ["", "pt_BR", "en"]:
        raise AssertionError("Language.csv: cabeçalho esperado: ,pt_BR,en")

    catalog: dict[str, tuple[str, str]] = {}
    for line, row in enumerate(rows[1:], 2):
        if len(row) != 3:
            raise AssertionError(f"Language.csv:{line}: a linha precisa ter três colunas")
        key, pt_br, english = row
        if not key or not pt_br or not english:
            raise AssertionError(f"Language.csv:{line}: tradução vazia")
        if key in catalog:
            raise AssertionError(f"Language.csv:{line}: chave duplicada {key!r}")
        catalog[key] = (pt_br, english)

        formato = re.compile(r'%(?:\d+\$)?[-+0#]*(?:\d+|\*)?(?:\.\d+)?[sdf]')
        esperado = sorted(formato.findall(key))
        if sorted(formato.findall(pt_br)) != esperado or sorted(formato.findall(english)) != esperado:
            raise AssertionError(f"Language.csv:{line}: marcadores de formato divergentes")

    missing = sorted(collect_candidates() - catalog.keys())
    if missing:
        raise AssertionError("Textos sem tradução:\n- " + "\n- ".join(missing))

    required = {"T_INTRO_MADE_BY", "T_INTRO_CREATIVELY", "T_SKIPANIM"}
    if missing_intro := sorted(required - catalog.keys()):
        raise AssertionError(f"Introdução sem tradução: {missing_intro}")

    global_script = (ROOT / "Scripts/Global.gd").read_text(encoding="utf-8")
    if "OS.get_locale()" not in global_script or '_idioma_inicial_do_sistema()' not in global_script:
        raise AssertionError("Global.gd: idioma inicial não deriva da localização do sistema")
    if 'return "pt_BR" if local_sistema.begins_with("pt") else "en"' not in global_script:
        raise AssertionError("Global.gd: regra pt-BR/inglês não está explícita")

    print(f"TESTE OK: {len(catalog)} traduções cobrem interface, tutorial, dados e abertura")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
