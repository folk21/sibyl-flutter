# Stable capabilities

| Feature ID | Capability and owner |
|---|---|
| `APP.EXTRACTIVE` | Exact persisted passage display and text-version/translation-role handling (`app/domain`, `app/runtime`, corpus format) |
| `APP.RETRIEVAL` | Local embedding/vector and candidate hydration (`app/retrieval`, `app/runtime`) |
| `APP.SELECTION` | Controlled random candidate selection (`app/domain`) |
| `APP.GUIDED` | Stable question mappings from SQLite (`app/runtime`, corpus v4) |
| `APP.HISTORY` | Local encounter history and saved encounters (`app/ui`; persistence future) |
| `CORPUS.BUILD` | Canonical corpus preparation and publication (Python builder) |
| `CORPUS.RIGHTS` | Text version/source provenance and translation rights (`corpus-sources`, `corpus-format`) |
| `DEV.AGENTS` | Source-bound MAIN_MODEL/WORKER_MODEL stage delegation and review (`tools/agent-pipeline`) |
| `DEV.SPECS` | Normative specs, advisory implementation plans and checkpoint state (`docs/specs`) |

Feature IDs persist across specifications; implementation stage IDs and requirement IDs do not replace them.
