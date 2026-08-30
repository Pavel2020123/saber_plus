import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/app/app.dart';
import 'package:saber_plus/app/page_transitions.dart';
import 'package:saber_plus/core/feedback/answer_streak_feedback.dart';
import 'package:saber_plus/core/notifications/study_reminder_service.dart';
import 'package:saber_plus/core/preferences/app_preferences.dart';
import 'package:saber_plus/core/preferences/app_preferences_store.dart';
import 'package:saber_plus/core/storage/secure_session_store.dart';
import 'package:saber_plus/features/difficult_questions/data/drift_difficult_question_repository.dart';
import 'package:saber_plus/features/difficult_questions/domain/difficult_question_models.dart';
import 'package:saber_plus/features/difficult_questions/domain/difficult_question_repository.dart';
import 'package:saber_plus/features/practice/data/practice_draft_store.dart';
import 'package:saber_plus/features/favorites/data/drift_favorite_repository.dart';
import 'package:saber_plus/features/favorites/domain/favorite_models.dart';
import 'package:saber_plus/features/favorites/domain/favorite_repository.dart';
import 'package:saber_plus/features/resume/data/drift_learning_resume_repository.dart';
import 'package:saber_plus/features/resume/domain/learning_resume_models.dart';
import 'package:saber_plus/features/resume/domain/learning_resume_repository.dart';

class _FakeSecureSessionStore extends SecureSessionStore {
  _FakeSecureSessionStore() : super(const FlutterSecureStorage());

  @override
  Future<String?> readAccessToken() async => null;

  @override
  Future<void> saveAccessToken(String token) async {}

  @override
  Future<void> clear() async {}
}

Widget _testApp() => ProviderScope(
  overrides: [
    secureSessionStoreProvider.overrideWithValue(_FakeSecureSessionStore()),
    practiceDraftStoreProvider.overrideWithValue(_FakePracticeDraftStore()),
    appPreferencesStoreProvider.overrideWithValue(_FakePreferencesStore()),
    studyReminderServiceProvider.overrideWithValue(_FakeReminderService()),
    answerStreakFeedbackProvider.overrideWithValue(_FakeAnswerStreakFeedback()),
    favoriteRepositoryProvider.overrideWith((ref) {
      final repository = _FakeFavoriteRepository();
      ref.onDispose(repository.dispose);
      return repository;
    }),
    difficultQuestionRepositoryProvider.overrideWith((ref) {
      final repository = _FakeDifficultQuestionRepository();
      ref.onDispose(repository.dispose);
      return repository;
    }),
    learningResumeRepositoryProvider.overrideWith((ref) {
      final repository = _FakeLearningResumeRepository();
      ref.onDispose(repository.dispose);
      return repository;
    }),
  ],
  child: const SaberPlusApp(),
);

void main() {
  testWidgets('muestra la bienvenida de SaberPlus', (tester) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.light);
    expect(app.theme?.scaffoldBackgroundColor, Colors.white);
    expect(find.text('SaberPlus'), findsOneWidget);
    expect(find.text('Comenzar'), findsOneWidget);
    expect(find.textContaining('Tu preparación ICFES'), findsOneWidget);
  });

  testWidgets('permite entrar al dashboard demostrativo', (tester) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Comenzar'));
    await tester.tap(find.text('Comenzar'));
    await tester.pumpAndSettle();
    expect(find.text('Qué bueno verte'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('student-demo-button')));
    await tester.tap(find.byKey(const Key('student-demo-button')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Hola, Santiago'), findsOneWidget);
    expect(find.text('Refuerzo de matemáticas'), findsOneWidget);
    expect(find.text('Inicio'), findsOneWidget);
    expect(find.byKey(const Key('exam-countdown-banner')), findsOneWidget);
    expect(find.byKey(const Key('expand-exam-countdown')), findsOneWidget);

    await tester.tap(find.byKey(const Key('expand-exam-countdown')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('exam-countdown-headline')), findsOneWidget);

    await tester.tap(find.byKey(const Key('minimize-exam-countdown')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('expand-exam-countdown')), findsOneWidget);

    await tester.tap(find.text('Estudiar'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('exam-countdown-banner')), findsOneWidget);
    expect(find.byKey(const Key('expand-exam-countdown')), findsOneWidget);
  });

  testWidgets('abre registro y recuperación desde el ingreso', (tester) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Comenzar'));
    await tester.tap(find.text('Comenzar'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Crear una cuenta'));
    await tester.tap(find.text('Crear una cuenta'));
    await tester.pumpAndSettle();
    expect(find.text('Crea tu cuenta'), findsOneWidget);
    expect(find.byType(SaberPageTransition), findsWidgets);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('¿Olvidaste tu contraseña?'));
    await tester.tap(find.text('¿Olvidaste tu contraseña?'));
    await tester.pumpAndSettle();
    expect(find.text('Recupera tu cuenta'), findsOneWidget);
  });

  testWidgets('navega por área, tema, subtema y lección demostrativa', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Comenzar'));
    await tester.tap(find.text('Comenzar'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('student-demo-button')));
    await tester.tap(find.byKey(const Key('student-demo-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Estudiar'));
    await tester.pumpAndSettle();
    expect(find.text('Contenido por área'), findsOneWidget);

    await tester.tap(find.byKey(const Key('open-offline-downloads')));
    await tester.pumpAndSettle();
    expect(find.text('Descargas'), findsOneWidget);
    expect(find.text('Aún no tienes temas descargados.'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('study-area-matematicas')));
    await tester.pumpAndSettle();
    expect(find.text('Razones y proporciones'), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('study-subtopic-demo-mathematics-subtopic')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Regla de tres'), findsWidgets);

    await tester.drag(find.byType(ListView).last, const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('Marcar como completada'), findsOneWidget);
    await tester.tap(find.byKey(const Key('complete-study-lesson-button')));
    await tester.pumpAndSettle();
    expect(find.text('Lección completada'), findsOneWidget);

    await tester.drag(find.byType(ListView).last, const Offset(0, -650));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('start-subtopic-practice-button')));
    await tester.pumpAndSettle();
    expect(find.text('Pregunta 1 de 2'), findsOneWidget);
    expect(find.textContaining('3 cuadernos'), findsOneWidget);
  });

  testWidgets('muestra el countdown del temario por materia', (tester) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Comenzar'));
    await tester.tap(find.text('Comenzar'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('student-demo-button')));
    await tester.tap(find.byKey(const Key('student-demo-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Estudiar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-syllabus-countdown')));
    await tester.pumpAndSettle();

    expect(find.text('Tu ruta antes del examen'), findsOneWidget);
    expect(find.byKey(const Key('syllabus-countdown-summary')), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('subtemas pendientes'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('syllabus-area-matematicas')),
      250,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.byKey(const Key('syllabus-area-matematicas')), findsOneWidget);
    expect(find.textContaining('Regla de tres'), findsOneWidget);
  });

  testWidgets('configura y abre una sesión aleatoria demostrativa', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Comenzar'));
    await tester.tap(find.text('Comenzar'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('student-demo-button')));
    await tester.tap(find.byKey(const Key('student-demo-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Practicar'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('open-random-practice')),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await Scrollable.ensureVisible(
      tester.element(find.byKey(const Key('open-random-practice'))),
      alignment: 0.5,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-random-practice')));
    await tester.pumpAndSettle();
    expect(find.text('Configura tu sesión'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const Key('start-random-practice-button')),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byKey(const Key('start-random-practice-button')));
    await tester.pumpAndSettle();

    expect(find.text('Preguntas aleatorias'), findsOneWidget);
    expect(find.text('Pregunta 1 de 10'), findsOneWidget);
    expect(find.textContaining('3 cuadernos'), findsOneWidget);
  });

  testWidgets('configura y abre una prueba contrarreloj demostrativa', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Comenzar'));
    await tester.tap(find.text('Comenzar'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('student-demo-button')));
    await tester.tap(find.byKey(const Key('student-demo-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Practicar'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('open-time-trial')),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byKey(const Key('open-time-trial')));
    await tester.pumpAndSettle();

    expect(find.text('Entrena tu velocidad'), findsOneWidget);
    await tester.tap(find.byKey(const Key('time-trial-preset-sprint')));
    await tester.scrollUntilVisible(
      find.byKey(const Key('start-time-trial-button')),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byKey(const Key('start-time-trial-button')));
    await tester.pumpAndSettle();

    expect(find.text('Prueba contrarreloj'), findsOneWidget);
    expect(find.text('Pregunta 1 de 5'), findsOneWidget);
    expect(find.byKey(const Key('time-trial-countdown')), findsOneWidget);
  });

  testWidgets('abre la jornada AM del simulacro de 150 preguntas', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Comenzar'));
    await tester.tap(find.text('Comenzar'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('student-demo-button')));
    await tester.tap(find.byKey(const Key('student-demo-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Practicar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-official-simulation')));
    await tester.pumpAndSettle();

    expect(find.text('Dos jornadas, una prueba completa'), findsOneWidget);
    expect(find.text('150'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('start-official-am')),
      250,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byKey(const Key('start-official-am')));
    await tester.pumpAndSettle();

    expect(find.text('Simulacro 150 · Jornada AM'), findsOneWidget);
    expect(find.text('Pregunta 1 de 75'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('Integridad activa'), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(find.text('1 salida registrada'), findsOneWidget);
    expect(find.textContaining('quedó registrada'), findsOneWidget);
  });

  testWidgets(
    'consulta el catálogo histórico sin habilitar contenido no autorizado',
    (tester) async {
      await tester.pumpWidget(_testApp());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Comenzar'));
      await tester.tap(find.text('Comenzar'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('student-demo-button')));
      await tester.tap(find.byKey(const Key('student-demo-button')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Practicar'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('open-historical-simulations')));
      await tester.pumpAndSettle();

      expect(find.text('Banco con trazabilidad de derechos'), findsOneWidget);
      expect(find.byKey(const Key('historical-year-filter')), findsOneWidget);
      expect(find.text('Edición 2025'), findsOneWidget);
      await tester.tap(find.byKey(const Key('historical-edition-demo-2025')));
      await tester.pumpAndSettle();

      expect(find.text('Fuente y derechos'), findsOneWidget);
      expect(find.text('No hay una autorización registrada.'), findsOneWidget);
      expect(
        find.byKey(const Key('historical-edition-locked')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('start-historical-am')), findsNothing);
    },
  );

  testWidgets('configura y abre un simulacro completo demostrativo', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Comenzar'));
    await tester.tap(find.text('Comenzar'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('student-demo-button')));
    await tester.tap(find.byKey(const Key('student-demo-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Practicar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-area-simulation')));
    await tester.pumpAndSettle();
    expect(find.text('Elige un área'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const Key('start-area-simulation-button')),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byKey(const Key('start-area-simulation-button')));
    await tester.pumpAndSettle();

    expect(find.text('Simulacro por área'), findsOneWidget);
    expect(find.text('Pregunta 1 de 2'), findsOneWidget);

    await tester.tap(find.byKey(const Key('practice-answer-answer-a')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('next-practice-question-button')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('practice-answer-answer-e')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('submit-practice-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-submit-practice-button')));
    await tester.pumpAndSettle();

    expect(find.text('Resultado del simulacro'), findsOneWidget);
    expect(find.byKey(const Key('practice-result-view')), findsOneWidget);
  });

  testWidgets('abre el historial demostrativo y revisa una respuesta', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Comenzar'));
    await tester.tap(find.text('Comenzar'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('student-demo-button')));
    await tester.tap(find.byKey(const Key('student-demo-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Practicar'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).last, const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-practice-history')));
    await tester.pumpAndSettle();

    expect(find.text('Resultados recientes'), findsOneWidget);
    expect(find.text('72%'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('history-answer-demo-history-1')),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await Scrollable.ensureVisible(
      tester.element(find.byKey(const Key('history-answer-demo-history-1'))),
      alignment: 0.3,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('history-answer-demo-history-1')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Respuesta correcta:'), findsOneWidget);
    expect(find.textContaining('20.000 pesos'), findsOneWidget);
  });

  testWidgets('compara dos simulacros de la misma materia', (tester) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Comenzar'));
    await tester.tap(find.text('Comenzar'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('student-demo-button')));
    await tester.tap(find.byKey(const Key('student-demo-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Practicar'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).last, const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-practice-history')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-simulation-comparison')));
    await tester.pumpAndSettle();

    expect(find.text('Mide tu evolución'), findsOneWidget);
    expect(find.byKey(const Key('comparison-area-filter')), findsOneWidget);
    expect(
      find.byKey(const Key('simulation-comparison-summary')),
      findsOneWidget,
    );
    expect(find.text('Mejora clara'), findsOneWidget);
    expect(find.text('+16.0 puntos'), findsOneWidget);
    await tester.tap(find.byKey(const Key('comparison-area-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Matemáticas').last);
    await tester.pumpAndSettle();
    expect(find.text('56.0%'), findsOneWidget);
    expect(find.text('72.0%'), findsOneWidget);
  });

  testWidgets('repasa los errores del día y actualiza su progreso', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Comenzar'));
    await tester.tap(find.text('Comenzar'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('student-demo-button')));
    await tester.tap(find.byKey(const Key('student-demo-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Practicar'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).last, const Offset(0, -250));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-daily-mistakes')));
    await tester.pumpAndSettle();

    expect(find.text('Repaso de hoy'), findsOneWidget);
    expect(find.text('Regla de tres'), findsOneWidget);
    expect(find.text('0 de 1 repasadas'), findsOneWidget);
    final reviewButton = find.byKey(
      const Key('review-daily-mistake-demo-question-mathematics-1'),
    );
    await tester.ensureVisible(reviewButton);
    await tester.drag(
      find.byKey(const Key('daily-mistakes-list')),
      const Offset(0, -120),
    );
    await tester.pumpAndSettle();
    await tester.tap(reviewButton);
    await tester.pumpAndSettle();

    expect(find.text('Marcar pendiente'), findsOneWidget);
    await tester.drag(
      find.byKey(const Key('daily-mistakes-list')),
      const Offset(0, 800),
    );
    await tester.pumpAndSettle();
    expect(find.text('1 de 1 repasadas'), findsOneWidget);
  });

  testWidgets('abre el panel de progreso y el cuaderno de errores', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Comenzar'));
    await tester.tap(find.text('Comenzar'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('student-demo-button')));
    await tester.tap(find.byKey(const Key('student-demo-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Progreso'));
    await tester.pumpAndSettle();

    expect(find.text('Tu progreso'), findsOneWidget);
    expect(find.text('Así vas en SaberPlus'), findsOneWidget);
    expect(find.byKey(const Key('open-adaptive-review')), findsOneWidget);

    await tester.tap(find.text('Cuaderno'));
    await tester.pumpAndSettle();
    expect(find.text('Cuaderno de errores'), findsOneWidget);
    expect(find.text('0 errores'), findsOneWidget);
  });

  testWidgets('prepara y abre un repaso inteligente demostrativo', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Comenzar'));
    await tester.tap(find.text('Comenzar'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('student-demo-button')));
    await tester.tap(find.byKey(const Key('student-demo-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Progreso'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('open-adaptive-review')),
      250,
      scrollable: find.descendant(
        of: find.byKey(const Key('progress-dashboard-list')),
        matching: find.byType(Scrollable),
      ),
    );
    final adaptiveButton = tester.widget<FilledButton>(
      find.byKey(const Key('open-adaptive-review')),
    );
    adaptiveButton.onPressed!();
    await tester.pumpAndSettle();

    expect(find.text('Una sesión hecha para ti'), findsOneWidget);
    expect(find.text('Nivel objetivo: Media'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('start-adaptive-review-button')),
      250,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byKey(const Key('start-adaptive-review-button')));
    await tester.pumpAndSettle();

    expect(find.text('Repaso inteligente'), findsOneWidget);
    expect(find.textContaining('Pregunta 1 de'), findsOneWidget);
  });

  testWidgets('consulta fórmulas, glosario y estrategia sin conexión', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Comenzar'));
    await tester.tap(find.text('Comenzar'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('student-demo-button')));
    await tester.tap(find.byKey(const Key('student-demo-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Progreso'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('open-reference-library')),
      250,
      scrollable: find.descendant(
        of: find.byKey(const Key('progress-dashboard-list')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(find.byKey(const Key('open-reference-library')));
    await tester.pumpAndSettle();

    expect(find.text('Biblioteca académica'), findsOneWidget);
    expect(find.text('Formulario por área'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('formula-search-field')),
      'Pitágoras',
    );
    await tester.pumpAndSettle();
    expect(find.text('Teorema de Pitágoras'), findsOneWidget);

    await tester.tap(find.text('Glosario'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('glossary-search-field')),
      'Homeostasis',
    );
    await tester.pumpAndSettle();
    expect(find.text('Homeostasis'), findsWidgets);

    await tester.tap(find.text('Estrategia'));
    await tester.pumpAndSettle();
    expect(find.text('132 segundos por pregunta'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('strategy-question-count')),
      '50',
    );
    await tester.pump();
    expect(find.text('264 segundos por pregunta'), findsOneWidget);
    await tester.drag(find.byType(ListView).last, const Offset(0, -320));
    await tester.pumpAndSettle();
    expect(find.text('Las cuatro fases'), findsOneWidget);
  });

  testWidgets('abre el estado de sincronización desde Más', (tester) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Comenzar'));
    await tester.tap(find.text('Comenzar'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('student-demo-button')));
    await tester.tap(find.byKey(const Key('student-demo-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Más'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('open-sync-queue')),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.drag(find.byType(ListView).last, const Offset(0, -120));
    await tester.pumpAndSettle();
    expect(find.text('Sin cambios pendientes'), findsOneWidget);
    await tester.tap(find.byKey(const Key('open-sync-queue')));
    await tester.pumpAndSettle();
    expect(find.text('Sincronización'), findsOneWidget);
    expect(find.text('No tienes cambios pendientes.'), findsOneWidget);
  });

  testWidgets('cambia la apariencia desde Preferencias', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Comenzar'));
    await tester.tap(find.text('Comenzar'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('student-demo-button')));
    await tester.tap(find.byKey(const Key('student-demo-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Más'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).last, const Offset(0, -250));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('open-preferences')));
    await tester.tap(find.byKey(const Key('open-preferences')));
    await tester.pumpAndSettle();

    expect(find.text('Preferencias'), findsOneWidget);
    expect(find.text('Recordatorio diario'), findsOneWidget);
    await tester.tap(find.text('Oscuro'));
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);

    await tester.tap(find.text('Sistema'));
    await tester.pumpAndSettle();
    final automaticApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(automaticApp.themeMode, ThemeMode.system);
    expect(find.textContaining('cambiará automáticamente'), findsOneWidget);

    await tester.drag(find.byType(ListView).last, const Offset(0, -700));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('preview-answer-streak-feedback')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('preview-answer-streak-feedback')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Prueba de racha reproducida.'), findsOneWidget);
  });

  testWidgets('muestra XP, racha y logros demostrativos', (tester) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Comenzar'));
    await tester.tap(find.text('Comenzar'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('student-demo-button')));
    await tester.tap(find.byKey(const Key('student-demo-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('open-gamification-from-home')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    expect(find.text('Logros y actividad'), findsOneWidget);
    expect(find.text('4 días de racha'), findsOneWidget);
    expect(find.text('1.240'), findsOneWidget);
    expect(find.byKey(const Key('streak-preview-controls')), findsOneWidget);
    expect(find.text('Llama naranja'), findsOneWidget);
    await tester.tap(find.byKey(const Key('advance-streak-preview')));
    await tester.pump();
    expect(find.text('14 días de racha'), findsOneWidget);
    expect(find.text('Llama dorada'), findsOneWidget);
    await tester.tap(find.text('Congelada'));
    await tester.pump();
    expect(find.text('Llama congelada'), findsOneWidget);
    expect(find.byKey(const Key('frozen-streak-indicator')), findsOneWidget);
    await tester.tap(find.text('Perdida'));
    await tester.pump();
    expect(find.text('0 días de racha'), findsOneWidget);
    expect(find.text('Llama apagada'), findsOneWidget);
    await tester.tap(find.byKey(const Key('reset-streak-preview')));
    await tester.pump();
    expect(find.text('4 días de racha'), findsOneWidget);
    await tester.drag(
      find.byKey(const Key('gamification-list')),
      const Offset(0, -450),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('achievement-total-progress')), findsOneWidget);
    await tester.drag(
      find.byKey(const Key('gamification-list')),
      const Offset(0, -250),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('achievement-PRIMER_PASO')), findsOneWidget);
    expect(find.text('Primer paso'), findsOneWidget);
    expect(find.text('Desbloqueado'), findsWidgets);
    expect(find.byKey(const Key('certificate-PRIMER_PASO')), findsOneWidget);
    await tester.tap(find.byKey(const Key('certificate-PRIMER_PASO')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('cuenta real'), findsOneWidget);
  });

  testWidgets('busca una lección y abre preguntas protegidas', (tester) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Comenzar'));
    await tester.tap(find.text('Comenzar'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('student-demo-button')));
    await tester.tap(find.byKey(const Key('student-demo-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Estudiar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-academic-search')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('academic-search-field')),
      'regla',
    );
    await tester.pumpAndSettle();
    expect(find.text('2 resultados'), findsOneWidget);
    expect(find.text('Lección'), findsOneWidget);
    expect(find.text('Banco de preguntas'), findsOneWidget);

    await tester.tap(find.text('Preguntas'));
    await tester.pumpAndSettle();
    expect(find.text('1 resultado'), findsOneWidget);
    expect(find.text('Lección'), findsNothing);
    await tester.tap(
      find.byKey(
        const Key(
          'academic-search-result-questionPractice-matematicas-demo-mathematics-subtopic',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Pregunta 1 de 2'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Buscar contenido'), findsOneWidget);
    expect(find.text('1 resultado'), findsOneWidget);
  });

  testWidgets('guarda y abre una lección favorita', (tester) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Comenzar'));
    await tester.tap(find.text('Comenzar'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('student-demo-button')));
    await tester.tap(find.byKey(const Key('student-demo-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Estudiar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('study-area-matematicas')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('study-subtopic-demo-mathematics-subtopic')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('toggle-lesson-favorite')));
    await tester.pumpAndSettle();
    expect(find.text('Lección agregada a favoritos.'), findsOneWidget);
    expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);

    await tester.tap(find.text('Más'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-favorites')));
    await tester.pumpAndSettle();
    expect(find.text('Mis favoritos'), findsOneWidget);
    expect(
      find.byKey(const Key('favorite-demo-mathematics-subtopic')),
      findsOneWidget,
    );
    expect(find.text('Regla de tres'), findsOneWidget);
  });

  testWidgets('abre la colección de preguntas difíciles', (tester) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Comenzar'));
    await tester.tap(find.text('Comenzar'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('student-demo-button')));
    await tester.tap(find.byKey(const Key('student-demo-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Más'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-difficult-questions')));
    await tester.pumpAndSettle();

    expect(find.text('Preguntas difíciles'), findsOneWidget);
    expect(find.text('No has marcado preguntas difíciles'), findsOneWidget);
    expect(find.text('Ir a practicar'), findsOneWidget);
  });

  testWidgets('muestra el tiempo total estudiado por actividad', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Comenzar'));
    await tester.tap(find.text('Comenzar'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('student-demo-button')));
    await tester.tap(find.byKey(const Key('student-demo-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Más'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-study-time')));
    await tester.pumpAndSettle();

    expect(find.text('Tiempo estudiado'), findsOneWidget);
    expect(find.byKey(const Key('study-time-total')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('study-time-total'))).data,
      '1 h 45 min',
    );
    expect(find.text('Pomodoro'), findsOneWidget);
    expect(find.text('Prácticas y simulacros'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('study-time-source-diagnostic')),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Diagnóstico'), findsOneWidget);
  });

  testWidgets('continúa desde Inicio en la última lección visitada', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Comenzar'));
    await tester.tap(find.text('Comenzar'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('student-demo-button')));
    await tester.tap(find.byKey(const Key('student-demo-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('continue-last-lesson')), findsNothing);

    await tester.tap(find.text('Estudiar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('study-area-matematicas')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('study-subtopic-demo-mathematics-subtopic')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Inicio'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('continue-last-lesson')), findsOneWidget);
    expect(find.text('CONTINÚA DONDE QUEDASTE'), findsOneWidget);
    expect(find.text('Regla de tres'), findsOneWidget);

    await tester.tap(find.byKey(const Key('continue-last-lesson')));
    await tester.pumpAndSettle();
    expect(find.text('Lección'), findsOneWidget);
    expect(find.text('Regla de tres'), findsWidgets);
  });

  testWidgets('mantiene el Pomodoro entre una lección y su práctica', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Comenzar'));
    await tester.tap(find.text('Comenzar'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('student-demo-button')));
    await tester.tap(find.byKey(const Key('student-demo-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Estudiar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('study-area-matematicas')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('study-subtopic-demo-mathematics-subtopic')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pomodoro-card')), findsOneWidget);
    expect(find.text('25:00'), findsOneWidget);
    await tester.tap(find.byKey(const Key('pomodoro-toggle')));
    await tester.pump();
    expect(find.byTooltip('Pausar Pomodoro'), findsOneWidget);
    await tester.tap(find.byKey(const Key('pomodoro-toggle')));
    await tester.pump();
    expect(find.byTooltip('Continuar Pomodoro'), findsOneWidget);

    await tester.drag(find.byType(ListView).last, const Offset(0, -650));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('start-subtopic-practice-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pomodoro-card')), findsOneWidget);
    expect(find.byTooltip('Continuar Pomodoro'), findsOneWidget);

    await tester.tap(find.byKey(const Key('pomodoro-reset')));
    await tester.pump();
    expect(find.text('25:00'), findsOneWidget);
    expect(find.byTooltip('Iniciar Pomodoro'), findsOneWidget);
  });
}

class _FakePracticeDraftStore extends PracticeDraftStore {
  _FakePracticeDraftStore() : super(const FlutterSecureStorage());

  @override
  Future<PracticeDraft?> read(String userId, String draftId) async => null;

  @override
  Future<void> save(String userId, String draftId, PracticeDraft draft) async {}

  @override
  Future<void> clear(String userId, String draftId) async {}
}

class _FakePreferencesStore implements AppPreferencesStore {
  AppPreferences value = const AppPreferences();

  @override
  Future<AppPreferences> load() async => value;

  @override
  Future<void> save(AppPreferences preferences) async {
    value = preferences;
  }
}

class _FakeReminderService implements StudyReminderService {
  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> scheduleDaily({required int hour, required int minute}) async {}

  @override
  Future<void> cancel() async {}
}

class _FakeAnswerStreakFeedback implements AnswerStreakFeedback {
  @override
  Future<void> play() async {}
}

class _FakeFavoriteRepository implements FavoriteRepository {
  final List<AcademicFavorite> _items = [];
  final StreamController<void> _changes = StreamController.broadcast();

  @override
  Stream<List<AcademicFavorite>> watchAll(String userId) async* {
    yield _forUser(userId);
    yield* _changes.stream.map((_) => _forUser(userId));
  }

  @override
  Stream<bool> watchContains(String userId, FavoriteIdentity identity) async* {
    yield _contains(userId, identity);
    yield* _changes.stream.map((_) => _contains(userId, identity));
  }

  @override
  Future<bool> toggle(AcademicFavorite favorite) async {
    final index = _items.indexWhere(
      (item) =>
          item.userId == favorite.userId && item.identity == favorite.identity,
    );
    if (index >= 0) {
      _items.removeAt(index);
      _changes.add(null);
      return false;
    }
    _items.add(favorite);
    _changes.add(null);
    return true;
  }

  @override
  Future<void> remove(String userId, FavoriteIdentity identity) async {
    _items.removeWhere(
      (item) => item.userId == userId && item.identity == identity,
    );
    _changes.add(null);
  }

  List<AcademicFavorite> _forUser(String userId) =>
      _items.where((item) => item.userId == userId).toList(growable: false);

  bool _contains(String userId, FavoriteIdentity identity) =>
      _items.any((item) => item.userId == userId && item.identity == identity);

  void dispose() => _changes.close();
}

class _FakeLearningResumeRepository implements LearningResumeRepository {
  final Map<String, LearningResume> _entries = {};
  final StreamController<void> _changes = StreamController.broadcast();

  @override
  Stream<LearningResume?> watch(String userId) async* {
    yield _entries[userId];
    yield* _changes.stream.map((_) => _entries[userId]);
  }

  @override
  Future<void> save(LearningResume entry) async {
    _entries[entry.userId] = entry;
    _changes.add(null);
  }

  @override
  Future<void> clear(String userId) async {
    _entries.remove(userId);
    _changes.add(null);
  }

  void dispose() => _changes.close();
}

class _FakeDifficultQuestionRepository implements DifficultQuestionRepository {
  final Map<String, DifficultQuestionMark> _items = {};
  final StreamController<void> _changes = StreamController.broadcast();

  @override
  Stream<List<DifficultQuestionMark>> watchAll(String userId) async* {
    yield _forUser(userId);
    yield* _changes.stream.map((_) => _forUser(userId));
  }

  @override
  Stream<bool> watchContains(String userId, String questionId) async* {
    yield _items.containsKey('$userId:$questionId');
    yield* _changes.stream.map(
      (_) => _items.containsKey('$userId:$questionId'),
    );
  }

  @override
  Future<bool> toggle(DifficultQuestionMark mark) async {
    final key = '${mark.userId}:${mark.questionId}';
    if (_items.remove(key) != null) {
      _changes.add(null);
      return false;
    }
    _items[key] = mark;
    _changes.add(null);
    return true;
  }

  @override
  Future<void> remove(String userId, String questionId) async {
    _items.remove('$userId:$questionId');
    _changes.add(null);
  }

  List<DifficultQuestionMark> _forUser(String userId) => _items.values
      .where((item) => item.userId == userId)
      .toList(growable: false);

  void dispose() => _changes.close();
}
