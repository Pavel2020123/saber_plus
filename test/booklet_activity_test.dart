import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/practice/domain/booklet_activity.dart';

void main() {
  final choices = List.generate(
    7,
    (index) => BookletChoice(
      id: 'word-$index',
      label: String.fromCharCode(65 + index),
      text: 'Word $index',
    ),
  );
  BookletActivity activity({List<BookletChoice>? bank, List<String>? ids}) =>
      BookletActivity(
        id: 'food',
        format: BookletActivityFormat.vocabularyMatching,
        title: 'Food',
        instructions: 'Match each description with a word.',
        example: const BookletExample(prompt: 'Example', answer: 'H. apple'),
        choices: bank ?? choices,
        items: List.generate(
          5,
          (index) => BookletItem(
            id: 'item-$index',
            number: 80 + index,
            prompt: 'Description $index',
            choiceIds: ids ?? choices.map((choice) => choice.id).toList(),
          ),
        ),
      );

  test('preserves seven stable labels, five items and separate example', () {
    final value = activity();
    expect(value.choices.map((choice) => choice.label), [
      'A',
      'B',
      'C',
      'D',
      'E',
      'F',
      'G',
    ]);
    expect(value.items.length, 5);
    expect(value.example!.answer, 'H. apple');
    expect(() => value.choices.clear(), throwsUnsupportedError);
  });
  test('requires complete valid selections without inventing answers', () {
    final value = activity();
    expect(value.isComplete({}), isFalse);
    final selections = {for (var i = 0; i < 5; i++) 'item-$i': 'word-$i'};
    expect(value.isComplete(selections), isTrue);
    selections['item-0'] = 'unknown';
    expect(value.isComplete(selections), isFalse);
    expect(value.acceptsSelection('unknown', 'word-0'), isFalse);
  });
  test(
    'public JSON round trip preserves bank, example and item identifiers',
    () {
      final value = activity();
      final copy = BookletActivity.fromJson(value.id, value.toJson());
      expect(copy.toJson(), value.toJson());
      expect(copy.items.first.toJson().containsKey('correctChoiceId'), isFalse);
    },
  );
  test('rejects duplicate bank entries and incomplete matching banks', () {
    expect(
      () => activity(bank: [...choices, choices.first]),
      throwsArgumentError,
    );
    expect(() => activity(ids: ['word-0', 'word-1']), throwsArgumentError);
    expect(() => activity(ids: ['unknown', 'word-1']), throwsArgumentError);
  });
  test('images survive public serialization in all three positions', () {
    final json = activity().toJson();
    json['imageUrl'] = 'https://example.com/context.png';
    (json['items'] as List).first['imageUrl'] =
        'https://example.com/prompt.png';
    (json['choices'] as List).first['imageUrl'] =
        'https://example.com/option.png';
    final parsed = BookletActivity.fromJson('food', json);
    expect(parsed.imageUrl, json['imageUrl']);
    expect(parsed.items.first.imageUrl, 'https://example.com/prompt.png');
    expect(parsed.choices.first.imageUrl, 'https://example.com/option.png');
    expect(parsed.toJson(), json);
  });
}
