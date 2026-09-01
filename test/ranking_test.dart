import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/ranking/data/remote_ranking_repository.dart';
import 'package:saber_plus/features/ranking/domain/ranking_models.dart';
import 'package:saber_plus/features/ranking/domain/ranking_repository.dart';
import 'package:saber_plus/features/ranking/presentation/ranking_page.dart';
import 'package:saber_plus/features/ranking/presentation/ranking_providers.dart';

void main() {
  test('interpreta únicamente alias, posición y XP protegidos', () {
    final board = RankingBoard.fromJson(_response());

    expect(board.scope, RankingScope.global);
    expect(board.period, RankingPeriod.week);
    expect(board.identitiesProtected, isTrue);
    expect(board.entries.first.alias, 'Estudiante Cóndor 184527');
    expect(board.myPosition?.alias, 'Tú');
  });

  test('rechaza entradas que filtren identificadores o datos adicionales', () {
    final unsafe = _response();
    (unsafe['ranking'] as List<dynamic>).first['usuarioId'] = 'user-secret';

    expect(
      () => RankingBoard.fromJson(unsafe),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => RankingBoard.fromJson({
        ..._response(),
        'privacidad': {'identidadesProtegidas': false},
      }),
      throwsA(isA<FormatException>()),
    );
  });

  test('consulta el contrato remoto con alcance, período y límite', () async {
    late RequestOptions captured;
    final repository = RemoteRankingRepository(
      _dio((options) {
        captured = options;
        return _response(
          scope: RankingScope.institution,
          period: RankingPeriod.month,
        );
      }),
    );

    final board = await repository.load(
      scope: RankingScope.institution,
      period: RankingPeriod.month,
    );

    expect(captured.path, '/ranking');
    expect(captured.queryParameters, {
      'alcance': 'INSTITUCION',
      'periodo': 'MES',
      'limite': 50,
    });
    expect(board.scope, RankingScope.institution);
  });

  testWidgets('muestra privacidad y permite cambiar período y alcance', (
    tester,
  ) async {
    final repository = _FakeRankingRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [rankingRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: RankingPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('ranking-privacy-card')), findsOneWidget);
    expect(find.text('Identidades protegidas'), findsOneWidget);
    expect(find.byKey(const Key('ranking-my-position')), findsOneWidget);
    expect(find.text('Estudiante Cóndor 184527'), findsOneWidget);
    expect(find.text('Juan Completo'), findsNothing);
    expect(repository.queries.last.period, RankingPeriod.week);

    await tester.tap(find.byKey(const Key('ranking-period-MES')));
    await tester.pumpAndSettle();
    expect(repository.queries.last.period, RankingPeriod.month);

    await tester.tap(find.text('Institución'));
    await tester.pumpAndSettle();
    expect(repository.queries.last.scope, RankingScope.institution);
    expect(find.text('Mi institución'), findsOneWidget);
  });
}

class _FakeRankingRepository implements RankingRepository {
  final List<({RankingScope scope, RankingPeriod period})> queries = [];

  @override
  Future<RankingBoard> load({
    required RankingScope scope,
    required RankingPeriod period,
  }) async {
    queries.add((scope: scope, period: period));
    return RankingBoard.fromJson(_response(scope: scope, period: period));
  }
}

Map<String, dynamic> _response({
  RankingScope scope = RankingScope.global,
  RankingPeriod period = RankingPeriod.week,
}) => {
  'alcance': scope.backendValue,
  'periodo': period.backendValue,
  'nombreAlcance': scope == RankingScope.global
      ? 'SaberPlus'
      : 'Mi institución',
  'institucionDisponible': true,
  'totalParticipantes': 2847,
  'actualizadoEn': '2026-08-31T15:30:00.000Z',
  'ranking': <Map<String, dynamic>>[
    {
      'posicion': 1,
      'alias': 'Estudiante Cóndor 184527',
      'xp': 980,
      'esUsuarioActual': false,
    },
    {'posicion': 4, 'alias': 'Tú', 'xp': 620, 'esUsuarioActual': true},
  ],
  'miPosicion': {
    'posicion': 4,
    'alias': 'Tú',
    'xp': 620,
    'esUsuarioActual': true,
  },
  'privacidad': {
    'identidadesProtegidas': true,
    'datosPublicados': ['posicion', 'alias', 'xp'],
  },
};

Dio _dio(Map<String, dynamic> Function(RequestOptions options) response) {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) => handler.resolve(
        Response<Map<String, dynamic>>(
          requestOptions: options,
          statusCode: 200,
          data: response(options),
        ),
      ),
    ),
  );
  return dio;
}
