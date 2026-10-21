# Installation and visual testing

## MacBook Pro 2020 Intel (recommended first-run path)

Install the **macOS x64 / Intel** Flutter stable SDK from the [official Flutter macOS installation guide](https://docs.flutter.dev/get-started/install/macos/desktop); do not choose Apple Silicon (arm64). Install a compatible Xcode version from Apple and select its command-line tools:

```bash
xcode-select --install
sudo xcodebuild -license accept
flutter doctor -v
flutter config --enable-macos-desktop
```

`flutter doctor -v` reports whether the installed SDK, Xcode and CocoaPods match your macOS version. If iOS testing is needed, install an iOS Simulator runtime in Xcode and CocoaPods as Flutter Doctor instructs. Android Studio plus its Android SDK are **optional** for macOS-only visual testing.

Unzip into a fresh independent folder, for example `~/work/sibyl-flutter` (the ZIP already contains its `sibyl-flutter/` root). Do not nest the old KMP checkout inside this folder. Then:

```bash
cd ~/work/sibyl-flutter/app
flutter create --project-name sibyl --platforms=macos,android,ios,windows,linux,web .
flutter pub get
flutter devices
flutter run -d macos
```

For convenience `./bootstrap.sh` from `app/` performs the scaffold/pub-get/device-list steps and normalizes `lib/` and `test/` with `dart format`. Review and commit those initial formatting changes together with Sibyl-owned generated platform files. `flutter create` is a **one-time bootstrap** for platform hosts (`macos/`, `ios/`, `android/`, `web/`, `linux/`, `windows/`). Host runner files are not included in this source ZIP; Flutter generates them for the SDK installed on your machine. Do not use `--overwrite` or replace existing `lib/` / `test/`. The Dart sources do not depend on the local username/path. You may commit the generated host projects afterward.

The native macOS app opens immediately with all 66 bundled guided prompts visible without network, models or a production corpus. Searching/browsing those prompts needs no SQLite database; guided literary answers remain disabled until a compatible corpus is installed. `Own question` provides a clearly labelled synthetic demo. If no macOS device appears in `flutter devices`, resolve the findings from `flutter doctor -v` before continuing.

## Platforms and what can be exercised

| Host workstation | Target / visual command (from `app/`) | Current behavior |
|---|---|---|
| Intel or Apple Silicon macOS | `flutter run -d macos` | Native demo; opt-in existing SQLite corpus guided mode |
| macOS + Xcode simulator | `flutter run -d ios` | Demo; device or simulator provisioning may be needed |
| macOS/Windows/Linux + Android SDK | `flutter run -d android` or an actual `flutter devices` ID | Demo; native corpus asset installation not yet implemented |
| macOS/Windows/Linux with Chrome | `flutter run -d chrome` | Browser demo only, deliberately no native local-file SQLite |
| Windows with C++ desktop toolchain | `flutter run -d windows` | Native demo; opt-in SQLite guided mode via Dart define |
| Linux with GTK/CMake/clang toolchain | `flutter run -d linux` | Native demo; opt-in SQLite guided mode via Dart define |

For a real corpus on macOS, Windows or Linux desktop:

```bash
flutter run -d macos --dart-define=SIBYL_CORPUS_DIR=/absolute/path/to/your/output
```

On Linux/Windows substitute `-d linux` / `-d windows` and use a path native to the host. Guided mode needs format v4 with mapped questions. A format-v3 corpus has no guided mappings (the bundled UI catalog still appears), and the real E5 free-form adapter is pending, so it will not yield working literary search yet.

### macOS App Sandbox and a local corpus

Generated macOS runner projects commonly enable App Sandbox. A path that Terminal can read (such as `~/work/.../corpus-builder/data/output`) is **not automatically readable by a sandboxed app**. This is a macOS file-access boundary, not a reason to disable the sandbox for release builds. The `SIBYL_CORPUS_DIR` example above works only when that directory is accessible to the process.

For an Intel Mac development build, one option is to **copy a prepared, approved local corpus into the app's own sandbox container**, after generating the macOS runner and launching the app once:

```bash
cd app
# Read the actual identifier from the generated runner; do not assume a fixed ID.
grep PRODUCT_BUNDLE_IDENTIFIER macos/Runner/Configs/AppInfo.xcconfig
# Set this to the value from that file, for example com.example.sibyl.
APP_ID=com.example.sibyl
CORPUS_SOURCE="$(cd ../corpus-builder/data/output && pwd -P)"
SANDBOX_CORPUS="$HOME/Library/Containers/$APP_ID/Data/Library/Application Support/Sibyl/corpus"
mkdir -p "$SANDBOX_CORPUS"
rsync -a "$CORPUS_SOURCE/" "$SANDBOX_CORPUS/"
flutter run -d macos --dart-define="SIBYL_CORPUS_DIR=$SANDBOX_CORPUS"
```

Replace `APP_ID` with the **actual** bundle identifier before copying. The destination is for local development only; do not commit corpus contents or copies. If the generated runner has different signing/sandbox settings or macOS refuses this path, check the local app's entitlements and data-container path rather than granting broad filesystem access. This container-copy workflow has not been validated on the user's Mac. Production import/install behavior remains future work.

For iOS/Android production packaging, corpus/model installation, storage permissions, artifact integrity and ONNX support require follow-on specifications. The current UI demo does not depend on them.

## Python corpus tooling

From the repository root, use Python 3.11/3.12 for the existing corpus pipeline:

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -e ./corpus-core -e './corpus-builder[dev]'
make check
```

Opt-in real embedding work requires separately installed ML dependencies and a model bundle; see `corpus-builder/README.md` and `docs/WORKFLOW.md`. Neither is needed to test Flutter UI.

## Troubleshooting

- `flutter: command not found`: add the Intel Flutter SDK `bin` to your shell `PATH`, then restart the shell.
- `No supported devices`: run `flutter doctor -v`, enable the relevant desktop target, or start the simulator/emulator.
- macOS CocoaPods error: follow the current Flutter Doctor instructions for Xcode/CocoaPods, then rerun `flutter pub get`.
- `Cannot open local corpus`: verify `manifest.json`, `corpus.db` and relative manifest artifact names; no silent fallback to demo occurs for an explicitly configured invalid corpus.
- `Own question` unavailable for a real E5 corpus: expected current limitation, not an installation fault.

Always follow the [official Flutter desktop setup documentation](https://docs.flutter.dev/platform-integration/desktop) for the SDK version installed locally.
