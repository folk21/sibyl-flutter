import '../domain/models.dart';
import '../retrieval/contracts.dart';

/// Clearly synthetic UI fixtures, never presented as authentic quotations.
class DemoRetrievalService implements RetrievalService {
  const DemoRetrievalService();

  @override
  Future<List<Candidate>> candidates(String question, int limit) async => [
    _candidate('demo-road', 'The Road',
        'The road became visible only after the traveller stepped onto it.', 0.77),
    _candidate('demo-window', 'The Window',
        'Nothing outside had changed, but the window was open now.', 0.66),
    _candidate('demo-lamp', 'The Lamp',
        'He lit one lamp and stopped asking how he would illuminate the whole house.', 0.71),
  ].take(limit).toList();

  Candidate _candidate(String id, String work, String text, double score) => Candidate(
    passage: Passage(
      id: id, author: 'Synthetic fixture', work: work, location: 'Test corpus',
      originalLanguage: 'en', variants: {
        PassageLength.short: PassageVariant(length: PassageLength.short, texts: [
          PassageText(language: 'en', role: PassageTextRole.original, text: text),
        ]),
      },
    ), semanticScore: score,
  );
}
