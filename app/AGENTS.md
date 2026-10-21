# Flutter development rules

Read root `AGENTS.md` and the selected active specification before changes.

- `lib/domain` owns immutable passage data and pure weighted selection.
- `lib/retrieval` owns embedding/index interfaces and candidate-pool orchestration.
- `lib/runtime` owns native SQLite and future ONNX/FFI dependencies; web uses a separate stub.
- `lib/ui` owns presentation and local interaction state, not ranking or SQL.
- `lib/demo` contains visibly synthetic examples only.
- Persisted literary wording must be returned **exactly** from an approved text version. Never truncate or rewrite it in UI.
- Machine translations must remain visibly labelled, even if shown alone.
- Never replace a real E5 query vector with an incompatible deterministic hash vector.
- Tests must be deterministic, avoid network, and include negative/boundary behavior.
- All code, comments, README/AGENTS/config and tests remain in English.
