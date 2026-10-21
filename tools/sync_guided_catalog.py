"""Keep the Flutter offline catalog identical to its corpus-curation source."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "corpus-curation/questions.json"
ASSET = ROOT / "app/assets/guided_questions.json"


def sync_catalog(source: Path, asset: Path, *, write: bool) -> None:
    canonical = source.read_bytes()
    catalog = json.loads(canonical)
    if catalog.get("schema_version") != 1 or not isinstance(catalog.get("items"), list):
        raise ValueError("Invalid canonical guided question catalog")
    ids = [item["id"] for item in catalog["items"]]
    if not ids or len(ids) != len(set(ids)):
        raise ValueError("Catalog has empty or duplicate question IDs")
    if write:
        asset.parent.mkdir(parents=True, exist_ok=True)
        asset.write_bytes(canonical)
    elif not asset.is_file() or asset.read_bytes() != canonical:
        raise ValueError("Flutter guided catalog differs from corpus-curation/questions.json; "
                         "run python3 tools/sync_guided_catalog.py --write")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--check", action="store_true")
    group.add_argument("--write", action="store_true")
    args = parser.parse_args()
    sync_catalog(SOURCE, ASSET, write=args.write)
    print("Guided catalog asset is synchronized with corpus-curation/questions.json")


if __name__ == "__main__":
    main()
