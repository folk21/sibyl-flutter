import 'dart:convert';
import 'dart:math' as math;
import 'package:crypto/crypto.dart';

import 'contracts.dart';

/// Byte-for-byte equivalent to Python HashEmbeddingProvider for synthetic tests.
/// This is NOT semantic search and MUST NOT substitute for the E5 production model.
class HashEmbeddingEngine implements EmbeddingEngine {
  const HashEmbeddingEngine({required this.dimensions, this.normalize = true});
  final int dimensions;
  final bool normalize;

  @override
  Future<List<double>> embed(String text) async {
    if (dimensions <= 0) throw ArgumentError.value(dimensions, 'dimensions');
    final values = <double>[];
    var counter = 0;
    while (values.length < dimensions) {
      final bytes = sha256.convert(utf8.encode('$counter:$text')).bytes;
      for (final value in bytes) {
        values.add(value / 127.5 - 1.0);
        if (values.length == dimensions) break;
      }
      counter++;
    }
    if (normalize) {
      final norm = math.sqrt(values.fold<double>(0, (sum, value) => sum + value * value));
      if (norm > 0) {
        for (var i = 0; i < values.length; i++) {
          values[i] /= norm;
        }
      }
    }
    return values;
  }
}
