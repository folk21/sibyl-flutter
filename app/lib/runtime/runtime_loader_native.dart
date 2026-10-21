import 'dart:convert';
import 'dart:io';
import 'package:sqlite3/sqlite3.dart';

import '../retrieval/contracts.dart';
import '../retrieval/hash_embedding.dart';
import '../retrieval/json_vector_index.dart';
import '../retrieval/local_retrieval.dart';
import 'sqlite_corpus_repository.dart';

class RuntimeBundle {
  const RuntimeBundle({required this.label, required this.guided, this.freeform, this.close});
  final String label;
  final GuidedRetrievalService? guided;
  final RetrievalService? freeform;
  final void Function()? close;
}

/// Runtime corpus is opt-in; no model or source download occurs on app launch.
/// Only hash fixtures support free-form embedding until a reviewed E5/ONNX adapter is shipped.
Future<RuntimeBundle?> loadRuntimeFromEnvironment() async {
  const corpusDir = String.fromEnvironment('SIBYL_CORPUS_DIR');
  if (corpusDir.isEmpty) return null;
  final manifest = jsonDecode(await File('$corpusDir/manifest.json').readAsString()) as Map<String, dynamic>;
  final version = manifest['format_version'] as int;
  if (version != 3 && version != 4) throw UnsupportedError('Unsupported format $version');
  final artifacts = manifest['artifacts'] as Map<String, dynamic>;
  final embedding = manifest['embedding'] as Map<String, dynamic>;
  final dimensions = embedding['dimensions'] as int;
  if (dimensions <= 0) throw FormatException('Embedding dimensions must be positive');
  String resolveArtifact(String field) {
    final name = artifacts[field] as String;
    if (name.isEmpty || name.startsWith('/') || name.contains('..') || name.contains('\\')) {
      throw FormatException('Unsafe artifact path for $field');
    }
    return '$corpusDir/$name';
  }
  final db = sqlite3.open(resolveArtifact('corpus'), mode: OpenMode.readOnly);
  try {
    final metadata = db.select("SELECT value FROM metadata WHERE key = 'format_version'");
    if (metadata.isEmpty || int.parse(metadata.single['value'] as String) != version) {
      throw FormatException('SQLite and manifest format versions do not match');
    }
    final repository = SqliteCorpusRepository(db, version);
    RetrievalService? freeform;
    if (embedding['provider'] == 'hash') {
      final raw = jsonDecode(await File(resolveArtifact('vectors')).readAsString()) as Map<String, dynamic>;
      freeform = LocalRetrievalService(
        HashEmbeddingEngine(dimensions: dimensions, normalize: embedding['normalize'] as bool),
        JsonVectorIndex(raw, dimensions), repository,
      );
    }
    final counts = manifest['counts'] as Map<String, dynamic>;
    final countLabel = '${counts['works']} works · ${counts['passages']} passages';
    return RuntimeBundle(
      label: '$countLabel · local corpus v$version · '
          '${freeform == null ? 'guided-only (E5 pending)' : 'synthetic hash search'}',
      guided: version >= 4 ? LocalGuidedRetrievalService(repository) : null,
      freeform: freeform,
      close: db.dispose,
    );
  } catch (_) {
    db.dispose();
    rethrow;
  }
}
