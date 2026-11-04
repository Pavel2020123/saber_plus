import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saber_plus/core/widgets/academic_image.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/practice/domain/booklet_activity.dart';
import 'package:saber_plus/features/practice/presentation/booklet_exercise.dart';

BookletActivity sample(BookletActivityFormat format) => BookletActivity(
  id: 'sample',
  format: format,
  title: 'Food',
  instructions: 'Choose the appropriate word.',
  passage: format == BookletActivityFormat.gapFill
      ? 'A complete text with {{80}} and {{81}}.'
      : 'A short reading passage.',
  choices: const [
    BookletChoice(id: 'a', label: 'A', text: 'candy'),
    BookletChoice(id: 'b', label: 'B', text: 'carrot'),
  ],
  items: List.generate(
    2,
    (i) => BookletItem(
      id: 'item-$i',
      number: 80 + i,
      prompt: 'Description $i',
      choiceIds: ['a', 'b'],
    ),
  ),
  example: const BookletExample(prompt: 'A fruit', answer: 'H. apple'),
);
void main() {
  testWidgets('context item and answer photos open without answering', (
    tester,
  ) async {
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder).drawColor(Colors.blue, ui.BlendMode.src);
    final picture = recorder.endRecording();
    final image = picture.toImageSync(40, 20);
    picture.dispose();
    addTearDown(image.dispose);
    const path = '/recursos/editoriales/a6ec3648-24ee-47d0-91f8-e59b2b68b9ab';
    final json = sample(BookletActivityFormat.vocabularyMatching).toJson();
    json['imageUrl'] = path;
    (json['items'] as List).first['imageUrl'] = path;
    (json['choices'] as List).first['imageUrl'] = path;
    var answers = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          editorialImageProvider.overrideWith((ref, path) async => image),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: BookletExercise(
                activity: BookletActivity.fromJson('images', json),
                selections: const {},
                onSelect: (_, _) {
                  answers++;
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AcademicImage), findsNWidgets(3));
    await tester.tap(find.byTooltip('Toca para ampliar').first);
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(answers, 0);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('large text remains readable on a narrow screen', (tester) async {
    tester.view.physicalSize = const Size(320, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: BookletExercise(
              activity: sample(BookletActivityFormat.vocabularyMatching),
              selections: const {},
              onSelect: (_, _) {},
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
  for (final format in BookletActivityFormat.values) {
    for (final width in [320.0, 390.0, 800.0]) {
      testWidgets('${format.name} fits $width without overflow', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: BookletExercise(
                  activity: sample(format),
                  selections: const {},
                  onSelect: (_, _) {},
                ),
              ),
            ),
          ),
        );
        expect(find.text('Food'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('matching selects stable bank answer from sheet', (tester) async {
    String? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: BookletExercise(
              activity: sample(BookletActivityFormat.vocabularyMatching),
              selections: const {},
              onSelect: (_, id) {
                selected = id;
              },
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('booklet-answer-item-0')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('B. carrot').last);
    await tester.pumpAndSettle();
    expect(selected, 'b');
  });
}
