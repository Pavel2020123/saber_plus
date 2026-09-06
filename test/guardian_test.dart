import 'dart:io';
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/core/feedback/game_audio_feedback.dart';
import 'package:saber_plus/core/network/api_error.dart';
import 'package:saber_plus/features/academic/domain/academic_models.dart';
import 'package:saber_plus/features/auth/domain/session.dart';
import 'package:saber_plus/features/auth/presentation/session_controller.dart';
import 'package:saber_plus/features/games/guardian/data/demo_guardian_repository.dart';
import 'package:saber_plus/features/games/guardian/data/guardian_repository.dart';
import 'package:saber_plus/features/games/guardian/domain/guardian_models.dart';
import 'package:saber_plus/features/games/guardian/presentation/guardian_page.dart';
import 'package:saber_plus/features/games/guardian/presentation/guardian_scene.dart';
import 'package:saber_plus/features/practice/domain/practice_models.dart';

const _config = GuardianConfig(
  area: AcademicArea.mathematics,
  difficulty: PracticeDifficulty.medium,
);

void main() {
  test('six correct answers win; demo never grants academic XP', () async {
    final repository = DemoGuardianRepository();
    var attempt = await repository.start(_config);
    for (var i = 0; i < 6; i++) {
      final question = attempt.question!;
      attempt = await repository.answer(
        id: attempt.id,
        questionId: question.id,
        answerId: question.options.first.id,
        idempotencyKey: 'key-$i',
      );
    }
    expect(attempt.status, GuardianStatus.victory);
    expect(attempt.correct, 6);
    expect(attempt.energy, 0);
    expect(attempt.shield, 3);
    expect(attempt.question, isNull);
    expect(await repository.active(), isNull);
    expect(attempt.review.every((r) => r.explanation!.isNotEmpty), isTrue);
  });

  test(
    'three wrong answers close the game and identify review subtopics',
    () async {
      final repository = DemoGuardianRepository();
      var attempt = await repository.start(_config);
      for (var i = 0; i < 3; i++) {
        final q = attempt.question!;
        attempt = await repository.answer(
          id: attempt.id,
          questionId: q.id,
          answerId: q.options.last.id,
          idempotencyKey: 'wrong-$i',
        );
      }
      expect(attempt.status, GuardianStatus.defeat);
      expect(attempt.shield, 0);
      expect(attempt.toReinforce.length, 3);
      expect(attempt.toReinforce.first.question.subtopicName, isNotEmpty);
      expect(attempt.toReinforce.first.correctText, isNotEmpty);
    },
  );

  test(
    'demo retries are idempotent and keys cannot be reused for a new answer',
    () async {
      final repository = DemoGuardianRepository();
      final attempt = await repository.start(_config);
      final q = attempt.question!;
      Future<GuardianAttempt> send(String answer) => repository.answer(
        id: attempt.id,
        questionId: q.id,
        answerId: answer,
        idempotencyKey: 'same-key',
      );
      await send(q.options.first.id);
      expect((await send(q.options.first.id)).review.length, 1);
      await expectLater(send(q.options.last.id), throwsA(isA<ApiError>()));
      final closed = await repository.abandon(attempt.id);
      expect(closed.status, GuardianStatus.abandoned);
      expect(closed.question, isNull);
      expect((await repository.get(attempt.id)).review.length, 1);
    },
  );

  test(
    'remote sends only choice and supplied idempotency key, never scores',
    () async {
      late RequestOptions request;
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            request = options;
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: _response(),
              ),
            );
          },
        ),
      );
      final repository = RemoteGuardianRepository(dio);
      await repository.start(_config);
      expect(request.data, {'area': 'MATEMATICAS', 'dificultad': 'MEDIO'});
      final attempt = await repository.answer(
        id: 'attempt',
        questionId: 'q1',
        answerId: 'a1',
        idempotencyKey: 'stable-key',
      );
      expect(request.path, '/guardian/intentos/attempt/respuestas');
      expect(request.data, {
        'preguntaId': 'q1',
        'respuestaId': 'a1',
        'idempotencyKey': 'stable-key',
      });
      expect(attempt.question!.options.length, 2);
      expect(
        attempt.question!.toJson().toString(),
        isNot(contains('esCorrecta')),
      );
    },
  );

  test('remote handles no saved game and rejects incompatible rules', () async {
    final dio = Dio();
    Object? body;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) => handler.resolve(
          Response(requestOptions: options, data: body, statusCode: 200),
        ),
      ),
    );
    final repository = RemoteGuardianRepository(dio);
    expect(await repository.active(), isNull);
    body = {
      ..._response(),
      'reglas': {'version': 2},
    };
    await expectLater(repository.get('attempt'), throwsFormatException);
  });

  testWidgets(
    'resumes a game and retries a lost acknowledgment with the same key',
    (tester) async {
      tester.view.physicalSize = const Size(430, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = _LostAcknowledgmentRepository();
      final initial = await repository.start(_config);
      await tester.pumpWidget(_app(repository));
      await tester.pump();
      final option = find.byKey(
        ValueKey('guardian-option-${initial.question!.options.first.id}'),
      );
      await tester.ensureVisible(option);
      await tester.tap(option);
      await tester.pump();
      final submit = find.byKey(const Key('guardian-answer'));
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pump();
      expect(repository.keys.length, 1);
      await tester.scrollUntilVisible(
        find.textContaining('Tu envío se conserva'),
        -300,
      );
      expect(find.textContaining('Tu envío se conserva'), findsOneWidget);
      await tester.scrollUntilVisible(submit, 300);
      await tester.tap(submit);
      await tester.pump();
      expect(repository.keys.length, 2);
      expect(repository.keys.first, repository.keys.last);
      expect((await repository.get(initial.id)).review.length, 1);
      expect(
        find.text('¡Acierto! El guardián pierde energía.'),
        findsOneWidget,
      );
      final next = find.byKey(const Key('guardian-next'));
      await tester.ensureVisible(next);
      await tester.tap(next);
      await tester.pump();
      expect(find.textContaining('Pregunta 2 ·'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('small dark screen with enlarged text can configure and start', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_app(DemoGuardianRepository(), small: true));
    await tester.pump();
    await tester.pump();
    final start = find.byKey(const Key('guardian-start'));
    await tester.scrollUntilVisible(start, 300);
    await tester.tap(start);
    await tester.pump();
    await tester.scrollUntilVisible(find.textContaining('Pregunta 1 ·'), 300);
    expect(find.textContaining('Pregunta 1 ·'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('guardian pauses outside foreground and for reduced motion', (
    tester,
  ) async {
    Widget app({bool reduced = false}) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduced),
        child: const GuardianScene(),
      ),
    );
    double phase() =>
        (tester
                    .widget<CustomPaint>(
                      find.byKey(const Key('guardian-scene')),
                    )
                    .painter!
                as GuardianPainter)
            .phase;
    await tester.pumpWidget(app());
    await tester.pump(const Duration(milliseconds: 450));
    final moving = phase();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 1));
    expect(phase(), moving);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(app(reduced: true));
    final reduced = phase();
    await tester.pump(const Duration(seconds: 1));
    expect(phase(), reduced);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('optional guardian raster inspection', (tester) async {
    if (!const bool.fromEnvironment('CAPTURE_GAME_VISUALS')) return;
    final boundary = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: RepaintBoundary(
              key: boundary,
              child: const MediaQuery(
                data: MediaQueryData(disableAnimations: true),
                child: SizedBox(width: 340, child: GuardianScene()),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 350));
    final render =
        boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final raster = await render.toImage(pixelRatio: 3);
      final bytes = await raster.toByteData(format: ui.ImageByteFormat.png);
      final output = File('build/test-artifacts/guardian-preview.png');
      await output.parent.create(recursive: true);
      await output.writeAsBytes(bytes!.buffer.asUint8List());
      raster.dispose();
    });
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

Widget _app(GuardianRepository repository, {bool small = false}) =>
    ProviderScope(
      overrides: [
        guardianRepositoryProvider.overrideWithValue(repository),
        sessionControllerProvider.overrideWith(_DemoSession.new),
        gameAudioFeedbackProvider.overrideWithValue(_SilentAudio()),
      ],
      child: MaterialApp(
        theme: small ? ThemeData.dark() : ThemeData.light(),
        home: MediaQuery(
          data: MediaQueryData(
            disableAnimations: true,
            textScaler: TextScaler.linear(small ? 1.5 : 1),
          ),
          child: const GuardianPage(),
        ),
      ),
    );

class _DemoSession extends SessionController {
  @override
  SessionState build() => const SessionState.authenticated(
    UserSession(
      id: 'demo-guardian',
      firstName: 'Demo',
      role: AppRole.student,
      isDemo: true,
    ),
  );
}

class _SilentAudio implements GameAudioFeedback {
  @override
  Future<void> play(GameSound sound) async {}
}

class _LostAcknowledgmentRepository extends DemoGuardianRepository {
  final keys = <String>[];
  @override
  Future<GuardianAttempt> answer({
    required String id,
    required String questionId,
    required String answerId,
    required String idempotencyKey,
  }) async {
    keys.add(idempotencyKey);
    final result = await super.answer(
      id: id,
      questionId: questionId,
      answerId: answerId,
      idempotencyKey: idempotencyKey,
    );
    if (keys.length == 1) {
      throw const ApiError(
        code: 'network_timeout',
        message: 'Conexión interrumpida.',
      );
    }
    return result;
  }
}

Map<String, dynamic> _response() => {
  'id': 'attempt',
  'area': 'MATEMATICAS',
  'dificultad': 'MEDIO',
  'estado': 'ACTIVO',
  'venceEn': '2026-09-06T12:00:00Z',
  'reglas': {'version': 1, 'questions': 8, 'target': 6, 'shields': 3},
  'revision': <Object>[],
  'pregunta': {
    'id': 'q1',
    'enunciado': '¿Cuánto es 2 + 2?',
    'respuestas': [
      {'id': 'a1', 'texto': '4'},
      {'id': 'a2', 'texto': '5'},
    ],
    'subtema': {
      'id': 's1',
      'nombre': 'Suma',
      'tema': {'nombre': 'Aritmética', 'area': 'MATEMATICAS'},
    },
  },
};
