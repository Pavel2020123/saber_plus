import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/core/network/access_token_store.dart';
import 'package:saber_plus/core/network/api_error.dart';
import 'package:saber_plus/core/network/auth_interceptor.dart';
import 'package:saber_plus/features/auth/data/remote_auth_repository.dart';
import 'package:saber_plus/features/ranking/data/competitive_ranking_repository.dart';
import 'package:saber_plus/features/ranking/domain/competitive_ranking_models.dart';

// Real HTTP login/guards/SQL, opt-in ONLY with tool/local_ranking_validation.mjs.
// These repository tests do not claim to be a manual Android UI walkthrough.
void main() {
  const enabled = bool.fromEnvironment('LOCAL_RANKING_ENABLED');
  const corrected = bool.fromEnvironment('LOCAL_RANKING_CORRECTED');
  const base = String.fromEnvironment('AUTH_E2E_API_BASE_URL');
  const password = String.fromEnvironment('AUTH_E2E_PASSWORD');
  const seasonText = String.fromEnvironment('LOCAL_RANKING_SEASON');

  group(
    'ranking contra API y PostgreSQL locales propios',
    () {
      late Dio publicDio;
      late Dio privateDio;
      late AccessTokenStore tokens;
      late RemoteAuthRepository auth;
      late RemoteCompetitiveRankingRepository ranking;
      late int season;

      setUp(() {
        expect(base, 'http://127.0.0.1:43187');
        expect(password, isNotEmpty);
        season = int.parse(seasonText);
        publicDio = Dio(BaseOptions(baseUrl: base));
        privateDio = Dio(BaseOptions(baseUrl: base));
        tokens = AccessTokenStore();
        privateDio.interceptors.add(AuthInterceptor(tokens));
        auth = RemoteAuthRepository(publicDio, privateDio);
        ranking = RemoteCompetitiveRankingRepository(privateDio);
      });
      tearDown(() {
        publicDio.close(force: true);
        privateDio.close(force: true);
      });
      Future<void> login(String account) async {
        final result = await auth.login(
          email: '$account@example.invalid',
          password: password,
        );
        tokens.set(result.tokens.accessToken);
        final profile = await auth.profile();
        expect(profile.emailVerified, isTrue);
      }

      test(
        'login real, TOP 50, propio fuera del TOP o corrección interna',
        () async {
          await login('student');
          final board = await ranking.load(
            game: CompetitiveGame.trivia,
            season: season,
          );
          expect(board.state, CompetitiveRankingState.participants);
          expect(board.entries, hasLength(50));
          expect(board.totalParticipants, 61);
          expect(board.myPosition!.position, corrected ? 1 : 51);
          expect(board.myPosition!.xp, corrected ? 2100 : 100);
          final legacy = await privateDio.get<Object?>(
            '/ranking',
            queryParameters: {
              'alcance': 'GLOBAL',
              'periodo': 'TOTAL',
              'limite': 50,
            },
          );
          expect(legacy.statusCode, 200);
          final raw = await privateDio.get<Object?>(
            '/ranking/competitivo',
            queryParameters: {'juego': 'TRIVIA_RUSH', 'temporada': season},
          );
          expect(
            jsonEncode(raw.data),
            isNot(
              matches(
                r'usuarioId|correo|contrasena|institucion|@example\.invalid|Ensayo|Ficticio',
              ),
            ),
          );
        },
      );

      test(
        'juego y temporada, vacío y los dos juegos no disponibles',
        () async {
          await login('student');
          final boards = await Future.wait([
            ranking.load(game: CompetitiveGame.trivia, season: season - 1),
            ranking.load(game: CompetitiveGame.summit, season: season),
            ranking.load(game: CompetitiveGame.memory, season: season),
            ranking.load(game: CompetitiveGame.battles, season: season),
            ranking.load(game: CompetitiveGame.trivia, season: season),
          ]);
          expect(boards[0].season, season - 1);
          expect(boards[0].state, CompetitiveRankingState.empty);
          expect(boards[1].game, CompetitiveGame.summit);
          expect(boards[1].state, CompetitiveRankingState.empty);
          expect(boards[2].state, CompetitiveRankingState.unavailable);
          expect(boards[3].state, CompetitiveRankingState.unavailable);
          expect(boards[4].state, CompetitiveRankingState.participants);
        },
      );

      test('XP cero y cuenta sin balance no tienen posición', () async {
        for (final account in ['zero', 'absent']) {
          await login(account);
          final board = await ranking.load(
            game: CompetitiveGame.trivia,
            season: season,
          );
          expect(board.myPosition, isNull);
          expect(board.totalParticipants, 61);
        }
      });

      test(
        'login de profesor y ADMIN real, acceso competitivo prohibido',
        () async {
          for (final account in ['teacher', 'admin']) {
            await login(account);
            await expectLater(
              ranking.load(game: CompetitiveGame.trivia, season: season),
              throwsA(
                isA<ApiError>().having((error) => error.code, 'status', '403'),
              ),
            );
          }
        },
      );

      test('sesión inválida, nuevo login y reintento real', () async {
        tokens.set('invalid-local-validation-token');
        await expectLater(
          ranking.load(game: CompetitiveGame.trivia, season: season),
          throwsA(
            isA<ApiError>().having((error) => error.code, 'status', '401'),
          ),
        );
        await login('student');
        expect(
          (await ranking.load(
            game: CompetitiveGame.trivia,
            season: season,
          )).entries,
          hasLength(50),
        );
      });
    },
    skip: enabled
        ? false
        : 'Requiere el harness PostgreSQL local OWNED de I2-5.',
  );
}
