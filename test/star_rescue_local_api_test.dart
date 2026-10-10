import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/core/network/access_token_store.dart';
import 'package:saber_plus/core/network/auth_interceptor.dart';
import 'package:saber_plus/features/academic/domain/academic_models.dart';
import 'package:saber_plus/features/auth/data/remote_auth_repository.dart';
import 'package:saber_plus/features/games/star_rescue/data/remote_star_rescue_repository.dart';
import 'package:saber_plus/features/games/star_rescue/data/star_rescue_resume_store.dart';
import 'package:saber_plus/features/games/star_rescue/domain/star_rescue_models.dart';
import 'package:saber_plus/features/games/trivia_rush/data/remote_trivia_rush_repository.dart';
import 'package:saber_plus/features/practice/domain/practice_models.dart';
import 'package:saber_plus/features/ranking/data/competitive_ranking_repository.dart';
import 'package:saber_plus/features/ranking/domain/competitive_ranking_models.dart';

/// Opt-in only for the disposable loopback harness. Uses a separate seeded
/// account by default. Explicit student selection can prepare genuine XP for
/// a fresh-session phone test; it does not copy old balances or award fixture XP.
void main() {
  const base = String.fromEnvironment('AUTH_E2E_API_BASE_URL');
  const password = String.fromEnvironment('AUTH_E2E_PASSWORD');
  const local = String.fromEnvironment('LOCAL_RANKING_ENABLED');
  const competitive = bool.fromEnvironment('RESCUE_LOCAL_COMPETITIVE');
  const email = String.fromEnvironment(
    'RESCUE_LOCAL_EMAIL',
    defaultValue: 'zero@example.invalid',
  );
  final enabled =
      base == 'http://127.0.0.1:43187' &&
      local == 'true' &&
      password.isNotEmpty;

  test(
    'Rescate real: normal/competitivo, recuperación y resultado único',
    () async {
      expect(email, isIn(['zero@example.invalid', 'student@example.invalid']));
      final public = Dio(BaseOptions(baseUrl: base));
      final dio = Dio(BaseOptions(baseUrl: base));
      addTearDown(() {
        public.close();
        dio.close();
      });
      final tokens = AccessTokenStore();
      dio.interceptors.add(AuthInterceptor(tokens));
      final auth = RemoteAuthRepository(public, dio);
      final login = await auth.login(email: email, password: password);
      tokens.set(login.tokens.accessToken);
      final values = <String, String>{};
      final store = StarRescueResumeStore(
        readValue: (key) async => values[key],
        writeValue: (key, value) async => values[key] = value,
      );
      final scope = '$base\u0000${login.user.id}';
      final rankings = RemoteCompetitiveRankingRepository(dio);
      final season = suggestedCompetitiveSeason(DateTime.now());
      final before = await rankings.load(
        game: CompetitiveGame.rescue,
        season: season,
      );
      final previousXp = before.myPosition?.xp ?? 0;
      var repo = RemoteStarRescueRepository(dio, store, scope: scope);
      expect(await repo.restore(), null);
      var attempt = await repo.start(
        AcademicArea.mathematics,
        difficulty: PracticeDifficulty.easy,
        competitive: competitive,
      );
      expect(attempt.isCompetitive, competitive);
      final attemptId = attempt.id;
      String? lastQuestion, lastAnswer, lastKey;
      for (var index = 0; index < 6; index++) {
        final q = attempt.question!;
        // Only the harness-owned synthetic n + 1 questions, never real content.
        expect(q.themeName, 'Cima - ensayo local IC-1A2');
        final sum = RegExp(r'(\d+)\s*\+\s*1').firstMatch(q.statement);
        expect(sum, isNotNull);
        final correct = '${int.parse(sum!.group(1)!) + 1}';
        lastQuestion = q.id;
        lastAnswer = q.options.singleWhere((o) => o.text == correct).id;
        lastKey = createTriviaIdempotencyKey();
        attempt = await repo.answer(
          attemptId: attemptId,
          questionId: q.id,
          answerId: lastAnswer,
          requestKey: lastKey,
        );
        expect(attempt.progress.stars, index + 1);
        if (index == 0) {
          repo.dispose();
          repo = RemoteStarRescueRepository(dio, store, scope: scope);
          attempt = (await repo.restore())!;
          expect(attempt.id, attemptId);
          expect(attempt.isCompetitive, competitive);
          expect(attempt.progress.stars, 1);
        }
      }
      expect(attempt.status, 'VICTORIA');
      expect(attempt.progress.stars, 6);
      // Replaying a terminal request checks the real HTTP idempotency contract.
      final duplicate = await dio.post<Object?>(
        '/rescate-estrellas/intentos/$attemptId/respuestas',
        data: {
          'preguntaId': lastQuestion,
          'respuestaId': lastAnswer,
          'idempotencyKey': lastKey,
        },
      );
      expect(
        StarRescueAttempt.fromJson(
          Map<String, dynamic>.from(duplicate.data as Map),
        ).progress.stars,
        6,
      );
      var board = await rankings.load(
        game: CompetitiveGame.rescue,
        season: season,
      );
      if (competitive) {
        final deadline = DateTime.now().add(const Duration(seconds: 45));
        while ((board.myPosition?.xp ?? 0) != previousXp + 100 &&
            DateTime.now().isBefore(deadline)) {
          await Future<void>.delayed(const Duration(milliseconds: 500));
          board = await rankings.load(
            game: CompetitiveGame.rescue,
            season: season,
          );
        }
      }
      expect(board.myPosition?.xp ?? 0, previousXp + (competitive ? 100 : 0));
      repo.dispose();
      final restored = (await RemoteStarRescueRepository(
        dio,
        store,
        scope: scope,
      ).restore())!;
      expect(restored.status, 'VICTORIA');
      expect(restored.isCompetitive, competitive);
      final reread = await rankings.load(
        game: CompetitiveGame.rescue,
        season: season,
      );
      expect(reread.myPosition?.xp ?? 0, board.myPosition?.xp ?? 0);
    },
    skip: enabled
        ? false
        : 'Requiere harness local y archivo privado de ensayo.',
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
