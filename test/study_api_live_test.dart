import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/core/network/access_token_store.dart';
import 'package:saber_plus/core/network/auth_interceptor.dart';
import 'package:saber_plus/features/academic/domain/academic_models.dart';
import 'package:saber_plus/features/auth/data/remote_auth_repository.dart';
import 'package:saber_plus/features/study/data/remote_study_repository.dart';
import 'package:saber_plus/features/study/domain/study_models.dart';

void main() {
  const apiBaseUrl = String.fromEnvironment('AUTH_E2E_API_BASE_URL');
  const email = String.fromEnvironment('AUTH_E2E_EMAIL');
  const password = String.fromEnvironment('AUTH_E2E_PASSWORD');
  final enabled =
      apiBaseUrl.isNotEmpty && email.isNotEmpty && password.isNotEmpty;

  test(
    'Flutter consulta contenido, guarda progreso y descarga un PDF real',
    () async {
      final publicDio = Dio(BaseOptions(baseUrl: apiBaseUrl));
      final authenticatedDio = Dio(BaseOptions(baseUrl: apiBaseUrl));
      final tokenStore = AccessTokenStore();
      authenticatedDio.interceptors.add(AuthInterceptor(tokenStore));

      final auth = RemoteAuthRepository(publicDio, authenticatedDio);
      final login = await auth.login(email: email, password: password);
      tokenStore.set(login.tokens.accessToken);
      final study = RemoteStudyRepository(authenticatedDio);

      StudyTheme? firstTheme;
      StudySubtopic? firstSubtopic;
      for (final area in AcademicArea.values) {
        final catalog = await study.loadCatalog(area);
        expect(catalog.area, area);
        if (catalog.themes.isNotEmpty &&
            catalog.themes.first.subtopics.isNotEmpty &&
            firstTheme == null) {
          firstTheme = catalog.themes.first;
          firstSubtopic = catalog.themes.first.subtopics.first;
        }
      }
      expect(firstTheme, isNotNull);
      expect(firstSubtopic, isNotNull);

      await study.updateSubtopicProgress(firstSubtopic!.id, 100);
      final progress = await study.loadProgress();
      expect(progress.percentageFor(firstSubtopic.id), 100);

      final pdf = await study.downloadThemePdf(firstTheme!);
      final file = File(pdf.path);
      expect(await file.exists(), isTrue);
      expect(await file.length(), greaterThan(4));
      await file.delete();
    },
    skip: enabled ? false : 'Requiere las variables AUTH_E2E_*.',
  );
}
