"""Checks that corpus-owned prompts remain the Flutter asset source of truth."""

from __future__ import annotations

import importlib.util
import json
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location("sync_guided_catalog", ROOT / "tools/sync_guided_catalog.py")
assert SPEC is not None and SPEC.loader is not None
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class GuidedCatalogSyncTests(unittest.TestCase):
    def test_repository_asset_is_exact_source_copy(self) -> None:
        MODULE.sync_catalog(MODULE.SOURCE, MODULE.ASSET, write=False)
        catalog = json.loads(MODULE.SOURCE.read_text(encoding="utf-8"))
        self.assertEqual(len(catalog["items"]), 66)

    def test_divergence_fails_closed_and_repair_is_deterministic(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory) / "questions.json"
            asset = Path(directory) / "assets" / "guided_questions.json"
            source.write_bytes(MODULE.SOURCE.read_bytes())
            with self.assertRaises(ValueError):
                MODULE.sync_catalog(source, asset, write=False)
            MODULE.sync_catalog(source, asset, write=True)
            MODULE.sync_catalog(source, asset, write=False)
            asset.write_text('{"unexpected":true}', encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "differs"):
                MODULE.sync_catalog(source, asset, write=False)


if __name__ == "__main__":
    unittest.main()
