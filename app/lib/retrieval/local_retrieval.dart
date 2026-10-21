import '../domain/models.dart';
import 'contracts.dart';

/// Coordinates query embedding, widened hint retrieval and exact passage hydration.
class LocalRetrievalService implements RetrievalService {
  LocalRetrievalService(this.embedding, this.index, this.repository, {this.multiplier = 4}) {
    if (multiplier <= 0) throw ArgumentError.value(multiplier, 'multiplier');
  }

  final EmbeddingEngine embedding;
  final VectorIndex index;
  final CorpusRepository repository;
  final int multiplier;

  @override
  Future<List<Candidate>> candidates(String question, int limit) async {
    if (limit <= 0) throw ArgumentError.value(limit, 'limit');
    final matches = await index.search(await embedding.embed(question), limit * multiplier);
    final resolved = await repository.resolve(matches);
    final strongest = <String, Candidate>{};
    for (final candidate in resolved) {
      final previous = strongest[candidate.passage.id];
      if (previous == null || candidate.semanticScore > previous.semanticScore) {
        strongest[candidate.passage.id] = candidate;
      }
    }
    final values = strongest.values.toList()
      ..sort((a, b) => b.semanticScore.compareTo(a.semanticScore));
    return values.take(limit).toList();
  }
}

/// Guided mappings retain their curated strength and do not call query embedding.
class LocalGuidedRetrievalService implements GuidedRetrievalService {
  const LocalGuidedRetrievalService(this.repository);
  final GuidedCorpusRepository repository;

  @override
  Future<List<GuidedQuestion>> availableQuestions() => repository.availableQuestions();

  @override
  Future<List<Candidate>> candidates(String questionId, int limit) async {
    if (questionId.trim().isEmpty || limit <= 0) throw ArgumentError('Invalid guided request');
    final strongest = <String, Candidate>{};
    for (final candidate in await repository.candidates(questionId, limit)) {
      final previous = strongest[candidate.passage.id];
      if (previous == null || candidate.semanticScore > previous.semanticScore) {
        strongest[candidate.passage.id] = candidate;
      }
    }
    final values = strongest.values.toList()
      ..sort((a, b) {
        final score = b.semanticScore.compareTo(a.semanticScore);
        return score != 0 ? score : a.passage.id.compareTo(b.passage.id);
      });
    return values.take(limit).toList();
  }
}
