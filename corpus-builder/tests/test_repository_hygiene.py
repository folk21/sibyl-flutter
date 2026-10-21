"""Repository archive/snapshot regression tests for the Flutter migration."""

import subprocess
import re
import sys
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SOURCE = "corpus-builder/src/sibyl_corpus_builder/build/api.py"


def test_build_feature_is_trackable_source() -> None:
    """The Python feature named `build` is not a generated output directory."""
    rules = set((ROOT / ".gitignore").read_text(encoding="utf-8").splitlines())
    assert (ROOT / SOURCE).is_file()
    assert "**/build/" not in rules
    assert "/corpus-builder/build/" in rules
    assert "/app/build/" in rules


def test_full_archive_is_rooted_and_excludes_sensitive_artifacts(tmp_path: Path) -> None:
    """The actual FULL archive keeps source packages and rejects generated artifacts."""
    output = tmp_path / "sibyl-flutter-FULL.zip"
    subprocess.run([sys.executable, str(ROOT / "tools/repository_snapshot.py"), "full", str(output)],
                   check=True, cwd=ROOT)
    with zipfile.ZipFile(output) as archive:
        names = archive.namelist()
        assert names and all(name.startswith("sibyl-flutter/") for name in names)
        assert f"sibyl-flutter/{SOURCE}" in names
        assert "sibyl-flutter/app/lib/main.dart" in names
        assert "sibyl-flutter/docs/specs/STATE.json" in names
        assert "sibyl-flutter/app/assets/guided_questions.json" in names
        assert not any(".dart_tool" in name or "corpus-builder/data/" in name for name in names)
        assert not any(name.startswith("sibyl-flutter/build/") for name in names)


def test_llm_snapshot_keeps_active_specs_and_excludes_historical_worklog(tmp_path: Path) -> None:
    """Context includes current normative state without old KMP historical archive noise."""
    output = tmp_path / "snapshot.txt"
    subprocess.run([sys.executable, str(ROOT / "tools/repository_snapshot.py"), "concat", str(output)],
                   check=True, cwd=ROOT)
    content = output.read_text(encoding="utf-8")
    assert SOURCE in content
    assert "docs/specs/active/subspecs/flutter-native-e5.md" in content
    assert "=== FILE: docs/specs/STATE.json ===" in content
    assert re.search(r"^=== FILE: docs/specs/archive/", content, re.M) is None
    assert re.search(r"^=== FILE: docs/WORKLOG.md ===", content, re.M) is None


def test_selected_state_is_single_and_points_to_active_spec() -> None:
    """The migration must not leave an ambiguous KMP-era active processing scope."""
    import json

    state = json.loads((ROOT / "docs/specs/STATE.json").read_text(encoding="utf-8"))
    assert state["mode"] == "SINGLE"
    selected = [item for item in state["workstreams"]
                if item["id"] == state["selectedWorkstreamId"]]
    assert len(selected) == 1
    assert (ROOT / selected[0]["specPath"]).is_file()
    assert selected[0]["phase"] not in {"RUNNING", "ACCEPTED"}
