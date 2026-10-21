#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ "$(basename "$root")" != 'sibyl-flutter' ]]; then
  echo 'Expected repository folder name sibyl-flutter.' >&2
  exit 2
fi
required_source="sibyl_corpus_builder/build/api.py"
# Source-only archive; must not match a generic */build/* exclusion.
python3 "$root/tools/repository_snapshot.py" full "${1:-$(dirname "$root")/sibyl-flutter-FULL.zip}"
