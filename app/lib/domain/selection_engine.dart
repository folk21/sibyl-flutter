import 'dart:math' as math;

import 'models.dart';

typedef RandomSource = double Function();

/// An injectable policy for relevance gating and controlled serendipity.
class SelectionPolicy {
  const SelectionPolicy({
    this.minSemanticScore = 0.20,
    this.semanticExponent = 1.5,
    this.preferredLength = PassageLength.short,
  });

  final double minSemanticScore;
  final double semanticExponent;
  final PassageLength preferredLength;

  static const defaults = SelectionPolicy();
  static const guided = SelectionPolicy(minSemanticScore: 0);
}

/// Chooses among eligible exact stored passages, never synthesizing literary text.
class SelectionEngine {
  SelectionEngine({RandomSource? random}) : _random = random ?? math.Random().nextDouble;

  final RandomSource _random;

  Answer? select({
    required String question,
    required List<Candidate> candidates,
    SelectionPolicy policy = SelectionPolicy.defaults,
  }) {
    final seen = <String>{};
    final eligible = candidates.where((candidate) =>
      candidate.semanticScore >= policy.minSemanticScore &&
      seen.add(candidate.passage.id)).toList();
    if (eligible.isEmpty) return null;

    final weights = eligible.map((candidate) {
      final value = math.pow(math.max(0, candidate.semanticScore), policy.semanticExponent).toDouble() *
          math.max(0, candidate.qualityScore) *
          math.max(0, candidate.historyWeight) *
          math.max(0, candidate.diversityWeight);
      return value.isFinite ? value : 0.0;
    }).toList();
    final total = weights.fold<double>(0, (total, weight) => total + weight);
    var selected = eligible.first;
    if (total > 0) {
      var cursor = _random().clamp(0.0, 0.999999999).toDouble() * total;
      selected = eligible.last;
      for (var i = 0; i < weights.length; i++) {
        cursor -= weights[i];
        if (cursor <= 0) {
          selected = eligible[i];
          break;
        }
      }
    }
    final variants = selected.passage.variants;
    final variant = variants[policy.preferredLength] ??
        variants[PassageLength.standard] ?? variants.values.first;
    return Answer(question: question, passage: selected.passage, variant: variant);
  }
}
