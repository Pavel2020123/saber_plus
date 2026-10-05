import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/core/network/api_client.dart';
import 'package:saber_plus/core/network/api_error.dart';
import 'package:saber_plus/features/auth/domain/session.dart';
import 'package:saber_plus/features/auth/presentation/session_controller.dart';
import 'package:saber_plus/features/ranking/data/competitive_ranking_repository.dart';
import 'package:saber_plus/features/ranking/domain/competitive_ranking_models.dart';
import 'package:saber_plus/features/ranking/presentation/competitive_ranking_providers.dart';
import 'package:saber_plus/features/ranking/presentation/ranking_providers.dart';
import 'helpers/competitive_ranking_fixture.dart';

class TestCompetitiveRepository implements CompetitiveRankingRepository {
  TestCompetitiveRepository(this.respond);
  final Future<CompetitiveBoard> Function(CompetitiveQuery) respond;
  final queries = <CompetitiveQuery>[];
  @override
  Future<CompetitiveBoard> load({
    required CompetitiveGame game,
    required int season,
  }) {
    final query = (game: game, season: season);
    queries.add(query);
    return respond(query);
  }
}

class _Session extends SessionController {
  _Session(this.demo);
  final bool demo;
  @override
  SessionState build() => SessionState.authenticated(
    UserSession(
      id: 'synthetic-student',
      firstName: 'Ficticio',
      role: AppRole.student,
      isDemo: demo,
    ),
  );
}

void main() {
  const trivia = (game: CompetitiveGame.trivia, season: 2026);
  test(
    'loading -> éxito y filtros independientes ante respuesta antigua tardía',
    () async {
      final pending = <CompetitiveQuery, Completer<CompetitiveBoard>>{};
      final repo = TestCompetitiveRepository(
        (q) => (pending[q] = Completer<CompetitiveBoard>()).future,
      );
      final container = ProviderContainer(
        overrides: [
          competitiveRankingRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);
      final a = container.listen(competitiveBoardProvider(trivia), (_, _) {});
      expect(
        container.read(competitiveBoardProvider(trivia)).isLoading,
        isTrue,
      );
      const newer = (game: CompetitiveGame.summit, season: 2025);
      final b = container.listen(competitiveBoardProvider(newer), (_, _) {});
      pending[newer]!.complete(
        fixtureBoard(game: newer.game, season: newer.season),
      );
      final board = await container.read(
        competitiveBoardProvider(newer).future,
      );
      expect(board.game, newer.game);
      expect(board.season, 2025);
      pending[trivia]!.complete(fixtureBoard());
      await container.read(competitiveBoardProvider(trivia).future);
      expect(
        container.read(competitiveBoardProvider(newer)).requireValue,
        same(board),
      );
      a.close();
      b.close();
    },
  );
  test(
    'error -> invalidación -> recuperación sin tocar provider general',
    () async {
      var calls = 0;
      var legacyReads = 0;
      final repo = TestCompetitiveRepository((q) async {
        if (calls++ == 0) {
          throw const ApiError(code: '503', message: 'Temporal');
        }
        return fixtureBoard();
      });
      final container = ProviderContainer(
        overrides: [
          competitiveRankingRepositoryProvider.overrideWithValue(repo),
          rankingRepositoryProvider.overrideWith((ref) {
            legacyReads++;
            throw StateError('legacy must remain unobserved');
          }),
        ],
      );
      addTearDown(container.dispose);
      final sub = container.listen(competitiveBoardProvider(trivia), (_, _) {});
      await expectLater(
        container.read(competitiveBoardProvider(trivia).future),
        throwsA(isA<ApiError>()),
      );
      expect(container.read(competitiveBoardProvider(trivia)).hasError, isTrue);
      container.invalidate(competitiveBoardProvider(trivia));
      expect(
        (await container.read(
          competitiveBoardProvider(trivia).future,
        )).totalParticipants,
        60,
      );
      expect(repo.queries.length, 2);
      expect(legacyReads, 0);
      sub.close();
    },
  );
  test(
    'provider remoto reutiliza Dio suministrado y no crea cliente paralelo',
    () async {
      final dio = Dio();
      addTearDown(() => dio.close(force: true));
      var requests = 0;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (r, h) {
            requests++;
            h.resolve(
              Response(
                requestOptions: r,
                data: competitiveFixture(),
                statusCode: 200,
              ),
            );
          },
        ),
      );
      final container = ProviderContainer(
        overrides: [
          dioProvider.overrideWithValue(dio),
          sessionControllerProvider.overrideWith(() => _Session(false)),
        ],
      );
      addTearDown(container.dispose);
      expect(
        container.read(competitiveRankingRepositoryProvider),
        isA<RemoteCompetitiveRankingRepository>(),
      );
      expect(
        (await container.read(competitiveBoardProvider(trivia).future)).season,
        2026,
      );
      expect(requests, 1);
    },
  );
  test('demo no fabrica XP ni abre cliente HTTP', () async {
    final container = ProviderContainer(
      overrides: [
        sessionControllerProvider.overrideWith(() => _Session(true)),
        dioProvider.overrideWith(
          (ref) => throw StateError('demo must not open HTTP'),
        ),
      ],
    );
    addTearDown(container.dispose);
    await expectLater(
      container.read(competitiveBoardProvider(trivia).future),
      throwsA(
        isA<ApiError>().having((e) => e.code, 'code', 'demo_unavailable'),
      ),
    );
  });
}
