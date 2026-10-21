"""Public source-ingestion API.

This is the feature boundary for academic author/work planning plus everything from external
catalogs/artifacts to the prepared canonical source set consumed by automatic build and curation:

    enable authors -> discover work candidates -> review works
    discover concrete source -> review -> acquire/import -> normalize/cache -> prepare/register

Callers should use this module instead of importing ``sources._internal`` or concrete adapters.
"""

from ._internal.acquisition import acquire_selection, fetch_registry_source, import_registry_source
from ._internal.catalog import discover_work_catalog, load_active_authors, load_active_works
from ._internal.discovery import discover_to_file
from ._internal.preparation import prepare_registry_sources, prepare_selection_sources
from ._internal.registration import register_selection
from ._internal.reports import AcquisitionReport
from ._internal.selection import load_selection, write_selection
from .models import (
    AuthorCatalogEntry,
    AuthorCatalogSource,
    SelectionManifest,
    SelectionWork,
    WorkCatalogEntry,
    WorkCatalogSource,
)

__all__ = [
    "AcquisitionReport",
    "AuthorCatalogEntry",
    "AuthorCatalogSource",
    "SelectionManifest",
    "SelectionWork",
    "WorkCatalogEntry",
    "WorkCatalogSource",
    "acquire_selection",
    "discover_to_file",
    "discover_work_catalog",
    "fetch_registry_source",
    "import_registry_source",
    "load_active_authors",
    "load_active_works",
    "load_selection",
    "prepare_registry_sources",
    "prepare_selection_sources",
    "register_selection",
    "write_selection",
]
