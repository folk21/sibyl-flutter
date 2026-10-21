# Kotlin Multiplatform to Flutter migration ledger

**Reference:** user-supplied `sibyl-FULL.zip` (KMP source) and `signalharvester_files.txt` (agent workflow source, 2026-10-20 snapshot). This new repository does not depend on the original checkout or on SignalHarvester at runtime.

| KMP behavior / subsystem | Flutter/Dart migration state |
|---|---|
| Immutable passage/translation/length metadata | Ported to `app/lib/domain/models.dart` |
| Exact stored short/standard/extended selection | Ported; no text cutting |
| Weighted, injected-random SelectionEngine | Ported with negative/edge tests |
| Candidate pool / hint deduplication / guided retrieval | Ported to `app/lib/retrieval` |
| Compose Material UI | Reimplemented with Flutter Material 3: standalone searchable theme-grouped catalog of 66 guided prompts even without a corpus, available-only literary retrieval, results, history and saved encounters |
| DemoRetrievalService | Ported, explicitly marked synthetic |
| SQLite corpus format-v3/v4 reader | Ported for native desktop (`sqlite3`), including original/human/machine text versions |
| `vectors.json` exhaustive cosine index | Ported for small fixture corpora |
| Build-time Python hash provider | Ported byte-compatible SHA-256 development engine |
| Kotlin Desktop E5 tokenizer + ONNX Runtime | **Not ported**; future FFI/plugin adapter with parity tests; never substitute fake query vectors |
| Android product real corpus support | KMP used demo; Flutter currently demo until asset-install runtime is implemented |
| iOS product support | Flutter UI preview possible after runner generation, real corpus/runtime packaging pending |
| Saved history persistence | KMP was memory-only, Flutter stays memory-only pending local store spec |
| Python corpus-core/builder/sources/curation/test fixtures | Retained as build-time code, no rewrite |
| `corpus-format` v4 schema and manifest | Retained intact; no format bump needed for UI migration |
| MAIN_MODEL / WORKER_MODEL | SignalHarvester controller imported with Sibyl policy mapping, strict state validator and spec/implementation-plan convention |

## Limits and fidelity

The guided-question catalog is available offline from a packaged, byte-for-byte canonical JSON asset. Real guided *answers* require published v4 mappings; a missing or unmapped corpus never causes a fabricated literary answer. The deterministic synthetic own-question demo does not claim semantic relevance. Dart SQLite queries preserve exact persisted text and role metadata. `sentence_transformers` E5 bundles are not consumed until the active spec completes; the Kotlin Desktop app's complete free-form real-corpus feature is therefore **not yet feature-parity**. In addition, platform runners are generated once on the target workstation, and full Mac/Android/iOS/Windows/Linux build success has not been established in this environment.

The imported agent controller preserves its existing restrictive source-bound model rather than granting unattended execution. Project-specific policy, developer Git checks, Aider 0.86.2, scanner 8.30.1, provider access/consent and independent review must be validated in an actual clean Git checkout before any live coding worker task. Its SignalHarvester implementation plans are a reference, not Sibyl active specifications.

## Review of the AnotherBoringNote Flutter port (2026-10-20)

The user-supplied `anotherboringnote-flutter-FULL.zip` was reviewed as a **reference for porting process**, not as a source of Sibyl product behavior. Its Git-tracked Flutter runners, source-to-target parity ledger, platform-aware storage boundary, widget smoke tests, and stage-oriented MAIN/WORKER instructions are useful patterns. The decisions for Sibyl are:

| Reference practice | Sibyl decision | Reason / next gate |
|---|---|---|
| Native macOS, Android, iOS, Linux, Windows and web runners checked into Git | **Defer copying runners; generate Sibyl-owned runners with `flutter create` on the workstation, format the Dart source, then commit them** | Another app's package IDs, entitlements, icons, generated version files and signing settings must not be transplanted. The new repo becomes independently buildable once its own generated hosts are committed. |
| Traceable KMP-to-Flutter porting matrix | **Retain this existing migration ledger and record verification gaps explicitly** | Do not create a competing parity document. Native runner and E5 parity remain unverified. |
| Widget smoke tests independent of services | **Adopt** `app/test/ui_smoke_test.dart` | Synthetic guided service exercises exact source/translation presentation, saved encounters and empty retrieval without external services. |
| macOS sandbox-scoped local storage | **Adopt access guidance, not AnotherBoringNote's storage implementation** | Sibyl's opt-in corpus is read-only; raw absolute paths may be sandbox-denied. See `INSTALLATION.md`. Durable encounter/history storage requires its own contract and testable adapter, not copying notes' plain-text storage format. |
| Simple Aider shell wrapper and per-spec mutable `STATE.json` | **Do not replace Sibyl workflow** | SignalHarvester-derived source-bound controller already enforces stronger isolated worker/reviewer/evidence checks. `docs/specs/STATE.json` remains the single developer checkpoint; implementation plans remain adjacent to normative specs. |
| Pin Flutter SDK in CI | **Adopt a provisional CI baseline** | CI targets Flutter 3.35.5, matching the reference bootstrap era and Dart 3.9 constraint. This is a repeatable target, **not** a validated Intel macOS build; record actual native evidence before declaring it known-good. |

### Recommended parity evidence before release

| Target | UI preview | Real guided corpus | Native E5 retrieval | Evidence still needed |
|---|---|---|---|---|
| Intel macOS | Source implemented; launch unverified | SQLite reader implemented; sandbox run unverified | Not implemented | `flutter run -d macos`, macOS sandbox test, Intel x64 smoke |
| Chrome/web | Synthetic demo implemented; launch unverified | Not implemented | Not implemented | `flutter run -d chrome`, smoke/overflow and privacy checks |
| Android | Synthetic demo implemented; device run unverified | Not packaged | Not implemented | Emulator/device smoke, asset install, storage permissions |
| iOS Simulator | Synthetic demo implemented; simulator run unverified | Not packaged | Not implemented | Xcode simulator smoke, signing and asset install |
| Windows/Linux desktop | Synthetic demo implemented; native run unverified | SQLite reader implemented; access unverified | Not implemented | Tests on each target operating system, corpus fixture smoke |

Do not promote source-level presence to parity acceptance. Product and stage statuses remain governed by `docs/specs/STATE.json`, the active E5 spec and actual validation evidence.
