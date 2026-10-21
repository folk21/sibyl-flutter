# Data Preparation Workflow

Status: Active

Sibyl corpus preparation is organized around stable work identities.

```
Source -> Canonical Text -> Curation -> Translation -> Runtime Corpus
```

Each work stores resumable state separately. The global index is used to discover incomplete work without rebuilding the whole corpus.

## Advance

Use:

```bash
sibyl-corpus advance --state-root corpus-builder/state
```

The command only inspects unfinished work states. Generated artifacts are not stored as workflow state.
