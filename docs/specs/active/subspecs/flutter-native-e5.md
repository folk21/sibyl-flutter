---
document_role: subspec
spec_status: active
id: flutter-native-e5
feature_ids:
  - APP.RETRIEVAL
  - APP.EXTRACTIVE
---
# Native offline E5 query embedding for Flutter

**Status: active — design, not implemented, not delegated or accepted.**

## Context and objective

KMP Desktop supported local multilingual E5 with ONNX/runtime tokenizer; the Flutter port currently reads format-v4 guided mappings and supports only development hash vectors for free-form queries. This specification defines native **real** E5 retrieval parity without adding a backend, telemetry, runtime model downloads or weakening exact-text semantics. Current truth: `docs/MIGRATION.md`, `app/IMPLEMENTATION.md`, Python format-v4 manifest, runtime model metadata and current Dart retrieval interfaces.

Affected Feature IDs: `APP.RETRIEVAL`, `APP.EXTRACTIVE`. Owner: `app/lib/runtime`, using read-only public interfaces in `app/lib/retrieval`. Design/implementation risk is **HIGH** due to native FFI, model numerical semantics, packaging and platform lifecycle. No stage may be delegated autonomously until the developer approves native implementation approach and external binary/dependency choices.

## Implementation scope

- Expected editable paths (after approval): `app/lib/runtime/`, focused native tests in `app/test/`, `app/pubspec.yaml`, and owning `app/IMPLEMENTATION.md`; platform runner native targets only after platform-by-platform approval.
- Read-only context: `corpus-format/`, Python embedding config and runtime model bundle generation, `app/lib/domain`, selection/retrieval contracts, root/local `AGENTS.md`, active spec and companion plan.
- Forbidden: bypassing corpus manifest compatibility; runtime network inference; substitution of synthetic hash E5; changing source wording; unreviewed API keys/telemetry; rewriting format v4 as a shortcut.
- Unknown native runtime binary/license/distribution and tokenizer implementation compatibility remain `UNRESOLVED`. They need developer-led discovery and explicit approval before coding worker delegation.

## Normative requirements

**R-E5-01 (runtime compatibility)**: Given an explicit corpus and model bundle, the runtime MUST verify supported schema version, model ID, dimensions, normalization flag, `query_prefix`, tokenizer/ONNX artifacts, supported pooling and nonzero embeddings *before* offering free-form search. On mismatch or incomplete bundle it MUST fail closed with clear diagnostics and MUST NOT run hash/silent fallback.

**R-E5-02 (offline inference)**: The runtime MUST embed question text locally, tokenize and perform mean-pooling/normalization consistent with the approved E5 reference; it MUST NOT upload questions, store prompt logs, or download model assets during answering.

**R-E5-03 (retrieval and exact output)**: The adapter MUST implement existing `EmbeddingEngine`, preserving `LocalRetrievalService` candidate widening, hint-level cosine index, passage deduplication and injected controlled-random selection. Final text MUST come exclusively from stored `passage_text` versions; translations MUST be labelled.

**R-E5-04 (resources/platform)**: Native sessions MUST own and release model/tokenizer/SQLite resources reliably across normal exit, repeated app initialization and partial startup failures, with deterministic error surface. Initial target is Intel macOS x64; additional Android/iOS/Windows/Linux support requires explicit approval and platform evidence.

**R-E5-05 (verification)**: Before marking verified, use offline fixed-vector/tokenization parity fixtures independently generated from the reference runtime, positive/negative/boundary/regression cases and native Intel macOS integration testing. Default `flutter test` MUST remain network/model-download free; integration tests MAY require separately provisioned approved test bundles.

## Stages

### M1 — Design and approve native adapter choice

Identify feasible local ONNX runtime/tokenizer binding, binary distribution and licensing, architecture-specific requirements and failure-mode tests. Produce decision evidence without granting worker executable scope. **Current checkpoint** is DESIGN.

### M2 — Implement native x64 macOS E5 service

After developer approval of M1, implement the runtime behind `EmbeddingEngine`; update native setup and focused tests. Keep original format contracts unchanged.

### M3 — Verify full end-to-end real-corpus parity

Independently validate tokenizer/vector numerical parity, rejection of incompatible manifests and exact-source text integrity; report performance and resource ownership. Only after explicit acceptance update current docs and archive spec and companion.

## Acceptance

No stage is accepted by its own unit tests or model report. `MAIN_MODEL` reviews independent evidence; developer explicitly authorizes platform/dependency decisions, Git promotion and archival. Unresolved security, rights, checksum or platform compatibility blocks acceptance.
