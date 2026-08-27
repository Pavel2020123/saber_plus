import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/core/network/access_token_store.dart';
import 'package:saber_plus/core/network/auth_interceptor.dart';
import 'package:saber_plus/features/academic/data/remote_academic_repository.dart';
import 'package:saber_plus/features/academic/domain/academic_models.dart';
import 'package:saber_plus/features/auth/data/remote_auth_repository.dart';

void main() {
  const apiBaseUrl = String.fromEnvironment('AUTH_E2E_API_BASE_URL');
  const email = String.fromEnvironment('AUTH_E2E_EMAIL');
  const password = String.fromEnvironment('AUTH_E2E_PASSWORD');
  final enabled =
      apiBaseUrl.isNotEmpty && email.isNotEmpty && password.isNotEmpty;

  test(
    'Flutter completa el diagnóstico real y consulta sus falencias',
    () async {
      final publicDio = Dio(BaseOptions(baseUrl: apiBaseUrl));
      final authenticatedDio = Dio(BaseOptions(baseUrl: apiBaseUrl));
      final tokenStore = AccessTokenStore();
      authenticatedDio.interceptors.add(AuthInterceptor(tokenStore));

      final auth = RemoteAuthRepository(publicDio, authenticatedDio);
      final login = await auth.login(email: email, password: password);
      tokenStore.set(login.tokens.accessToken);
      final academic = RemoteAcademicRepository(authenticatedDio);

      final started = await academic.startDiagnostic();
      expect(started.status, DiagnosticStatus.inProgress);
      expect(started.questions, hasLength(15));
      expect(
        started.questions.every((question) => question.options.isNotEmpty),
        isTrue,
      );

      final result = await academic.finishDiagnostic([
        for (final question in started.questions)
          DiagnosticAnswer(
            questionId: question.id,
            answerId: question.options.first.id,
            responseTimeSeconds: 1,
          ),
      ]);
      expect(result.status, DiagnosticStatus.completed);
      expect(result.totalQuestions, 15);
      expect(result.resultsByArea, hasLength(5));

      final weakTopics = await academic.loadWeakTopics();
      final failedQuestions = weakTopics.fold<int>(
        0,
        (total, topic) => total + topic.failedQuestions,
      );
      expect(failedQuestions, result.totalQuestions - result.correctAnswers);
    },
    skip: enabled ? false : 'Requiere las variables AUTH_E2E_*.',
  );
}
