import 'package:sqlite3/sqlite3.dart';

import '../domain/models.dart';
import '../retrieval/contracts.dart';

/// Opens only format-v3/v4 published rows, preserving SQLite literary text verbatim.
/// The database lifecycle belongs to the RuntimeBundle, not the UI.
class SqliteCorpusRepository implements CorpusRepository, GuidedCorpusRepository {
  SqliteCorpusRepository(this.database, this.formatVersion) {
    if (formatVersion != 3 && formatVersion != 4) {
      throw UnsupportedError('Corpus format $formatVersion');
    }
  }

  final Database database;
  final int formatVersion;

  @override
  Future<List<GuidedQuestion>> availableQuestions() async {
    if (formatVersion < 4) return [];
    return database.select('''
      SELECT q.id, q.text, q.kind, q.theme
      FROM guided_question q
      WHERE EXISTS (
        SELECT 1 FROM guided_question_passage mapping WHERE mapping.question_id = q.id
      )
      ORDER BY q.catalog_id, q.ordinal, q.id
    ''').map((row) => GuidedQuestion(
      id: row['id'] as String,
      text: row['text'] as String,
      kind: row['kind'] as String?,
      theme: row['theme'] as String?,
    )).toList();
  }

  @override
  Future<List<Candidate>> candidates(String questionId, int limit) async {
    if (limit <= 0) throw ArgumentError.value(limit, 'limit');
    if (formatVersion < 4) return [];
    final rows = database.select('''
      WITH selected AS (
        SELECT passage_id, strength FROM guided_question_passage
        WHERE question_id = ? ORDER BY strength DESC, passage_id ASC LIMIT ?
      )
      ${_joinedPassages('selected', 'selected.passage_id', 'selected.strength')}
      ORDER BY selected.strength DESC, p.id, pt.variant, tv.id
    ''', [questionId, limit]);
    return _hydrate(rows, (row) => (row['guided_strength'] as num).toDouble());
  }

  @override
  Future<List<Candidate>> resolve(List<VectorMatch> matches) async {
    if (matches.isEmpty) return [];
    final scoreByHint = {for (final m in matches) m.hintId: m.score};
    final placeholders = List.filled(scoreByHint.length, '?').join(',');
    final rows = database.select('''
      ${_joinedPassages('semantic_hint sh', 'sh.passage_id', 'sh.id')}
      WHERE sh.id IN ($placeholders)
    ''', scoreByHint.keys.toList());
    return _hydrate(rows, (row) => scoreByHint[row['score_key']]!);
  }

  static String _joinedPassages(String base, String passageKey, String scoreKey) => '''
    SELECT $scoreKey AS score_key,
           ${base == 'selected' ? 'selected.strength AS guided_strength,' : ''}
           p.id AS passage_id, p.source_locator, p.quality_score,
           w.title AS work_title, w.original_language, w.category,
           a.display_name AS author_name,
           pt.variant, pt.text, tv.id AS text_version_id, tv.language, tv.role,
           tv.translator, tv.translation_provider, tv.translation_model
    FROM $base
    JOIN passage p ON p.id = $passageKey
    JOIN work w ON w.id = p.work_id
    JOIN author a ON a.id = w.author_id
    JOIN passage_text pt ON pt.passage_id = p.id
    JOIN text_version tv ON tv.id = pt.text_version_id
  ''';

  /// Maps one row per stored realization into one candidate per passage ID.
  static List<Candidate> _hydrate(ResultSet rows, double Function(Row) score) {
    final passages = <String, _HydratedPassage>{};
    for (final row in rows) {
      final id = row['passage_id'] as String;
      final value = score(row);
      final current = passages.putIfAbsent(id, () => _HydratedPassage(
        id: id,
        author: row['author_name'] as String,
        work: row['work_title'] as String,
        location: row['source_locator'] as String?,
        originalLanguage: row['original_language'] as String,
        category: _category(row['category'] as String),
        quality: (row['quality_score'] as num?)?.toDouble() ?? 1,
        score: value,
      ));
      if (value > current.score) current.score = value;
      final length = _length(row['variant'] as String);
      final texts = current.texts.putIfAbsent(length, () => {});
      texts.putIfAbsent(row['text_version_id'] as String, () => PassageText(
        text: row['text'] as String,
        language: row['language'] as String,
        role: _role(row['role'] as String),
        translator: row['translator'] as String?,
        translationProvider: row['translation_provider'] as String?,
        translationModel: row['translation_model'] as String?,
      ));
    }
    return passages.values.map((p) => Candidate(
      passage: Passage(
        id: p.id, author: p.author, work: p.work,
        originalLanguage: p.originalLanguage, location: p.location,
        category: p.category, variants: {
          for (final item in p.texts.entries)
            item.key: PassageVariant(length: item.key, texts: item.value.values.toList()),
        },
      ), semanticScore: p.score, qualityScore: p.quality,
    )).toList();
  }

  static PassageLength _length(String value) => switch (value) {
    'short' => PassageLength.short,
    'standard' => PassageLength.standard,
    'extended' => PassageLength.extended,
    _ => throw FormatException('Unknown passage length $value'),
  };
  static PassageTextRole _role(String value) => switch (value) {
    'original' => PassageTextRole.original,
    'human_translation' => PassageTextRole.humanTranslation,
    'machine_translation' => PassageTextRole.machineTranslation,
    _ => throw FormatException('Unknown text role $value'),
  };
  static WorkCategory _category(String value) => switch (value) {
    'literature' => WorkCategory.literature,
    'philosophy' => WorkCategory.philosophy,
    'sacred_text' => WorkCategory.sacredText,
    _ => throw FormatException('Unknown category $value'),
  };
}

class _HydratedPassage {
  _HydratedPassage({
    required this.id, required this.author, required this.work, required this.location,
    required this.originalLanguage, required this.category, required this.quality,
    required this.score,
  });
  final String id;
  final String author;
  final String work;
  final String? location;
  final String originalLanguage;
  final WorkCategory category;
  final double quality;
  double score;
  final Map<PassageLength, Map<String, PassageText>> texts = {};
}
