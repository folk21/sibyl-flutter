"""Strict checkpoint regressions independent of source-bound worker execution."""
from __future__ import annotations

import importlib.util
import json
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
MODULE = importlib.util.spec_from_file_location("state_validator", ROOT / "tools/specs/validate_state.py")
assert MODULE is not None and MODULE.loader is not None
validator = importlib.util.module_from_spec(MODULE)
MODULE.loader.exec_module(validator)


class StateContractTests(unittest.TestCase):
    """Protect exact state fields, lifecycle semantics and root-relative active spec identity."""

    def setUp(self) -> None:
        self.folder = tempfile.TemporaryDirectory()
        self.addCleanup(self.folder.cleanup)
        self.root = Path(self.folder.name)
        self.spec = self.root / "docs/specs/active/subspecs/example.md"
        self.spec.parent.mkdir(parents=True)
        self.spec.write_text("---\nspec_status: active\n---\n# Spec\n\n### M1 — Design\n", encoding="utf-8")
        self.path = self.root / "docs/specs/STATE.json"
        self.state = {
            "schemaVersion": 1,
            "mode": "SINGLE",
            "selectedWorkstreamId": "flutter-ml-adapter",
            "workstreams": [{
                "id": "flutter-ml-adapter", "specPath": "docs/specs/active/subspecs/example.md",
                "stageId": "M1", "phase": "DESIGN", "runId": None,
                "developerDecision": "UNRECORDED",
            }],
        }

    def read(self):
        self.path.write_text(json.dumps(self.state), encoding="utf-8")
        return validator.validate_state(self.path, self.root)

    def test_valid_single_workstream_checkpoint(self):
        self.assertEqual(self.read()["workstreams"][0]["phase"], "DESIGN")

    def test_rejects_unsupported_running_phase(self):
        self.state["workstreams"][0]["phase"] = "RUNNING"
        with self.assertRaisesRegex(ValueError, "phase"):
            self.read()

    def test_rejects_model_self_acceptance(self):
        self.state["workstreams"][0]["developerDecision"] = "ACCEPTED"
        with self.assertRaisesRegex(ValueError, "developerDecision"):
            self.read()

    def test_rejects_unbound_review_without_run_id(self):
        self.state["workstreams"][0]["phase"] = "READY_FOR_REVIEW"
        with self.assertRaisesRegex(ValueError, "runId"):
            self.read()

    def test_rejects_invalid_stage_without_header(self):
        self.state["workstreams"][0]["stageId"] = "M2"
        with self.assertRaisesRegex(ValueError, "not found"):
            self.read()

    def test_rejects_additional_progressing_workstream_in_single_mode(self):
        other = dict(self.state["workstreams"][0])
        other.update(id="other-stream", specPath="docs/specs/active/subspecs/other.md")
        (self.spec.parent / "other.md").write_text("### M1 — Design\n", encoding="utf-8")
        self.state["workstreams"].append(other)
        with self.assertRaisesRegex(ValueError, "SINGLE"):
            self.read()

    def test_rejects_duplicate_json_keys(self):
        self.path.write_text('{"mode":"SINGLE","mode":"SINGLE"}', encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "Duplicate key"):
            validator.validate_state(self.path, self.root)

    def test_rejects_symlink_state(self):
        external = self.root / "outside.json"
        external.write_text(json.dumps(self.state), encoding="utf-8")
        self.path.symlink_to(external)
        with self.assertRaisesRegex(ValueError, "regular file"):
            validator.validate_state(self.path, self.root)


if __name__ == "__main__":
    unittest.main()
