import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/gamification/data/demo_gamification_repository.dart';
import 'package:saber_plus/features/gamification/data/remote_gamification_repository.dart';
import 'package:saber_plus/features/gamification/domain/course_certificate.dart';
import 'package:saber_plus/features/gamification/presentation/course_certificates_section.dart';
import 'package:saber_plus/features/gamification/presentation/gamification_providers.dart';

List<Map<String, Object>> catalog() => [
  for (final type in CourseCertificateType.values)
    {
      'id': type.id,
      'total': type == CourseCertificateType.course ? 5 : 2,
      'completadas': 0,
      'disponible': false,
    },
];

void main() {
  test('parsea seis tipos separados de los logros', () {
    final data = catalog()..add({'id': 'PRIMER_PASO', 'disponible': true});
    final result = CourseCertificate.parseList(data);
    expect(result, hasLength(6));
    expect(result.any((item) => item.available), isFalse);
  });

  test('no habilita áreas vacías ni disponibilidad inconsistente', () {
    final data = catalog();
    data[0].addAll({'total': 0, 'disponible': true});
    data[1]['disponible'] = true;
    final result = CourseCertificate.parseList(data);
    expect(result[0].available, isFalse);
    expect(result[1].available, isFalse);
  });

  test('rechaza catálogos parciales, duplicados y progreso negativo', () {
    expect(() => CourseCertificate.parseList([]), throwsFormatException);
    expect(
      () => CourseCertificate.parseList(catalog()..add(catalog().first)),
      throwsFormatException,
    );
    final data = catalog();
    data[0]['completadas'] = -1;
    expect(() => CourseCertificate.parseList(data), throwsFormatException);
  });

  test('consulta la nueva ruta y soporta respuesta envuelta', () async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.path, '/gamificacion/certificados');
          handler.resolve(
            Response(requestOptions: options, data: {'data': catalog()}),
          );
        },
      ),
    );
    expect(
      await RemoteGamificationRepository(dio).loadCertificates(),
      hasLength(6),
    );
  });

  test('la demostración nunca emite PDFs personales', () async {
    final demo = DemoGamificationRepository();
    expect(
      (await demo.loadCertificates()).every((item) => !item.available),
      isTrue,
    );
    expect(
      () => demo.downloadCertificate(
        userId: 'demo',
        certificate: const CourseCertificate(
          type: CourseCertificateType.english,
          available: true,
        ),
      ),
      throwsException,
    );
  });

  testWidgets('muestra seis tarjetas sin desbordar con textos grandes', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          courseCertificatesProvider.overrideWith(
            (ref) async => CourseCertificate.parseList(catalog()),
          ),
        ],
        child: MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 640),
              textScaler: TextScaler.linear(2),
            ),
            child: const Scaffold(
              body: SingleChildScrollView(
                child: SizedBox(
                  width: 320,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CourseCertificatesSection(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (final type in CourseCertificateType.values) {
      expect(find.byKey(Key('course-certificate-${type.id}')), findsOneWidget);
      final button = tester.widget<OutlinedButton>(
        find.byKey(Key('download-course-certificate-${type.id}')),
      );
      expect(button.onPressed, isNull);
    }
    expect(tester.takeException(), isNull);
  });
}
