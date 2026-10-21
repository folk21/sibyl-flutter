#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
if ! command -v flutter >/dev/null 2>&1; then
  echo 'Flutter SDK is required. Install the Intel macOS Flutter SDK; see ../docs/INSTALLATION.md.' >&2
  exit 1
fi
flutter create --project-name sibyl --platforms=macos,android,ios,windows,linux,web .
flutter pub get
dart format lib test
flutter devices
