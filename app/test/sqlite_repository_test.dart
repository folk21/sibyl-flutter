import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sibyl/domain/models.dart';
import 'package:sibyl/retrieval/contracts.dart';
import 'package:sibyl/runtime/sqlite_corpus_repository.dart';

Database fixtureDb() {
  final db = sqlite3.openInMemory();
  db.execute('''
    CREATE TABLE author (id TEXT PRIMARY KEY, display_name TEXT NOT NULL);
    CREATE TABLE work (id TEXT PRIMARY KEY, author_id TEXT NOT NULL, title TEXT NOT NULL,
      original_language TEXT NOT NULL, category TEXT NOT NULL);
    CREATE TABLE passage (id TEXT PRIMARY KEY, work_id TEXT NOT NULL, source_locator TEXT,
      quality_score REAL);
    CREATE TABLE text_version (id TEXT PRIMARY KEY, language TEXT NOT NULL, role TEXT NOT NULL,
      translator TEXT, translation_provider TEXT, translation_model TEXT);
    CREATE TABLE passage_text (passage_id TEXT NOT NULL, text_version_id TEXT NOT NULL,
      variant TEXT NOT NULL, text TEXT NOT NULL);
    CREATE TABLE semantic_hint (id TEXT PRIMARY KEY, passage_id TEXT NOT NULL);
    CREATE TABLE guided_question (id TEXT PRIMARY KEY, catalog_id TEXT NOT NULL, ordinal INTEGER NOT NULL,
      text TEXT NOT NULL, kind TEXT, theme TEXT);
    CREATE TABLE guided_question_passage (question_id TEXT NOT NULL, passage_id TEXT NOT NULL,
      strength REAL NOT NULL);
  ''');
  db.execute("INSERT INTO author VALUES ('a', 'Exact Author')");
  db.execute("INSERT INTO work VALUES ('w', 'a', 'Original Work', 'en', 'literature')");
  db.execute("INSERT INTO passage VALUES ('p1', 'w', 'characters:1-30', NULL)");
  db.execute("INSERT INTO passage VALUES ('p2', 'w', 'characters:40-60', 0.8)");
  db.execute("INSERT INTO text_version VALUES ('v_original', 'en', 'original', NULL, NULL, NULL)");
  db.execute("INSERT INTO text_version VALUES ('v_mt', 'ru', 'machine_translation', NULL, 'fixture', 'fixture-v1')");
  db.execute("INSERT INTO passage_text VALUES ('p1', 'v_original', 'standard', 'Preserve  exact punctuation!')");
  db.execute("INSERT INTO passage_text VALUES ('p1', 'v_mt', 'standard', 'Сохранить  точную пунктуацию!')");
  db.execute("INSERT INTO passage_text VALUES ('p2', 'v_original', 'short', 'Second exact text')");
  db.execute("INSERT INTO semantic_hint VALUES ('h1', 'p1')");
  db.execute("INSERT INTO semantic_hint VALUES ('h2', 'p1')");
  db.execute("INSERT INTO guided_question VALUES ('q1', 'cat', 0, 'What to do?', 'question', 'hope')");
  db.execute("INSERT INTO guided_question VALUES ('q2', 'cat', 1, 'No mappings', 'question', 'hope')");
  db.execute("INSERT INTO guided_question_passage VALUES ('q1', 'p1', 0.7)");
  db.execute("INSERT INTO guided_question_passage VALUES ('q1', 'p2', 0.3)");
  return db;
}

void main() {
  test('guided v4 queries only mapped questions and preserves exact text/MT labels', () async {
    final db = fixtureDb();
    addTearDown(db.dispose);
    final repository = SqliteCorpusRepository(db, 4);
    expect((await repository.availableQuestions()).map((q) => q.id), ['q1']);
    final values = await repository.candidates('q1', 1);
    expect(values.length, 1);
    expect(values.single.passage.id, 'p1');
    expect(values.single.semanticScore, 0.7);
    expect(values.single.passage.variants[PassageLength.standard]!.parallelDisplayTexts()
      .map((text) => text.text), ['Preserve  exact punctuation!', 'Сохранить  точную пунктуацию!']);
    expect(values.single.passage.variants[PassageLength.standard]!.preferredText().role,
        PassageTextRole.machineTranslation);
  });

  test('hint duplicates resolve to one strongest passage and store exact text', () async {
    final db = fixtureDb();
    addTearDown(db.dispose);
    final repository = SqliteCorpusRepository(db, 4);
    final results = await repository.resolve([
      const VectorMatch('h1', 0.2), const VectorMatch('h2', 0.9),
    ]);
    expect(results.length, 1);
    expect(results.single.semanticScore, 0.9);
    expect(results.single.passage.variants[PassageLength.standard]!.texts.length, 2);
  });

  test('format-v3 guided access returns no mappings without table probing', () async {
    final db = fixtureDb();
    addTearDown(db.dispose);
    final repo = SqliteCorpusRepository(db, 3);
    db.execute('DROP TABLE guided_question_passage');
    db.execute('DROP TABLE guided_question');
    expect(await repo.availableQuestions(), isEmpty);
    expect(await repo.candidates('q1', 10), isEmpty);
  });

  test('unsupported format is rejected before querying', () {
    final db = fixtureDb();
    addTearDown(db.dispose);
    expect(() => SqliteCorpusRepository(db, 5), throwsUnsupportedError);
  });
}
