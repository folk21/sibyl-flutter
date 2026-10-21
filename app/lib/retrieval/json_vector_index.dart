import 'dart:math' as math;
import 'contracts.dart';

/// Exhaustive cosine search intended for small local development corpora.
class JsonVectorIndex implements VectorIndex {
  JsonVectorIndex(Map<String, dynamic> raw, this.dimensions)
    : entries = raw.entries.map((entry) {
        final values = (entry.value as List).map((v) => (v as num).toDouble()).toList();
        if (values.length != dimensions || _norm(values) == 0) {
          throw FormatException('Invalid vector ${entry.key}');
        }
        return (id: entry.key, values: values, norm: _norm(values));
      }).toList();

  final int dimensions;
  final List<({String id, List<double> values, double norm})> entries;

  static double _norm(List<double> values) =>
      math.sqrt(values.fold<double>(0, (sum, v) => sum + v * v));

  @override
  Future<List<VectorMatch>> search(List<double> vector, int limit) async {
    if (limit <= 0 || vector.length != dimensions || _norm(vector) == 0) {
      throw ArgumentError('Query dimension, norm or limit invalid');
    }
    final qNorm = _norm(vector);
    final matches = entries.map((entry) {
      var dot = 0.0;
      for (var i = 0; i < dimensions; i++) {
        dot += vector[i] * entry.values[i];
      }
      return VectorMatch(entry.id, dot / (qNorm * entry.norm));
    }).toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    return matches.take(limit).toList();
  }
}
