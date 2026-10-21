# Sibyl development-agent pipeline (opt-in)

This directory ports the **SignalHarvester source-bound Aider orchestration controller** to Sibyl's independent Flutter/Python repository. The original controller is intentionally comprehensive (`agent_pipeline.py`) and its hermetic regression suite lives under `tests/`. The ported repository policy (`pipeline-policy.json`) replaces backend/Gradle ownership and checks with Flutter, corpus-format and `./run_checks.sh` gates. This is software-development automation, not the literary retrieval engine.

## Trust boundaries

- `MAIN_MODEL` (ChatGPT) authors the normative spec, advisory same-directory `*-implementation-plan.md` and independent test/oracle descriptions; the developer explicitly approves a bounded stage task packet before any model access.
- Aider `WORKER_MODEL` runs only inside an isolated source-bound worktree; protected paths and file digests are checked; worker cannot accept its changes, rewrite specifications, merge, or archive.
- Gitleaks scans the entire worker filesystem including untracked files before canonical checks. An independent fresh-context reviewer follows passing checks; developer/main-model approval is still required for promotion.
- `docs/specs/STATE.json` is a **developer checkpoint**, never a live execution lock or acceptance receipt. Private run-local evidence is stored in ignored `build/reports/agent-pipeline/` and isolated worktrees; do not copy it into shareable ZIPs.
- No automatic cross-stage execution, unconditional retries, automatic merge/checkout, or provider calls are authorized.

## Required prerequisites for LIVE execution

A clean real Git checkout on an approved `feature/*` branch; Python 3.11+; installed Flutter stable and Python corpus dependencies for canonical checks; compatible Git SHA-1 repository; independently installed exact supported versions **Aider 0.86.2** and **Gitleaks 8.30.1**; a developer-reviewed source exposure and external API/reviewer policy; safe Git identity and private evidence custody. The imported controller rejects unsupported tool versions and review authority gaps; do not bypass preflight to force a pilot.

Its current `pipeline-policy.json` retains the reference's explicitly approved model/provider defaults only as **configuration to review**, not a decision to upload Sibyl code. The developer must decide whether source is permitted to leave the workstation. No worker keys or corpus data belong in version control.

## Safe read-only inspection

```bash
python3 tools/specs/validate_state.py
python3 -m unittest discover -s tools/agent-pipeline/tests -p 'test_*.py'
python3 tools/agent-pipeline/agent_pipeline.py --help
```

`examples/sibyl-low-risk-stage-packet.json` is an **illustrative proposal**, not a signed approval or configured live stage. An active stage such as native E5 integration is HIGH-risk and cannot be delegated using the LOW-risk packet contract without discovery and a new explicit approval.

## When a LOW-risk pilot is actually approved

Use source-bound CLI commands `init-stage`, `prepare-worker`, `run-cycle`, `verify`, `summarize-subspec` and explicit developer-controlled `promote-stage`/`prepare-next-stage` as available in `agent_pipeline.py --help`. The standard shape is:

```bash
python3 tools/agent-pipeline/agent_pipeline.py init-stage --packet <reviewed-json-path> --run-id <unique-id>
python3 tools/agent-pipeline/agent_pipeline.py prepare-worker --run-id <unique-id>
python3 tools/agent-pipeline/agent_pipeline.py run-cycle --run-id <unique-id>
```

These are **not** setup instructions to execute without approval, because they can call paid providers and transmit code. Existing conservative source-bound invariants and negative-case tests are retained from SignalHarvester; the original detailed migration assumptions remain in `PORTING.md`. Separate fresh independent review, explicit developer acceptance and Git CAS are not optional.

Project-specific policy/authority: root `AGENTS.md`, `docs/AI_DEVELOPMENT.md`, `docs/specs/README.md` and current spec's advisory implementation plan. Do not treat SignalHarvester Java references in `PORTING.md` as Sibyl implementation context.
