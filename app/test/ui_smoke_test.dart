import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sibyl/demo/demo_retrieval.dart';
import 'package:sibyl/domain/models.dart';
import 'package:sibyl/domain/selection_engine.dart';
import 'package:sibyl/retrieval/contracts.dart';
import 'package:sibyl/ui/sibyl_home.dart';

/// A fixed local guided fixture checks the UI boundary without corpus or model I/O.
class _GuidedFixture implements GuidedRetrievalService {
  String? requestedId;

  @override
  Future<List<GuidedQuestion>> availableQuestions() async => const [
    GuidedQuestion(id: 'guided-1', text: 'What can I notice?', kind: 'question', theme: 'test_theme'),
  ];

  @override
  Future<List<Candidate>> candidates(String questionId, int limit) async {
    requestedId = questionId;
    return [
      Candidate(
        semanticScore: 0.8,
        passage: Passage(
          id: 'stored-1',
          author: 'Fixture author',
          work: 'Fixture work',
          originalLanguage: 'en',
          variants: {
            PassageLength.short: PassageVariant(
              length: PassageLength.short,
              texts: const [
                PassageText(
                  language: 'en',
                  role: PassageTextRole.original,
                  text: '  Exact source wording.\nSecond line.  ',
                ),
                PassageText(
                  language: 'ru',
                  role: PassageTextRole.machineTranslation,
                  text: '  Stored translation.  ',
                  translationProvider: 'local-fixture',
                ),
              ],
            ),
          },
        ),
      ),
    ];
  }
}

class _EmptyRetrieval implements RetrievalService {
  @override
  Future<List<Candidate>> candidates(String question, int limit) async => [];
}

void main() {
  testWidgets('compact desktop or mobile demo offers an accessible input', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(MaterialApp(
      home: SibylHome(
        retrieval: const DemoRetrievalService(),
        isDemo: true,
        selector: SelectionEngine(random: () => 0),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('55 questions · 11 states'), findsOneWidget);
    expect(find.textContaining('Literary corpus is not installed'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);
    await tester.tap(find.text('Own question'));
    await tester.pumpAndSettle();
    expect(find.text('Your question'), findsOneWidget);
    expect(find.textContaining('synthetic test passages'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('search finds a canonical Russian prompt without a local corpus', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SibylHome(
      retrieval: null,
      isDemo: true,
    )));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byKey(const Key('guided-search')), 120);
    await tester.enterText(find.byKey(const Key('guided-search')), 'сожалеть');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('guided-regret_about_past')), findsOneWidget);
    await tester.tap(find.byKey(const Key('guided-regret_about_past')));
    await tester.pumpAndSettle();
    expect(find.text('Selected: Стоит ли сожалеть о прошлом?'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);
    expect(find.text('Remember this'), findsNothing);
  });

  testWidgets('guided UI preserves stored source and machine-translation text', (tester) async {
    final guided = _GuidedFixture();
    await tester.pumpWidget(MaterialApp(
      home: SibylHome(
        retrieval: null,
        guided: guided,
        isDemo: false,
        catalogLoader: () async => const [
          GuidedQuestion(id: 'guided-1', text: 'What can I notice?', kind: 'question', theme: 'test_theme'),
          GuidedQuestion(id: 'unmapped', text: 'Another concern?', kind: 'question', theme: 'test_theme'),
        ],
        selector: SelectionEngine(random: () => 0),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Prepared questions and states'), findsOneWidget);
    expect(find.text('What can I notice?'), findsWidgets);

    await tester.tap(find.text('Find passage'));
    await tester.pumpAndSettle();
    expect(guided.requestedId, 'guided-1');
    final sourceText = find.byWidgetPredicate((widget) =>
      widget is SelectableText && widget.data == '  Exact source wording.\nSecond line.  ');
    final translatedText = find.byWidgetPredicate((widget) =>
      widget is SelectableText && widget.data == '  Stored translation.  ');
    await tester.scrollUntilVisible(sourceText, 120);
    expect(sourceText, findsOneWidget);
    await tester.scrollUntilVisible(translatedText, 120);
    expect(translatedText, findsOneWidget);
    expect(find.text('Machine translation · ru'), findsOneWidget);
    expect(find.textContaining('DEMO:'), findsNothing);

    await tester.scrollUntilVisible(find.text('Remember this'), 150);
    await tester.tap(find.text('Remember this'));
    await tester.pump();
    await tester.scrollUntilVisible(find.text('Saved encounters'), 150);
    expect(find.text('Saved encounters'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('unmapped guided question stays selectable but cannot fabricate an answer', (tester) async {
    final guided = _GuidedFixture();
    await tester.pumpWidget(MaterialApp(home: SibylHome(
      retrieval: null,
      guided: guided,
      isDemo: false,
      catalogLoader: () async => const [
        GuidedQuestion(id: 'guided-1', text: 'What can I notice?', kind: 'question', theme: 'test_theme'),
        GuidedQuestion(id: 'unmapped', text: 'Another concern?', kind: 'state', theme: 'test_theme'),
      ],
    )));
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNotNull);
    await tester.scrollUntilVisible(find.byKey(const Key('guided-unmapped')), 100);
    await tester.tap(find.byKey(const Key('guided-unmapped')));
    await tester.pumpAndSettle();
    expect(find.textContaining('No stored literary passages are mapped'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);
    expect(guided.requestedId, isNull);
    expect(find.text('Remember this'), findsNothing);
  });

  testWidgets('no candidates is an explicit state rather than a fake quotation', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: SibylHome(
        retrieval: _EmptyRetrieval(),
        isDemo: false,
        selector: SelectionEngine(random: () => 0),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Own question'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'What now?');
    await tester.tap(find.text('Find passage'));
    await tester.pumpAndSettle();
    expect(find.text('No eligible stored passage was found.'), findsOneWidget);
    expect(find.text('Remember this'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
