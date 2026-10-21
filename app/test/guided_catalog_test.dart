import 'package:flutter_test/flutter_test.dart';
import 'package:sibyl/runtime/guided_question_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled guided catalog preserves all source prompts and source order', () async {
    final catalog = await loadGuidedQuestionCatalog();
    expect(catalog, hasLength(66));
    expect(catalog.where((item) => item.kind == 'question'), hasLength(55));
    expect(catalog.where((item) => item.kind == 'state'), hasLength(11));
    expect(catalog.first.id, 'change_timing');
    expect(catalog.first.text, 'Как понять, что пора что-то менять?');
    expect(catalog.first.theme, 'change_and_choice');
    expect(catalog.map((item) => item.id).toSet(), hasLength(66));
    expect(() => catalog.clear(), throwsUnsupportedError);
  });

  test('rejects unsupported or duplicate catalog records', () {
    const invalid = '{"schema_version":1,"catalog_id":"test",'
        '"language":"ru","items":['
        '{"id":"same","text":"First","theme":"test","kind":"question"},'
        '{"id":"same","text":"Second","theme":"test","kind":"state"}]}';
    expect(() => decodeGuidedQuestionCatalog(invalid), throwsFormatException);
    expect(() => decodeGuidedQuestionCatalog('{"schema_version":2,"items":[]}'),
        throwsFormatException);
    expect(() => decodeGuidedQuestionCatalog('{"schema_version":1,"catalog_id":"test",'
        '"language":"ru","items":[]}'), throwsFormatException);
  });
}
