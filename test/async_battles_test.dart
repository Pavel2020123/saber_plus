import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/academic/domain/academic_models.dart';
import 'package:saber_plus/features/battles/data/demo_battle_repository.dart';
import 'package:saber_plus/features/battles/data/remote_battle_repository.dart';
import 'package:saber_plus/features/battles/domain/battle_models.dart';
import 'package:saber_plus/features/battles/presentation/async_battles_page.dart';
import 'package:saber_plus/features/battles/presentation/battle_detail_page.dart';
import 'package:saber_plus/features/battles/presentation/battle_providers.dart';

void main() {
  test('interpreta únicamente rivales anónimos y progreso protegido', () {
    final dashboard = BattleDashboard.fromJson(_dashboard());

    expect(dashboard.identitiesProtected, isTrue);
    expect(dashboard.battles.single.rivalAlias, 'Rival anónimo');
    expect(dashboard.battles.single.rivalProgress?.correct, isNull);
    expect(dashboard.battles.single.ownProgress.correct, isNull);
  });

  test('rechaza identificadores, nombres y contratos sin privacidad', () {
    final withId = _dashboard();
    (withId['batallas'] as List<dynamic>).first['rivalId'] = 'usuario-secreto';
    expect(
      () => BattleDashboard.fromJson(withId),
      throwsA(isA<FormatException>()),
    );

    final withName = _dashboard();
    (withName['batallas'] as List<dynamic>).first['rival'] = {
      'alias': 'Rival anónimo',
      'nombre': 'Nombre real',
    };
    expect(
      () => BattleDashboard.fromJson(withName),
      throwsA(isA<FormatException>()),
    );

    expect(
      () => BattleDashboard.fromJson({
        ..._dashboard(),
        'privacidad': {'identidadesProtegidas': false},
      }),
      throwsA(isA<FormatException>()),
    );

    final earlyScore = _dashboard();
    final ownProgress =
        (earlyScore['batallas'] as List<dynamic>).first['progresoPropio']
            as Map<String, dynamic>;
    ownProgress['correctas'] = 2;
    expect(
      () => BattleDashboard.fromJson(earlyScore),
      throwsA(isA<FormatException>()),
    );
  });

  test(
    'crea una invitación remota sin enviar identificadores personales',
    () async {
      late RequestOptions captured;
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            captured = options;
            handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                statusCode: 200,
                data: _detail(),
              ),
            );
          },
        ),
      );
      final repository = RemoteBattleRepository(dio);

      final result = await repository.create(
        mode: BattleMode.survival,
        area: AcademicArea.mathematics,
        privateInvitation: true,
      );

      expect(captured.path, '/batallas');
      expect(captured.data, {
        'modo': 'SUPERVIVENCIA',
        'area': 'MATEMATICAS',
        'invitacionPrivada': true,
      });
      expect((captured.data as Map).containsKey('rivalId'), isFalse);
      expect(result.summary.invitationCode, 'SABER123');
    },
  );

  test(
    'la demostración completa preguntas y revela corrección al final',
    () async {
      final repository = DemoBattleRepository();
      var battle = await repository.create(mode: BattleMode.ghostRace);
      battle = await repository.start(battle.summary.id);

      expect(battle.currentQuestion, isNotNull);
      expect(battle.currentQuestion?.correctAnswerId, isNull);
      battle = await repository.answer(
        battleId: battle.summary.id,
        questionId: battle.currentQuestion!.id,
        answerId: battle.currentQuestion!.options.first.id,
      );
      battle = await repository.answer(
        battleId: battle.summary.id,
        questionId: battle.currentQuestion!.id,
        answerId: battle.currentQuestion!.options[1].id,
      );

      expect(battle.summary.status, BattleStatus.finished);
      expect(battle.summary.result, BattleResult.victory);
      expect(
        battle.questions.every((item) => item.correctAnswerId != null),
        isTrue,
      );
    },
  );

  testWidgets('muestra privacidad, estadísticas y formas seguras de competir', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          battleRepositoryProvider.overrideWithValue(DemoBattleRepository()),
        ],
        child: const MaterialApp(home: AsyncBattlesPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('battle-privacy-card')), findsOneWidget);
    expect(find.text('Competencia segura y anónima'), findsOneWidget);
    expect(find.byKey(const Key('find-anonymous-rival')), findsOneWidget);
    expect(find.byKey(const Key('create-private-invitation')), findsOneWidget);
    expect(find.byKey(const Key('join-private-invitation')), findsOneWidget);
    expect(find.text('No has jugado'), findsNothing);
  });

  testWidgets('responde una batalla y solo entonces muestra la revisión', (
    tester,
  ) async {
    final repository = DemoBattleRepository();
    final created = await repository.create(mode: BattleMode.ghostRace);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [battleRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          home: BattleDetailPage(battleId: created.summary.id),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Aciertos ocultos'), findsWidgets);
    await tester.tap(find.byKey(const Key('start-async-battle')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Si 3 cuadernos'), findsOneWidget);
    expect(find.text('Respuesta correcta:'), findsNothing);

    await tester.tap(find.text('24.000 pesos'));
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(const Key('submit-async-battle-answer')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('submit-async-battle-answer')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Resumir y cerrar la idea central'));
    await tester.tap(find.text('Resumir y cerrar la idea central'));
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(const Key('submit-async-battle-answer')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('submit-async-battle-answer')));
    await tester.pumpAndSettle();

    expect(find.text('Victoria'), findsOneWidget);
    expect(find.text('Revisión'), findsOneWidget);
    expect(find.textContaining('Respuesta correcta'), findsWidgets);
  });
}

Map<String, dynamic> _dashboard() => {
  'resumen': {
    'jugadas': 4,
    'victorias': 2,
    'derrotas': 1,
    'empates': 1,
    'rachaActual': 1,
    'mejorRacha': 2,
    'xpBatallas': 120,
  },
  'batallas': [_summary()],
  'privacidad': _privacy,
};

Map<String, dynamic> _summary() => {
  'id': 'batalla-1',
  'modo': 'CARRERA_FANTASMA',
  'area': 'MATEMATICAS',
  'estado': 'ACTIVA',
  'creadaEn': '2026-08-31T18:00:00.000Z',
  'expiraEn': '2026-09-01T18:00:00.000Z',
  'rival': {'alias': 'Rival anónimo'},
  'soyCreador': true,
  'codigoInvitacion': null,
  'progresoPropio': {
    'respondidas': 3,
    'correctas': null,
    'totalPreguntas': 8,
    'energia': null,
    'vidas': 3,
    'finalizo': false,
  },
  'progresoRival': {
    'respondidas': 4,
    'correctas': null,
    'totalPreguntas': 8,
    'energia': null,
    'vidas': 3,
    'finalizo': false,
  },
  'resultado': null,
  'xpGanado': 0,
  'privacidad': _privacy,
};

Map<String, dynamic> _detail() => {
  ..._summary(),
  'modo': 'SUPERVIVENCIA',
  'estado': 'PENDIENTE',
  'rival': null,
  'codigoInvitacion': 'SABER123',
  'progresoRival': null,
  'totalPreguntas': 8,
  'iniciadaEn': null,
  'finalizadaEn': null,
  'yo': {'alias': 'Tú'},
  'preguntas': <Map<String, dynamic>>[],
  'insigniasDesbloqueadas': <Map<String, dynamic>>[],
};

const _privacy = {
  'identidadesProtegidas': true,
  'chatHabilitado': false,
  'datosRivalPublicados': ['alias', 'progreso'],
};
