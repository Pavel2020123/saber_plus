import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/gamification/data/remote_gamification_repository.dart';
import 'package:saber_plus/features/gamification/domain/course_certificate.dart';

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
                  'attachment; filename="certificado-matematicas-juanito-perez.pdf"',
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
      certificate: _availableCertificate,
    );
    final existing = await repository.findCertificate(
      userId: '../student-1',
      certificate: _availableCertificate,
    );

    expect(captured.path, '/gamificacion/certificados/MATEMATICAS/pdf');
    expect(captured.responseType, ResponseType.bytes);
    expect(certificate.fileName, 'certificado-matematicas-juanito-perez.pdf');
    expect(
      certificate.localPath,
      contains('certificado-matematicas-juanito-perez.pdf'),
    );
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
    expect(existing?.certificateId, 'MATEMATICAS');
    expect(existing?.fileName, 'certificado-matematicas-juanito-perez.pdf');
    expect(existing?.byteSize, 7);
  });

  test('no solicita certificados de áreas pendientes', () async {
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
        certificate: const CourseCertificate(
          type: CourseCertificateType.english,
        ),
      ),
      throwsA(isA<Exception>()),
    );
    expect(requests, 0);
  });
}

const _availableCertificate = CourseCertificate(
  type: CourseCertificateType.mathematics,
  available: true,
  completed: 1,
  total: 1,
);
