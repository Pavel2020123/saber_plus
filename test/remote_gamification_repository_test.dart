import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/gamification/data/remote_gamification_repository.dart';

void main() {
  test('consulta el resumen protegido de gamificación', () async {
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
                'data': {
                  'racha': {
                    'actual': 4,
                    'mejor': 8,
                    'activoHoy': false,
                    'ultimaActividad': '2026-08-27',
                  },
                  'actividad': [
                    {'fecha': '2026-08-27', 'cantidad': 3},
                  ],
                  'resumen': {
                    'desbloqueados': 5,
                    'total': 16,
                    'preguntasRespondidas': 50,
                  },
                  'logros': <Object>[],
                },
              },
            ),
          );
        },
      ),
    );

    final summary = await RemoteGamificationRepository(dio).loadSummary();

    expect(captured.method, 'GET');
    expect(captured.path, '/gamificacion/resumen');
    expect(summary.streak.current, 4);
    expect(summary.totals.unlocked, 5);
    expect(summary.activity.single.count, 3);
  });
}
