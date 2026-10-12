import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/core/network/access_token_store.dart';
import 'package:saber_plus/core/network/auth_interceptor.dart';
import 'package:saber_plus/core/network/api_error.dart';
import 'package:saber_plus/features/auth/data/remote_auth_repository.dart';
import 'package:saber_plus/features/institutions/data/institution_directory_repository.dart';
import 'package:saber_plus/features/institutions/data/institution_profile_repository.dart';

// Opt-in: only the disposable loopback session prepared by the local supervisor.
void main() {
  const url = String.fromEnvironment('AUTH_E2E_API_BASE_URL');
  const password = String.fromEnvironment('AUTH_E2E_PASSWORD');
  final enabled = url == 'http://127.0.0.1:43187' && password.isNotEmpty;
  late Dio ownerDio, readerDio, studentDio;
  Future<Dio> authenticated(String email) async {
    final public = Dio(BaseOptions(baseUrl: url));
    final dio = Dio(BaseOptions(baseUrl: url));
    final store = AccessTokenStore();
    dio.interceptors.add(AuthInterceptor(store));
    try {
      final login = await RemoteAuthRepository(
        public,
        dio,
      ).login(email: email, password: password);
      store.set(login.tokens.accessToken);
      return dio;
    } finally {
      public.close();
    }
  }

  setUpAll(() async {
    if (!enabled) return;
    ownerDio = await authenticated('teacher@example.invalid');
    readerDio = await authenticated('teacher-reader@example.invalid');
    studentDio = await authenticated('student@example.invalid');
  });
  tearDownAll(() {
    if (!enabled) return;
    ownerDio.close();
    readerDio.close();
    studentDio.close();
  });
  final skip = enabled ? false : 'Requiere sesión local C1 y AUTH_E2E_*.';
  test(
    'C1 Flutter/API: propietario guarda y estudiante consulta presentación',
    () async {
      final repository = RemoteInstitutionProfileRepository(ownerDio);
      final original = await repository.load();
      expect(original.canEdit, isTrue);
      try {
        final saved = await repository.save(
          original,
          'Presentación de ensayo Flutter C1',
        );
        expect(saved.revision, original.revision + 1);
        final public = await RemoteInstitutionDirectoryRepository(
          studentDio,
        ).detail(original.id);
        expect(public.description, 'Presentación de ensayo Flutter C1');
        expect(public.locationLabel, contains('LETICIA'));
      } finally {
        final current = await repository.load();
        await repository.save(current, original.description ?? '');
      }
    },
    skip: skip,
  );
  test('C1 Flutter/API: docente lector recibe solo lectura', () async {
    expect(
      (await RemoteInstitutionProfileRepository(readerDio).load()).canEdit,
      isFalse,
    );
  }, skip: skip);
  test(
    'C1 Flutter/API: revisión antigua produce conflicto y conserva versión nueva',
    () async {
      final repository = RemoteInstitutionProfileRepository(ownerDio);
      final original = await repository.load();
      try {
        await repository.save(original, 'Versión reciente C1');
        await expectLater(
          repository.save(original, 'Versión obsoleta C1'),
          throwsA(isA<ApiError>().having((e) => e.code, 'status', '409')),
        );
        expect((await repository.load()).description, 'Versión reciente C1');
      } finally {
        final current = await repository.load();
        await repository.save(current, original.description ?? '');
      }
    },
    skip: skip,
  );
}
