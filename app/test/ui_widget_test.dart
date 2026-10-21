import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sibyl/demo/demo_retrieval.dart';
import 'package:sibyl/domain/selection_engine.dart';
import 'package:sibyl/ui/sibyl_home.dart';

void main() {
  testWidgets('demo UI visibly labels synthetic passages', (tester) async {
    await tester.pumpWidget(MaterialApp(home: SibylHome(
      retrieval: const DemoRetrievalService(), isDemo: true,
      selector: SelectionEngine(random: () => 0),
    )));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Own question'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'What next?');
    await tester.tap(find.text('Find passage'));
    await tester.pumpAndSettle();
    expect(find.textContaining('DEMO: synthetic fixture'), findsOneWidget);
    expect(find.text('Remember this'), findsOneWidget);
  });

  testWidgets('real E5 corpus does not silently offer demo search', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SibylHome(
      retrieval: null, isDemo: false, runtimeLabel: 'local corpus',
    )));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Own question'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'What next?');
    final action = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(action.onPressed, isNull);
    expect(find.textContaining('E5 inference is not ported'), findsOneWidget);
    expect(find.textContaining('DEMO:'), findsNothing);
  });
}
