import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:saber_plus/features/dashboard/presentation/teacher_dashboard_page.dart';
import 'package:saber_plus/features/institutions/data/demo_teacher_basic_analytics_repository.dart';
import 'package:saber_plus/features/institutions/data/demo_teacher_detailed_analytics_repository.dart';
import 'package:saber_plus/features/institutions/data/demo_teacher_institution_repository.dart';
import 'package:saber_plus/features/institutions/domain/teacher_basic_analytics_models.dart';
import 'package:saber_plus/features/institutions/domain/teacher_detailed_analytics_models.dart';
import 'package:saber_plus/features/institutions/presentation/teacher_basic_analytics_page.dart';
import 'package:saber_plus/features/institutions/presentation/teacher_basic_analytics_providers.dart';
import 'package:saber_plus/features/institutions/presentation/teacher_detailed_analytics_page.dart';
import 'package:saber_plus/features/institutions/presentation/teacher_detailed_analytics_providers.dart';
import 'package:saber_plus/features/institutions/presentation/teacher_institution_providers.dart';

void main() {
  for (final page in ['inicio', 'basica', 'detallada']) {
    testWidgets('$page admite 320 px y texto al 200% sin desbordarse', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final institution = DemoTeacherInstitutionRepository();
      await institution.createInstitution(name: 'Colegio de prueba');
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            teacherInstitutionRepositoryProvider.overrideWithValue(institution),
            teacherBasicAnalyticsRepositoryProvider.overrideWithValue(
              DemoTeacherBasicAnalyticsRepository(),
            ),
            teacherDetailedAnalyticsRepositoryProvider.overrideWithValue(
              DemoTeacherDetailedAnalyticsRepository(),
            ),
          ],
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: switch (page) {
              'inicio' => const TeacherDashboardPage(),
              'basica' => const TeacherBasicAnalyticsPage(),
              _ => const TeacherDetailedAnalyticsPage(),
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final list = find.byKey(
        Key(switch (page) {
          'inicio' => 'teacher-institution-list',
          'basica' => 'teacher-basic-analytics-list',
          _ => 'teacher-detailed-summary',
        }),
      );
      for (var i = 0; i < 12; i++) {
        await tester.drag(list, const Offset(0, -400));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });
  }

  testWidgets('accesos rápidos abren grupos, seguimiento y equipo', (
    tester,
  ) async {
    final institution = DemoTeacherInstitutionRepository();
    await institution.createInstitution(name: 'Colegio');
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const TeacherDashboardPage()),
        for (final destination in ['groups', 'analytics', 'administration'])
          GoRoute(
            path: '/teacher/$destination',
            builder: (_, _) => Scaffold(body: Text('Destino $destination')),
          ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          teacherInstitutionRepositoryProvider.overrideWithValue(institution),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    for (final destination in ['groups', 'analytics', 'administration']) {
      final button = find.byKey(Key('teacher-quick-$destination'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.text('Destino $destination'), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
    }
  });

  for (final hasResults in [false, true]) {
    testWidgets('básica diferencia sin resultados de cero real: $hasResults', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            teacherBasicAnalyticsRepositoryProvider.overrideWithValue(
              _BasicZeroRepository(hasResults),
            ),
          ],
          child: const MaterialApp(home: TeacherBasicAnalyticsPage()),
        ),
      );
      await tester.pumpAndSettle();
      final metric = find
          .ancestor(
            of: find.text('Promedio / 100'),
            matching: find.byType(Card),
          )
          .first;
      expect(
        find.descendant(
          of: metric,
          matching: find.text(hasResults ? '0' : 'Sin datos'),
        ),
        findsOneWidget,
      );
    });
    testWidgets(
      'detallada diferencia sin resultados de cero real: $hasResults',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              teacherDetailedAnalyticsRepositoryProvider.overrideWithValue(
                _DetailedZeroRepository(hasResults),
              ),
            ],
            child: const MaterialApp(home: TeacherDetailedAnalyticsPage()),
          ),
        );
        await tester.pumpAndSettle();
        final metric = find
            .ancestor(
              of: find.text('Promedio / 100'),
              matching: find.byType(Card),
            )
            .first;
        await tester.ensureVisible(metric);
        expect(
          find.descendant(
            of: metric,
            matching: find.text(hasResults ? '0' : 'Sin datos'),
          ),
          findsOneWidget,
        );
        await tester.tap(find.widgetWithText(Tab, 'Estudiantes'));
        await tester.pumpAndSettle();
        expect(
          find.textContaining(hasResults ? 'promedio 0' : 'Sin resultados'),
          findsOneWidget,
        );
      },
    );
  }
}

class _BasicZeroRepository extends DemoTeacherBasicAnalyticsRepository {
  _BasicZeroRepository(this.hasResults);
  final bool hasResults;
  @override
  Future<TeacherBasicAnalytics> load() async {
    final demo = await super.load();
    return TeacherBasicAnalytics(
      scope: demo.scope,
      periodDays: demo.periodDays,
      generatedAt: demo.generatedAt,
      plan: demo.plan,
      privacyDescription: demo.privacyDescription,
      groups: const [],
      summary: BasicAnalyticsMetrics(
        totalStudents: 1,
        activeStudents: 0,
        totalSimulations: hasResults ? 1 : 0,
        averageScore: 0,
        averageProgress: 0,
      ),
    );
  }
}

class _DetailedZeroRepository extends DemoTeacherDetailedAnalyticsRepository {
  _DetailedZeroRepository(this.hasResults);
  final bool hasResults;
  @override
  Future<TeacherDetailedDashboard> load() async {
    final demo = await super.load();
    return TeacherDetailedDashboard(
      risks: demo.risks,
      analytics: TeacherDetailedAnalytics(
        scope: demo.analytics.scope,
        generatedAt: demo.analytics.generatedAt,
        planName: demo.analytics.planName,
        groupLimit: 5,
        studentLimit: 200,
        priorities: const [],
        summary: DetailedAnalyticsSummary(
          totalStudents: 1,
          averageScore: 0,
          totalSimulations: hasResults ? 1 : 0,
          studentsNeedingSupport: 0,
        ),
        students: [
          DetailedStudentAnalytics(
            id: 'student',
            name: 'Ana',
            email: 'ana@example.com',
            groups: const [],
            xp: 0,
            totalSimulations: hasResults ? 1 : 0,
            averageScore: 0,
            progress: 0,
            areas: const [],
            academicStatus: hasResults ? 'REFUERZO' : 'SIN_DATOS',
          ),
        ],
      ),
    );
  }
}
