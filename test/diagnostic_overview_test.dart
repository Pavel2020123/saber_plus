import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/academic/domain/academic_models.dart';
import 'package:saber_plus/features/academic/presentation/academic_home_controller.dart';
import 'package:saber_plus/features/academic/presentation/diagnostic_overview_page.dart';

void main() {
  testWidgets('prepara un diagnóstico no iniciado', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          academicHomeControllerProvider.overrideWith(
            _NotStartedAcademicController.new,
          ),
        ],
        child: const MaterialApp(home: DiagnosticOverviewPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Descubre tu punto de partida'), findsOneWidget);
    await tester.tap(find.byKey(const Key('start-diagnostic-button')));
    await tester.pumpAndSettle();

    expect(find.text('Tu diagnóstico está preparado'), findsOneWidget);
    expect(
      find.textContaining('15 preguntas quedaron reservadas'),
      findsOneWidget,
    );
  });
}

class _NotStartedAcademicController extends AcademicHomeController {
  static const initial = AcademicHomeData(
    diagnostic: DiagnosticSummary(status: DiagnosticStatus.notStarted),
    plan: StudyPlanSummary(status: StudyPlanStatus.diagnosticPending),
  );

  @override
  Future<AcademicHomeData> build() async => initial;

  @override
  Future<bool> startDiagnostic() async {
    state = const AsyncData(
      AcademicHomeData(
        diagnostic: DiagnosticSummary(
          status: DiagnosticStatus.inProgress,
          id: 'diagnostic-1',
          totalQuestions: 15,
        ),
        plan: StudyPlanSummary(status: StudyPlanStatus.diagnosticPending),
      ),
    );
    return true;
  }
}
