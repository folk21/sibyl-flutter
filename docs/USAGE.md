# Usage and commands

Run from the repository root unless `cd app` is shown.

## Flutter UI

From the repository root, `make bootstrap-flutter` generates Sibyl-owned platform runners, then `make run-macos` or `make run-web` opens a labelled synthetic UI preview. The equivalent direct Flutter commands are below.

```bash
cd app
flutter create --project-name sibyl --platforms=macos,android,ios,windows,linux,web .
flutter pub get
flutter run -d macos
flutter run -d chrome
flutter test
flutter analyze
```

With no corpus installed, the `Guided questions` tab lists all 66 prompts from the bundled canonical catalog, organized by theme and searchable. Selecting a prompt is always allowed, but `Find passage` stays disabled until a matching SQLite guided mapping exists. `Own question` remains the explicitly synthetic demo without a real E5 adapter. After modifying `corpus-curation/questions.json`, run `python3 tools/sync_guided_catalog.py --write` and `make validate-guided-catalog` from the repository root. The native runtime never reads the source repository at app startup.

On macOS, native desktop UI is the fastest test loop. Other supported targets are listed in `INSTALLATION.md`. `flutter create` is a one-time bootstrap; repeat it only intentionally, without `--overwrite`.

Real corpus on desktop:

```bash
flutter run -d macos --dart-define=SIBYL_CORPUS_DIR=/absolute/path/to/output
```

This path must contain a supported format-v3/v4 manifest and SQLite artifact. Format v4 guided mappings work without query embeddings. E5 free-form inference is pending and is visibly unavailable; synthetic `hash` corpora support exact-format testing of retrieval, not semantic relevance.

## Python corpus workflow

```bash
make check
make smoke-corpus
make build-runtime-corpus
make download-runtime-model
```

`build-runtime-corpus` requires already prepared local inputs and may execute the configured local sentence-transformer embedding pipeline. It discovers all prepared author directories, compatible curated metadata, and validated machine translations; see `corpus-builder/README.md` and `WORKFLOW.md`. `download-runtime-model` is kept for compatibility and future Flutter E5 adapter testing; the current Flutter runtime does **not** consume its ONNX/tokenizer bundle yet.

## Agent-assisted development (opt-in, NOT automatic)

```bash
python3 tools/specs/validate_state.py
python3 -m unittest discover -s tools/agent-pipeline/tests -p 'test_*.py'
python3 tools/agent-pipeline/agent_pipeline.py --help
```

Read `AI_DEVELOPMENT.md` before initializing a worker stage. Do not use example packet files as self-executing approval. Aider and Gitleaks are optional externally installed developer tools; they are never called during normal Flutter startup or `make check`.
