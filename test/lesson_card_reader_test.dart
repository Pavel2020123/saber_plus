import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/core/widgets/collapsible_practice_context.dart';
import 'package:saber_plus/features/study/presentation/lesson_card_reader.dart';

class MemoryLessonStore implements LessonViewStore {
  final values = <String, String>{};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}

const content =
    '## El orden\n\nPrimero los paréntesis.\n\n'
    '## Ejemplo: Multiplicación\n\n3 × 4 + 2 = 14.\n\n'
    '## Consejo: Misma prioridad\n\nResuelve de izquierda a derecha.';

Widget reader(
  MemoryLessonStore store, {
  String user = 'a',
  String text = content,
  TextScaler scaler = TextScaler.noScaling,
  Brightness brightness = Brightness.light,
  bool unavailablePreferences = false,
}) => ProviderScope(
  overrides: [
    lessonViewStoreProvider.overrideWith((_) {
      if (unavailablePreferences) throw StateError('Preferences unavailable');
      return store;
    }),
  ],
  child: MaterialApp(
    theme: ThemeData(brightness: brightness),
    builder: (_, child) => MediaQuery(
      data: MediaQueryData(textScaler: scaler),
      child: child!,
    ),
    home: Scaffold(
      body: ListView(
        children: [
          LessonCardReader(
            userId: user,
            subtopicId: 'subtema',
            title: 'Operaciones',
            markdown: text,
            questionCount: 8,
            footer: const Text('Completar y practicar'),
            onOpenLink: (_) {},
          ),
        ],
      ),
    ),
  ),
);

Future<void> tap(WidgetTester tester, Key key) async {
  await tester.ensureVisible(find.byKey(key));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
}

void main() {
  test('panel blocks preserve content and remove editorial prefixes only', () {
    final cards = splitLessonCards(content);
    expect(cards.length, 3);
    expect(cards[1].title, 'Multiplicación');
    expect(cards[1].body, '3 × 4 + 2 = 14.');
    expect(cards[2].title, 'Misma prioridad');
    expect(
      splitLessonCards('Un texto sin bloques.').single.body,
      'Un texto sin bloques.',
    );
    expect(splitLessonCards(''), isEmpty);
  });
  test('fenced code headings do not create spurious cards', () {
    final cards = splitLessonCards(
      '## Lectura\n```md\n## Código\n```\nTexto\n## Final\nFin',
    );
    expect(cards.length, 2);
    expect(cards.first.body, contains('## Código'));
  });
  testWidgets(
    'one card at a time; footer only on last and navigation is reversible',
    (tester) async {
      await tester.pumpWidget(reader(MemoryLessonStore()));
      await tester.pumpAndSettle();
      expect(find.text('El orden'), findsOneWidget);
      expect(find.text('Multiplicación'), findsNothing);
      expect(find.text('Completar y practicar'), findsNothing);
      await tap(tester, const Key('lesson-card-next'));
      expect(find.text('Multiplicación'), findsOneWidget);
      expect(find.text('El orden'), findsNothing);
      await tap(tester, const Key('lesson-card-next'));
      expect(find.text('Completar y practicar'), findsOneWidget);
      await tap(tester, const Key('lesson-card-previous'));
      expect(find.text('Completar y practicar'), findsNothing);
    },
  );
  testWidgets(
    'dismissals and position survive reopen; accounts stay isolated',
    (tester) async {
      final store = MemoryLessonStore();
      await tester.pumpWidget(reader(store));
      await tester.pumpAndSettle();
      await tap(tester, const Key('dismiss-lesson-intro'));
      await tap(tester, const Key('dismiss-lesson-question-count'));
      await tap(tester, const Key('lesson-card-next'));
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await tester.pumpWidget(reader(store));
      await tester.pumpAndSettle();
      expect(find.text('Multiplicación'), findsOneWidget);
      expect(find.text('¡Vamos paso a paso!'), findsNothing);
      expect(find.text('8 preguntas de práctica disponibles'), findsNothing);
      await tester.pumpWidget(reader(store, user: 'b'));
      await tester.pumpAndSettle();
      expect(find.text('El orden'), findsOneWidget);
      expect(find.text('¡Vamos paso a paso!'), findsOneWidget);
    },
  );
  testWidgets(
    'edited lesson resets reading position without reopening dismissed welcome',
    (tester) async {
      final store = MemoryLessonStore();
      await tester.pumpWidget(reader(store));
      await tester.pumpAndSettle();
      await tap(tester, const Key('dismiss-lesson-intro'));
      await tap(tester, const Key('lesson-card-next'));
      await tester.pumpWidget(
        reader(store, text: '$content\n\nTexto actualizado.'),
      );
      await tester.pumpAndSettle();
      expect(find.text('El orden'), findsOneWidget);
      expect(find.text('¡Vamos paso a paso!'), findsNothing);
      expect(find.text('Mostrar ayuda'), findsNothing);
    },
  );
  testWidgets(
    'lesson does not offer recommended bases or repeat welcome controls',
    (tester) async {
      await tester.pumpWidget(reader(MemoryLessonStore()));
      await tester.pumpAndSettle();
      expect(find.text('Bases recomendadas'), findsNothing);
      await tap(tester, const Key('dismiss-lesson-intro'));
      expect(find.text('Mostrar ayuda'), findsNothing);
      expect(find.text('¡Vamos paso a paso!'), findsNothing);
    },
  );
  for (final brightness in Brightness.values) {
    testWidgets('320px and 200% text scrolls without overflow: $brightness', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        reader(
          MemoryLessonStore(),
          scaler: const TextScaler.linear(2),
          brightness: brightness,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tap(tester, const Key('lesson-card-next'));
      expect(tester.takeException(), isNull);
      expect(find.text('2 / 3'), findsOneWidget);
    });
  }
  testWidgets(
    'horizontal swipe changes cards and keeps vertical scrolling available',
    (tester) async {
      await tester.pumpWidget(reader(MemoryLessonStore()));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('lesson-card-swipe')));
      await tester.pumpAndSettle();
      await tester.drag(
        find.byKey(const Key('lesson-card-swipe')),
        const Offset(-180, 0),
      );
      await tester.pumpAndSettle();
      expect(find.text('2 / 3'), findsOneWidget);
      expect(find.text('Multiplicación'), findsOneWidget);
      await tester.drag(
        find.byKey(const Key('lesson-card-swipe')),
        const Offset(180, 0),
      );
      await tester.pumpAndSettle();
      expect(find.text('1 / 3'), findsOneWidget);
      await tester.drag(
        find.byKey(const Key('lesson-card-swipe')),
        const Offset(180, 0),
      );
      await tester.pumpAndSettle();
      expect(find.text('1 / 3'), findsOneWidget);
    },
  );
  testWidgets(
    'missing native preferences never prevent closing welcome or reading',
    (tester) async {
      await tester.pumpWidget(
        reader(MemoryLessonStore(), unavailablePreferences: true),
      );
      await tester.pumpAndSettle();
      await tap(tester, const Key('dismiss-lesson-intro'));
      await tap(tester, const Key('lesson-card-next'));
      expect(find.text('2 / 3'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('practice context hides and restores without changing question', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              CollapsiblePracticeContext(label: 'Tema · Subtema'),
              Text('Pregunta intacta'),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Ocultar tema de la práctica'));
    await tester.pump();
    expect(find.text('Tema · Subtema'), findsNothing);
    expect(find.text('Pregunta intacta'), findsOneWidget);
    await tester.tap(find.text('Mostrar tema'));
    await tester.pump();
    expect(find.text('Tema · Subtema'), findsOneWidget);
  });
}
