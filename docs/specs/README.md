# Change specifications and processing state

## Source of truth

- `docs/FEATURES.md`: stable capability/Feature IDs, independent of a particular spec.
- `docs/specs/active/subspecs/<name>.md`: **normative** behavior/requirements and explicit implementation impact for significant unfinished work.
- `docs/specs/active/subspecs/<name>-implementation-plan.md`: detailed **advisory** stage blueprint authored by `MAIN_MODEL`; it is not another spec and cannot approve worker edits.
- `docs/specs/STATE.json`: **only Git-tracked developer-maintained processing checkpoint**. Strict v1 schema in `state.schema.json`, validated by `python3 tools/specs/validate_state.py`.
- `tools/agent-pipeline/` private evidence: current source-bound worker run status/digests/logs. Never infer live runtime status from a README, umbrella, frontmatter or checkpoint.
- `docs/specs/archive/`: historical accepted design and old KMP migration specs, not current Flutter requirements.

## State contract

`STATE.json` intentionally has `schemaVersion: 1`, `mode: SINGLE`, one `selectedWorkstreamId`, an array of unique workstreams and per-record `id`, `specPath`, `stageId`, `phase`, `runId`, `developerDecision`.

Allowed checkpoint phases: `DESIGN`, `READY_TO_DELEGATE`, `READY_FOR_REVIEW`, `BLOCKED`, `PAUSED`, `AWAITING_DEVELOPER_DECISION`. `RUNNING` and `ACCEPTED` are forbidden; only `UNRECORDED`/`REJECTED` developer decisions appear. `READY_FOR_REVIEW` and `AWAITING_DEVELOPER_DECISION` require a known `runId`. `SINGLE` permits only one progressing selected workstream; others may only be PAUSED/BLOCKED. A selected ID is informational, **not** a scheduler lock.

Update the checkpoint **only between** source-bound runs, at a developer-controlled clean Git checkpoint. Do not write it from an active worker, infer successful acceptance from a model/review status, or create a second processing-state file. Missing/invalid/stale state must be reported and blocks delegation. A future concurrent `MULTI` mode requires a new normative spec and ownership/CAS tests.

## Spec lifecycle and staged plans

1. For a substantial change, identify existing Feature IDs and create a bounded normative sub-spec under `active/subspecs/`, `spec_status: active` at document start, with owner, MUST/MUST NOT, observable outcome, failure semantics and evidence for each requirement. Unknown ownership is `UNRESOLVED` and stops autonomous work.
2. Record known implementation scope: editable owning paths, read-only interfaces/contracts, affected features, dependencies, risk, tests and stage order. Distinguish discovery stages from bounded/known stages; an architecture-level change requires developer approval.
3. `MAIN_MODEL` creates an adjacent `<stem>-implementation-plan.md` with concrete file-by-file architecture, algorithms, alternatives, dependencies, and independent **positive/negative/boundary/regression/adversarial** scenario IDs, inputs, outcomes and exact checks. Mark changes as expected/candidate/to-be-discovered and every code example illustrative unless copied from authoritative source.
4. Developer reviews the normative spec, advisory plan, risk, privacy and bounded task packet. Packet scope does not grant human approval merely through JSON validity. Worker records material departures, never rewrites the normative spec to suit an implementation.
5. Required scanner/checks/review and explicit developer acceptance precede implementation being treated as current state. Move stable knowledge into owning docs, then **move** completed normative spec and companion to `archive/`. Never duplicate active/archive copies.

A staged plan is not executable worker instructions; the controller builds a separately approved task packet with exact source-bound context and permitted paths. See `../AI_DEVELOPMENT.md` and `../../tools/agent-pipeline/README.md`.

## Current work

Read `STATE.json`; the Flutter E5 adapter sub-spec is in `active/subspecs/flutter-native-e5.md` with its advisory implementation plan. No live worker execution or developer acceptance is implied by the initial `DESIGN` checkpoint.
