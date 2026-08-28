import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/gamification/data/remote_gamification_repository.dart';
import 'package:saber_plus/features/gamification/domain/gamification_models.dart';

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

  test('descarga y recupera un certificado PDF dentro de la cuenta', () async {
    final temporary = await Directory.systemTemp.createTemp('saberplus-cert-');
    addTearDown(() => temporary.delete(recursive: true));
    late RequestOptions captured;
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          captured = options;
          handler.resolve(
            Response<List<int>>(
              requestOptions: options,
              statusCode: 200,
              headers: Headers.fromMap({
                'content-disposition': [
                  'attachment; filename="certificado-primer-paso.pdf"',
                ],
              }),
              data: const [0x25, 0x50, 0x44, 0x46, 1, 2, 3],
            ),
          );
        },
      ),
    );
    final repository = RemoteGamificationRepository(
      dio,
      certificateDirectory: () async => temporary,
    );

    final certificate = await repository.downloadCertificate(
      userId: '../student-1',
      achievement: _unlockedAchievement,
    );
    final existing = await repository.findCertificate(
      userId: '../student-1',
      achievement: _unlockedAchievement,
    );

    expect(captured.path, '/gamificacion/logros/PRIMER_PASO/certificado');
    expect(captured.responseType, ResponseType.bytes);
    expect(certificate.fileName, 'certificado-primer-paso.pdf');
    expect(certificate.localPath, startsWith(temporary.path));
    expect(certificate.localPath, isNot(contains('..')));
    expect(await File(certificate.localPath).readAsBytes(), const [
      0x25,
      0x50,
      0x44,
      0x46,
      1,
      2,
      3,
    ]);
    expect(existing?.achievementId, 'PRIMER_PASO');
    expect(existing?.byteSize, 7);
  });

  test('no solicita certificados de logros bloqueados', () async {
    var requests = 0;
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests++;
          handler.reject(DioException(requestOptions: options));
        },
      ),
    );
    final temporary = await Directory.systemTemp.createTemp('saberplus-cert-');
    addTearDown(() => temporary.delete(recursive: true));
    final repository = RemoteGamificationRepository(
      dio,
      certificateDirectory: () async => temporary,
    );

    await expectLater(
      repository.downloadCertificate(
        userId: 'student-1',
        achievement: const Achievement(
          id: 'RACHA_7',
          title: 'Semana completa',
          description: 'Alcanza una racha de 7 días.',
          category: AchievementCategory.streak,
          unlocked: false,
          progress: 3,
          goal: 7,
          percentage: 43,
        ),
      ),
      throwsA(isA<Exception>()),
    );
    expect(requests, 0);
  });
}

const _unlockedAchievement = Achievement(
  id: 'PRIMER_PASO',
  title: 'Primer paso',
  description: 'Responde tu primera pregunta.',
  category: AchievementCategory.practice,
  unlocked: true,
  progress: 1,
  goal: 1,
  percentage: 100,
);
