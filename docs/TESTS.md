# Tests and reproducible checks

## Offline Python baseline

After installing `corpus-core` and `corpus-builder[dev]` locally:

```bash
make check
```

This executes corpus-core tests, corpus-builder tests, format and registry validation, strict `STATE.json` validation, and byte-identical bundled guided-question catalog synchronization tests. No model download, source fetch or external API is part of the baseline.

## Flutter

```bash
cd app
flutter pub get
flutter test
flutter analyze
dart format --output=none --set-exit-if-changed lib test
```

`make check-all` combines Python with Flutter tests and analyzer and requires the Flutter SDK. Tests exercise exact stored text selection, translation labels, deterministic weighted randomness, retrieval deduplication, synthetic hash compatibility, and local SQLite v4 guided mappings. UI smoke tests additionally verify a compact viewport, complete catalog browsing without SQLite, disabled responses for unmapped questions, guided-question use, byte-for-byte text display including whitespace, visibly labelled machine translations, session-only saving, and an explicit empty-candidate state. Native UI smoke runs on macOS via `flutter run -d macos`; browser demo via `flutter run -d chrome`. Flutter CI uses a pinned Flutter 3.35.5 toolchain for repeatability (Dart 3.9 baseline), but this is not an Intel macOS runtime certification. Flutter widget tests do not establish native packaging, App Sandbox permissions, simulator input behavior, or ONNX inference. No CI result is claimed without execution.

## Spec/worker controller

```bash
python3 tools/specs/validate_state.py
python3 -m unittest discover -s tools/specs/tests -p 'test_*.py'
python3 -m unittest discover -s tools/agent-pipeline/tests -p 'test_*.py'
```

The worker controller is ported from SignalHarvester and requires clean Git, pinned external Aider/Gitleaks tools and provider settings before **live** execution. Its test suite uses local fixtures; a passing test does not grant permission to call a provider. The canonical opt-in worker verification script `./run_checks.sh` runs all applicable local checks and fails when Flutter is absent.

Test cases are independent evidence, not targets to weaken for a green status. Report unsupported platforms and missing tools explicitly. `docs/MIGRATION.md` tracks unverified parity.
