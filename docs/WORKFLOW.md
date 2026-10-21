# Sibyl operations workflow

## Preview visual behavior immediately

Bootstrap the Flutter platform hosts as described in `INSTALLATION.md`, then `cd app && flutter run -d macos` (Intel macOS recommended). The UI opens with clearly synthetic fixtures and demonstrates weighted selection, passage cards, save/history state and labels without models or network.

## Prepare and publish a real corpus

1. Register/review concrete source editions and rights in `corpus-sources/` or use existing approved records. Consult `SOURCES.md` and `corpus-builder/README.md` before acquiring external texts.
2. Use explicit builder commands (discover → review selection → acquire → prepare-selection) or the documented file-import preparation path. Prepared canonical directories live under ignored `corpus-builder/data/work/<name>/`.
3. Optionally export a build-time LLM curation bundle, validate external proposals against exact canonical SHA-256 locators and produce Git-safe curated mappings. Translation proposal text stays ignored local builder data with explicit `machine_translation` provenance.
4. Run `make build-runtime-corpus` to assemble a published v4 `corpus.db`, vector artifact and manifest from locally available prepared sources. It validates before atomic publication.
5. Run Flutter desktop with `--dart-define=SIBYL_CORPUS_DIR=/absolute/path/to/corpus-builder/data/output`. Current real functionality is curated guided-question lookup. E5 free-form native inference is the next separately specified milestone.

Do not commit downloaded sources, runtime models, generated translations or user questions. Full builder CLI syntax/rights overrides are owned by `corpus-builder/README.md` and `USAGE.md` for the migrated repository.

## Continue engineering with MAIN_MODEL and WORKER_MODEL

1. Read `docs/specs/STATE.json` (checkpoint) and selected normative active spec (current change intent).
2. `MAIN_MODEL` authors/updates the same-directory advisory `*-implementation-plan.md`, independent scenario expectations and a candidate bounded task packet.
3. Developer explicitly reviews scope, provider safety and risk; only then opt in to a source-bound Aider stage in a clean Git checkout.
4. Pipeline verifies immutable context, allowed edits, scanner, canonical checks and independent reviewer. Failed checks/unknown ownership stop delegation.
5. `MAIN_MODEL` and developer review evidence. Only the developer accepts and authorizes promotion/archival; `STATE.json` is updated only at a safe checkpoint between runs.

Detailed agent policy and command examples live in `AI_DEVELOPMENT.md` and `tools/agent-pipeline/README.md`.
