import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/progress/data/demo_progress_repository.dart';
import 'package:saber_plus/features/progress/domain/progress_models.dart';
import 'package:saber_plus/features/progress/presentation/progress_page.dart';
import 'package:saber_plus/features/progress/presentation/progress_providers.dart';

class _RetryRepository extends DemoProgressRepository {
  int calls = 0;
  final firstRequest = Completer<ErrorNotebook>();

  @override
  Future<ProgressDashboard> loadDashboard() async => ProgressDashboard.empty;

  @override
  Future<ErrorNotebook> loadNotebook(NotebookFilter filter) async {
    if (++calls == 1) return firstRequest.future;
    return ErrorNotebook.empty;
  }
}

void main() {
  testWidgets('notebook retry rebuilds after a failed request', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _RetryRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [progressRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: ProgressPage()),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Cuaderno'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(find.text('Cuaderno de errores'), findsOneWidget);
    repository.firstRequest.completeError(Exception('Offline test'));
    await tester.pumpAndSettle();
    expect(find.text('Reintentar'), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(repository.calls, 2);
    expect(find.text('Reintentar'), findsNothing);
    expect(find.text('0 errores'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
