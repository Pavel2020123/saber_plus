import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/core/network/api_error.dart';
import 'package:saber_plus/features/auth/domain/session.dart';
import 'package:saber_plus/features/auth/presentation/session_controller.dart';
import 'package:saber_plus/features/profile/data/remote_vocational_orientation_repository.dart';
import 'package:saber_plus/features/profile/domain/vocational_orientation.dart';
import 'package:saber_plus/features/profile/domain/vocational_orientation_repository.dart';
import 'package:saber_plus/features/profile/presentation/sabi_profession_gallery.dart';
import 'package:saber_plus/features/profile/presentation/sabi_profession_illustration.dart';
import 'package:saber_plus/features/profile/presentation/vocational_orientation_page.dart';
import 'package:saber_plus/features/profile/presentation/vocational_orientation_providers.dart';

const _id1 = '00000000-0000-4000-8000-000000000001';
const _id2 = '00000000-0000-4000-8000-000000000002';
const _time = '2026-10-14T12:00:00.000Z';
const _prefixes = ['T', 'S', 'C', 'N', 'H', 'D'];

List<Map<String, Object>> _questions() => [
  for (var f = 0; f < 6; f++)
    for (var n = 1; n <= 5; n++)
      {
        'id': '${_prefixes[f]}$n',
        'texto': 'Actividad ${_prefixes[f]}$n',
        'familia': vocationalFamilyNames.keys.elementAt(f),
      },
];

Map<String, Object> _questionnaire() => {
  'rulesVersion': 1,
  'naturaleza': 'INTERESES_DECLARADOS',
  'escala': [0, 1, 2, 3, 4, 'NO_SE'],
  'preguntas': _questions(),
};

Map<String, Object> _result({List<String>? main}) => {
  'ov1RulesVersion': 1,
  'naturaleza': 'INTERESES_DECLARADOS',
  'finalizable': true,
  'cantidadValidas': 30,
  'totalPreguntas': 30,
  'familias': [
    for (final family in vocationalFamilyNames.keys)
      {
        'familia': family,
        'cantidadValidas': 5,
        'totalPreguntas': 5,
        'puntaje': 80,
      },
  ],
  'principales': main ?? vocationalFamilyNames.keys.take(4).toList(),
  'completadoEn': _time,
  'preguntas': _questions(),
  'respuestas': [
    for (final question in _questions())
      {'preguntaId': question['id']!, 'valor': 4},
  ],
};

Map<String, Object?> _attempt({
  String id = _id1,
  bool completed = false,
  List<Map<String, Object>> answers = const [],
  Map<String, Object>? result,
}) => {
  'id': id,
  'rulesVersion': 1,
  'estado': completed ? 'COMPLETADO' : 'EN_PROGRESO',
  'iniciadoEn': _time,
  'actualizadoEn': _time,
  'completadoEn': completed ? _time : null,
  'respuestas': completed && answers.isEmpty
      ? (result ?? _result())['respuestas']
      : answers,
  'resultado': completed ? (result ?? _result()) : null,
};

class _StudentSession extends SessionController {
  @override
  SessionState build() => const SessionState.authenticated(
    UserSession(id: 'student', firstName: 'Ana', role: AppRole.student),
  );

  void switchStudent() {
    state = const SessionState.authenticated(
      UserSession(
        id: 'other-student',
        firstName: 'Luis',
        role: AppRole.student,
      ),
    );
  }
}

class _DemoSession extends SessionController {
  @override
  SessionState build() => const SessionState.authenticated(
    UserSession(
      id: 'demo-student',
      firstName: 'Ana',
      role: AppRole.student,
      isDemo: true,
    ),
  );
}

class _MemoryVocationalRepository implements VocationalOrientationRepository {
  VocationalAttempt? active;
  final stored = <String, VocationalAttempt>{};
  int questionnaireCalls = 0, currentCalls = 0, startCalls = 0;
  int finishCalls = 0, saveCalls = 0;
  bool failNextSave = false;
  bool insufficient = false;
  bool failLoad = false;
  bool failCurrent = false;
  bool failFinish = false;
  bool failOpen = false;
  bool failDelete = false;
  int? failHistoryPage;
  final historyPages = <int>[];
  Completer<void>? saveGate;

  @override
  Future<VocationalQuestionnaire> questionnaire() async {
    questionnaireCalls++;
    if (failLoad) {
      throw const ApiError(
        code: 'network_unavailable',
        message: 'Red no disponible.',
      );
    }
    return VocationalQuestionnaire.parse(_questionnaire());
  }

  @override
  Future<VocationalAttempt?> current() async {
    currentCalls++;
    if (failCurrent) {
      throw const ApiError(
        code: 'network_timeout',
        message: 'Tiempo de espera agotado.',
      );
    }
    return active;
  }

  @override
  Future<VocationalAttempt> start() async {
    startCalls++;
    final existing = active;
    if (existing != null) return existing;
    final id = stored.containsKey(_id1) ? _id2 : _id1;
    final created = VocationalAttempt.parse(_attempt(id: id));
    active = created;
    stored[id] = created;
    return created;
  }

  @override
  Future<VocationalAttempt> saveAnswer(
    String attemptId,
    String questionId,
    VocationalAnswer answer,
  ) async {
    saveCalls++;
    await saveGate?.future;
    if (failNextSave) {
      failNextSave = false;
      throw const ApiError(
        code: 'network_unavailable',
        message: 'Red no disponible.',
      );
    }
    final old = stored[attemptId]!;
    final values = {
      for (final entry in old.answers.entries) entry.key: entry.value.wireValue,
      questionId: answer.wireValue,
    };
    final updated = VocationalAttempt.parse(
      _attempt(
        id: attemptId,
        answers: [
          for (final entry in values.entries)
            {'preguntaId': entry.key, 'valor': entry.value},
        ],
      ),
    );
    stored[attemptId] = updated;
    active = updated;
    return updated;
  }

  @override
  Future<VocationalAttempt> finish(String attemptId) async {
    finishCalls++;
    if (failFinish) {
      throw const ApiError(
        code: 'network_unavailable',
        message: 'Red no disponible.',
      );
    }
    if (insufficient) {
      throw const ApiError(
        code: 'COBERTURA_INSUFICIENTE',
        message: 'Insuficiente',
      );
    }
    final completed = VocationalAttempt.parse(
      _attempt(
        id: attemptId,
        completed: true,
        answers: [
          for (final question in _questions())
            {'preguntaId': question['id']!, 'valor': 4},
        ],
      ),
    );
    stored[attemptId] = completed;
    active = null;
    return completed;
  }

  @override
  Future<VocationalHistory> history(int page) async {
    historyPages.add(page);
    if (failHistoryPage == page) {
      throw const ApiError(
        code: 'network_timeout',
        message: 'Tiempo de espera agotado.',
      );
    }
    return VocationalHistory.parse({
      'pagina': page,
      'porPagina': 20,
      'total': stored.length,
      'intentos': [
        for (final entry in stored.values.skip((page - 1) * 20).take(20))
          _attempt(
            id: entry.id,
            completed: entry.completed,
            answers: [
              for (final answer in entry.answers.entries)
                {'preguntaId': answer.key, 'valor': answer.value.wireValue},
            ],
          ),
      ],
    });
  }

  @override
  Future<VocationalAttempt> getAttempt(String attemptId) async {
    if (failOpen) {
      throw const ApiError(
        code: 'network_unavailable',
        message: 'Red no disponible.',
      );
    }
    return stored[attemptId]!;
  }

  @override
  Future<void> deleteAttempt(String attemptId) async {
    if (failDelete) {
      throw const ApiError(
        code: 'network_unavailable',
        message: 'Red no disponible.',
      );
    }
    stored.remove(attemptId);
    if (active?.id == attemptId) active = null;
  }
}

Widget _app(_MemoryVocationalRepository repository, {bool demo = false}) =>
    ProviderScope(
      overrides: [
        sessionControllerProvider.overrideWith(
          demo ? _DemoSession.new : _StudentSession.new,
        ),
        vocationalOrientationRepositoryProvider.overrideWithValue(repository),
        vocationalOfficialLinkOpenerProvider.overrideWithValue(
          (_) async => true,
        ),
      ],
      child: const MaterialApp(home: VocationalOrientationPage()),
    );

Future<void> _tapVisible(WidgetTester tester, String key) async {
  final finder = find.byKey(Key(key));
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      250,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  group('OV-1D3D-F1 local API dates', () {
    test(
      'UTC dates become local without changing instants or terminal validation',
      () {
        const started = '2026-10-27T04:00:00.123456Z';
        const updated = '2026-10-27T04:04:21.654321Z';
        const completed = '2026-10-27T04:05:00.987654Z';
        final payload = {
          ..._attempt(completed: true),
          'iniciadoEn': started,
          'actualizadoEn': updated,
          'completadoEn': completed,
          'resultado': {..._result(), 'completadoEn': completed},
        };
        final attempt = VocationalAttempt.parse(payload);
        void expectLocalInstant(DateTime actual, String original) {
          final utc = DateTime.parse(original).toUtc();
          expect(actual.isUtc, isFalse);
          expect(actual.isAtSameMomentAs(utc), isTrue);
          expect(actual.toUtc(), utc);
          expect(actual.microsecondsSinceEpoch, utc.microsecondsSinceEpoch);
          expect(actual, utc.toLocal());
        }

        expectLocalInstant(attempt.startedAt, started);
        expectLocalInstant(attempt.updatedAt, updated);
        expectLocalInstant(attempt.completedAt!, completed);
        expectLocalInstant(attempt.result!.completedAt, completed);
        expect(attempt.result!.completedAt, attempt.completedAt);
        final equivalent = VocationalAttempt.parse({
          ...payload,
          'resultado': {
            ..._result(),
            'completadoEn': '2026-10-26T23:05:00.987654-05:00',
          },
        });
        expect(equivalent.result!.completedAt, equivalent.completedAt);
        expect(
          () => VocationalAttempt.parse({
            ...payload,
            'resultado': {
              ..._result(),
              'completadoEn': '2026-10-27T04:05:00.987655Z',
            },
          }),
          throwsFormatException,
        );
        final active = VocationalAttempt.parse({
          ..._attempt(),
          'iniciadoEn': started,
          'actualizadoEn': updated,
        });
        expectLocalInstant(active.startedAt, started);
        expectLocalInstant(active.updatedAt, updated);
        expect(active.completedAt, isNull);
        expect(active.result, isNull);
      },
    );

    testWidgets('history text and semantics use the local model date', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        final repo = _MemoryVocationalRepository();
        repo.stored[_id1] = VocationalAttempt.parse(_attempt(completed: true));
        await tester.pumpWidget(_app(repo));
        await tester.pumpAndSettle();
        await _tapVisible(tester, 'vocational-open-history');
        final local = DateTime.parse(_time).toLocal();
        final date = '${local.day}/${local.month}/${local.year}';
        expect(find.text(date), findsOneWidget);
        expect(
          find.bySemanticsLabel('Abrir exploración completada del $date'),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel('Eliminar exploración completada del $date'),
          findsOneWidget,
        );
      } finally {
        semantics.dispose();
      }
    });
  });

  group('OV-1B strict contract', () {
    test(
      'questionnaire parses 30 server questions and the exact 0..4 + NO_SE scale',
      () {
        final catalog = VocationalQuestionnaire.parse(_questionnaire());
        expect(catalog.questions, hasLength(30));
        expect(catalog.version, 1);
        expect(VocationalAnswer.values.map((a) => a.wireValue), [
          0,
          1,
          2,
          3,
          4,
          'NO_SE',
        ]);
        expect(catalog.questions.first.text, 'Actividad T1');
        expect(catalog.questions.last.id, 'D5');
      },
    );
    test(
      'rejects altered scale, missing or duplicate questions, unknown family',
      () {
        expect(
          () => VocationalQuestionnaire.parse({
            ..._questionnaire(),
            'escala': [0, 1, 2, 3, 4],
          }),
          throwsFormatException,
        );
        expect(
          () => VocationalQuestionnaire.parse({
            ..._questionnaire(),
            'preguntas': _questions().take(29).toList(),
          }),
          throwsFormatException,
        );
        expect(
          () => VocationalQuestionnaire.parse({
            ..._questionnaire(),
            'preguntas': [..._questions().take(29), _questions().first],
          }),
          throwsFormatException,
        );
        expect(
          () => VocationalQuestionnaire.parse({
            ..._questionnaire(),
            'rulesVersion': 2,
          }),
          throwsFormatException,
        );
      },
    );
    test(
      'NO_SE stays distinct from zero; numeric strings and invalid values fail',
      () {
        final parsed = VocationalAttempt.parse(
          _attempt(
            answers: [
              {'preguntaId': 'T1', 'valor': 'NO_SE'},
              {'preguntaId': 'T2', 'valor': 0},
            ],
          ),
        );
        expect(parsed.answers['T1'], VocationalAnswer.unsure);
        expect(parsed.answers['T2'], VocationalAnswer.none);
        for (final invalid in ['4', 5, -1, 1.5, null]) {
          expect(() => VocationalAnswer.parse(invalid), throwsFormatException);
        }
        expect(
          () => VocationalAttempt.parse(
            _attempt(
              answers: [
                {'preguntaId': 'T1', 'valor': 4},
                {'preguntaId': 'T1', 'valor': 3},
              ],
            ),
          ),
          throwsFormatException,
        );
      },
    );
    test(
      'server snapshot preserves all four tied families without sorting',
      () {
        final main = [
          vocationalFamilyNames.keys.elementAt(2),
          vocationalFamilyNames.keys.elementAt(0),
          vocationalFamilyNames.keys.elementAt(1),
          vocationalFamilyNames.keys.elementAt(3),
        ];
        final result = VocationalResult.parse(_result(main: main));
        expect(result.mainFamilies, main);
        expect(result.mainFamilies, hasLength(4));
        expect(result.families.first.score, 80);
        expect(
          () => VocationalResult.parse({
            ..._result(),
            'principales': ['INVALID'],
          }),
          throwsFormatException,
        );
      },
    );
    test('terminal parser does not reapply server coverage policy', () {
      final questions = _questions();
      final snapshot = {
        ..._result(),
        'cantidadValidas': 23,
        'familias': [
          for (var i = 0; i < vocationalFamilyNames.length; i++)
            {
              'familia': vocationalFamilyNames.keys.elementAt(i),
              'cantidadValidas': i < 4 ? 5 : (i == 4 ? 3 : 0),
              'totalPreguntas': 5,
              'puntaje': i == 5 ? 0 : 80,
            },
        ],
        'respuestas': [
          for (var i = 0; i < questions.length; i++)
            {'preguntaId': questions[i]['id']!, 'valor': i < 23 ? 4 : 'NO_SE'},
        ],
      };
      final parsed = VocationalResult.parse(snapshot);
      expect(parsed.validCount, 23);
      expect(parsed.families.last.validCount, 0);
      expect(parsed.mainFamilies, _result()['principales']);
    });
    test(
      'active attempt rejects fabricated final result and incompatible version',
      () {
        expect(
          () =>
              VocationalAttempt.parse({..._attempt(), 'resultado': _result()}),
          throwsFormatException,
        );
        expect(
          () => VocationalAttempt.parse({..._attempt(), 'rulesVersion': 2}),
          throwsFormatException,
        );
        expect(parseCurrentVocationalAttempt({'intento': null}), isNull);
        expect(() => parseCurrentVocationalAttempt({}), throwsFormatException);
        expect(
          () => VocationalAttempt.parse({..._attempt()}..remove('resultado')),
          throwsFormatException,
        );
        expect(
          () => parseCurrentVocationalAttempt({
            'intento': _attempt(completed: true),
          }),
          throwsFormatException,
        );
      },
    );
  });

  group('authenticated Dio repository', () {
    test(
      'uses exact endpoints/payloads, with no userId or client scores',
      () async {
        final calls = <RequestOptions>[];
        final dio = Dio(BaseOptions(baseUrl: 'https://example.invalid'));
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              calls.add(options);
              final data = switch (options.path) {
                '/orientacion-vocacional/cuestionario' => _questionnaire(),
                '/orientacion-vocacional' => {'intento': null},
                '/orientacion-vocacional/historial' => {
                  'pagina': 1,
                  'porPagina': 20,
                  'total': 0,
                  'intentos': [],
                },
                _ => _attempt(
                  answers: [
                    {'preguntaId': 'T1', 'valor': 'NO_SE'},
                  ],
                ),
              };
              handler.resolve(Response(requestOptions: options, data: data));
            },
          ),
        );
        final repo = RemoteVocationalOrientationRepository(dio);
        expect((await repo.questionnaire()).questions, hasLength(30));
        expect(await repo.current(), isNull);
        expect((await repo.start()).id, _id1);
        expect(
          (await repo.saveAnswer(
            _id1,
            'T1',
            VocationalAnswer.unsure,
          )).answers['T1'],
          VocationalAnswer.unsure,
        );
        await repo.finish(_id1);
        await repo.history(1);
        await repo.getAttempt(_id1);
        await repo.deleteAttempt(_id1);
        expect(calls.map((c) => c.path), [
          '/orientacion-vocacional/cuestionario',
          '/orientacion-vocacional',
          '/orientacion-vocacional/intentos',
          '/orientacion-vocacional/intentos/$_id1/respuestas',
          '/orientacion-vocacional/intentos/$_id1/finalizar',
          '/orientacion-vocacional/historial',
          '/orientacion-vocacional/intentos/$_id1',
          '/orientacion-vocacional/intentos/$_id1',
        ]);
        expect(calls[3].data, {
          'respuestas': [
            {'preguntaId': 'T1', 'valor': 'NO_SE'},
          ],
        });
        expect(calls[2].data, isEmpty);
        expect(calls[4].data, isEmpty);
        expect(
          calls.map((c) => c.data.toString()).join(),
          isNot(contains('usuarioId')),
        );
        expect(calls[5].queryParameters, {'pagina': 1});
      },
    );
    test(
      'surfaces incompatible server contract as manageable ApiError',
      () async {
        final dio = Dio(BaseOptions(baseUrl: 'https://example.invalid'));
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              handler.resolve(
                Response(requestOptions: options, data: {'preguntas': []}),
              );
            },
          ),
        );
        await expectLater(
          RemoteVocationalOrientationRepository(dio).questionnaire(),
          throwsA(
            isA<ApiError>().having(
              (e) => e.code,
              'code',
              'invalid_vocational_response',
            ),
          ),
        );
      },
    );
    test('maps COBERTURA_INSUFICIENTE through ApiError', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.invalid'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(
              DioException(
                requestOptions: options,
                response: Response(
                  requestOptions: options,
                  statusCode: 409,
                  data: {'codigo': 'COBERTURA_INSUFICIENTE'},
                ),
              ),
            );
          },
        ),
      );
      await expectLater(
        RemoteVocationalOrientationRepository(dio).finish(_id1),
        throwsA(
          isA<ApiError>().having(
            (e) => e.code,
            'code',
            'COBERTURA_INSUFICIENTE',
          ),
        ),
      );
    });
  });

  group('OV-1C widget', () {
    testWidgets(
      'OV-1D3A gallery is optional, does not write answers, and stays out of questionnaire',
      (tester) async {
        final repo = _MemoryVocationalRepository();
        await tester.pumpWidget(_app(repo));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('vocational-start')), findsOneWidget);
        await _tapVisible(tester, 'sabi-gallery-toggle');
        await _tapVisible(tester, 'sabi-gallery-next');
        expect(
          tester
              .widget<SabiProfessionIllustration>(
                find.byType(SabiProfessionIllustration),
              )
              .profession,
          SabiProfession.nursing,
        );
        expect(repo.startCalls, 0);
        expect(repo.saveCalls, 0);
        expect(repo.finishCalls, 0);
        expect(repo.stored, isEmpty);
        tester
            .state<ScrollableState>(
              find
                  .descendant(
                    of: find.byKey(const Key('vocational-intro')),
                    matching: find.byType(Scrollable),
                  )
                  .first,
            )
            .position
            .jumpTo(0);
        await tester.pumpAndSettle();
        await _tapVisible(tester, 'vocational-start');
        expect(
          find.byKey(const Key('vocational-questionnaire')),
          findsOneWidget,
        );
        expect(find.byType(SabiProfessionGallery), findsNothing);
        expect(find.byType(SabiProfessionIllustration), findsNothing);
        expect(repo.active!.answers, isEmpty);
        expect(repo.startCalls, 1);
      },
    );

    testWidgets(
      'OV-1D3A gallery does not represent historical results or tied families',
      (tester) async {
        final repo = _MemoryVocationalRepository();
        final main = vocationalFamilyNames.keys
            .toList()
            .reversed
            .take(4)
            .toList();
        final terminal = VocationalAttempt.parse(
          _attempt(completed: true, result: _result(main: main)),
        );
        repo.stored[_id1] = terminal;
        await tester.pumpWidget(_app(repo));
        await tester.pumpAndSettle();
        await _tapVisible(tester, 'sabi-gallery-toggle');
        expect(
          tester
              .widget<SabiProfessionIllustration>(
                find.byType(SabiProfessionIllustration),
              )
              .profession,
          SabiProfession.medicine,
        );
        await _tapVisible(tester, 'vocational-open-history');
        expect(find.byType(SabiProfessionGallery), findsNothing);
        expect(find.byType(SabiProfessionIllustration), findsNothing);
        await _tapVisible(tester, 'vocational-history-$_id1');
        expect(find.byKey(const Key('vocational-result')), findsOneWidget);
        expect(find.byType(SabiProfessionGallery), findsNothing);
        // D3B adds editorial examples separately; the intro gallery stays absent.
        expect(find.byType(SabiProfessionIllustration), findsOneWidget);
        expect(
          find.byKey(Key('vocational-family-${main.first}')),
          findsOneWidget,
        );
        expect(repo.stored[_id1], same(terminal));
        expect(terminal.result!.mainFamilies, main);
        expect(terminal.result!.mainFamilies, hasLength(4));
        expect(repo.startCalls, 0);
        expect(repo.saveCalls, 0);
        expect(repo.finishCalls, 0);
      },
    );

    testWidgets('demo never creates invented attempts or calls repository', (
      tester,
    ) async {
      final repo = _MemoryVocationalRepository();
      await tester.pumpWidget(_app(repo, demo: true));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('vocational-demo-unavailable')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('vocational-start')), findsNothing);
      expect(repo.questionnaireCalls, 0);
      expect(repo.startCalls, 0);
    });
    testWidgets(
      'begins, saves, corrects, moves previous/next and resumes confirmed answers',
      (tester) async {
        final repo = _MemoryVocationalRepository();
        await tester.pumpWidget(_app(repo));
        await tester.pumpAndSettle();
        expect(repo.questionnaireCalls, 1);
        await _tapVisible(tester, 'vocational-start');
        expect(repo.startCalls, 1);
        expect(find.text('Pregunta 1 de 30'), findsWidgets);
        await _tapVisible(tester, 'vocational-answer-much');
        expect(repo.active!.answers['T1'], VocationalAnswer.much);
        await _tapVisible(tester, 'vocational-answer-little');
        expect(repo.active!.answers['T1'], VocationalAnswer.little);
        await _tapVisible(tester, 'vocational-next');
        await tester.drag(
          find.byKey(const Key('vocational-questionnaire')),
          const Offset(0, 1200),
        );
        await tester.pumpAndSettle();
        expect(find.text('Pregunta 2 de 30'), findsWidgets);
        await _tapVisible(tester, 'vocational-answer-unsure');
        expect(repo.active!.answers['T2'], VocationalAnswer.unsure);
        await _tapVisible(tester, 'vocational-previous');
        await tester.drag(
          find.byKey(const Key('vocational-questionnaire')),
          const Offset(0, 1200),
        );
        await tester.pumpAndSettle();
        expect(find.text('Pregunta 1 de 30'), findsWidgets);
        await _tapVisible(tester, 'vocational-exit');
        expect(find.text('Continuar'), findsOneWidget);
        await _tapVisible(tester, 'vocational-start');
        expect(repo.startCalls, 2);
        expect(repo.active!.answers['T1'], VocationalAnswer.little);
        expect(repo.active!.answers['T2'], VocationalAnswer.unsure);
        expect(find.text('Pregunta 3 de 30'), findsWidgets);
        await _tapVisible(tester, 'vocational-previous');
        await tester.drag(
          find.byKey(const Key('vocational-questionnaire')),
          const Offset(0, 1200),
        );
        await tester.pumpAndSettle();
        expect(find.text('Pregunta 2 de 30'), findsWidgets);
        await _tapVisible(tester, 'vocational-previous');
        await tester.drag(
          find.byKey(const Key('vocational-questionnaire')),
          const Offset(0, 1200),
        );
        await tester.pumpAndSettle();
        expect(find.text('Pregunta 1 de 30'), findsWidgets);
        expect(
          tester
              .widget<ListTile>(
                find.byKey(const Key('vocational-answer-little')),
              )
              .selected,
          isTrue,
        );
      },
    );
    testWidgets(
      'server coverage refusal keeps attempt editable; server result retains a tie of four',
      (tester) async {
        final repo = _MemoryVocationalRepository()..insufficient = true;
        await tester.pumpWidget(_app(repo));
        await tester.pumpAndSettle();
        await _tapVisible(tester, 'vocational-start');
        await _tapVisible(tester, 'vocational-finish');
        expect(
          find.textContaining('faltan respuestas numéricas'),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('vocational-questionnaire')),
          findsOneWidget,
        );
        expect(repo.active!.completed, false);
        await _tapVisible(tester, 'vocational-answer-much');
        repo.insufficient = false;
        await _tapVisible(tester, 'vocational-finish');
        expect(find.byKey(const Key('vocational-result')), findsOneWidget);
        await tester.scrollUntilVisible(
          find.byKey(
            Key('vocational-family-${vocationalFamilyNames.keys.elementAt(3)}'),
          ),
          250,
          scrollable: find
              .descendant(
                of: find.byKey(const Key('vocational-result')),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        expect(
          find.byKey(
            Key('vocational-family-${vocationalFamilyNames.keys.elementAt(3)}'),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(
            Key('vocational-family-${vocationalFamilyNames.keys.elementAt(4)}'),
          ),
          findsNothing,
        );
        await tester.scrollUntilVisible(
          find.byKey(
            Key(
              'vocational-other-family-${vocationalFamilyNames.keys.elementAt(4)}',
            ),
          ),
          250,
          scrollable: find
              .descendant(
                of: find.byKey(const Key('vocational-result')),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        expect(
          find.byKey(
            Key(
              'vocational-other-family-${vocationalFamilyNames.keys.elementAt(4)}',
            ),
          ),
          findsOneWidget,
        );
        expect(repo.finishCalls, 2);
        expect(find.textContaining('No miden aptitud'), findsOneWidget);
        expect(find.textContaining('índice de interés'), findsNothing);
        expect(find.textContaining('XP'), findsNothing);
        expect(find.textContaining('ranking'), findsNothing);
        expect(find.textContaining('certificado'), findsNothing);
      },
    );
    testWidgets('fully answered active attempt opens for review, not scoring', (
      tester,
    ) async {
      final repo = _MemoryVocationalRepository();
      final attempt = VocationalAttempt.parse(
        _attempt(
          answers: [
            for (final question in _questions())
              {'preguntaId': question['id']!, 'valor': 'NO_SE'},
          ],
        ),
      );
      repo.active = attempt;
      repo.stored[attempt.id] = attempt;
      await tester.pumpWidget(_app(repo));
      await tester.pumpAndSettle();
      await _tapVisible(tester, 'vocational-start');
      expect(find.text('Pregunta 30 de 30'), findsWidgets);
      expect(repo.finishCalls, 0);
      expect(repo.active!.completed, isFalse);
    });
    testWidgets(
      'network save error offers retry and preserves last confirmed response',
      (tester) async {
        final repo = _MemoryVocationalRepository();
        await tester.pumpWidget(_app(repo));
        await tester.pumpAndSettle();
        await _tapVisible(tester, 'vocational-start');
        await _tapVisible(tester, 'vocational-answer-little');
        repo.failNextSave = true;
        await _tapVisible(tester, 'vocational-answer-much');
        expect(find.byKey(const Key('vocational-retry-save')), findsOneWidget);
        expect(repo.active!.answers['T1'], VocationalAnswer.little);
        expect(
          tester
              .widget<ListTile>(
                find.byKey(const Key('vocational-answer-little')),
              )
              .selected,
          isTrue,
        );
        expect(
          tester
              .widget<ListTile>(find.byKey(const Key('vocational-answer-much')))
              .selected,
          isFalse,
        );
        await tester.scrollUntilVisible(
          find.text('Pendiente de guardar: Me interesa mucho'),
          200,
          scrollable: find
              .descendant(
                of: find.byKey(const Key('vocational-questionnaire')),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        expect(
          find.text('Pendiente de guardar: Me interesa mucho'),
          findsOneWidget,
        );
        await _tapVisible(tester, 'vocational-retry-save');
        expect(repo.active!.answers['T1'], VocationalAnswer.much);
        expect(find.byKey(const Key('vocational-retry-save')), findsNothing);
        expect(
          find.text('Pendiente de guardar: Me interesa mucho'),
          findsNothing,
        );
        expect(
          tester
              .widget<ListTile>(find.byKey(const Key('vocational-answer-much')))
              .selected,
          isTrue,
        );
        expect(repo.saveCalls, 3);
      },
    );
    testWidgets(
      'load error retries without fabricated data; history and repeat stay private',
      (tester) async {
        final repo = _MemoryVocationalRepository()..failLoad = true;
        await tester.pumpWidget(_app(repo));
        await tester.pumpAndSettle();
        expect(find.text('Red no disponible.'), findsOneWidget);
        repo.failLoad = false;
        await tester.tap(find.text('Reintentar'));
        await tester.pumpAndSettle();
        await _tapVisible(tester, 'vocational-start');
        await _tapVisible(tester, 'vocational-finish');
        expect(find.byKey(const Key('vocational-result')), findsOneWidget);
        await _tapVisible(tester, 'vocational-official-programs');
        expect(find.text('Consultar programas oficiales'), findsOneWidget);
        expect(
          find.textContaining('técnicas, tecnológicas y universitarias'),
          findsOneWidget,
        );
        await _tapVisible(tester, 'vocational-repeat');
        expect(repo.stored.length, 2);
        await _tapVisible(tester, 'vocational-exit');
        await _tapVisible(tester, 'vocational-open-history');
        expect(
          find.byKey(const Key('vocational-history-$_id1')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('vocational-history-$_id2')),
          findsOneWidget,
        );
        await _tapVisible(tester, 'vocational-history-$_id1');
        expect(find.byKey(const Key('vocational-result')), findsOneWidget);
        await _tapVisible(tester, 'vocational-repeat');
        await _tapVisible(tester, 'vocational-exit');
        await _tapVisible(tester, 'vocational-open-history');
        await _tapVisible(tester, 'vocational-delete-$_id1');
        await tester.tap(find.text('Eliminar'));
        await tester.pumpAndSettle();
        expect(repo.stored.containsKey(_id1), false);
      },
    );
    testWidgets('changing account clears the previous private result', (
      tester,
    ) async {
      final repo = _MemoryVocationalRepository();
      await tester.pumpWidget(_app(repo));
      await tester.pumpAndSettle();
      await _tapVisible(tester, 'vocational-start');
      await _tapVisible(tester, 'vocational-finish');
      expect(find.byKey(const Key('vocational-result')), findsOneWidget);

      repo.active = null;
      repo.stored.clear();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(VocationalOrientationPage)),
      );
      (container.read(sessionControllerProvider.notifier) as _StudentSession)
          .switchStudent();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('vocational-result')), findsNothing);
      expect(find.byKey(const Key('vocational-intro')), findsOneWidget);
      expect(find.text('Comenzar'), findsOneWidget);
    });
  });
  group('OV-1D3C controlled pending requests and recovery', () {
    testWidgets(
      'pending save blocks navigation, finish and exit until acknowledged; failure stays unconfirmed',
      (tester) async {
        final repo = _MemoryVocationalRepository();
        await tester.pumpWidget(_app(repo));
        await tester.pumpAndSettle();
        await _tapVisible(tester, 'vocational-start');
        await _tapVisible(tester, 'vocational-answer-little');
        await _tapVisible(tester, 'vocational-next');
        final gate = Completer<void>();
        repo.saveGate = gate;
        repo.failNextSave = true;
        final target = find.byKey(const Key('vocational-answer-much'));
        await tester.ensureVisible(target);
        await tester.tap(target);
        await tester
            .pump(); // Deliberately not pumpAndSettle: the request is outstanding.
        expect(gate.isCompleted, isFalse);
        expect(repo.active!.answers, {'T1': VocationalAnswer.little});
        expect(tester.widget<ListTile>(target).selected, isFalse);
        for (final key in [
          'vocational-previous',
          'vocational-next',
          'vocational-finish',
          'vocational-exit',
        ]) {
          final button = find.byKey(Key(key));
          // These controls follow all answer options, so build them without waiting for the spinner.
          final scrollable = find.byType(Scrollable).first;
          tester
              .state<ScrollableState>(scrollable)
              .position
              .jumpTo(
                tester
                    .state<ScrollableState>(scrollable)
                    .position
                    .maxScrollExtent,
              );
          await tester.pump();
          expect(tester.widget<ButtonStyleButton>(button).onPressed, isNull);
        }
        expect(repo.finishCalls, 0);
        gate.complete();
        await tester.pumpAndSettle();
        expect(
          find.textContaining('No se guardó esta respuesta'),
          findsOneWidget,
        );
        expect(repo.active!.answers.containsKey('T2'), isFalse);
        expect(
          tester
              .widget<ButtonStyleButton>(
                find.byKey(const Key('vocational-finish')),
              )
              .onPressed,
          isNull,
        );
        repo.saveGate = null;
        await _tapVisible(tester, 'vocational-retry-save');
        expect(repo.active!.answers, {
          'T1': VocationalAnswer.little,
          'T2': VocationalAnswer.much,
        });
        expect(
          tester
              .widget<ButtonStyleButton>(
                find.byKey(const Key('vocational-finish')),
              )
              .onPressed,
          isNotNull,
        );
        expect(repo.finishCalls, 0);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'an old save completion cannot repopulate the UI after account switch',
      (tester) async {
        final repo = _MemoryVocationalRepository();
        await tester.pumpWidget(_app(repo));
        await tester.pumpAndSettle();
        await _tapVisible(tester, 'vocational-start');
        final gate = Completer<void>();
        repo.saveGate = gate;
        await tester.tap(find.byKey(const Key('vocational-answer-much')));
        await tester.pump();
        final container = ProviderScope.containerOf(
          tester.element(find.byType(VocationalOrientationPage)),
        );
        repo.active = null; // The new account has no active attempt.
        (container.read(sessionControllerProvider.notifier) as _StudentSession)
            .switchStudent();
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('vocational-intro')), findsOneWidget);
        gate.complete();
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('vocational-questionnaire')), findsNothing);
        expect(find.byKey(const Key('vocational-result')), findsNothing);
        expect(
          find.byKey(const Key('vocational-pending-announcement')),
          findsNothing,
        );
        expect(find.text('Comenzar'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'current-attempt timeout retries the whole load without fabricating an attempt',
      (tester) async {
        final repo = _MemoryVocationalRepository()..failCurrent = true;
        await tester.pumpWidget(_app(repo));
        await tester.pumpAndSettle();
        expect(find.text('Tiempo de espera agotado.'), findsOneWidget);
        expect(repo.startCalls, 0);
        expect(repo.active, isNull);
        repo.failCurrent = false;
        await tester.tap(find.text('Reintentar'));
        await tester.pumpAndSettle();
        expect(repo.currentCalls, 2);
        expect(find.byKey(const Key('vocational-intro')), findsOneWidget);
        expect(repo.startCalls, 0);
      },
    );

    testWidgets(
      'finish network error preserves confirmed answers and permits an explicit retry',
      (tester) async {
        final repo = _MemoryVocationalRepository()..failFinish = true;
        await tester.pumpWidget(_app(repo));
        await tester.pumpAndSettle();
        await _tapVisible(tester, 'vocational-start');
        await _tapVisible(tester, 'vocational-answer-little');
        final confirmed = repo.active;
        await _tapVisible(tester, 'vocational-finish');
        expect(find.text('Red no disponible.'), findsOneWidget);
        expect(find.byKey(const Key('vocational-result')), findsNothing);
        expect(repo.active, same(confirmed));
        expect(repo.active!.answers['T1'], VocationalAnswer.little);
        repo.failFinish = false;
        await _tapVisible(tester, 'vocational-finish');
        expect(find.byKey(const Key('vocational-result')), findsOneWidget);
        expect(repo.finishCalls, 2);
      },
    );

    testWidgets(
      'history page timeout preserves page one and retries page two without skipping or duplicates',
      (tester) async {
        final repo = _MemoryVocationalRepository()..failHistoryPage = 2;
        for (var n = 1; n <= 21; n++) {
          final id = '00000000-0000-4000-8000-${n.toString().padLeft(12, '0')}';
          repo.stored[id] = VocationalAttempt.parse(_attempt(id: id));
        }
        await tester.pumpWidget(_app(repo));
        await tester.pumpAndSettle();
        await _tapVisible(tester, 'vocational-open-history');
        await tester.scrollUntilVisible(
          find.text('Ver más exploraciones'),
          400,
        );
        await tester.tap(find.text('Ver más exploraciones'));
        await tester.pumpAndSettle();
        expect(repo.historyPages, [1, 2]);
        tester
            .state<ScrollableState>(find.byType(Scrollable).first)
            .position
            .jumpTo(0);
        await tester.pumpAndSettle();
        expect(
          find.text('21 intentos guardados solo para tu cuenta.'),
          findsOneWidget,
        );
        await tester.scrollUntilVisible(
          find.text('Tiempo de espera agotado.'),
          400,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('Tiempo de espera agotado.'), findsOneWidget);
        repo.failHistoryPage = null;
        await tester.tap(find.text('Ver más exploraciones'));
        await tester.pumpAndSettle();
        expect(repo.historyPages, [1, 2, 2]);
        expect(find.text('Ver más exploraciones'), findsNothing);
        await _tapVisible(
          tester,
          'vocational-history-00000000-0000-4000-8000-000000000021',
        );
        expect(
          find.byKey(const Key('vocational-questionnaire')),
          findsOneWidget,
        );
        expect(find.text('Pregunta 1 de 30'), findsWidgets);
        expect(repo.startCalls, 0);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'failed opening and deleting a historical attempt do not fabricate success; both retry',
      (tester) async {
        final repo = _MemoryVocationalRepository()..failOpen = true;
        final terminal = VocationalAttempt.parse(_attempt(completed: true));
        repo.stored[_id1] = terminal;
        await tester.pumpWidget(_app(repo));
        await tester.pumpAndSettle();
        await _tapVisible(tester, 'vocational-open-history');
        await _tapVisible(tester, 'vocational-history-$_id1');
        expect(find.byKey(const Key('vocational-history')), findsOneWidget);
        expect(find.byKey(const Key('vocational-result')), findsNothing);
        repo.failOpen = false;
        await _tapVisible(tester, 'vocational-history-$_id1');
        expect(find.byKey(const Key('vocational-result')), findsOneWidget);
        expect(repo.stored[_id1], same(terminal));
        await tester.scrollUntilVisible(
          find.text('Ver mi historial'),
          400,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text('Ver mi historial'));
        await tester.pumpAndSettle();
        repo.failDelete = true;
        await _tapVisible(tester, 'vocational-delete-$_id1');
        await tester.tap(find.text('Eliminar'));
        await tester.pumpAndSettle();
        expect(find.text('Red no disponible.'), findsOneWidget);
        expect(repo.stored[_id1], same(terminal));
        expect(
          find.byKey(const Key('vocational-history-$_id1')),
          findsOneWidget,
        );
        repo.failDelete = false;
        await _tapVisible(tester, 'vocational-delete-$_id1');
        await tester.tap(find.text('Eliminar'));
        await tester.pumpAndSettle();
        expect(repo.stored, isEmpty);
        expect(find.byKey(const Key('vocational-history-$_id1')), findsNothing);
      },
    );

    for (final type in [
      DioExceptionType.connectionError,
      DioExceptionType.connectionTimeout,
      DioExceptionType.receiveTimeout,
    ]) {
      test(
        'repository maps $type for every operation without using a real network',
        () async {
          final dio = Dio(BaseOptions(baseUrl: 'https://example.invalid'));
          addTearDown(() => dio.close(force: true));
          dio.interceptors.add(
            InterceptorsWrapper(
              onRequest: (options, handler) {
                handler.reject(
                  DioException(requestOptions: options, type: type),
                );
              },
            ),
          );
          final repo = RemoteVocationalOrientationRepository(dio);
          for (final operation in <Future<Object?> Function()>[
            repo.questionnaire,
            repo.current,
            repo.start,
            () => repo.saveAnswer(_id1, 'T1', VocationalAnswer.much),
            () => repo.finish(_id1),
            () => repo.history(1),
            () => repo.getAttempt(_id1),
            () => repo.deleteAttempt(_id1),
          ]) {
            await expectLater(
              operation(),
              throwsA(
                isA<ApiError>().having(
                  (e) => e.code,
                  'code',
                  type == DioExceptionType.connectionError
                      ? 'network_unavailable'
                      : 'network_timeout',
                ),
              ),
            );
          }
        },
      );
    }
  });
}
