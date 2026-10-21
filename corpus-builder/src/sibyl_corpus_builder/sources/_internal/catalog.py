"""Human-reviewed author/work catalog loading and deterministic work-candidate refresh.

The author catalog is a Git-tracked academic seed list whose entries are disabled by comments.
Only uncommented authors are discovered. The generated work catalog follows the same convention:
new candidates are commented by default, while previously uncommented works stay active and keep
their accepted stable IDs across refreshes.
"""

import hashlib
from pathlib import Path
import re
import unicodedata
from urllib.parse import urlparse

import yaml

from ..models import AuthorCatalogEntry, AuthorCatalogSource, WorkCatalogEntry, WorkCatalogSource
from .adapters import discover_source

_NON_LITERARY_GENRES = {
    "публицистика",
    "критика",
    "мемуары",
    "философия",
    "религия",
    "переводы",
    "эпистолярий",
}
_CYRILLIC = str.maketrans(
    {
        "а": "a", "б": "b", "в": "v", "г": "g", "д": "d", "е": "e", "ё": "e",
        "ж": "zh", "з": "z", "и": "i", "й": "y", "к": "k", "л": "l", "м": "m",
        "н": "n", "о": "o", "п": "p", "р": "r", "с": "s", "т": "t", "у": "u",
        "ф": "f", "х": "kh", "ц": "ts", "ч": "ch", "ш": "sh", "щ": "shch",
        "ъ": "", "ы": "y", "ь": "", "э": "e", "ю": "yu", "я": "ya",
    }
)


def _load_yaml(path: Path) -> dict:
    if not path.is_file():
        raise ValueError(f"Catalog file does not exist: {path}")
    payload = yaml.safe_load(path.read_text(encoding="utf-8")) or {}
    if not isinstance(payload, dict):
        raise ValueError(f"Catalog root must be a mapping: {path}")
    if int(payload.get("schema_version", 0)) != 1:
        raise ValueError(f"Catalog schema_version must be 1: {path}")
    return payload


def load_active_authors(path: Path) -> tuple[AuthorCatalogEntry, ...]:
    """Loads only uncommented author entries from the human-reviewed seed catalog."""
    payload = _load_yaml(path)
    raw_authors = payload.get("authors") or []
    if not isinstance(raw_authors, list):
        raise ValueError("authors must be a YAML list when entries are enabled")
    authors: list[AuthorCatalogEntry] = []
    seen_ids: set[str] = set()
    for raw in raw_authors:
        if not isinstance(raw, dict):
            raise ValueError("Each enabled author must be a mapping")
        author_id = str(raw.get("id", "")).strip()
        name = str(raw.get("name", "")).strip()
        if not author_id or not name:
            raise ValueError("Enabled authors require id and name")
        if author_id in seen_ids:
            raise ValueError(f"Duplicate enabled author id: {author_id}")
        seen_ids.add(author_id)
        raw_sources = raw.get("sources") or []
        if not isinstance(raw_sources, list) or not raw_sources:
            raise ValueError(f"Enabled author {author_id} requires at least one discovery source")
        sources: list[AuthorCatalogSource] = []
        for source in raw_sources:
            if not isinstance(source, dict):
                raise ValueError(f"Author {author_id} source must be a mapping")
            family = str(source.get("family", "")).strip()
            url = str(source.get("url", "")).strip()
            if family not in {"libru", "project_gutenberg"}:
                raise ValueError(f"Unsupported author discovery source family: {family!r}")
            if urlparse(url).scheme not in {"http", "https"}:
                raise ValueError(f"Author discovery URL must be http(s): {url}")
            sources.append(
                AuthorCatalogSource(
                    family=family,
                    url=url,
                    language=str(source.get("language", "")).strip() or None,
                    original_language=str(source.get("original_language", "")).strip() or None,
                )
            )
        authors.append(AuthorCatalogEntry(id=author_id, name=name, sources=tuple(sources)))
    return tuple(authors)


def load_active_works(path: Path) -> tuple[WorkCatalogEntry, ...]:
    """Loads only uncommented work entries; these IDs are the reviewed stable work identities."""
    payload = _load_yaml(path)
    raw_works = payload.get("works") or []
    if not isinstance(raw_works, list):
        raise ValueError("works must be a YAML list when entries are enabled")
    works: list[WorkCatalogEntry] = []
    seen_ids: set[str] = set()
    for raw in raw_works:
        if not isinstance(raw, dict):
            raise ValueError("Each enabled work must be a mapping")
        work_id = str(raw.get("id", "")).strip()
        author_id = str(raw.get("author_id", "")).strip()
        title = str(raw.get("title", "")).strip()
        if not work_id or not author_id or not title:
            raise ValueError("Enabled works require id, author_id, and title")
        if work_id in seen_ids:
            raise ValueError(f"Duplicate enabled work id: {work_id}")
        seen_ids.add(work_id)
        sources = tuple(_parse_work_source(work_id, value) for value in (raw.get("sources") or []))
        if not sources:
            raise ValueError(f"Enabled work {work_id} requires at least one source URL")
        works.append(
            WorkCatalogEntry(
                id=work_id,
                author_id=author_id,
                title=title,
                sources=sources,
            )
        )
    return tuple(works)


def _parse_work_source(work_id: str, raw: object) -> WorkCatalogSource:
    if not isinstance(raw, dict):
        raise ValueError(f"Work {work_id} source must be a mapping")
    family = str(raw.get("family", "")).strip()
    url = str(raw.get("url", "")).strip()
    if not family or urlparse(url).scheme not in {"http", "https"}:
        raise ValueError(f"Work {work_id} has invalid source: {raw!r}")
    return WorkCatalogSource(
        family=family,
        url=url,
        language=str(raw.get("language", "")).strip() or None,
        original_language=str(raw.get("original_language", "")).strip() or None,
    )


def _title_key(value: str) -> str:
    return re.sub(r"\W+", " ", value.casefold(), flags=re.UNICODE).strip()


def _slug(value: str) -> str:
    transliterated = value.casefold().translate(_CYRILLIC)
    ascii_value = unicodedata.normalize("NFKD", transliterated).encode("ascii", "ignore").decode()
    slug = re.sub(r"[^a-z0-9]+", "-", ascii_value).strip("-")
    if slug:
        return slug[:80].rstrip("-")
    return "work-" + hashlib.sha256(value.encode("utf-8")).hexdigest()[:12]


def _candidate_id(author_id: str, title: str, occupied: set[str]) -> str:
    base = f"{author_id}-{_slug(title)}"
    candidate = base
    counter = 2
    while candidate in occupied:
        candidate = f"{base}-{counter}"
        counter += 1
    occupied.add(candidate)
    return candidate


def _is_catalog_candidate(work) -> bool:
    if work.decision == "exclude":
        return False
    genres = {genre.casefold() for genre in work.genres}
    return not genres.intersection(_NON_LITERARY_GENRES)


def _merge_sources(
    existing: tuple[WorkCatalogSource, ...],
    additions: list[WorkCatalogSource],
) -> tuple[WorkCatalogSource, ...]:
    by_identity = {(source.family, source.url): source for source in existing}
    for source in additions:
        by_identity.setdefault((source.family, source.url), source)
    return tuple(sorted(by_identity.values(), key=lambda source: (source.family, source.url)))


def discover_work_catalog(authors_path: Path, output_path: Path) -> tuple[int, int]:
    """Refreshes candidate works for enabled authors while preserving enabled work selections."""
    authors = load_active_authors(authors_path)
    active_works = load_active_works(output_path) if output_path.exists() else ()
    active_by_key = {(work.author_id, _title_key(work.title)): work for work in active_works}
    active_ids = {work.id for work in active_works}

    discovered: dict[tuple[str, str], tuple[str, list[WorkCatalogSource]]] = {}
    for author in authors:
        successful_sources = 0
        failures: list[str] = []
        for source in author.sources:
            try:
                manifest = discover_source(
                    source.url,
                    language=source.language,
                    original_language=source.original_language,
                    author_id=author.id,
                    author_name=author.name,
                    source_family=source.family,
                )
            except (OSError, ValueError) as error:
                failures.append(f"{source.family}: {error}")
                continue
            successful_sources += 1
            for work in manifest.works:
                if not _is_catalog_candidate(work):
                    continue
                key = (author.id, _title_key(work.title))
                if not key[1]:
                    continue
                entry = discovered.setdefault(key, (work.title, []))
                entry[1].append(
                    WorkCatalogSource(
                        family=manifest.source_family,
                        url=work.source_url,
                        language=manifest.language,
                        original_language=manifest.original_language,
                    )
                )
        if successful_sources == 0:
            details = "; ".join(failures) or "no discovery sources configured"
            print(f"WARNING: no source succeeded for {author.id}: {details}")
        elif failures:
            print(f"WARNING: some sources failed for {author.id}: {'; '.join(failures)}")

    occupied = set(active_ids)
    candidates: list[tuple[WorkCatalogEntry, bool]] = []
    all_keys = set(discovered) | set(active_by_key)
    for key in sorted(all_keys, key=lambda item: (item[0], item[1])):
        active = active_by_key.get(key)
        discovered_title, new_sources = discovered.get(
            key,
            (active.title if active else key[1], []),
        )
        if active is not None:
            entry = WorkCatalogEntry(
                id=active.id,
                author_id=active.author_id,
                title=active.title,
                sources=_merge_sources(active.sources, new_sources),
            )
            candidates.append((entry, True))
        else:
            entry = WorkCatalogEntry(
                id=_candidate_id(key[0], discovered_title, occupied),
                author_id=key[0],
                title=discovered_title,
                sources=_merge_sources((), new_sources),
            )
            candidates.append((entry, False))

    _write_work_catalog(output_path, authors_path=authors_path, candidates=candidates)
    return len(authors), len(candidates)


def _entry_payload(entry: WorkCatalogEntry) -> dict:
    sources: list[dict[str, str]] = []
    for source in entry.sources:
        payload = {"family": source.family, "url": source.url}
        if source.language is not None:
            payload["language"] = source.language
        if source.original_language is not None:
            payload["original_language"] = source.original_language
        sources.append(payload)
    return {
        "id": entry.id,
        "author_id": entry.author_id,
        "title": entry.title,
        "sources": sources,
    }


def _yaml_lines(payload: dict) -> list[str]:
    return yaml.safe_dump(
        payload,
        allow_unicode=True,
        sort_keys=False,
        default_flow_style=False,
    ).rstrip().splitlines()


def _write_work_catalog(
    path: Path,
    *,
    authors_path: Path,
    candidates: list[tuple[WorkCatalogEntry, bool]],
) -> None:
    lines = [
        "# Candidate literary work catalog generated from enabled authors.",
        "# Uncomment a complete work block to accept its id as a stable work identity.",
        "# Re-running discover-works preserves uncommented works and their accepted IDs.",
        "# Obvious letters, correspondence, memoirs, criticism, and collected-edition containers",
        "# are filtered during discovery; all remaining new candidates stay commented for review.",
        "schema_version: 1",
        f"generated_from: {authors_path.as_posix()}",
        "works:",
    ]
    for entry, active in candidates:
        block = yaml.safe_dump(
            [_entry_payload(entry)],
            allow_unicode=True,
            sort_keys=False,
            default_flow_style=False,
        ).rstrip().splitlines()
        for line in block:
            rendered = "  " + line
            lines.append(rendered if active else "  # " + line)
        lines.append("")
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")
