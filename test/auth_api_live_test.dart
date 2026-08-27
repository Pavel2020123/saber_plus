import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/core/network/access_token_store.dart';
import 'package:saber_plus/core/network/auth_interceptor.dart';
import 'package:saber_plus/features/academic/data/remote_academic_repository.dart';
import 'package:saber_plus/features/academic/domain/academic_models.dart';
import 'package:saber_plus/features/auth/data/remote_auth_repository.dart';
import 'package:saber_plus/features/auth/domain/session.dart';

void main() {
  const apiBaseUrl = String.fromEnvironment('AUTH_E2E_API_BASE_URL');
  const email = String.fromEnvironment('AUTH_E2E_EMAIL');
  const password = String.fromEnvironment('AUTH_E2E_PASSWORD');
  final enabled =
      apiBaseUrl.isNotEmpty && email.isNotEmpty && password.isNotEmpty;

  test(
    'Flutter inicia sesión y carga el inicio académico real',
    () async {
      final publicDio = Dio(BaseOptions(baseUrl: apiBaseUrl));
      final authenticatedDio = Dio(BaseOptions(baseUrl: apiBaseUrl));
      final tokenStore = AccessTokenStore();
      authenticatedDio.interceptors.add(AuthInterceptor(tokenStore));
      final repository = RemoteAuthRepository(publicDio, authenticatedDio);

      final login = await repository.login(email: email, password: password);
      tokenStore.set(login.tokens.accessToken);
      final profile = await repository.profile();

      expect(login.user.role, AppRole.student);
      expect(profile.email, email);
      expect(profile.emailVerified, isTrue);
      expect(profile.requiresEmailVerification, isFalse);

      final academic = await RemoteAcademicRepository(
        authenticatedDio,
      ).loadHome();
      expect(academic.diagnostic.status, DiagnosticStatus.notStarted);
      expect(academic.plan.status, StudyPlanStatus.diagnosticPending);
    },
    skip: enabled ? false : 'Requiere las variables AUTH_E2E_*.',
  );
}
