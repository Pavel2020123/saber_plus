import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/academic/domain/academic_models.dart';
import 'package:saber_plus/features/progress/data/remote_progress_repository.dart';
import 'package:saber_plus/features/progress/domain/progress_models.dart';

void main() {
  test(
    'combina aprendizaje y rendimiento global por las cinco áreas',
    () async {
      final requests = <RequestOptions>[];
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requests.add(options);
            if (options.path == '/simulacros/progreso') {
              handler.resolve(
                Response<Map<String, dynamic>>(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'totalSubtemas': 10,
                    'temasVistos': 6,
                    'temasCompletados': 4,
                    'porcentajeGeneral': 55,
                    'porSubtema': <String, int>{},
                  },
                ),
              );
              return;
            }
            handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'resumen': {
                    'total': 8,
                    'correctas': 6,
                    'incorrectas': 2,
                    'porcentajeAciertos': 75,
                  },
                  'respuestas': <Object>[],
                },
              ),
            );
          },
        ),
      );

      final dashboard = await RemoteProgressRepository(dio).loadDashboard();

      expect(requests, hasLength(7));
      expect(dashboard.study.overallPercentage, 55);
      expect(dashboard.answers.total, 8);
      expect(dashboard.byArea.keys, containsAll(AcademicArea.values));
      expect(
        requests
            .where(
              (request) => request.path == '/simulacros/historial-respuestas',
            )
            .every((request) => request.queryParameters['limite'] == 1),
        isTrue,
      );
    },
  );

  test('envía los filtros del cuaderno con los valores del backend', () async {
    late RequestOptions captured;
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          captured = options;
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: {
                'resumen': {
                  'total': 0,
                  'pendientes': 0,
                  'repasando': 0,
                  'dominados': 0,
                },
                'errores': <Object>[],
              },
            ),
          );
        },
      ),
    );

    await RemoteProgressRepository(dio).loadNotebook(
      const NotebookFilter(
        area: AcademicArea.english,
        status: NotebookStatus.mastered,
      ),
    );

    expect(captured.path, '/cuaderno-errores');
    expect(captured.queryParameters, {'area': 'INGLES', 'estado': 'DOMINADO'});
  });

  test('guarda la nota y estado de una pregunta con PATCH', () async {
    late RequestOptions captured;
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          captured = options;
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: {
                'preguntaId': 'question 1',
                'nota': 'Repasar proporciones',
                'estado': 'REPASANDO',
              },
            ),
          );
        },
      ),
    );

    await RemoteProgressRepository(dio).updateNotebookEntry(
      questionId: 'question 1',
      note: '  Repasar proporciones  ',
      status: NotebookStatus.reviewing,
    );

    expect(captured.method, 'PATCH');
    expect(captured.path, '/cuaderno-errores/question%201');
    expect(captured.data, {
      'nota': 'Repasar proporciones',
      'estado': 'REPASANDO',
    });
  });
}
