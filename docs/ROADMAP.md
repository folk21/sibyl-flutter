# Roadmap

## Delivered in this Flutter handoff (source-level)

- Flutter app UI, synthetic demo, domain, local retrieval interfaces and pure selection engine.
- Format-v3/v4 native SQLite hydration and format-v4 guided-question navigation on desktop.
- Synthetic hash embedding and exhaustive vector index for deterministic build compatibility tests (not a production semantic model).
- Preserved Python corpus builder/source registries and format v4.
- Transferred strict `STATE.json` validator/schema and adapted source-bound Aider controller/policy; separate explicit human review remains required.

## Active migration priorities

1. `APP.RETRIEVAL`: real local E5/ONNX tokenizer/runtime support on macOS Intel; validate numerical parity and manifest compatibility. See active spec `flutter-native-e5.md` and its advisory companion.
2. `APP.RETRIEVAL`: add Android/iOS native model and corpus packaging with explicit paths, lifecycle and offline constraints.
3. `APP.HISTORY`: persistent privacy-preserving local encounter store with deletion controls and migration tests.
4. Broader UI/accessibility/desktop integration and packaging tests across macOS, Windows, Linux, Android, iOS and web.
5. Pilot `DEV.AGENTS` in a clean Git checkout with approved LOW-risk task and live prerequisites, independently review evidence before broadening scope.

Current behavior is described in `IMPLEMENTATION.md`; roadmap entries are not worker authorization.
