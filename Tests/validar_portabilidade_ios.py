#!/usr/bin/env python3
"""Valida o contrato portátil iOS sem exigir credenciais Apple no CI Linux."""

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PRESETS = (ROOT / "export_presets.cfg").read_text(encoding="utf-8")
GLOBAL = (ROOT / "Scripts/Global.gd").read_text(encoding="utf-8")
AIM = (ROOT / "Scripts/aim.gd").read_text(encoding="utf-8")

assert 'name="iOS Xcode Project"' in PRESETS
assert 'platform="iOS"' in PRESETS
assert 'custom_features="mobile,mobile_controls,ios"' in PRESETS
assert 'architectures/arm64=true' in PRESETS
assert 'application/bundle_identifier="com.lucascruz1377.chromaticvoid"' in PRESETS
assert 'application/app_store_team_id="XXXXXXXXXX"' in PRESETS
assert 'application/export_project_only=true' in PRESETS
assert 'application/min_ios_version="14.0"' in PRESETS
assert 'OS.get_name() in ["Android", "iOS"]' in GLOBAL
assert 'func definir_cursor_interface(' in GLOBAL
assert 'if Global.dispositivo_mobile()' in AIM
assert (ROOT / "PORTABILIDADE_IOS.md").exists()

print("VALIDAÇÃO OK: preset e comportamento mobile/iOS preparados")
