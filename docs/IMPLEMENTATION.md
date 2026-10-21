# Cross-project implementation map

| Responsibility | Current owning implementation |
|---|---|
| Flutter bootstrap and native/runtime choice | `app/lib/main.dart`, `app/lib/runtime/runtime_loader*.dart` |
| Stored passage and role/length models | `app/lib/domain/models.dart` |
| Weighted controlled randomness | `app/lib/domain/selection_engine.dart` |
| Free-form and guided retrieval interfaces/services | `app/lib/retrieval/contracts.dart`, `local_retrieval.dart` |
| Read-only v3/v4 corpus/hint hydration | `app/lib/runtime/sqlite_corpus_repository.dart` |
| Synthetic hash compatibility and vector index | `app/lib/retrieval/hash_embedding.dart`, `json_vector_index.dart` |
| Standalone guided prompt catalog, UI grouping and retrieval gating | `app/assets/guided_questions.json`, `app/lib/runtime/guided_question_catalog.dart`, `app/lib/ui/guided_question_picker.dart`, `app/lib/ui/sibyl_home.dart` |
| Corpus catalog-to-asset synchronization | `tools/sync_guided_catalog.py`, `make validate-guided-catalog` |
| Exact answer labels and memory-only history | `app/lib/ui/sibyl_home.dart` |
| Python canonical source and shared primitives | `corpus-core/IMPLEMENTATION.md` |
| Python source ingestion, curation, translation, build | `corpus-builder/IMPLEMENTATION.md` |
| Current persisted semantics | `corpus-format/IMPLEMENTATION.md` and `docs/CORPUS_FORMAT.md` |
| Source registration and rights | `corpus-sources/IMPLEMENTATION.md` |
| Guided questions/curation metadata | `corpus-curation/IMPLEMENTATION.md` |
| Specs processing checkpoint | `tools/specs/validate_state.py`, `docs/specs/STATE.json` |
| Worker orchestration controller | `tools/agent-pipeline/agent_pipeline.py` and `pipeline-policy.json` |

The first runtime port preserves Kotlin SelectionEngine gates, deduplication, weighting, stored-variant fallbacks, display roles and guided SQL; E5 inference and platform-specific packaging require additional milestones documented in `MIGRATION.md`.
