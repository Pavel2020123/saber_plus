enum BookletActivityFormat {
  vocabularyMatching,
  notice,
  conversation,
  gapFill,
  readingComprehension,
}

class BookletChoice {
  const BookletChoice({
    required this.id,
    required this.label,
    required this.text,
    this.imageUrl,
  });

  final String id;
  final String label;
  final String text;
  final String? imageUrl;

  factory BookletChoice.fromJson(Map<String, dynamic> json) => BookletChoice(
    id: json['id'] as String,
    label: json['label'] as String,
    text: json['text'] as String,
    imageUrl: json['imageUrl'] as String?,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'text': text,
    if (imageUrl != null) 'imageUrl': imageUrl,
  };
}

class BookletItem {
  BookletItem({
    required this.id,
    required this.number,
    required this.prompt,
    required List<String> choiceIds,
    this.imageUrl,
  }) : choiceIds = List.unmodifiable(choiceIds);

  final String id;
  final int number;
  final String prompt;
  final String? imageUrl;
  final List<String> choiceIds;

  factory BookletItem.fromJson(Map<String, dynamic> json) => BookletItem(
    id: json['id'] as String,
    number: json['number'] as int,
    prompt: json['prompt'] as String,
    choiceIds: (json['choiceIds'] as List).cast<String>(),
    imageUrl: json['imageUrl'] as String?,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'number': number,
    'prompt': prompt,
    'choiceIds': choiceIds,
    if (imageUrl != null) 'imageUrl': imageUrl,
  };
}

class BookletExample {
  const BookletExample({required this.prompt, required this.answer});

  final String prompt;
  final String answer;
}

// Public student content deliberately excludes the answer key.
class BookletActivity {
  BookletActivity({
    required this.id,
    required this.format,
    required this.title,
    required this.instructions,
    required List<BookletChoice> choices,
    required List<BookletItem> items,
    this.example,
    this.passage,
    this.source = '',
    this.imageUrl,
  }) : choices = List.unmodifiable(choices),
       items = List.unmodifiable(items) {
    final ids = choices.map((choice) => choice.id).toSet();
    final labels = choices.map((choice) => choice.label).toSet();
    if (id.trim().isEmpty ||
        instructions.trim().isEmpty ||
        choices.isEmpty ||
        items.isEmpty ||
        ids.length != choices.length ||
        (format == BookletActivityFormat.vocabularyMatching &&
            labels.length != choices.length) ||
        choices.any(
          (choice) =>
              choice.id.trim().isEmpty ||
              choice.label.trim().isEmpty ||
              choice.text.trim().isEmpty,
        ) ||
        items.map((item) => item.id).toSet().length != items.length ||
        items.map((item) => item.number).toSet().length != items.length ||
        items.any(
          (item) =>
              item.id.trim().isEmpty ||
              item.number < 1 ||
              item.prompt.trim().isEmpty ||
              item.choiceIds.length < 2 ||
              item.choiceIds.toSet().length != item.choiceIds.length ||
              item.choiceIds.any((id) => !ids.contains(id)),
        )) {
      throw ArgumentError('Invalid booklet activity');
    }
    if (format == BookletActivityFormat.vocabularyMatching &&
        items.any((item) => item.choiceIds.length != choices.length)) {
      throw ArgumentError('Matching items must share the complete word bank');
    }
  }

  final String id;
  final BookletActivityFormat format;
  final String title;
  final String instructions;
  final String? passage;
  final String source;
  final String? imageUrl;
  final BookletExample? example;
  final List<BookletChoice> choices;
  final List<BookletItem> items;

  Map<String, dynamic> toJson() => {
    'format': format.name,
    'title': title,
    'instructions': instructions,
    'passage': passage,
    'source': source,
    if (imageUrl != null) 'imageUrl': imageUrl,
    'example': example == null
        ? null
        : {'prompt': example!.prompt, 'answer': example!.answer},
    'choices': choices.map((choice) => choice.toJson()).toList(),
    'items': items.map((item) => item.toJson()).toList(),
  };

  factory BookletActivity.fromJson(String id, Map<String, dynamic> json) {
    final example = json['example'];
    return BookletActivity(
      id: id,
      format: BookletActivityFormat.values.byName(json['format'] as String),
      title: json['title'] as String,
      instructions: json['instructions'] as String,
      passage: json['passage'] as String?,
      source: json['source'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      example: example is Map
          ? BookletExample(
              prompt: example['prompt'] as String,
              answer: example['answer'] as String,
            )
          : null,
      choices: (json['choices'] as List)
          .map(
            (value) =>
                BookletChoice.fromJson(Map<String, dynamic>.from(value as Map)),
          )
          .toList(),
      items: (json['items'] as List)
          .map(
            (value) =>
                BookletItem.fromJson(Map<String, dynamic>.from(value as Map)),
          )
          .toList(),
    );
  }

  bool acceptsSelection(String itemId, String choiceId) => items.any(
    (item) => item.id == itemId && item.choiceIds.contains(choiceId),
  );

  bool isComplete(Map<String, String> selections) =>
      selections.length == items.length &&
      items.every(
        (item) => acceptsSelection(item.id, selections[item.id] ?? ''),
      );
}
