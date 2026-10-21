# Academic source catalogs

`authors.yaml` is a human-reviewed seed list of major Russian and world-literature authors. The
initial candidates were assembled from broad philology/literary-history curriculum coverage and
established survey canons. Every author is commented out by default.

Uncomment a complete author block, then refresh work candidates from the repository root:

```bash
sibyl-corpus discover-works \
  --authors corpus-sources/catalog/authors.yaml \
  --output corpus-sources/catalog/works.yaml
```

The command tries the configured discovery sources independently, so one unavailable catalog does
not prevent fallback sources from being used. It filters obvious correspondence, memoirs,
criticism, bibliography, and collected-edition containers. All newly discovered works remain
commented in `works.yaml` for human review.

Uncommenting a complete work block accepts its proposed ID as the stable `work-id`. Later refreshes
preserve active work IDs and source URLs while adding newly discovered source candidates. The
future state-driven `advance` workflow consumes only uncommented work entries; it never invents
work identities itself.

These files are planning/review metadata, not source-rights approval. Concrete text versions still
require normal `corpus-sources/works/*.toml` provenance and rights review before publication.
