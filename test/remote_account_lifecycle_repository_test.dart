import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/core/network/api_error.dart';
import 'package:saber_plus/features/institutions/data/remote_account_lifecycle_repository.dart';
import 'package:saber_plus/features/institutions/domain/personal_return_eligibility.dart';

void main() {
  late Dio dio;
  late RemoteAccountLifecycleRepository repository;
  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:1'));
    repository = RemoteAccountLifecycleRepository(dio);
  });
  tearDown(() => dio.close(force: true));

  void respond(Object? body, {int status = 200}) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response(requestOptions: options, data: body, statusCode: status),
          );
        },
      ),
    );
  }

  PersonalReturnEligibility decision({bool managed = false}) =>
      PersonalReturnEligibility.fromJson({
        'puedeVolver': !managed,
        'gestionada': managed,
        'asignacionId': 'seat',
        'versionAsignacion': '2026-11-03T12:00:00.123Z',
      });

  test(
    'return carries exact server revision and caller idempotency key',
    () async {
      late RequestOptions sent;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            sent = options;
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 201,
                data: {
                  'data': {
                    'usuarioId': 'self',
                    'modalidad': 'PERSONAL',
                    'historialConservado': true,
                  },
                },
              ),
            );
          },
        ),
      );
      await repository.returnToPersonal(
        institutionId: 'school',
        userId: 'self',
        operationId: 'operation',
        eligibility: decision(),
      );
      expect(sent.path, '/instituciones/school/licencia/volver-personal');
      expect(sent.data, {
        'usuarioId': 'self',
        'operacionId': 'operation',
        'asignacionId': 'seat',
        'versionAsignacion': '2026-11-03T12:00:00.123Z',
      });
    },
  );

  test('managed decision never sends a return command', () async {
    var sent = 0;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (_, _) {
          sent++;
        },
      ),
    );
    await expectLater(
      repository.returnToPersonal(
        institutionId: 'school',
        userId: 'self',
        operationId: 'operation',
        eligibility: decision(managed: true),
      ),
      throwsStateError,
    );
    expect(sent, 0);
  });

  test('timeout maps to ApiError without retrying POST', () async {
    var sent = 0;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          sent++;
          handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.receiveTimeout,
            ),
          );
        },
      ),
    );
    await expectLater(
      repository.returnToPersonal(
        institutionId: 'school',
        userId: 'self',
        operationId: 'operation',
        eligibility: decision(),
      ),
      throwsA(isA<ApiError>()),
    );
    expect(sent, 1);
  });

  test('missing eligibility cannot become a permission', () async {
    respond(null);
    await expectLater(
      repository.personalReturnEligibility('school'),
      throwsFormatException,
    );
  });

  test(
    'different-target receipt cannot be reported as own return success',
    () async {
      respond({
        'usuarioId': 'other',
        'modalidad': 'PERSONAL',
        'historialConservado': true,
      });
      await expectLater(
        repository.returnToPersonal(
          institutionId: 'school',
          userId: 'self',
          operationId: 'operation',
          eligibility: decision(),
        ),
        throwsFormatException,
      );
    },
  );

  test('privacy pagination rejects inconsistent server page', () async {
    respond({'pagina': 2, 'tieneSiguiente': false, 'items': []});
    await expectLater(repository.privacyRequests(1), throwsFormatException);
  });

  test(
    'privacy request verifies receipt belongs to submitting account',
    () async {
      respond({
        'id': 'request',
        'usuarioId': 'other',
        'estado': 'PENDIENTE',
        'creadoEn': '2026-11-03T12:00:00Z',
      });
      await expectLater(
        repository.requestSuppression(
          userId: 'self',
          operationId: 'operation',
          reason: 'Own request',
        ),
        throwsFormatException,
      );
    },
  );
}
