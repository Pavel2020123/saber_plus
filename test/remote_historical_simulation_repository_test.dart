import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/academic/domain/academic_models.dart';
import 'package:saber_plus/features/historical_simulations/data/remote_historical_simulation_repository.dart';
import 'package:saber_plus/features/practice/domain/practice_models.dart';

void main() {
  test('consulta únicamente metadatos y derechos del catálogo', () async {
    final adapter = _HandlerAdapter((options) {
      expect(options.path, '/simulacros/historicos');
      return {
        'data': {
          'actualizadoEn': '2026-08-30T12:00:00.000Z',
          'ediciones': [_availableEditionJson],
        },
      };
    });
    final repository = RemoteHistoricalSimulationRepository(_dio(adapter));

    final catalog = await repository.loadCatalog();

    expect(catalog.editions.single.canStart, isTrue);
    expect(catalog.editions.single.rights?.reference, 'SP-OWN-2024');
  });

  test('abre una jornada histórica protegida de 75 preguntas', () async {
    final adapter = _HandlerAdapter((options) {
      expect(options.path, '/simulacros/historicos/edition-2024/iniciar');
      expect(options.queryParameters['jornada'], 'AM');
      return {
        'data': {
          'intentoId': 'historical-attempt-1',
          'preguntas': _historicalQuestions(),
        },
      };
    });
    final repository = RemoteHistoricalSimulationRepository(_dio(adapter));

    final session = await repository.startEdition(
      editionId: 'edition-2024',
      block: OfficialSimulationBlock.morning,
    );

    expect(session.isHistorical, isTrue);
    expect(session.historicalEditionId, 'edition-2024');
    expect(session.historicalBlock, OfficialSimulationBlock.morning);
    expect(session.questions, hasLength(75));
    expect(session.areas.toSet(), containsAll(AcademicArea.values));

    final restored = PracticeSession.fromStoredJson(session.toStoredJson());
    expect(restored.isHistorical, isTrue);
    expect(restored.historicalEditionId, 'edition-2024');
    expect(restored.historicalBlock, OfficialSimulationBlock.morning);
  });

  test('califica la edición sin exponer respuestas antes del envío', () async {
    late RequestOptions captured;
    final adapter = _HandlerAdapter((options) {
      captured = options;
      return {
        'data': {
          'resumen': {
            'totalPreguntas': 1,
            'respuestasCorrectas': 1,
            'respuestasIncorrectas': 0,
            'puntaje': 100,
            'xpGanado': 10,
          },
          'detalle': <Object>[],
        },
      };
    });
    final repository = RemoteHistoricalSimulationRepository(_dio(adapter));

    final result = await repository.gradeEdition(
      editionId: 'edition-2024',
      block: OfficialSimulationBlock.afternoon,
      attemptId: 'historical-attempt-1',
      answers: const [
        PracticeAnswer(
          questionId: 'question-1',
          answerId: 'answer-1',
          responseTimeSeconds: 22,
        ),
      ],
    );

    expect(captured.path, '/simulacros/historicos/edition-2024/calificar');
    expect((captured.data as Map<String, dynamic>)['jornada'], 'PM');
    expect(result.summary.percentage, 100);
  });
}

Dio _dio(HttpClientAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
  dio.httpClientAdapter = adapter;
  return dio;
}

List<Map<String, dynamic>> _historicalQuestions() => List.generate(75, (index) {
  final area = AcademicArea.values[index % AcademicArea.values.length];
  return {
    'id': 'question-$index',
    'enunciado': 'Pregunta protegida $index',
    'dificultad': 'MEDIO',
    'respuestas': [
      {'id': 'answer-$index', 'texto': 'Opción pública'},
    ],
    'subtema': {
      'id': 'subtopic-$index',
      'nombre': 'Subtema',
      'tema': {'nombre': 'Tema', 'area': area.backendValue},
    },
  };
});

const _availableEditionJson = {
  'id': 'edition-2024',
  'anio': 2024,
  'titulo': 'Edición propia 2024',
  'descripcion': 'Contenido de SaberPlus.',
  'proveedor': 'SaberPlus',
  'totalPreguntas': 150,
  'estado': 'DISPONIBLE',
  'derechos': {
    'tipo': 'PROPIO',
    'titular': 'SaberPlus',
    'referencia': 'SP-OWN-2024',
  },
};

class _HandlerAdapter implements HttpClientAdapter {
  _HandlerAdapter(this.handler);

  final Map<String, dynamic> Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    jsonEncode(handler(options)),
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  void close({bool force = false}) {}
}
