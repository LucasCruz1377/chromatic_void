#!/usr/bin/env python3

"""Valida o contrato entre o jogo, os exports e as Releases do GitHub."""

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def exigir(texto: str, trecho: str, arquivo: str) -> None:
    if trecho not in texto:
        raise AssertionError(f"{arquivo}: não foi encontrado {trecho!r}")


def main() -> int:
    manager = (ROOT / "Scripts/UpdateManager.gd").read_text(encoding="utf-8")
    janela = (ROOT / "JanelaAtualizacao.gd").read_text(encoding="utf-8")
    cena = (ROOT / "janela_atualizacao.tscn").read_text(encoding="utf-8")
    projeto = (ROOT / "project.godot").read_text(encoding="utf-8")
    presets = (ROOT / "export_presets.cfg").read_text(encoding="utf-8")
    workflow = (ROOT / ".github/workflows/release.yml").read_text(encoding="utf-8")
    itch_workflow = (ROOT / ".github/workflows/itchio.yml").read_text(encoding="utf-8")

    exigir(manager, "Windows.Desktop.zip", "UpdateManager.gd")
    exigir(manager, "ChromaticVoid-Android.apk", "UpdateManager.gd")
    exigir(manager, "api.github.com/repos/%s/releases", "UpdateManager.gd")
    exigir(manager, "itch.io/api/1/x/wharf/latest", "UpdateManager.gd")
    exigir(manager, "var endpoint := ITCH_LATEST_API if verificando_itch else RELEASES_API", "UpdateManager.gd")
    exigir(manager, "if response_code == 404:", "UpdateManager.gd")
    exigir(manager, "update_check_finished.emit()", "UpdateManager.gd")
    exigir(manager, "lukass-1377.itch.io/chromatic-void", "UpdateManager.gd")
    exigir(manager, "FileAccess.get_sha256", "UpdateManager.gd")
    exigir(janela, "UpdateManager.iniciar_atualizacao()", "JanelaAtualizacao.gd")
    exigir(cena, 'anchor_right = 1.0', "janela_atualizacao.tscn")
    exigir(cena, 'anchor_bottom = 1.0', "janela_atualizacao.tscn")
    exigir(cena, '[node name="Centralizador" type="CenterContainer"', "janela_atualizacao.tscn")
    exigir(projeto, 'UpdateManager="*', "project.godot")

    exigir(presets, 'name="Android APK"', "export_presets.cfg")
    exigir(presets, 'package/unique_name="com.lucascruz1377.chromaticvoid"', "export_presets.cfg")
    exigir(presets, 'package/signed=true', "export_presets.cfg")
    exigir(presets, 'package/retain_data_on_uninstall=true', "export_presets.cfg")
    exigir(presets, 'permissions/internet=true', "export_presets.cfg")

    exigir(workflow, "ANDROID_KEYSTORE_BASE64", "release.yml")
    exigir(workflow, "packages: platform-tools", "release.yml")
    if "packages: tools" in workflow:
        raise AssertionError("release.yml: pacote Android legado tools não deve ser instalado")
    exigir(workflow, "apksigner", "release.yml")
    exigir(workflow, "PyInstaller", "release.yml")
    exigir(workflow, "Preparar Release em rascunho", "release.yml")
    exigir(workflow, 'gh release upload "$TAG"', "release.yml")
    exigir(workflow, 'gh release download "$TAG"', "release.yml")
    if "actions/upload-artifact" in workflow or "actions/download-artifact" in workflow:
        raise AssertionError("release.yml: Actions artifacts não devem ser usados")
    exigir(workflow, "ChromaticVoid-Android.apk", "release.yml")
    exigir(workflow, "Windows.Desktop.zip", "release.yml")
    exigir(itch_workflow, "Windows.Desktop.zip", "itchio.yml")
    exigir(itch_workflow, "ChromaticVoid-Android.apk", "itchio.yml")

    print("TESTE OK: contrato do sistema de atualização Windows/Android")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
