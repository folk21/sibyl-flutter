from pathlib import Path

import yaml

from sibyl_corpus_builder.sources._internal import catalog as catalog_module
from sibyl_corpus_builder.sources.api import (
    discover_work_catalog,
    load_active_authors,
    load_active_works,
)
from sibyl_corpus_builder.sources.models import SelectionManifest, SelectionWork
from sibyl_corpus_builder.sources.adapters.gutenberg.discovery import discover_author_search


def test_author_catalog_loads_only_uncommented_entries(tmp_path: Path) -> None:
    path = tmp_path / "authors.yaml"
    path.write_text(
        """schema_version: 1
authors:
  # - id: disabled-author
  #   name: Disabled Author
  #   sources:
  #     - family: project_gutenberg
  #       url: https://www.gutenberg.org/ebooks/authors/search/?query=Disabled
  - id: active-author
    name: Active Author
    sources:
      - family: project_gutenberg
        url: https://www.gutenberg.org/ebooks/authors/search/?query=Active
        language: en
        original_language: en
""",
        encoding="utf-8",
    )

    authors = load_active_authors(path)

    assert [author.id for author in authors] == ["active-author"]
    assert authors[0].sources[0].family == "project_gutenberg"


def test_gutenberg_discovery_resolves_author_pages_filters_non_literary_and_paginates() -> None:
    search = b"""
    <html><body>
      <a href="/ebooks/author/65"><span class="title">Shakespeare, William</span></a>
    </body></html>
    """
    pages = {
        "https://www.gutenberg.org/ebooks/author/65": b"""
        <html><body>
          <a href="/ebooks/1513"><span class="title">Romeo and Juliet</span>
            <span>William Shakespeare</span></a>
          <a href="/ebooks/100">
            <span class="title">The Complete Works of William Shakespeare</span></a>
          <a href="?start_index=26">Next</a>
        </body></html>
        """,
        "https://www.gutenberg.org/ebooks/author/65?start_index=26": b"""
        <html><body>
          <a href="/ebooks/1524"><span class="title">Hamlet</span>
            <span>William Shakespeare</span></a>
          <a href="/ebooks/9999"><span class="title">The Letters of William Shakespeare</span></a>
        </body></html>
        """,
    }

    def download(url: str, **_kwargs) -> bytes:
        return pages[url]

    manifest = discover_author_search(
        "https://www.gutenberg.org/ebooks/authors/search/?query=William+Shakespeare",
        search,
        author_id="william-shakespeare",
        author_name="William Shakespeare",
        language="en",
        original_language="en",
        downloader=download,
    )

    assert [work.title for work in manifest.works] == ["Hamlet", "Romeo and Juliet"]
    assert {work.source_url for work in manifest.works} == {
        "https://www.gutenberg.org/ebooks/1513",
        "https://www.gutenberg.org/ebooks/1524",
    }


def test_discover_work_catalog_comments_new_candidates_and_preserves_active_work_ids(
    tmp_path: Path, monkeypatch
) -> None:
    authors = tmp_path / "authors.yaml"
    works = tmp_path / "works.yaml"
    authors.write_text(
        """schema_version: 1
authors:
  - id: leo-tolstoy
    name: Leo Tolstoy
    sources:
      - family: libru
        url: https://az.lib.ru/t/tolstoj_lew_nikolaewich/
        language: ru
        original_language: ru
""",
        encoding="utf-8",
    )

    def fake_discover_source(url: str, **_kwargs) -> SelectionManifest:
        assert url.startswith("https://az.lib.ru/")
        return SelectionManifest(
            source_family="libru",
            source_url=url,
            author="Толстой Лев Николаевич",
            language="ru",
            original_language="ru",
            category="literature",
            works=(
                SelectionWork(
                    id="source-war-and-peace",
                    title="Война и мир",
                    source_url="https://az.lib.ru/t/tolstoj_lew_nikolaewich/text_0040.shtml",
                    decision="include",
                    reason="automatic: literary category",
                    genres=("Проза",),
                ),
                SelectionWork(
                    id="source-letters",
                    title="Письма 1860",
                    source_url="https://az.lib.ru/t/tolstoj_lew_nikolaewich/letters.shtml",
                    decision="exclude",
                    reason="automatic: epistolary/correspondence",
                    genres=("Эпистолярий",),
                ),
            ),
        )

    monkeypatch.setattr(catalog_module, "discover_source", fake_discover_source)

    author_count, work_count = discover_work_catalog(authors, works)

    assert (author_count, work_count) == (1, 1)
    text = works.read_text(encoding="utf-8")
    assert "# - id: leo-tolstoy-voyna-i-mir" in text
    assert "Письма 1860" not in text
    assert load_active_works(works) == ()

    enabled = text.replace(
        "  # - id: leo-tolstoy-voyna-i-mir\n"
        "  #   author_id: leo-tolstoy\n"
        "  #   title: Война и мир\n"
        "  #   sources:\n"
        "  #   - family: libru\n"
        "  #     url: https://az.lib.ru/t/tolstoj_lew_nikolaewich/text_0040.shtml\n"
        "  #     language: ru\n"
        "  #     original_language: ru\n",
        "  - id: tolstoy-war-and-peace\n"
        "    author_id: leo-tolstoy\n"
        "    title: Война и мир\n"
        "    sources:\n"
        "    - family: libru\n"
        "      url: https://az.lib.ru/t/tolstoj_lew_nikolaewich/text_0040.shtml\n"
        "      language: ru\n"
        "      original_language: ru\n",
    )
    works.write_text(enabled, encoding="utf-8")
    assert load_active_works(works)[0].id == "tolstoy-war-and-peace"

    discover_work_catalog(authors, works)

    refreshed = yaml.safe_load(works.read_text(encoding="utf-8"))
    assert refreshed["works"][0]["id"] == "tolstoy-war-and-peace"


def test_repository_author_seed_is_large_and_fully_commented() -> None:
    repository_root = Path(__file__).resolve().parents[2]
    authors_path = repository_root / "corpus-sources" / "catalog" / "authors.yaml"
    text = authors_path.read_text(encoding="utf-8")

    assert text.count("  # - id:") >= 120
    assert "\n  - id:" not in text
    assert load_active_authors(authors_path) == ()
