import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import '../domain/booklet_activity.dart';
import 'booklet_exercise.dart';

@Preview(name: 'Asociación · Celular', size: Size(390, 844))
@Preview(name: 'Asociación · Tableta', size: Size(800, 1000))
Widget bookletMatchingPreview() => MaterialApp(
  home: Scaffold(
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: BookletExercise(
        activity: BookletActivity(
          id: 'preview',
          format: BookletActivityFormat.vocabularyMatching,
          title: 'Food',
          instructions:
              'Match each description with a word. Two words are not used.',
          example: const BookletExample(
            prompt: 'A red or green fruit.',
            answer: 'H. apple',
          ),
          choices: List.generate(
            7,
            (i) => BookletChoice(
              id: 'word-$i',
              label: String.fromCharCode(65 + i),
              text: [
                'candy',
                'carrot',
                'chicken',
                'fish',
                'milk',
                'soup',
                'tea',
              ][i],
            ),
          ),
          items: List.generate(
            5,
            (i) => BookletItem(
              id: 'item-$i',
              number: 80 + i,
              prompt: [
                'An orange vegetable.',
                'A warm dish served in a bowl.',
                'A drink that comes from cows.',
                'A sweet food.',
                'An animal that lives in water.',
              ][i],
              choiceIds: List.generate(7, (j) => 'word-$j'),
            ),
          ),
        ),
        selections: const {},
        onSelect: (_, _) {},
      ),
    ),
  ),
);
