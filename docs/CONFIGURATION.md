# Configuration ownership

- `app/pubspec.yaml` — Flutter packages and Dart toolchain constraints.
- `SIBYL_CORPUS_DIR` — optional Flutter compile-time define (`--dart-define=SIBYL_CORPUS_DIR=/absolute/path`) for a published development corpus on desktop. Absent means demo; invalid explicit path fails closed. No network lookup occurs.
- `corpus-builder/config/*.toml` — reproducible build-time corpus/embedding options. `hash` is synthetic, `sentence_transformers` produces real E5 vectors.
- `corpus-format/` — persisted SQLite/manifest semantics (currently v4).
- `tools/agent-pipeline/pipeline-policy.json` — worker executable/version/model allowlists, independent reviewer, risk rules and verification gates. External credentials never belong in repository configuration.
- `docs/specs/STATE.json` — developer-maintained source-bound checkpoint, never an executable command/permission.

Never put real questions, secrets or downloaded corpus text in Git. Model and provider settings require an explicit approved integration decision.
