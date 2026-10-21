# Flutter application implementation

`main.dart` loads an optional desktop corpus and injects retrieval services into `SibylHome`.

- `domain/models.dart`: stored text/version/length categories and display order.
- `domain/selection_engine.dart`: semantic eligibility, passage deduplication, weighted random selection, injectable random source, stored variant fallback.
- `retrieval/contracts.dart`: `EmbeddingEngine`, `VectorIndex`, `CorpusRepository`, guided and free-form service contracts.
- `retrieval/local_retrieval.dart`: widened hint search, deduplication, guided mappings; no final choice.
- `retrieval/json_vector_index.dart`: local cosine scan, suitable for small development corpora.
- `retrieval/hash_embedding.dart`: exact Python hash provider parity for synthetic fixtures only.
- `runtime/guided_question_catalog.dart`: validates and loads the bundled canonical guided-question catalog even when no SQLite corpus is installed.
- `assets/guided_questions.json`: Git-tracked, byte-for-byte asset mirror of `corpus-curation/questions.json` enforced by `tools/sync_guided_catalog.py` and `make check`.
- `ui/guided_question_picker.dart`: local searching, theme grouping and selection independent of answer availability.
- `runtime/sqlite_corpus_repository.dart`: read-only format-v3/v4 hydration, exact stored text, v4 guided mappings.
- `runtime/runtime_loader_native.dart`: manifest/SQLite validation, native bundle lifetime, no E5 fallback.
- `runtime/runtime_loader_stub.dart`: safe web demo boundary.
- `ui/sibyl_home.dart`: Flutter layout, standalone prompt catalog, gated guided retrieval, exact answer rendering, session-only history and saves. Missing/mismatched corpora cannot produce synthetic guided answers.
- `demo/demo_retrieval.dart`: labelled synthetic test passages, not literary quotations.

The Kotlin Desktop native ONNX/tokenizer/E5 adapter is **not yet ported**. Platform runner projects are generated with Flutter CLI on developer machines. See the active spec and implementation plan in `../docs/specs/active/subspecs/`.

UI smoke coverage: `test/ui_smoke_test.dart` uses injected retrieval fixtures to check compact rendering, offline catalog browsing, unavailable mapping gating, guided selection, verbatim original and machine-translation display, encounter saving and empty results. `test/guided_catalog_test.dart` validates bundled IDs, text and category counts. These widget checks do not validate the generated native runners.
