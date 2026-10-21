# Sibyl Flutter application

The Flutter UI and domain/selection/retrieval code live in `lib/`.

Run on Intel macOS from the repository root:

```bash
cd app
flutter create --project-name sibyl --platforms=macos,android,ios,windows,linux,web .
flutter pub get
flutter run -d macos
```

The first `flutter create` generates platform runner projects **on your workstation**. `./bootstrap.sh` also runs `dart format lib test` once, so inspect and commit the resulting source formatting together with the generated runners. It is required because these files are not included in this source-only handoff. Run it without `--overwrite` so existing Dart source is preserved. You may commit generated host projects to your own Git repository after inspecting them.

Tests: `flutter test`. Formatting: `dart format --output=none --set-exit-if-changed lib test`; analysis: `flutter analyze`.

Real format-v4 guided mode on desktop:

```bash
flutter run -d macos --dart-define=SIBYL_CORPUS_DIR=/absolute/path/to/corpus-builder/data/output
```

No `SIBYL_CORPUS_DIR` means the **complete catalog of 66 prepared questions/states is still visible** (searchable, grouped by theme), but literary answers are disabled. `Own question` offers a clearly marked synthetic UI demo. The catalog is bundled at `assets/guided_questions.json` as an exact copy of `../corpus-curation/questions.json`; run `python3 ../tools/sync_guided_catalog.py --write` from this directory after editing its canonical source, then `make validate-guided-catalog` from the repository root. SQLite supplies availability and stored passages, never the master UI catalog. Real `sentence_transformers`/E5 free-form query inference is **not implemented** in Dart; the app will not pretend that hash embeddings are equivalent. Free-form retrieval works only with explicitly synthetic `hash` corpora. The backend-free corpus builder remains in Python. See `../docs/INSTALLATION.md` and `../docs/USAGE.md`.
