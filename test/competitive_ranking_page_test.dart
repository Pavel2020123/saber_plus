import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/core/network/api_error.dart';
import 'package:saber_plus/features/ranking/domain/competitive_ranking_models.dart';
import 'package:saber_plus/features/ranking/domain/ranking_models.dart';
import 'package:saber_plus/features/ranking/presentation/competitive_ranking_page.dart';
import 'package:saber_plus/features/ranking/presentation/competitive_ranking_providers.dart';
import 'package:saber_plus/features/ranking/presentation/ranking_page.dart';
import 'package:saber_plus/features/ranking/presentation/ranking_providers.dart';
import 'helpers/competitive_ranking_fixture.dart';
import 'competitive_ranking_providers_test.dart' show TestCompetitiveRepository;

Future<void> showPage(WidgetTester tester, TestCompetitiveRepository repo) =>
    tester.pumpWidget(
      ProviderScope(
        overrides: [
          competitiveRankingRepositoryProvider.overrideWithValue(repo),
        ],
        child: const MaterialApp(home: CompetitiveRankingPage()),
      ),
    );
void main() {
  for (final scenario in [
    (name: 'texto grande', scale: 2.0, keyboard: 0.0, error: false),
    (name: 'error con teclado', scale: 1.0, keyboard: 280.0, error: true),
    (
      name: 'error, teclado y texto grande',
      scale: 2.0,
      keyboard: 280.0,
      error: true,
    ),
  ]) {
    testWidgets('pantalla pequeña sin desbordes: ${scenario.name}', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = TestCompetitiveRepository((q) async {
        if (scenario.error) {
          throw const ApiError(
            code: '503',
            message:
                'No pudimos cargar el ranking competitivo. Inténtalo de nuevo.',
          );
        }
        return fixtureBoard(game: q.game, season: q.season);
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            competitiveRankingRepositoryProvider.overrideWithValue(repo),
          ],
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scenario.scale),
                viewInsets: EdgeInsets.only(bottom: scenario.keyboard),
              ),
              child: child!,
            ),
            home: const CompetitiveRankingPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      if (scenario.error) {
        await tester.drag(find.byType(NestedScrollView), const Offset(0, -350));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Reintentar'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Reintentar'));
        await tester.pumpAndSettle();
        expect(repo.queries.length, 2);
        expect(tester.takeException(), isNull);
      }
    });
  }
  testWidgets('TOP y mi posición 51 se muestran sin calcular XP ni posición', (
    tester,
  ) async {
    final repo = TestCompetitiveRepository(
      (q) async => fixtureBoard(game: q.game, season: q.season),
    );
    await showPage(tester, repo);
    await tester.pumpAndSettle();
    expect(find.text('60 participantes'), findsOneWidget);
    expect(find.text('Mi posición'), findsOneWidget);
    expect(find.text('#51 · Tú · 950 XP'), findsOneWidget);
    expect(find.text('Estudiante ficticio 1'), findsOneWidget);
    expect(find.textContaining('TOP 50'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'cambio de juego y temporada no muestra resultado anterior durante carga ni después de respuesta tardía',
    (tester) async {
      final pending = <CompetitiveQuery, Completer<CompetitiveBoard>>{};
      final repo = TestCompetitiveRepository(
        (q) => (pending[q] = Completer<CompetitiveBoard>()).future,
      );
      await showPage(tester, repo);
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final original = repo.queries.single;
      await tester.tap(find.byKey(const Key('competitive-game')));
      // Finish the menu animation without waiting for the deliberately pending request/spinner.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('Cima').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final gameQuery = repo.queries.last;
      expect(gameQuery.game, CompetitiveGame.summit);
      pending[original]!.complete(fixtureBoard(season: original.season));
      await tester.pump();
      expect(find.text('60 participantes'), findsNothing);
      pending[gameQuery]!.complete(
        fixtureBoard(game: gameQuery.game, season: gameQuery.season),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('competitive-year')), '2025');
      await tester.tap(find.text('Consultar'));
      await tester.pump();
      final yearQuery = repo.queries.last;
      expect(yearQuery.season, 2025);
      expect(find.text('60 participantes'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      pending[yearQuery]!.complete(
        fixtureBoard(game: yearQuery.game, season: yearQuery.season),
      );
      await tester.pumpAndSettle();
      expect(find.text('TOP 50 · Cima · 2025'), findsOneWidget);
    },
  );
  testWidgets('sin participantes tiene mensaje propio y no inventa posición', (
    tester,
  ) async {
    await showPage(
      tester,
      TestCompetitiveRepository(
        (q) async => fixtureBoard(
          game: q.game,
          season: q.season,
          state: 'SIN_PARTICIPANTES',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Aún no hay participantes con XP competitivo en esta temporada.',
      ),
      findsOneWidget,
    );
    expect(find.text('Mi posición'), findsNothing);
  });
  testWidgets(
    'Memoria y Batallas se pueden seleccionar y muestran no disponible',
    (tester) async {
      final repo = TestCompetitiveRepository(
        (q) async => fixtureBoard(
          game: q.game,
          season: q.season,
          state: q.game.available ? 'SIN_PARTICIPANTES' : 'NO_DISPONIBLE',
        ),
      );
      await showPage(tester, repo);
      await tester.pumpAndSettle();
      for (final game in [CompetitiveGame.memory, CompetitiveGame.battles]) {
        await tester.tap(find.byKey(const Key('competitive-game')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('${game.label} · No disponible').last);
        await tester.pumpAndSettle();
        expect(repo.queries.last.game, game);
        expect(
          find.text(
            'Este juego todavía no está disponible en el ranking competitivo.',
          ),
          findsOneWidget,
        );
        expect(find.textContaining('0 participantes'), findsNothing);
      }
    },
  );
  testWidgets('500/503 permiten reintento, carga visible y recuperación', (
    tester,
  ) async {
    var calls = 0;
    final pending = Completer<CompetitiveBoard>();
    final repo = TestCompetitiveRepository((q) async {
      if (calls++ == 0) {
        throw const ApiError(
          code: '503',
          message:
              'No pudimos cargar el ranking competitivo. Inténtalo nuevamente.',
        );
      }
      return pending.future;
    });
    await showPage(tester, repo);
    await tester.pumpAndSettle();
    expect(find.text('Reintentar'), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final query = repo.queries.last;
    pending.complete(fixtureBoard(season: query.season));
    await tester.pumpAndSettle();
    expect(find.text('60 participantes'), findsOneWidget);
  });
  for (final code in ['400', '401', '403']) {
    testWidgets('$code no presenta ranking vacío ni reintento engañoso', (
      tester,
    ) async {
      await showPage(
        tester,
        TestCompetitiveRepository(
          (q) async =>
              throw ApiError(code: code, message: 'Mensaje seguro $code'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Mensaje seguro $code'), findsOneWidget);
      expect(find.text('Reintentar'), findsNothing);
      expect(find.text('60 participantes'), findsNothing);
    });
  }
  testWidgets('año inválido no dispara otra consulta', (tester) async {
    final repo = TestCompetitiveRepository(
      (q) async => fixtureBoard(game: q.game, season: q.season),
    );
    await showPage(tester, repo);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('competitive-year')), '02026');
    await tester.tap(find.text('Consultar'));
    await tester.pumpAndSettle();
    expect(find.text('Indica un año entre 1 y 9999.'), findsOneWidget);
    expect(repo.queries.length, 1);
  });
  testWidgets(
    'fallo al actualizar por gesto se muestra sin excepción asíncrona sin manejar',
    (tester) async {
      var calls = 0;
      final repo = TestCompetitiveRepository((q) async {
        if (calls++ > 0) {
          throw const ApiError(code: '500', message: 'Fallo temporal seguro');
        }
        return fixtureBoard(game: q.game, season: q.season);
      });
      await showPage(tester, repo);
      await tester.pumpAndSettle();
      final refresh = tester.widget<RefreshIndicator>(
        find.byType(RefreshIndicator),
      );
      await expectLater(refresh.onRefresh(), completes);
      await tester.pumpAndSettle();
      expect(find.text('Fallo temporal seguro'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'ranking general abre competitivo y regresa conservando consulta legacy',
    (tester) async {
      var legacyQueries = 0;
      final repo = TestCompetitiveRepository(
        (q) async => fixtureBoard(game: q.game, season: q.season),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            competitiveRankingRepositoryProvider.overrideWithValue(repo),
            rankingBoardProvider.overrideWith((ref, q) async {
              legacyQueries++;
              return RankingBoard(
                scope: q.scope,
                period: q.period,
                scopeName: 'General ficticio',
                institutionAvailable: true,
                totalParticipants: 1,
                updatedAt: DateTime(2026),
                entries: const [
                  RankingEntry(
                    position: 1,
                    alias: 'Alias general',
                    xp: 10,
                    isCurrentUser: true,
                  ),
                ],
                identitiesProtected: true,
              );
            }),
          ],
          child: const MaterialApp(home: RankingPage()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('General ficticio'), findsOneWidget);
      await tester.tap(find.byTooltip('Ver ranking competitivo'));
      await tester.pumpAndSettle();
      expect(find.text('Ranking competitivo'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('General ficticio'), findsOneWidget);
      expect(find.text('Alias general'), findsOneWidget);
      expect(legacyQueries, 1);
    },
  );
}
