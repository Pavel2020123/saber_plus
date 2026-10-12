import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/institutions/data/institution_profile_repository.dart';
import 'package:saber_plus/features/institutions/domain/institution_profile.dart';

void main() {
  const profile = InstitutionProfile(
    id: 'i',
    name: 'Colegio',
    description: null,
    revision: 4,
    canEdit: true,
  );
  test('PATCH envía solo descripción y revisión y valida acuse', () async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.method, 'PATCH');
          expect(options.path, '/instituciones/me/perfil');
          expect(options.data, {'revision': 4, 'descripcion': 'Hola'});
          handler.resolve(
            Response(
              requestOptions: options,
              data: {'revision': 5, 'descripcion': 'Hola'},
            ),
          );
        },
      ),
    );
    final result = await RemoteInstitutionProfileRepository(
      dio,
    ).save(profile, ' Hola ');
    expect(result.revision, 5);
    expect(result.description, 'Hola');
  });
  test('respuesta equivocada no se considera guardada', () async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response(
              requestOptions: options,
              data: {'revision': 4, 'descripcion': 'Otro'},
            ),
          );
        },
      ),
    );
    await expectLater(
      RemoteInstitutionProfileRepository(dio).save(profile, 'Hola'),
      throwsFormatException,
    );
  });
  test('sin permisos no hace petición', () async {
    final dio = Dio();
    var requests = 0;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests++;
          handler.reject(DioException(requestOptions: options));
        },
      ),
    );
    await expectLater(
      RemoteInstitutionProfileRepository(dio).save(
        const InstitutionProfile(
          id: 'i',
          name: 'Colegio',
          description: null,
          revision: 0,
          canEdit: false,
        ),
        'Texto',
      ),
      throwsArgumentError,
    );
    expect(requests, 0);
  });
  test('fallo remoto no se convierte en éxito demo', () async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) => handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
          ),
        ),
      ),
    );
    await expectLater(
      RemoteInstitutionProfileRepository(dio).load(),
      throwsException,
    );
  });
  test('demo conserva y detecta revisión antigua', () async {
    final demo = DemoInstitutionProfileRepository();
    final old = await demo.load();
    await demo.save(old, 'Nuevo');
    expect((await demo.load()).description, 'Nuevo');
    await expectLater(demo.save(old, 'Viejo'), throwsException);
  });
}
