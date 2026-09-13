import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
import '../../auth/domain/session.dart';
import '../../auth/presentation/session_controller.dart';
import '../data/teacher_student_evidence_repository.dart';
import '../domain/teacher_student_evidence.dart';

final teacherStudentEvidenceRepositoryProvider =
    Provider<TeacherStudentEvidenceRepository>((ref) {
      final session = ref.watch(sessionControllerProvider);
      return session.user?.isDemo == true
          ? DemoTeacherStudentEvidenceRepository()
          : RemoteTeacherStudentEvidenceRepository(ref.watch(dioProvider));
    });

final teacherStudentEvidenceProvider = FutureProvider.autoDispose
    .family<TeacherStudentEvidence, String>((ref, studentId) async {
      final session = ref.watch(sessionControllerProvider);
      if (session.user?.role != AppRole.teacher) {
        throw const ApiError(
          code: 'teacher_session_required',
          message: 'Inicia sesión como profesor para consultar esta ficha.',
        );
      }
      final cancel = CancelToken();
      ref.onDispose(() => cancel.cancel());
      return ref
          .watch(teacherStudentEvidenceRepositoryProvider)
          .load(studentId, cancelToken: cancel);
    });
