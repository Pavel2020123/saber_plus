import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../auth/presentation/session_controller.dart';
import '../../auth/domain/session.dart';
import '../data/student_request_notice_store.dart';
import '../data/student_institution_request_repository.dart';
import '../domain/student_institution_request.dart';

final studentInstitutionRequestRepositoryProvider =
    Provider<StudentInstitutionRequestRepository>((ref) {
      // Destruir pantalla/borradores y descartar respuestas al cambiar de cuenta.
      ref.watch(
        sessionControllerProvider.select(
          (s) =>
              (s.user?.id, s.user?.institutionId, s.user?.role, s.user?.isDemo),
        ),
      );
      return RemoteStudentInstitutionRequestRepository(ref.watch(dioProvider));
    });

class StudentRequestMenuState {
  const StudentRequestMenuState({this.latest, this.rejectionRead = false});
  final StudentInstitutionRequest? latest;
  final bool rejectionRead;
  bool get visible =>
      latest?.status == StudentRequestStatus.pending ||
      (latest?.status == StudentRequestStatus.rejected && !rejectionRead);
}

final studentRequestMenuProvider =
    FutureProvider.autoDispose<StudentRequestMenuState>((ref) async {
      final user = ref.watch(sessionControllerProvider.select((s) => s.user));
      if (user == null ||
          user.role != AppRole.student ||
          user.isDemo ||
          user.institutionId != null) {
        return const StudentRequestMenuState();
      }
      final repository = ref.watch(studentInstitutionRequestRepositoryProvider);
      final notices = ref.watch(studentRequestNoticeStoreProvider);
      final page = await repository.own(1);
      final latest = page.items.firstOrNull;
      var read = false;
      if (latest?.status == StudentRequestStatus.rejected) {
        try {
          read = await notices.wasRead(user.id, latest!);
        } catch (_) {
          // Si fallan las preferencias, conservar el aviso en lugar de ocultarlo.
        }
      }
      return StudentRequestMenuState(latest: latest, rejectionRead: read);
    });
