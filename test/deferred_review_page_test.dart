import 'dart:convert';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/core/database/app_database.dart';
import 'package:saber_plus/features/auth/domain/session.dart';
import 'package:saber_plus/features/auth/presentation/session_controller.dart';
import 'package:saber_plus/features/academic/domain/academic_models.dart';
import 'package:saber_plus/features/flashcards/data/deferred_review_repository.dart';
import 'package:saber_plus/features/flashcards/domain/deferred_review.dart';
import 'package:saber_plus/features/flashcards/domain/flashcard_models.dart';
import 'package:saber_plus/features/flashcards/presentation/deferred_review_page.dart';
import 'package:saber_plus/features/flashcards/presentation/deferred_review_providers.dart';
import 'package:saber_plus/features/flashcards/presentation/flashcard_providers.dart';
import 'package:saber_plus/features/flashcards/presentation/flashcard_session_page.dart';

final now = DateTime.utc(2026, 9, 28, 12);
final cards = ['due', 'next', 'pending', 'new']
    .map(
      (id) => Flashcard(
        id: id,
        kind: FlashcardKind.formula,
        area: AcademicArea.mathematics,
        front: 'Tarjeta $id',
        back: 'Respuesta $id',
        context: 'Contexto',
      ),
    )
    .toList();
DeferredReviewEntry entry(
  String id,
  DateTime reviewed, {
  String status = 'synced',
}) => DeferredReviewEntry(
  userId: 'A',
  cardId: id,
  confirmedJson: jsonEncode({
    'tarjetaId': id,
    'contenidoVersion': 'library-v1',
    'paso': 0,
    'revision': 1,
    'revisadoEn': reviewed.toIso8601String(),
    'venceEn': reviewed.add(const Duration(days: 1)).toIso8601String(),
  }),
  provisionalJson: null,
  pendingJson: status == 'synced' ? null : '{}',
  status: status,
);

class _Session extends SessionController {
  _Session({this.demo = false});
  final bool demo;
  @override
  SessionState build() => SessionState.authenticated(
    UserSession(id: 'A', firstName: 'Ana', role: AppRole.student, isDemo: demo),
  );
}

class _Repo extends DeferredReviewRepository {
  _Repo(AppDatabase db)
    : super(
        db,
        Dio(),
        currentSession: () => null,
        allowedCardIds: {'due', 'new'},
      );
  int saved = 0, syncs = 0, discarded = 0;
  bool fail = false;
  @override
  Future<void> enqueue({
    required String userId,
    required String cardId,
    required RecallOutcome outcome,
  }) async {
    saved++;
  }

  @override
  Future<void> synchronize(String userId) async {
    syncs++;
    if (fail) throw StateError('offline');
  }

  @override
  Future<void> discardBlocked(String userId, String cardId) async {
    discarded++;
  }
}

void main() {
  late AppDatabase db;
  late _Repo repo;
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = _Repo(db);
  });
  tearDown(() async {
    repo.dispose();
    repo.dio.close();
    await db.close();
  });
  Widget app(
    Widget child, {
    bool demo = false,
    List<DeferredReviewEntry> rows = const [],
    double scale = 1,
  }) => ProviderScope(
    overrides: [
      sessionControllerProvider.overrideWith(() => _Session(demo: demo)),
      deferredReviewRepositoryProvider.overrideWith((ref) async => repo),
      deferredReviewRowsProvider.overrideWith((ref) => Stream.value(rows)),
      reviewClockProvider.overrideWith((ref) => Stream.value(now)),
      flashcardCatalogProvider.overrideWith((ref) async => cards),
      flashcardProgressProvider.overrideWith((ref) => Stream.value(const [])),
    ],
    child: MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: child,
      ),
    ),
  );
  testWidgets(
    'separates due, upcoming, blocked and new without claiming mastery',
    (tester) async {
      await tester.pumpWidget(
        app(
          const DeferredReviewPage(),
          rows: [
            entry('due', now.subtract(const Duration(days: 2))),
            entry('next', now),
            entry('pending', now, status: 'pending'),
          ],
          scale: 2,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Pendientes (1)'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Próximos (1)'), 200);
      expect(find.text('Próximos (1)'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Sin confirmar o bloqueados (1)'),
        200,
      );
      expect(find.text('Sin confirmar o bloqueados (1)'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Añadir tarjetas (1)'), 200);
      expect(find.text('Añadir tarjetas (1)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('demo cannot synchronize or enqueue', (tester) async {
    await tester.pumpWidget(app(const DeferredReviewPage(), demo: true));
    await tester.pumpAndSettle();
    expect(find.textContaining('cuenta real'), findsOneWidget);
    expect(find.text('Sincronizar agenda'), findsNothing);
    expect(repo.syncs, 0);
    expect(repo.saved, 0);
  });
  testWidgets('manual retry reports offline while keeping agenda visible', (
    tester,
  ) async {
    repo.fail = true;
    await tester.pumpWidget(app(const DeferredReviewPage()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sincronizar agenda'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Los cambios locales se conservan'),
      findsOneWidget,
    );
    expect(repo.syncs, 1);
  });
  testWidgets(
    'scheduled session saves one self-report without writing legacy mastery',
    (tester) async {
      await tester.pumpWidget(
        app(
          const FlashcardSessionPage(
            config: FlashcardSessionConfig(reviewCardId: 'due', count: 1),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('1/1'), findsOneWidget);
      await tester.tap(find.byKey(const Key('reveal-flashcard')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('master-flashcard')));
      await tester.pumpAndSettle();
      expect(repo.saved, 1);
      expect(repo.syncs, 1);
      expect(find.textContaining('Autoevaluación terminada'), findsOneWidget);
    },
  );
  testWidgets('unknown or retired card cannot be reviewed from a direct URL', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        const FlashcardSessionPage(
          config: FlashcardSessionConfig(reviewCardId: 'gone'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No hay tarjetas para esos filtros.'), findsOneWidget);
    expect(repo.saved, 0);
  });
  test(
    'scheduled route roundtrips and leaves free practice default unchanged',
    () {
      final config = FlashcardSessionConfig.fromUri(
        Uri.parse(const FlashcardSessionConfig(reviewCardId: 'due').location),
      );
      expect(config.reviewCardId, 'due');
      expect(const FlashcardSessionConfig().reviewCardId, isNull);
    },
  );
  testWidgets('discarding a conflict requires confirmation', (tester) async {
    await tester.pumpWidget(
      app(
        const DeferredReviewPage(),
        rows: [entry('pending', now, status: 'conflict')],
      ),
    );
    await tester.pumpAndSettle();
    final button = find.byTooltip('Revisar respuesta bloqueada');
    await tester.scrollUntilVisible(button, 150);
    await tester.tap(button);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(repo.discarded, 0);
    await tester.tap(button);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Descartar'));
    await tester.pumpAndSettle();
    expect(repo.discarded, 1);
  });
  testWidgets('a new day moves an upcoming confirmed review to due', (
    tester,
  ) async {
    final clock = StreamController<DateTime>();
    addTearDown(clock.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionControllerProvider.overrideWith(() => _Session()),
          deferredReviewRepositoryProvider.overrideWith((ref) async => repo),
          deferredReviewRowsProvider.overrideWith(
            (ref) => Stream.value([entry('next', now)]),
          ),
          reviewClockProvider.overrideWith((ref) => clock.stream),
          flashcardCatalogProvider.overrideWith((ref) async => cards),
        ],
        child: const MaterialApp(home: DeferredReviewPage()),
      ),
    );
    clock.add(now);
    await tester.pumpAndSettle();
    expect(find.text('Pendientes (0)'), findsOneWidget);
    clock.add(now.add(const Duration(days: 1)));
    await tester.pumpAndSettle();
    expect(find.text('Pendientes (1)'), findsOneWidget);
  });
}
