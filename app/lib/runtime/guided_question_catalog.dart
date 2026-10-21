import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/models.dart';

/// Loads the canonical question catalog independently of any SQLite corpus.
/// The packaged asset is a byte-for-byte mirror of corpus-curation/questions.json.
Future<List<GuidedQuestion>> loadGuidedQuestionCatalog() async {
  final source = await rootBundle.loadString('assets/guided_questions.json');
  return decodeGuidedQuestionCatalog(source);
}

/// Validates the packaged catalog before exposing stable guided-question IDs.
List<GuidedQuestion> decodeGuidedQuestionCatalog(String source) {
  final Object? raw = jsonDecode(source);
  if (raw is! Map<String, dynamic> || raw['schema_version'] != 1 ||
      raw['catalog_id'] is! String || raw['language'] is! String ||
      raw['items'] is! List) {
    throw const FormatException('Invalid guided question catalog header');
  }
  final questions = <GuidedQuestion>[];
  final ids = <String>{};
  for (final entry in raw['items'] as List) {
    if (entry is! Map<String, dynamic>) {
      throw const FormatException('Invalid guided question entry');
    }
    final id = entry['id'];
    final text = entry['text'];
    final theme = entry['theme'];
    final kind = entry['kind'];
    if (id is! String || id.trim().isEmpty ||
        text is! String || text.trim().isEmpty ||
        theme is! String || theme.trim().isEmpty ||
        (kind != 'question' && kind != 'state') || !ids.add(id)) {
      throw const FormatException('Invalid or duplicate guided question');
    }
    questions.add(GuidedQuestion(id: id, text: text, theme: theme, kind: kind as String));
  }
  if (questions.isEmpty) throw const FormatException('Guided question catalog is empty');
  return List.unmodifiable(questions);
}
