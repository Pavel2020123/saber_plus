import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/institutions/data/demo_teacher_detailed_analytics_repository.dart';
import 'package:saber_plus/features/institutions/data/remote_teacher_detailed_analytics_repository.dart';
import 'package:saber_plus/features/institutions/domain/teacher_detailed_analytics_models.dart';
import 'package:saber_plus/features/institutions/domain/teacher_detailed_analytics_repository.dart';
import 'package:saber_plus/features/institutions/domain/teacher_institution_models.dart';
import 'package:saber_plus/features/institutions/presentation/teacher_detailed_analytics_page.dart';
import 'package:saber_plus/features/institutions/presentation/teacher_detailed_analytics_providers.dart';

void main() {
  test('interpreta prioridades, estudiantes y alertas del plan', () {
    final analytics = TeacherDetailedAnalytics.fromJson(_analyticsJson());
    final risks = TeacherRiskReport.fromJson(_risksJson());

    expect(analytics.planName, 'SIN_ANUNCIOS');
    expect(analytics.groupLimit, 5);
    expect(analytics.studentLimit, 200);
    expect(analytics.priorities.single.areaLabel, 'Matematicas');
    expect(analytics.students.single.priorityArea, 'MATEMATICAS');
    expect(risks.alerts.single.level, 'ALTA');
    expect(risks.alerts.single.reasons.single.code, 'RENDIMIENTO_RECIENTE');
  });

  test('reconoce todas las capacidades del contexto sin anuncios', () {
    final institution = TeacherInstitution.fromJson({
      'id': 'institution-1',
      'nombre': 'Colegio Central',
      'codigoUnico': 'INST-ABC123',
      'planActual': 'SIN_ANUNCIOS',
      'totalEstudiantes': 80,
      'totalGrupos': 4,
      'totalProfesores': 3,
      'limiteGrupos': 5,
      'limiteEstudiantes': 200,
      'publicidadHabilitada': false,
      'nivelAnalitica': 'DETALLADA',
      'alertasHabilitadas': true,
      'prioridadesHabilitadas': true,
      'exportacionesHabilitadas': true,
      'planVencido': false,
      'venceEn': '2027-03-01T00:00:00.000Z',
    });

    expect(institution.analyticsLevel, InstitutionAnalyticsLevel.detailed);
    expect(institution.riskAlertsEnabled, isTrue);
    expect(institution.prioritiesEnabled, isTrue);
    expect(institution.exportsEnabled, isTrue);
    expect(institution.advertisingEnabled, isFalse);
    expect(institution.expiresAt, isNotNull);
  });

  test('consulta analítica y alertas por rutas protegidas', () async {
    final paths = <String>[];
    final repository = RemoteTeacherDetailedAnalyticsRepository(
      _dio((options) {
        paths.add(options.path);
        return options.path.endsWith('alertas-riesgo')
            ? _risksJson()
            : _analyticsJson();
      }),
    );

    final dashboard = await repository.load();

    expect(paths, contains('/instituciones/me/analiticas'));
    expect(paths, contains('/instituciones/me/alertas-riesgo'));
    expect(dashboard.analytics.summary.totalStudents, 1);
    expect(dashboard.risks.summary.atRisk, 1);
  });

  test('guarda una exportación en el directorio privado', () async {
    final directory = await Directory.systemTemp.createTemp(
      'saberplus_report_test_',
    );
    try {
      final repository = RemoteTeacherDetailedAnalyticsRepository(
        _dio((_) => <int>[0xEF, 0xBB, 0xBF, 65, 44, 66]),
        documentsDirectory: () async => directory,
      );

      final report = await repository.downloadReport(
        InstitutionReportFormat.csv,
      );

      expect(report.fileName, endsWith('.csv'));
      expect(await File(report.path).readAsBytes(), isNotEmpty);
      expect(
        report.path,
        contains('${Platform.pathSeparator}saberplus_reports'),
      );
    } finally {
      await directory.delete(recursive: true);
    }
  });

  testWidgets('muestra resumen, prioridades, alertas y estudiantes', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          teacherDetailedAnalyticsRepositoryProvider.overrideWithValue(
            DemoTeacherDetailedAnalyticsRepository(),
          ),
        ],
        child: const MaterialApp(home: TeacherDetailedAnalyticsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('teacher-detailed-summary')), findsOneWidget);
    expect(find.text('Plan sin anuncios'), findsOneWidget);
    await tester.fling(
      find.byKey(const Key('teacher-detailed-summary')),
      const Offset(0, -900),
      1800,
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('institution-priority-MATEMATICAS')),
      findsOneWidget,
    );

    await tester.tap(find.text('Alertas'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('teacher-risk-alerts')), findsOneWidget);
    expect(find.byKey(const Key('risk-alert-demo-student-1')), findsOneWidget);

    await tester.tap(find.text('Estudiantes'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('detailed-student-demo-student-1')),
      findsOneWidget,
    );
    expect(find.textContaining('andrea@'), findsNothing);
  });
}

Map<String, dynamic> _analyticsJson() => {
  'nivel': 'DETALLADA',
  'alcance': 'GRUPOS_ASIGNADOS',
  'generadoEn': '2026-09-01T12:00:00.000Z',
  'plan': {
    'nombre': 'SIN_ANUNCIOS',
    'limiteGrupos': 5,
    'limiteEstudiantes': 200,
    'publicidadHabilitada': false,
    'venceEn': '2027-03-01T00:00:00.000Z',
  },
  'institucion': {
    'totalEstudiantes': 1,
    'promedioGeneral': 45,
    'totalSimulacros': 2,
    'estudiantesPorReforzar': 1,
  },
  'prioridades': [
    {'area': 'MATEMATICAS', 'estudiantes': 1, 'promedio': 40},
  ],
  'estudiantes': [
    {
      'id': 'student-1',
      'nombre': 'Andrea',
      'correo': 'andrea@example.com',
      'xpTotal': 100,
      'grupos': [
        {'id': 'group-1', 'nombre': 'Once A'},
      ],
      'totalSimulacros': 2,
      'promedioPuntaje': 45,
      'ultimaActividad': '2026-08-31T00:00:00.000Z',
      'progresoPorcentaje': 20,
      'porArea': [
        {'area': 'MATEMATICAS', 'promedio': 40, 'cantidad': 2},
      ],
      'areaPrioritaria': 'MATEMATICAS',
      'estadoAcademico': 'REFUERZO',
    },
  ],
};

Map<String, dynamic> _risksJson() => {
  'alcance': 'GRUPOS_ASIGNADOS',
  'generadoEn': '2026-09-01T12:00:00.000Z',
  'resumen': {
    'totalEstudiantes': 1,
    'enRiesgo': 1,
    'criticas': 0,
    'altas': 1,
    'atencion': 0,
  },
  'alertas': [
    {
      'estudiante': {
        'id': 'student-1',
        'nombre': 'Andrea',
        'correo': 'andrea@example.com',
        'grupos': [
          {'id': 'group-1', 'nombre': 'Once A'},
        ],
      },
      'nivel': 'ALTA',
      'razones': [
        {
          'codigo': 'RENDIMIENTO_RECIENTE',
          'nivel': 'ALTA',
          'titulo': 'Bajo rendimiento',
          'detalle': '40% de aciertos.',
        },
      ],
      'areaPrioritaria': 'MATEMATICAS',
      'actividad': {'diasSinActividad': 8},
    },
  ],
};

Dio _dio(Object? Function(RequestOptions options) response) {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) => handler.resolve(
        Response<Object?>(
          requestOptions: options,
          statusCode: 200,
          data: response(options),
        ),
      ),
    ),
  );
  return dio;
}
