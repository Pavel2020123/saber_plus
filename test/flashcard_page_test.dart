import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/academic/domain/academic_models.dart';
import 'package:saber_plus/features/flashcards/domain/flashcard_models.dart';
import 'package:saber_plus/features/flashcards/presentation/flashcard_providers.dart';
import 'package:saber_plus/features/flashcards/presentation/flashcard_session_page.dart';
import 'package:saber_plus/features/flashcards/presentation/flashcards_page.dart';

void main() {
  final cards = List.generate(
    130,
    (index) => Flashcard(
      id: 'card-$index',
      kind: index < 80 ? FlashcardKind.formula : FlashcardKind.glossary,
      area: AcademicArea.values[index % AcademicArea.values.length],
      front: 'Frente $index',
      back: 'Respuesta $index',
      context: 'Contexto $index',
    ),
    growable: false,
  );

  Widget app(Widget child) => ProviderScope(
    overrides: [
      flashcardCatalogProvider.overrideWith((ref) => cards),
      flashcardProgressProvider.overrideWith((ref) => Stream.value(const [])),
    ],
    child: MaterialApp(home: child),
  );

  testWidgets('muestra el catálogo y permite configurar una sesión', (
    tester,
  ) async {
    await tester.pumpWidget(app(const FlashcardsPage()));
    await tester.pump();

    expect(find.text('0 de 130 dominadas'), findsOneWidget);
    expect(find.byKey(const Key('flashcard-kind-filter')), findsOneWidget);
    expect(find.byKey(const Key('flashcard-area-filter')), findsOneWidget);
    expect(find.byKey(const Key('flashcard-count-filter')), findsOneWidget);
  });

  testWidgets('oculta y revela la respuesta de una tarjeta', (tester) async {
    await tester.pumpWidget(
      app(const FlashcardSessionPage(config: FlashcardSessionConfig(count: 5))),
    );
    await tester.pump();

    expect(find.text('1/5'), findsOneWidget);
    expect(find.text('Respuesta 0'), findsNothing);
    await tester.tap(find.byKey(const Key('reveal-flashcard')));
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Respuesta'), findsOneWidget);
    expect(find.text('Respuesta 0'), findsOneWidget);
    expect(find.byKey(const Key('master-flashcard')), findsOneWidget);
    expect(find.byKey(const Key('review-flashcard-again')), findsOneWidget);
  });
}
