# Sibyl repository engineering rules

Sibyl is an offline-first Flutter/Dart literary-discovery application with a separate Python corpus builder. Read root `README.md`, the nearest local `AGENTS.md`, owning tests/contracts and `docs/specs/STATE.json` before changing code. An active specification governs intended changes in its stated scope.

## Product and privacy

- Displayed literary text MUST equal an approved persisted `passage_text.text` value exactly. No LLM-generated quotes, clipping, rewriting, runtime translation or fabricated source attribution.
- Retrieve multiple plausible candidates and use injected randomness for weighted passage selection; do not return nearest vector hit unconditionally.
- Passage length (`short`/`standard`/`extended`) and text-version role (`original`/`human_translation`/`machine_translation`) are independent. Label machine translations in all UI states.
- Questions, history, user actions, embeddings, retrieval and selection remain local. Do not add telemetry, cloud queries, user logging or mandatory accounts.
- Python source acquisition, curation and translation may use explicitly approved build-time network services only. Rights/provenance review is mandatory; public-domain originals do not authorize modern translations.

## Source ownership

- `app/lib/domain` — immutable models and pure selection; `app/lib/retrieval` — retrieval interfaces/orchestration; `app/lib/runtime` — SQLite and platform inference/index adapters; `app/lib/ui` — presentation only; `app/lib/demo` — labelled synthetic fixtures.
- `corpus-core` — feature-neutral Python corpus primitives; `corpus-builder` — build-time features; `corpus-format` — schema/format versions; `corpus-sources` — source versions, provenance, rights; `corpus-curation` — validated curation metadata; `test-corpus` — synthetic fixtures.
- Do not leak platform APIs into domain/selection. Do not convert incompatible real E5 embeddings to fake hash vectors. Format changes require explicit version changes and coordinated tests/writer/reader changes.
- All software code, comments, docs, tests, configuration comments and agent instructions MUST be in English. Literary passages retain exact source wording.

## MAIN_MODEL / WORKER_MODEL boundary

- `MAIN_MODEL` (ChatGPT) authors/maintains normative specifications, advisory same-directory `*-implementation-plan.md` companions, scenario oracles and task packet proposals. `WORKER_MODEL` (currently Aider) may implement only explicitly approved bounded tasks. The plan is advisory, not an approval grant.
- Source of truth: current source code/schema and tests for implemented behavior, selected active spec for intended changes, `docs/specs/STATE.json` for the Git-tracked developer checkpoint only, and repository docs for stable architecture.
- Read `docs/specs/README.md` and `tools/agent-pipeline/README.md`. `STATE.json` MUST NOT be edited during source-bound runs and cannot assert `RUNNING`/`ACCEPTED`. Human approval is never inferred from model output or JSON validity.
- Aider policy requires clean Git, bounded editable paths, isolated worktree, preflight and full secret/canonical checks, independent review, immutable evidence, and a developer acceptance checkpoint. Fail closed if prerequisites, ownership, rights, model/provider policies or evidence are uncertain.
- No worker may independently merge, change its approved scope, accept/archive a spec, disable tests, or send secrets or user data to a model. Provider use, review endpoints and code upload require explicit developer approval.

## Change and validation rules

1. Inspect existing code, contracts, local `AGENTS.md`, selected active spec and companion plan.
2. Identify file owners and the smallest authorized change; mark unresolved contracts `UNRESOLVED` and stop delegated work.
3. Define independent positive, negative, boundary and regression scenarios before worker modifications.
4. Implement with deterministic tests. Never weaken tests to obtain a passing result.
5. Run focused checks, then `make check` and, with Flutter installed, `./run_checks.sh`.
6. Update owning current-state docs, keep processing state at a safe checkpoint, and archive only after explicit developer acceptance.
7. Report changed/deleted files, tests genuinely run, unverified gates and a Git commit suggestion.

## Archive policy

Shareable archives unpack under `sibyl-flutter/` and MUST NOT include downloaded text, translations, production corpus/model assets, secrets, private user questions, caches, build outputs, Flutter `.dart_tool`, IDE state, Python virtualenvs or worker evidence. `archive.sh` builds `sibyl-flutter-FULL.zip`. Every generated patch/full handoff reports deleted paths explicitly.
