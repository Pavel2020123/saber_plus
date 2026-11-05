import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
import '../../auth/presentation/session_controller.dart';
import '../data/remote_vocational_orientation_repository.dart';
import '../domain/vocational_orientation.dart';
import '../domain/vocational_orientation_repository.dart';

final vocationalOrientationRepositoryProvider =
    Provider<VocationalOrientationRepository>((ref) {
      final user = ref.watch(sessionControllerProvider.select((s) => s.user));
      if (user == null || user.isDemo) {
        return const _UnavailableVocationalRepository();
      }
      return RemoteVocationalOrientationRepository(ref.watch(dioProvider));
    });

typedef VocationalOfficialLinkOpener = Future<bool> Function(Uri uri);
final vocationalOfficialLinkOpenerProvider =
    Provider<VocationalOfficialLinkOpener>(
      (ref) =>
          (uri) => launchUrl(uri, mode: LaunchMode.externalApplication),
    );

class _UnavailableVocationalRepository
    implements VocationalOrientationRepository {
  const _UnavailableVocationalRepository();

  Never _unavailable() => throw const ApiError(
    code: 'demo_unavailable',
    message:
        'Inicia sesión con tu cuenta de estudiante para guardar esta exploración privada.',
  );

  @override
  Future<VocationalQuestionnaire> questionnaire() async => _unavailable();
  @override
  Future<VocationalAttempt?> current() async => _unavailable();
  @override
  Future<VocationalAttempt> start() async => _unavailable();
  @override
  Future<VocationalAttempt> saveAnswer(
    String attemptId,
    String questionId,
    VocationalAnswer answer,
  ) async => _unavailable();
  @override
  Future<VocationalAttempt> finish(String attemptId) async => _unavailable();
  @override
  Future<VocationalHistory> history(int page) async => _unavailable();
  @override
  Future<VocationalAttempt> getAttempt(String attemptId) async =>
      _unavailable();
  @override
  Future<void> deleteAttempt(String attemptId) async => _unavailable();
}
