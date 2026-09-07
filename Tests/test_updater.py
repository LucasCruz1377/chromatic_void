#!/usr/bin/env python3

"""Testes locais do atualizador externo do Windows."""

from __future__ import annotations

import importlib.util
import sys
import tempfile
import zipfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location(
    "chromatic_updater",
    ROOT / "Updater/main.py",
)
UPDATER = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(UPDATER)


def testar_atualizacao() -> None:
    with tempfile.TemporaryDirectory() as temp:
        raiz = Path(temp)
        jogo = raiz / "jogo"
        jogo.mkdir()
        executavel = jogo / "Chromatic Void.exe"
        recurso = jogo / "jogo.pck"
        executavel.write_text("versao antiga", encoding="utf-8")
        recurso.write_text("recurso antigo", encoding="utf-8")

        pacote = raiz / "update.zip"
        with zipfile.ZipFile(pacote, "w") as arquivo:
            arquivo.writestr("Chromatic Void.exe", "versao nova")
            arquivo.writestr("jogo.pck", "recurso novo")
            arquivo.writestr("novo.txt", "arquivo novo")

        argumentos_anteriores = sys.argv
        sys.argv = [
            "Updater.exe",
            "--worker",
            str(pacote),
            str(jogo),
            str(executavel),
            "99999999",
        ]
        popen_anterior = UPDATER.subprocess.Popen
        UPDATER.subprocess.Popen = lambda *args, **kwargs: None
        try:
            codigo = UPDATER.executar_worker()
        finally:
            sys.argv = argumentos_anteriores
            UPDATER.subprocess.Popen = popen_anterior

        assert codigo == 0
        assert executavel.read_text(encoding="utf-8") == "versao nova"
        assert recurso.read_text(encoding="utf-8") == "recurso novo"
        assert (jogo / "novo.txt").read_text(encoding="utf-8") == "arquivo novo"
        assert not pacote.exists()


def testar_zip_inseguro() -> None:
    with tempfile.TemporaryDirectory() as temp:
        raiz = Path(temp)
        pacote = raiz / "inseguro.zip"
        destino = raiz / "destino"
        destino.mkdir()

        with zipfile.ZipFile(pacote, "w") as arquivo:
            arquivo.writestr("../fora.txt", "não pode sair")

        try:
            UPDATER.extrair_zip_seguro(str(pacote), str(destino))
        except RuntimeError:
            pass
        else:
            raise AssertionError("o updater aceitou um ZIP com path traversal")


if __name__ == "__main__":
    testar_atualizacao()
    testar_zip_inseguro()
    print("TESTE OK: aplicação segura do updater Windows")
