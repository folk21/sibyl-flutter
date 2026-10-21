#!/usr/bin/env python3
"""Build reproducible source-only FULL ZIPs and focused LLM text snapshots.

The Python builder's `build` feature is source code; only concrete generated
build directories are excluded. Never archive private corpus artifacts or evidence.
"""
from __future__ import annotations

import argparse
import os
import pathlib
import zipfile

ROOT = pathlib.Path(__file__).resolve().parents[1]
PROJECT = "sibyl-flutter"
EXCLUDED_DIRS = {
    ".git", ".idea", ".vscode", ".dart_tool", ".gradle", ".kotlin",
    ".pytest_cache", ".mypy_cache", ".ruff_cache", "__pycache__",
    ".cache", ".huggingface", ".torch", ".pub-cache", "Pods",
    "DerivedData", ".venv", "venv", "env", "node_modules",
}
EXCLUDED_PREFIXES = (
    "corpus-builder/data/", "corpus-builder/build/", "corpus-core/build/",
    "app/build/", "build/", "app/.flutter-plugins", "app/.pub-cache/",
    "app/android/.gradle/", "app/android/local.properties",
)
EXCLUDED_SUFFIXES = (".onnx", ".gguf", ".safetensors", ".usearch", ".pyc", ".zip", ".log", ".DS_Store")


def allowed(path: pathlib.Path, *, concat: bool = False) -> bool:
    relative = path.relative_to(ROOT).as_posix()
    parts = path.relative_to(ROOT).parts
    if any(part in EXCLUDED_DIRS or part.startswith(".venv") for part in parts):
        return False
    if relative.startswith(EXCLUDED_PREFIXES) or relative.endswith(EXCLUDED_SUFFIXES):
        return False
    if any(part.endswith(".egg-info") for part in parts):
        return False
    if any(part.startswith(".env") for part in parts):
        return False
    if concat and (relative == "docs/WORKLOG.md" or relative.startswith("docs/specs/archive/")):
        return False
    return path.is_file() and not path.is_symlink()


def source_files(*, concat: bool = False) -> list[pathlib.Path]:
    return sorted((path for path in ROOT.rglob("*") if allowed(path, concat=concat)),
                  key=lambda item: item.relative_to(ROOT).as_posix())


def ensure_included(files: list[pathlib.Path]) -> None:
    required_source = ROOT / "corpus-builder/src/sibyl_corpus_builder/build/api.py"
    if required_source not in files:
        raise SystemExit(f"Missing canonical Python build-feature source: {required_source}")
    for name in ("app/lib/main.dart", "docs/specs/STATE.json", "tools/agent-pipeline/agent_pipeline.py"):
        if ROOT / name not in files:
            raise SystemExit(f"Missing required repository source: {name}")


def write_full_zip(output: pathlib.Path) -> None:
    files = source_files()
    ensure_included(files)
    output.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(output, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=8) as archive:
        for path in files:
            relative = path.relative_to(ROOT)
            archive.write(path, arcname=f"{PROJECT}/{relative.as_posix()}")
    with zipfile.ZipFile(output) as archive:
        names = archive.namelist()
        if not names or any(not name.startswith(f"{PROJECT}/") for name in names):
            output.unlink(missing_ok=True)
            raise SystemExit("Invalid archive root")
    print(f"Created {output} ({len(files)} source files)")


def write_concat(output: pathlib.Path) -> None:
    permitted = {".kt", ".kts", ".dart", ".py", ".md", ".txt", ".toml", ".yaml",
                 ".yml", ".json", ".sh", ".sql", ".xml", ".properties", ".ini"}
    files = [path for path in source_files(concat=True)
             if path.suffix in permitted or path.name in {"Makefile", ".gitignore", "VERSION"}]
    ensure_included(files)
    with output.open("w", encoding="utf-8") as writer:
        for path in files:
            relative = path.relative_to(ROOT).as_posix()
            try:
                content = path.read_text(encoding="utf-8")
            except (OSError, UnicodeError):
                continue
            writer.write(f"\n=== FILE: {relative} ===\n{content}\n=== END FILE ===\n")
    print(f"Created {output}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("action", choices=["full", "concat"])
    parser.add_argument("output", type=pathlib.Path)
    args = parser.parse_args()
    if args.action == "full":
        write_full_zip(args.output.resolve())
    else:
        write_concat(args.output.resolve())


if __name__ == "__main__":
    main()
