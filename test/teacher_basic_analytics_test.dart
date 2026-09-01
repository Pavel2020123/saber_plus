import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/core/ads/advertising_policy.dart';
import 'package:saber_plus/features/institutions/data/demo_teacher_basic_analytics_repository.dart';
import 'package:saber_plus/features/institutions/data/remote_teacher_basic_analytics_repository.dart';
import 'package:saber_plus/features/institutions/domain/teacher_basic_analytics_models.dart';
import 'package:saber_plus/features/institutions/presentation/teacher_basic_analytics_page.dart';
import 'package:saber_plus/features/institutions/presentation/teacher_basic_analytics_providers.dart';

void main() {
  test('interpreta únicamente indicadores agregados y límites del plan', () {
    final analytics = TeacherBasicAnalytics.fromJson(_analyticsJson());

    expect(analytics.scope, 'GRUPOS_ASIGNADOS');
    expect(analytics.plan.groupLimit, 1);
    expect(analytics.plan.studentLimit, 40);
    expect(analytics.plan.advertisingEnabled, isTrue);
    expect(analytics.summary.totalStudents, 28);
    expect(analytics.groups.single.name, 'Once A');
  });

  test('rechaza una analítica básica que filtre identidades', () {
    final unsafe = _analyticsJson();
    unsafe['estudiantes'] = [
      {'correo': 'estudiante@saberplus.com'},
    ];

    expect(() => TeacherBasicAnalytics.fromJson(unsafe), throwsFormatException);
  });

  test('el repositorio consulta el endpoint básico protegido', () async {
    RequestOptions? captured;
    final repository = RemoteTeacherBasicAnalyticsRepository(
      _dio((options) {
        captured = options;
        return _analyticsJson();
      }),
    );

    final analytics = await repository.load();

    expect(captured?.path, '/instituciones/me/analiticas-basicas');
    expect(captured?.method, 'GET');
    expect(analytics.summary.totalSimulations, 46);
  });

  test('la política permite más pausas al profesor sin volverlas spam', () {
    final policy = AdvertisingPolicy(
      audience: AdvertisingAudience.teacher,
      adsEnabled: true,
    );
    final gate = LocalInterstitialGate(policy);
    final start = DateTime(2026, 9, 1, 10);

    expect(policy.maximumInterstitialsPerWindow, 3);
    expect(gate.canRequest(start), isFalse);
    for (var impression = 0; impression < 3; impression += 1) {
      gate
        ..registerCompletedAction()
        ..registerCompletedAction();
      expect(gate.canRequest(start), isTrue);
      gate.registerImpression(start);
    }
    gate
      ..registerCompletedAction()
      ..registerCompletedAction();
    expect(gate.canRequest(start), isFalse);
    expect(gate.canRequest(start.add(const Duration(minutes: 31))), isTrue);
  });

  test(
    'nunca habilita banners en concentración ni anuncios de un plan pago',
    () {
      const freePolicy = AdvertisingPolicy(
        audience: AdvertisingAudience.teacher,
        adsEnabled: true,
      );
      const paidPolicy = AdvertisingPolicy(
        audience: AdvertisingAudience.teacher,
        adsEnabled: false,
      );

      expect(
        freePolicy.allowsBanner(
          placement: AdvertisingPlacement.teacherAnalyticsBanner,
        ),
        isTrue,
      );
      expect(
        freePolicy.allowsBanner(
          placement: AdvertisingPlacement.teacherAnalyticsBanner,
          concentrationScreen: true,
        ),
        isFalse,
      );
      expect(
        paidPolicy.allowsBanner(
          placement: AdvertisingPlacement.teacherDashboardBanner,
        ),
        isFalse,
      );
      expect(
        paidPolicy.allowsVoluntaryReward(
          AdvertisingPlacement.voluntaryReward,
        ),
        isFalse,
      );
    },
  );

  testWidgets('muestra el resumen y el grupo sin listar estudiantes', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          teacherBasicAnalyticsRepositoryProvider.overrideWithValue(
            DemoTeacherBasicAnalyticsRepository(),
          ),
        ],
        child: const MaterialApp(home: TeacherBasicAnalyticsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('teacher-basic-analytics-list')),
      findsOneWidget,
    );
    expect(find.text('Actividad de los últimos 30 días'), findsOneWidget);
    expect(find.text('28'), findsOneWidget);
    await tester.fling(
      find.byKey(const Key('teacher-basic-analytics-list')),
      const Offset(0, -2000),
      3000,
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('basic-analytics-group-demo-group-1')),
      findsOneWidget,
    );
    expect(find.textContaining('Privacidad por diseño'), findsOneWidget);
    expect(find.textContaining('@'), findsNothing);
  });
}

Map<String, dynamic> _analyticsJson() => {
  'nivel': 'BASICA',
  'alcance': 'GRUPOS_ASIGNADOS',
  'periodoDias': 30,
  'generadoEn': '2026-09-01T12:00:00.000Z',
  'plan': {
    'nombre': 'GRATIS',
    'limiteGrupos': 1,
    'limiteEstudiantes': 40,
    'publicidadHabilitada': true,
  },
  'resumen': {
    'totalEstudiantes': 28,
    'estudiantesActivos': 21,
    'totalSimulacros': 46,
    'promedioPuntaje': 63.4,
    'progresoPromedio': 37.5,
    'ultimaActividad': '2026-09-01T11:00:00.000Z',
  },
  'grupos': [
    {
      'id': 'group-1',
      'nombre': 'Once A',
      'grado': 'ONCE',
      'totalEstudiantes': 28,
      'estudiantesActivos': 21,
      'totalSimulacros': 46,
      'promedioPuntaje': 63.4,
      'progresoPromedio': 37.5,
      'ultimaActividad': '2026-09-01T11:00:00.000Z',
    },
  ],
  'privacidad': {
    'incluyeIdentidades': false,
    'descripcion': 'Indicadores agregados sin identidades.',
  },
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
