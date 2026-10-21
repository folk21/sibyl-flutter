# Quality gates

Routine Python checks: `make check`. Complete Flutter/agent local gate: `./run_checks.sh` (requires Flutter SDK and offline Python prerequisites). For code formatting use `dart format`; code analysis uses `flutter analyze`; Python style tooling is inherited from the corpus-builder Ruff configuration.

The development-agent policy separately requires a pinned Gitleaks scan of the whole isolated worker worktree (including untracked files), then canonical checks, then independent review. A test pass, Aider completion, or worker report is not acceptance. Human review and a separate explicit repository promotion are required. Never bypass a failed gate by skipping, deleting or weakening a test. Scanner matches and credentials must not be committed or sent to providers.
