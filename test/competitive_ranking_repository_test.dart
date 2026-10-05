import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/core/network/access_token_store.dart';
import 'package:saber_plus/core/network/auth_interceptor.dart';
import 'package:saber_plus/core/network/api_error.dart';
import 'package:saber_plus/features/ranking/data/competitive_ranking_repository.dart';
import 'package:saber_plus/features/ranking/domain/competitive_ranking_models.dart';
import 'helpers/competitive_ranking_fixture.dart';

void main() {
  late Dio dio;
  late RemoteCompetitiveRankingRepository repository;
  late AccessTokenStore tokens;
  final requests = <RequestOptions>[];
  Object? body;
  int status = 200;
  setUp(() {
    body = competitiveFixture();
    status = 200;
    requests.clear();
    tokens = AccessTokenStore()..set('synthetic-jwt');
    dio = Dio(BaseOptions(baseUrl: 'https://api.example.invalid'));
    dio.interceptors.add(
      AuthInterceptor(tokens, apiBaseUrl: dio.options.baseUrl),
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          final response = Response<Object?>(
            requestOptions: options,
            statusCode: status,
            data: body,
          );
          if (status == 200) {
            handler.resolve(response);
          } else {
            handler.reject(
              DioException(
                requestOptions: options,
                response: response,
                type: DioExceptionType.badResponse,
              ),
            );
          }
        },
      ),
    );
    repository = RemoteCompetitiveRankingRepository(dio);
  });
  tearDown(() => dio.close(force: true));
  Future<CompetitiveBoard> load() =>
      repository.load(game: CompetitiveGame.trivia, season: 2026);
  test(
    'GET con únicamente juego/año y JWT del interceptor actual, sin body',
    () async {
      final board = await load();
      final req = requests.single;
      expect(
        req.uri.toString(),
        'https://api.example.invalid/ranking/competitivo?juego=TRIVIA_RUSH&temporada=2026',
      );
      expect(req.method, 'GET');
      expect(req.data, isNull);
      expect(req.queryParameters, {'juego': 'TRIVIA_RUSH', 'temporada': 2026});
      expect(req.headers['Authorization'], 'Bearer synthetic-jwt');
      expect(req.followRedirects, isFalse);
      expect(board.myPosition!.position, 51);
    },
  );
  test(
    'logout no conserva token y 401 se comunica sin datos internos',
    () async {
      tokens.clear();
      status = 401;
      body = {'message': 'PRIVATE_SQL'};
      await expectLater(
        load(),
        throwsA(isA<ApiError>().having((e) => e.code, 'code', '401')),
      );
      expect(requests.single.headers.containsKey('Authorization'), isFalse);
    },
  );
  for (final state in ['SIN_PARTICIPANTES', 'NO_DISPONIBLE']) {
    test('200 $state es éxito contractual', () async {
      final game = state == 'NO_DISPONIBLE'
          ? CompetitiveGame.memory
          : CompetitiveGame.trivia;
      body = competitiveFixture(game: game, state: state);
      final board = await repository.load(game: game, season: 2026);
      expect(board.entries, isEmpty);
      expect(
        board.state,
        state == 'NO_DISPONIBLE'
            ? CompetitiveRankingState.unavailable
            : CompetitiveRankingState.empty,
      );
    });
  }
  for (final code in [400, 401, 403, 500, 503]) {
    test('$code conserva clase de error y oculta body privado', () async {
      status = code;
      body = {
        'message': 'SELECT Prisma private-id password table',
        'details': 'secret',
      };
      try {
        await load();
        fail('must reject');
      } on ApiError catch (e) {
        expect(e.code, '$code');
        expect(e.message, isNot(contains('Prisma')));
        expect(e.message, isNot(contains('private-id')));
        expect(e.details, isNull);
      }
    });
  }
  for (final bad in [
    null,
    'invalid',
    {'ranking': []},
  ]) {
    test(
      'respuesta malformada $bad es error seguro, no ranking vacío',
      () async {
        body = bad;
        await expectLater(
          load(),
          throwsA(
            isA<ApiError>().having(
              (e) => e.code,
              'code',
              'invalid_competitive_response',
            ),
          ),
        );
      },
    );
  }
  test('respuesta de otra selección no se acepta', () async {
    body = competitiveFixture(season: 2025);
    await expectLater(
      load(),
      throwsA(
        isA<ApiError>().having(
          (e) => e.code,
          'code',
          'invalid_competitive_response',
        ),
      ),
    );
    body = competitiveFixture(game: CompetitiveGame.summit);
    await expectLater(load(), throwsA(isA<ApiError>()));
  });
  test('año fuera de contrato no envía petición', () async {
    await expectLater(
      repository.load(game: CompetitiveGame.trivia, season: 0),
      throwsA(isA<ApiError>()),
    );
    expect(requests, isEmpty);
  });
}
