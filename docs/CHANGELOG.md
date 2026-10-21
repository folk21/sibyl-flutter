# Changelog

## 2026-10-21

- Made the complete 66-prompt guided-question catalog (55 questions and 11 states) independently available in Flutter without a published SQLite corpus, with theme-grouped browsing and text search.
- Kept literal literary answers gated on available v4 mappings; a missing or unreadable corpus cannot yield synthetic guided quotations.
- Added canonical JSON asset synchronization checks, parser regression tests and no-corpus/unmapped UI smoke scenarios. E5 free-form production inference remains out of scope.

## 2026-10-20

- Reviewed the independent AnotherBoringNote Flutter port, added guided/translation UI smoke tests, pinned a provisional Flutter CI version, and documented macOS sandbox corpus access and platform parity evidence without replacing the source-bound agent workflow.
- Created an independent Flutter/Dart Sibyl codebase from the KMP source tree while retaining Python corpus tooling, format v4 and source/curation metadata.
- Added Dart selection/retrieval/domain and Flutter UI, read-only desktop SQLite guided lookup, labelled synthetic demo, and explicit unsupported real-E5 boundary.
- Introduced source-bound `MAIN_MODEL`/Aider `WORKER_MODEL` workflow conventions, advisory same-directory implementation plans, strict processing checkpoint `STATE.json`, and adapted agent-pipeline tooling and docs.
- Added workstation setup instructions for Intel macOS and supported platform previews.

This entry records source migration intent and contents, not an unexecuted Flutter build result.
