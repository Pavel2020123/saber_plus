import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:saber_plus/features/auth/domain/session.dart';
import 'package:saber_plus/features/auth/presentation/session_controller.dart';
import 'package:saber_plus/features/study/domain/study_models.dart';
import 'package:saber_plus/features/study/presentation/study_providers.dart';
import 'package:saber_plus/features/academic/domain/academic_models.dart';
import 'package:saber_plus/features/study/domain/learning_map.dart';
import 'package:saber_plus/features/study/data/learning_map_repository.dart';
import 'package:saber_plus/features/study/presentation/learning_map_card.dart';

const request = (area: AcademicArea.mathematics, subtopicId: 'c');
Map<String, Object> node(String id) => {
  'id': id,
  'nombre': id,
  'temaId': 't',
  'tema': 'Tema',
};
Map<String, Object> payload() => {
  'versionContrato': 1,
  'orientativo': true,
  'area': 'MATEMATICAS',
  'revision': 0,
  'subtema': node('c'),
  'previos': [node('a')],
  'recorrido': [node('a')],
};
void main() {
  test('account change discards an older pending map', () async {
    final repo = _PendingMap();
    final container = ProviderContainer(
      overrides: [
        sessionControllerProvider.overrideWith(_Session.new),
        learningMapRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      learningMapProvider(request),
      (_, _) {},
    );
    addTearDown(subscription.close);
    await Future<void>.delayed(Duration.zero);
    container.read(sessionControllerProvider.notifier).state =
        const SessionState.unauthenticated();
    await Future<void>.delayed(Duration.zero);
    repo.pending.complete(LearningMap.parse(payload(), request));
    await Future<void>.delayed(Duration.zero);
    expect(container.read(learningMapProvider(request)).hasError, isTrue);
  });
  testWidgets(
    'opens available base using study route and disables withdrawn content',
    (tester) async {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) =>
                const Scaffold(body: LearningMapCard(request: request)),
          ),
          GoRoute(
            path: '/student/study/matematicas/t/a',
            builder: (_, _) => const Scaffold(body: Text('Lección destino')),
          ),
        ],
      );
      addTearDown(router.dispose);
      final data = {
        ...payload(),
        'recorrido': [node('a'), node('removed')],
      };
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            learningMapProvider(
              request,
            ).overrideWith((ref) async => LearningMap.parse(data, request)),
            studyProgressProvider.overrideWith(
              (ref) async => StudyProgress.empty,
            ),
            studyCatalogProvider(request.area).overrideWith(
              (ref) async => const StudyCatalog(
                area: AcademicArea.mathematics,
                themes: [
                  StudyTheme(
                    id: 't',
                    name: 'Tema',
                    subtopics: [
                      StudySubtopic(id: 'a', name: 'a', totalQuestions: 0),
                    ],
                  ),
                ],
              ),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ver 2 bases'));
      await tester.pumpAndSettle();
      final removed = tester.widget<ListTile>(
        find.ancestor(
          of: find.text('2. removed'),
          matching: find.byType(ListTile),
        ),
      );
      expect(removed.onTap, isNull);
      await tester.tap(find.text('1. a'));
      await tester.pumpAndSettle();
      expect(find.text('Lección destino'), findsOneWidget);
    },
  );
  test(
    'validates target, area, version and references without inventing defaults',
    () {
      expect(LearningMap.parse(payload(), request).previous.single.id, 'a');
      for (final change in <String, Object>{
        'versionContrato': 2,
        'area': 'INGLES',
        'subtema': node('other'),
        'recorrido': <Object>[],
      }.entries) {
        expect(
          () => LearningMap.parse({
            ...payload(),
            change.key: change.value,
          }, request),
          throwsFormatException,
        );
      }
      expect(
        () => LearningMap.parse({
          ...payload(),
          'recorrido': [node('a'), node('a')],
        }, request),
        throwsFormatException,
      );
      expect(
        () => LearningMap.parse({
          ...payload(),
          'previos': [node('c')],
        }, request),
        throwsFormatException,
      );
    },
  );
  test('remote uses learner GET, no writes and no demo fallback', () async {
    final dio = Dio();
    int calls = 0;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          calls++;
          expect(options.method, 'GET');
          expect(options.path, '/mapa-aprendizaje/subtemas/c');
          handler.resolve(
            Response(requestOptions: options, data: payload(), statusCode: 200),
          );
        },
      ),
    );
    expect(
      (await RemoteLearningMapRepository(dio).load(request)).route.length,
      1,
    );
    expect(calls, 1);
    await expectLater(
      RemoteLearningMapRepository(
        dio,
      ).load((area: request.area, subtopicId: '../x')),
      throwsFormatException,
    );
    expect(calls, 1);
  });
  test(
    'demo has no fabricated prerequisite links or unknown destinations',
    () async {
      final repo = DemoLearningMapRepository();
      final map = await repo.load((
        area: request.area,
        subtopicId: 'demo-mathematics-subtopic',
      ));
      expect(map.route, isEmpty);
      await expectLater(repo.load(request), throwsA(anything));
    },
  );
  testWidgets('empty map explains its meaning with large text', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          learningMapProvider(request).overrideWith(
            (ref) async => LearningMap(
              target: const LearningMapNode('c', 'c', 't', 'Tema'),
              previous: const [],
              route: const [],
            ),
          ),
        ],
        child: MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: const Scaffold(
              body: SingleChildScrollView(
                child: LearningMapCard(request: request),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Esto no indica dominio'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('errors allow retry and are not an empty map', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          learningMapProvider(request).overrideWith((ref) async {
            calls++;
            throw Exception('offline');
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(body: LearningMapCard(request: request)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Reintentar mapa'), findsOneWidget);
    expect(find.textContaining('No hay bases'), findsNothing);
    await tester.tap(find.text('Reintentar mapa'));
    await tester.pumpAndSettle();
    expect(calls, 2);
  });
}

class _Session extends SessionController {
  @override
  SessionState build() => const SessionState.authenticated(
    UserSession(id: 'A', firstName: 'A', role: AppRole.student),
  );
}

class _PendingMap implements LearningMapRepository {
  final pending = Completer<LearningMap>();
  @override
  Future<LearningMap> load(LearningMapRequest request) => pending.future;
}
