import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/core/database/app_database.dart';
import 'package:saber_plus/features/auth/domain/session.dart';
import 'package:saber_plus/features/auth/presentation/session_controller.dart';
import 'package:saber_plus/features/study_time/data/pomodoro_sync_worker.dart';
import 'package:saber_plus/features/study_time/data/study_evolution_repository.dart';
import 'package:saber_plus/features/study_time/presentation/study_evolution_providers.dart';
import 'package:saber_plus/features/study_time/presentation/study_time_page.dart';

const id = 'pomodoro:11111111-1111-4111-8111-111111111111';
void main() {
  late AppDatabase db;
  late _Worker worker;
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    worker = _Worker(db);
  });
  tearDown(() async {
    worker.dispose();
    worker.dio.close(force: true);
    await db.close();
  });

  testWidgets(
    'dejar solo local exige confirmación; cancelar no modifica la cola',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionControllerProvider.overrideWith(_Session.new),
            studyEvolutionRepositoryProvider.overrideWithValue(
              DemoStudyEvolutionRepository(),
            ),
            pomodoroSyncWorkerProvider.overrideWithValue(worker),
            pomodoroQueueProvider.overrideWith(
              (ref) => Stream.value([
                const PomodoroSyncEntry(
                  userId: 'A',
                  eventId: id,
                  endedAtUtc: '2026-09-14T15:00:00.000Z',
                  status: 'blocked',
                  attempts: 1,
                  errorCode: 'conflict',
                ),
              ]),
            ),
          ],
          child: const MaterialApp(home: StudyTimePage()),
        ),
      );
      await tester.pumpAndSettle();
      final button = find.byKey(const Key('local-only-$id'));
      await tester.scrollUntilVisible(button, 180);
      await Scrollable.ensureVisible(tester.element(button), alignment: 0.5);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.textContaining('esta acción no lo borra'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(worker.local, isEmpty);
      await tester.tap(button);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Conservar solo local'));
      await tester.pumpAndSettle();
      expect(worker.local, [id]);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('sincronización automática se detiene en segundo plano y demo', (
    tester,
  ) async {
    final session = _Session();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionControllerProvider.overrideWith(() => session),
          pomodoroSyncWorkerProvider.overrideWithValue(worker),
        ],
        child: Consumer(
          builder: (context, ref, child) {
            ref.watch(studyTimeAutoSyncProvider);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pump();
    expect(worker.calls, 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(minutes: 1));
    expect(worker.calls, 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(minutes: 1));
    expect(worker.calls, 2);
    session.toDemo();
    await tester.pump();
    await tester.pump(const Duration(minutes: 2));
    expect(worker.calls, 2);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

class _Session extends SessionController {
  @override
  SessionState build() => const SessionState.authenticated(
    UserSession(id: 'A', firstName: 'Ana', role: AppRole.student),
  );
  void toDemo() => state = const SessionState.authenticated(
    UserSession(
      id: 'demo',
      firstName: 'Demo',
      role: AppRole.student,
      isDemo: true,
    ),
  );
}

class _Worker extends PomodoroSyncWorker {
  _Worker(AppDatabase db) : super(db, Dio(), currentSession: () => null);
  int calls = 0;
  final local = <String>[];
  @override
  Future<int> synchronize() async {
    calls++;
    return 0;
  }

  @override
  Future<void> keepLocalOnly(String eventId) async {
    local.add(eventId);
  }
}
