import '../domain/models.dart';

class VectorMatch {
  const VectorMatch(this.hintId, this.score);
  final String hintId;
  final double score;
}

abstract interface class EmbeddingEngine {
  Future<List<double>> embed(String text);
}

abstract interface class VectorIndex {
  Future<List<VectorMatch>> search(List<double> vector, int limit);
}

abstract interface class CorpusRepository {
  Future<List<Candidate>> resolve(List<VectorMatch> matches);
}

abstract interface class RetrievalService {
  Future<List<Candidate>> candidates(String question, int limit);
}

abstract interface class GuidedCorpusRepository {
  Future<List<GuidedQuestion>> availableQuestions();
  Future<List<Candidate>> candidates(String questionId, int limit);
}

abstract interface class GuidedRetrievalService {
  Future<List<GuidedQuestion>> availableQuestions();
  Future<List<Candidate>> candidates(String questionId, int limit);
}
