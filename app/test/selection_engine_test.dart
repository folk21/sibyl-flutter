import 'package:flutter_test/flutter_test.dart';
import 'package:sibyl/domain/models.dart';
import 'package:sibyl/domain/selection_engine.dart';
import 'package:sibyl/retrieval/hash_embedding.dart';
import 'package:sibyl/retrieval/json_vector_index.dart';
import 'package:sibyl/retrieval/contracts.dart';
import 'package:sibyl/retrieval/local_retrieval.dart';

Candidate fixture(String id, double score, {PassageLength length = PassageLength.short}) => Candidate(
  passage: Passage(
    id: id, author: 'Test author', work: 'Test work', originalLanguage: 'en',
    variants: {
      length: PassageVariant(length: length, texts: [
        PassageText(language: 'en', role: PassageTextRole.original, text: 'exact $id'),
      ]),
    },
  ),
  semanticScore: score,
);

class FakeEmbedding implements EmbeddingEngine {
  @override
  Future<List<double>> embed(String text) async => [1, 0];
}

class FakeIndex implements VectorIndex {
  int requestedLimit = 0;
  @override
  Future<List<VectorMatch>> search(List<double> vector, int limit) async {
    requestedLimit = limit;
    return [const VectorMatch('h1', 0.8)];
  }
}

class FakeCorpus implements CorpusRepository {
  @override
  Future<List<Candidate>> resolve(List<VectorMatch> matches) async => [
    fixture('repeat', 0.8), fixture('repeat', 0.9), fixture('other', 0.7),
  ];
}

void main() {
  group('SelectionEngine KMP parity', () {
    test('filters irrelevant candidates', () {
      final answer = SelectionEngine(random: () => 0).select(
        question: 'q', candidates: [fixture('low', 0.1), fixture('high', 0.7)],
      );
      expect(answer?.passage.id, 'high');
    });
    test('rejects when all candidates are below threshold', () {
      expect(SelectionEngine(random: () => 0.5).select(
        question: 'q', candidates: [fixture('low', 0.01)],
      ), isNull);
    });
    test('deduplicates passages and preserves non-top-one choice', () {
      final answer = SelectionEngine(random: () => 0.99).select(
        question: 'q', candidates: [fixture('same', 0.8), fixture('same', 0.81), fixture('other', 0.79)],
      );
      expect(answer?.passage.id, 'other');
    });
    test('guided policy does not reject weak curated strength', () {
      final answer = SelectionEngine(random: () => 0.99).select(
        question: 'guided', candidates: [fixture('strong', 0.9), fixture('weak', 0.05)],
        policy: SelectionPolicy.guided,
      );
      expect(answer?.passage.id, 'weak');
    });
    test('recency does not permanently blacklist repeated passages', () {
      final engine = SelectionEngine(random: () => 0);
      final pool = [fixture('again', 0.9), fixture('other', 0.5)];
      expect(engine.select(question: 'q', candidates: pool)?.passage.id, 'again');
      expect(engine.select(question: 'q', candidates: pool)?.passage.id, 'again');
    });
    test('uses existing standard variant without truncation', () {
      final selected = SelectionEngine(random: () => 0).select(
        question: 'q', candidates: [fixture('exact', 0.9, length: PassageLength.standard)],
      );
      expect(selected?.variant.texts.single.text, 'exact exact');
    });
    test('zero-weight fallback does not require random sampling', () {
      final zero = Candidate(passage: fixture('first', 0.5).passage,
        semanticScore: 0.5, qualityScore: 0);
      expect(SelectionEngine(random: () => 0.99).select(
        question: 'q', candidates: [zero],
      )?.passage.id, 'first');
    });
    test('render choice is original plus preferred machine translation', () {
      final variant = PassageVariant(length: PassageLength.standard, texts: [
        const PassageText(language: 'en', role: PassageTextRole.original, text: 'Exact original'),
        const PassageText(language: 'ru', role: PassageTextRole.machineTranslation, text: 'Точный перевод'),
      ]);
      expect(variant.parallelDisplayTexts().map((text) => text.text).toList(),
        ['Exact original', 'Точный перевод']);
      expect(variant.parallelDisplayTexts().last.role, PassageTextRole.machineTranslation);
    });
    test('prefers human over machine text in the same language', () {
      final variant = PassageVariant(length: PassageLength.short, texts: [
        const PassageText(language: 'ru', role: PassageTextRole.machineTranslation, text: 'machine'),
        const PassageText(language: 'ru', role: PassageTextRole.humanTranslation, text: 'human'),
      ]);
      expect(variant.preferredText().text, 'human');
    });
  });

  test('free-form retrieval expands hint search and keeps strongest passage score', () async {
    final index = FakeIndex();
    final service = LocalRetrievalService(FakeEmbedding(), index, FakeCorpus());
    final values = await service.candidates('q', 2);
    expect(index.requestedLimit, 8);
    expect(values.map((value) => value.passage.id).toList(), ['repeat', 'other']);
    expect(values.first.semanticScore, 0.9);
  });

  test('Python SHA-256 hash development embeddings match fixed reference values', () async {
    final vector = await const HashEmbeddingEngine(dimensions: 4).embed('What now?');
    final reference = [-0.4357902497409623, -0.6363308956394582, -0.27381511266910025, -0.574626081516844];
    for (var i = 0; i < reference.length; i++) {
      expect(vector[i], closeTo(reference[i], 1e-8));
    }
  });

  test('vector index rejects incompatible query dimensions', () async {
    final index = JsonVectorIndex({'hint1': [1.0, 0.0], 'hint2': [0.0, 1.0]}, 2);
    expect((await index.search([1, 0], 2)).first.hintId, 'hint1');
    await expectLater(index.search([1], 2), throwsArgumentError);
  });
}
