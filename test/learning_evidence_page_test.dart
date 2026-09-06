import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/core/network/api_error.dart';
import 'package:saber_plus/features/learning_evidence/data/learning_evidence_repository.dart';
import 'package:saber_plus/features/learning_evidence/domain/learning_evidence.dart';
import 'package:saber_plus/features/learning_evidence/presentation/learning_evidence_page.dart';
import 'learning_evidence_test.dart' show reportFixture;

void main() {
  testWidgets('muestra evidencia por subtema y etiqueta demo explícita', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          learningEvidenceProvider.overrideWith(
            (ref) async => demoLearningEvidence(),
          ),
        ],
        child: const MaterialApp(home: LearningEvidencePage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Demostración: datos de ejemplo'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Proporcionalidad'), 200);
    await tester.tap(find.text('Proporcionalidad'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Regla de tres directa'), 150);
    expect(find.text('Conviene reforzar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('muestra vacío sin declarar al estudiante fuerte o débil', (
    tester,
  ) async {
    final report = LearningEvidence.fromJson(
      reportFixture()..['temas'] = <Object>[],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          learningEvidenceProvider.overrideWith((ref) async => report),
        ],
        child: const MaterialApp(home: LearningEvidencePage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Todavía no hay respuestas evaluables'),
      findsOneWidget,
    );
    expect(find.text('Fortaleza en lo evaluado'), findsNothing);
    expect(find.text('Demostración: datos de ejemplo'), findsNothing);
  });

  testWidgets(
    'distingue carga, error y reintento sin mostrar un falso diagnóstico',
    (tester) async {
      final completer = Completer<LearningEvidence>();
      var calls = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            learningEvidenceProvider.overrideWith((ref) {
              calls++;
              return calls == 1
                  ? completer.future
                  : Future.value(demoLearningEvidence());
            }),
          ],
          child: const MaterialApp(home: LearningEvidencePage()),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      completer.completeError(
        const ApiError(code: 'offline', message: 'Sin conexión'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Sin conexión'), findsOneWidget);
      expect(find.text('Conviene reforzar'), findsNothing);
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(calls, 2);
      expect(find.text('Demostración: datos de ejemplo'), findsOneWidget);
    },
  );

  testWidgets('pantalla estrecha y texto grande no desbordan', (tester) async {
    tester.view.resetPhysicalSize();
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          learningEvidenceProvider.overrideWith(
            (ref) async => demoLearningEvidence(),
          ),
        ],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.8)),
            child: child!,
          ),
          home: const LearningEvidencePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Proporcionalidad'), 300);
    await tester.pumpAndSettle();
    await Scrollable.ensureVisible(
      tester.element(find.text('Proporcionalidad')),
      alignment: 0.5,
    );
    await tester.pumpAndSettle();
    expect(find.text('Proporcionalidad').hitTestable(), findsOneWidget);
    await tester.tap(find.text('Proporcionalidad'));
    await tester.pumpAndSettle();
    expect(find.text('Regla de tres directa'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
