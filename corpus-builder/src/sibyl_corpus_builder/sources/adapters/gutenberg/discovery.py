"""Project Gutenberg author-search discovery for candidate literary works.

Pipeline position:

    reviewed author search URL -> THIS MODULE -> SelectionManifest -> work catalog refresh

The adapter resolves one Gutenberg author search result, walks all author-result pages, and emits
candidate literary titles plus concrete ebook landing URLs. It excludes obvious correspondence,
memoirs, criticism, bibliography, and collected-edition containers; final work inclusion remains
human-reviewed in ``corpus-sources/catalog/works.yaml``.
"""

from collections.abc import Callable
from html.parser import HTMLParser
import re
from urllib.parse import urljoin, urlparse

from ...models import SelectionManifest, SelectionWork

_AUTHOR_PATH = re.compile(r"^/ebooks/author/(\d+)$")
_EBOOK_PATH = re.compile(r"^/ebooks/(\d+)$")
_DOWNLOAD_SUFFIX = re.compile(r"\s+\d[\d,]*\s+downloads?\s*$", re.I)
_NON_LITERARY = (
    "letters",
    "correspondence",
    "memoir",
    "autobiograph",
    "biograph",
    "diary",
    "journals",
    "criticism",
    "bibliograph",
    "life and letters",
    "essays and lectures",
    "complete works",
    "collected works",
    "works of ",
    "selected works",
)


class _LinkParser(HTMLParser):
    """Collects anchors while preferring Gutenberg's nested ``span.title`` label."""

    def __init__(self) -> None:
        super().__init__()
        self.links: list[tuple[str, str]] = []
        self._href: str | None = None
        self._text: list[str] = []
        self._title_depth = 0
        self._title_text: list[str] = []

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        attrs_dict = dict(attrs)
        if tag.lower() == "a":
            self._href = attrs_dict.get("href")
            self._text = []
            self._title_text = []
        if self._href is not None and tag.lower() == "span":
            classes = set((attrs_dict.get("class") or "").split())
            if "title" in classes:
                self._title_depth += 1

    def handle_endtag(self, tag: str) -> None:
        lower = tag.lower()
        if lower == "span" and self._title_depth:
            self._title_depth -= 1
        if lower == "a" and self._href is not None:
            label_parts = self._title_text or self._text
            label = " ".join(" ".join(label_parts).split())
            self.links.append((self._href, label))
            self._href = None
            self._text = []
            self._title_text = []
            self._title_depth = 0

    def handle_data(self, data: str) -> None:
        if self._href is None:
            return
        self._text.append(data)
        if self._title_depth:
            self._title_text.append(data)


def _parse_links(raw_html: bytes) -> list[tuple[str, str]]:
    parser = _LinkParser()
    parser.feed(raw_html.decode("utf-8", errors="replace"))
    return parser.links


def _normalized_name(value: str) -> str:
    return re.sub(r"[^a-z0-9]+", " ", value.casefold()).strip()


def _resolve_author_url(search_url: str, raw_html: bytes, author_name: str) -> str:
    candidates: list[tuple[int, str]] = []
    expected_tokens = set(_normalized_name(author_name).split())
    for href, label in _parse_links(raw_html):
        parsed = urlparse(urljoin(search_url, href))
        if not _AUTHOR_PATH.fullmatch(parsed.path):
            continue
        label_tokens = set(_normalized_name(label).split())
        score = len(expected_tokens.intersection(label_tokens))
        candidates.append((score, urljoin(search_url, href)))
    if not candidates:
        raise ValueError(f"No Project Gutenberg author result found for {author_name!r}")
    candidates.sort(key=lambda item: (-item[0], item[1]))
    return candidates[0][1]


def _clean_book_title(label: str, author_name: str) -> str:
    label = _DOWNLOAD_SUFFIX.sub("", label).strip()
    author_tokens = [part for part in re.split(r"\s+", author_name.strip()) if part]
    lowered = label.casefold()
    for token in sorted(author_tokens, key=len, reverse=True):
        position = lowered.rfind(token.casefold())
        if position > 0:
            prefix = label[:position].rstrip(" ,-—")
            if len(prefix) >= 2:
                return prefix
    return label


def _eligible_title(title: str) -> bool:
    normalized = title.casefold()
    return bool(title.strip()) and not any(marker in normalized for marker in _NON_LITERARY)


def _next_page_url(page_url: str, links: list[tuple[str, str]]) -> str | None:
    for href, label in links:
        if label.casefold().strip() == "next":
            return urljoin(page_url, href)
    return None


def discover_author_search(
    search_url: str,
    raw_search_html: bytes,
    *,
    author_id: str,
    author_name: str,
    language: str = "en",
    original_language: str | None = None,
    downloader: Callable[..., bytes],
) -> SelectionManifest:
    """Resolves a Gutenberg author search and returns literary ebook candidates from all pages."""
    author_url = _resolve_author_url(search_url, raw_search_html, author_name)
    page_url: str | None = author_url
    visited: set[str] = set()
    works_by_url: dict[str, SelectionWork] = {}

    while page_url is not None:
        if page_url in visited:
            raise ValueError(f"Project Gutenberg pagination loop detected at {page_url}")
        visited.add(page_url)
        links = _parse_links(downloader(page_url, accept="text/html"))
        for href, label in links:
            absolute = urljoin(page_url, href)
            if not _EBOOK_PATH.fullmatch(urlparse(absolute).path):
                continue
            title = _clean_book_title(label, author_name)
            if not _eligible_title(title):
                continue
            ebook_id = urlparse(absolute).path.rsplit("/", 1)[-1]
            works_by_url.setdefault(
                absolute,
                SelectionWork(
                    id=f"gutenberg-{author_id}-{ebook_id}",
                    title=title,
                    source_url=absolute,
                    decision="include",
                    reason="automatic: Project Gutenberg author bibliography candidate",
                ),
            )
        page_url = _next_page_url(page_url, links)

    if not works_by_url:
        raise ValueError(f"No literary Project Gutenberg works discovered for {author_name!r}")
    return SelectionManifest(
        source_family="project_gutenberg",
        source_url=author_url,
        author=author_name,
        language=language,
        original_language=original_language or language,
        category="literature",
        works=tuple(
            sorted(
                works_by_url.values(),
                key=lambda work: (work.title.casefold(), work.source_url),
            )
        ),
    )
