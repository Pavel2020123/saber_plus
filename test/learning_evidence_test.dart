import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/core/network/api_error.dart';
import 'package:saber_plus/features/learning_evidence/data/learning_evidence_repository.dart';
import 'package:saber_plus/features/learning_evidence/domain/learning_evidence.dart';

Map<String, dynamic> reportFixture() => {
  'version': 1,
  'politica': {
    'version': 1,
    'ventanaDias': 90,
    'minimoPreguntasSubtema': 5,
    'minimoPreguntasTema': 10,
    'minimoSesiones': 2,
    'minimoDias': 2,
    'umbralRefuerzo': 60,
    'umbralFortaleza': 80,
    'zonaHoraria': 'America/Bogota',
    'criterioRepeticiones': 'PRIMERA_RESPUESTA_POR_PREGUNTA_EN_VENTANA',
  },
  'desde': '2026-06-08T15:00:00.000Z',
  'hasta': '2026-09-06T15:00:00.000Z',
  'parcial': false,
  'registrosExcluidos': 0,
  'repeticionesIgnoradas': 3,
  'temas': <Map<String, dynamic>>[
    {
      'id': 't1',
      'nombre': 'Proporcionalidad',
      'area': 'MATEMATICAS',
      'preguntasUnicas': 5,
      'correctas': 2,
      'incorrectas': 3,
      'sesiones': 2,
      'dias': 2,
      'porcentaje': 40,
      'estado': 'EVIDENCIA_INSUFICIENTE',
      'subtemas': <Map<String, dynamic>>[
        {
          'id': 's1',
          'nombre': 'Regla de tres',
          'preguntasUnicas': 5,
          'correctas': 2,
          'incorrectas': 3,
          'sesiones': 2,
          'dias': 2,
          'porcentaje': 40,
          'estado': 'POR_REFORZAR',
        },
      ],
    },
  ],
};

void main() {
  test(
    'interpreta clasificación confirmada y mantiene el tema sin evidencia suficiente',
    () {
      final report = LearningEvidence.fromJson(reportFixture());
      expect(report.topics.single.level, EvidenceLevel.insufficient);
      expect(
        report.topics.single.subtopics.single.level,
        EvidenceLevel.needsReview,
      );
      expect(report.policy.windowDays, 90);
      expect(report.isDemo, false);
      expect(report.repeated, 3);
    },
  );

  for (final mutation in [
    'version',
    'negative',
    'unknown',
    'percentage',
    'insufficient',
    'partial',
    'children',
  ]) {
    test('rechaza informe inconsistente: $mutation', () {
      final json = reportFixture();
      final topic = (json['temas'] as List).single as Map<String, dynamic>;
      final child = (topic['subtemas'] as List).single as Map<String, dynamic>;
      switch (mutation) {
        case 'version':
          json['version'] = 2;
        case 'negative':
          json['registrosExcluidos'] = -1;
        case 'unknown':
          child['estado'] = 'APROBADO';
        case 'percentage':
          child['porcentaje'] = 100;
        case 'insufficient':
          child['sesiones'] = 1;
        case 'partial':
          json['parcial'] = true;
        case 'children':
          topic['subtemas'] = <Object>[];
      }
      expect(() => LearningEvidence.fromJson(json), throwsFormatException);
    });
  }

  test('sin historial conserva una lista vacía, sin inventar falencias', () {
    final json = reportFixture()..['temas'] = <Object>[];
    expect(LearningEvidence.fromJson(json).topics, isEmpty);
  });

  test('demo aislado distingue error inicial y evidencia acumulada', () {
    final report = demoLearningEvidence();
    expect(report.isDemo, true);
    expect(
      report.topics.last.subtopics.single.level,
      EvidenceLevel.insufficient,
    );
    expect(report.topics.first.subtopics.last.level, EvidenceLevel.strength);
  });

  test(
    'repositorio consulta solo GET propio y no envía identidad por query',
    () async {
      final dio = Dio();
      addTearDown(dio.close);
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.path, '/diagnostico-evidencia');
            expect(options.method, 'GET');
            expect(options.queryParameters, isEmpty);
            handler.resolve(
              Response(
                requestOptions: options,
                data: reportFixture(),
                statusCode: 200,
              ),
            );
          },
        ),
      );
      final result = await LearningEvidenceRepository(dio).load();
      expect(result.topics.single.subtopics.single.name, 'Regla de tres');
      expect(result.isDemo, false);
    },
  );

  test(
    '404 no se sustituye por datos demo ni por ausencia de historial',
    () async {
      final dio = Dio();
      addTearDown(dio.close);
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.badResponse,
                response: Response(requestOptions: options, statusCode: 404),
              ),
            );
          },
        ),
      );
      await expectLater(
        LearningEvidenceRepository(dio).load(),
        throwsA(
          isA<ApiError>().having(
            (error) => error.code,
            'code',
            'evidence_not_deployed',
          ),
        ),
      );
    },
  );

  test(
    'malformado se informa sin mostrar el contenido crudo del servidor',
    () async {
      final dio = Dio();
      addTearDown(dio.close);
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response(
                requestOptions: options,
                data: {'version': 'incorrect'},
                statusCode: 200,
              ),
            );
          },
        ),
      );
      await expectLater(
        LearningEvidenceRepository(dio).load(),
        throwsA(
          isA<ApiError>().having(
            (error) => error.code,
            'code',
            'invalid_evidence',
          ),
        ),
      );
    },
  );
}
