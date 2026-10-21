---
document_role: advisory-implementation-plan
---
# Native E5 adapter implementation plan (advisory)

**Owning normative spec:** [`flutter-native-e5.md`](flutter-native-e5.md); stages M1/M2/M3; requirements R-E5-01 … R-E5-05; Feature IDs `APP.RETRIEVAL` and `APP.EXTRACTIVE`. This companion does **not** grant approval, alter platform scope or acquire separate acceptance status.

## Read before implementation

`AGENTS.md`, `app/AGENTS.md`, `app/IMPLEMENTATION.md`, `docs/ARCHITECTURE.md`, `docs/MIGRATION.md`, `docs/TESTS.md`, `corpus-format/manifest.schema.json`, `corpus-format/schema.sql`, `app/lib/retrieval/contracts.dart`, `app/lib/retrieval/local_retrieval.dart`, `app/lib/runtime/runtime_loader_native.dart`, `corpus-builder/src/sibyl_corpus_builder/build/_internal/runtime_model/`, and the original KMP Desktop `OnnxE5EmbeddingEngine` if available as read-only reference. Do not treat Kotlin as runtime dependency.

## M1: native adapter discovery (developer-led; HIGH risk)

1. **Expected design files:** update this plan and owning spec's unresolved decisions with candidates for native ONNX Runtime via macOS x64 FFI or a maintained Flutter plugin; evaluate tokenizer parity, binary license/size, bundling, install/upgrade and offline model integrity. Confirm whether one ONNX/tokenizer implementation can cover Android/iOS later without exporting model input off device.
2. **Candidate APIs:** `class OnnxE5EmbeddingEngine implements EmbeddingEngine`, `RuntimeModelManifest`, `RuntimeBundle` resource ownership. Choose asynchronous inference scheduling without blocking Flutter UI. Keep resource constructors isolated in `runtime` and make failures explicit.
3. **Expected compatibility gate:** validate corpus/model `model_id`, dimensions, `normalize`, `query_prefix`, pooling=`mean`, model-file/tokenizer-file safe relative paths, model `schema_version`, corpus format in {3,4}; verify artifact/hash trust if provided by package. Reject mismatches before opening native sessions.
4. **Unresolved:** exact FFI package, supported ABI and minimum OS, tokenizer implementation, licensing/provenance/binary distribution and numerical parity tolerances. Stage authorization MUST remain blocked until these decisions and fixture ownership are reviewed.

## M2: integration approach after M1 approval

- Expected: `app/lib/runtime/onnx_e5_embedding_engine.dart` (adapter behind `EmbeddingEngine`), plus native binding files only where explicitly approved.
- Expected: `app/lib/runtime/runtime_loader_native.dart` validation and guarded ownership of corpus, vectors, tokenizer and inference session. Construct/release resources as a unit; failed initialization must close partially opened dependencies.
- Expected: use current `JsonVectorIndex` initially for small corpora; no ANN rewrite during E5 integration. Existing `LocalRetrievalService` still widens search and deduplicates at passage ID.
- Expected: update `app/pubspec.yaml` only after dependency approval; model distribution remains outside Git; update `app/IMPLEMENTATION.md`, `docs/INSTALLATION.md`, `docs/USAGE.md` after behavior is observed.
- Candidate: isolate inference in background isolates where backend threads/Flutter host allow it; document concurrency and cancellation. Do not invent production packaging semantics based on synthetic tests.

### Illustrative flow (not implementation)

```text
read corpus manifest and model manifest
validate model ID / dimensions / normalize / prefix / pooling / paths
open read-only SQLite and vectors; open local tokenizer and ONNX session
embed: tokenize(queryPrefix + question), run ONNX, masked mean pool, normalize
LocalRetrievalService: cosine vector search -> exact SQLite passage rows
SelectionEngine: eligible weighted random -> existing PassageVariant
on dispose/error: close every owned native handle
```

## M3: independent oracle scenarios

| ID | Setup / action | Required observable result |
|---|---|---|
| E5-P01 | Approved offline reference token/vector pairs for multilingual inputs, including Cyrillic; run local adapter | Token IDs/masks and normalized pooled vectors agree with independently pinned tolerance; no outbound calls |
| E5-P02 | v4 corpus with multiple hints mapping to one passage, ask a question | Candidate widening/dedup, stored text and translation labels match source; selection still samples more than top-1 |
| E5-N01 | Mismatch model ID/dimensions/normalize/query_prefix/pooling | Runtime rejects before model inference; no fake hash fallback |
| E5-N02 | Missing/corrupt tokenizer or unsafe manifest relative path | Clear local failure and all partially allocated resources released |
| E5-B01 | Empty, Unicode, long/truncated-to-token-limit input and zero-vector cases | Documented deterministic handling, finite vector or explicit rejection |
| E5-R01 | Close/reopen native runtime repeatedly, simulate failed startup | No stale session/use-after-close; exact storage can still reopen |
| E5-A01 | Turn off network, inspect process telemetry/logs during inference | No question transmission, model download or sensitive question logs |

Use synthetic fixtures for `flutter test` and an explicitly provisioned local reference bundle for opt-in native parity tests. Run focused tests before `make check-all` and local `flutter run -d macos`. If a valid oracle fails, fix implementation or escalate; never weaken it to make PASS. Every accepted stage needs independent evidence and developer signoff.

## Alternatives and trade-offs

- A supported cross-platform inference plugin may reduce native glue but could increase binary size, hidden downloads or backend coupling. Inspect source/licensing and verify offline boundaries.
- Direct FFI can minimize abstraction layers but adds ABI, packaging, thread and resource ownership complexity, particularly on Intel macOS.
- Embedding in Python at runtime or remote services is **not** allowed as a compatibility shortcut.
