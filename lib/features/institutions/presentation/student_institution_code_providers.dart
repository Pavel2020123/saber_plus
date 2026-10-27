import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../auth/presentation/session_controller.dart';
import '../data/student_institution_code_repository.dart';
import '../domain/student_institution_code.dart';

final studentInstitutionCodeRepositoryProvider =
    Provider<StudentInstitutionCodeRepository>((ref) {
      // Cambiar de cuenta/rol/demo recrea la pantalla y descarta secretos/respuestas tardías.
      ref.watch(
        sessionControllerProvider.select(
          (s) => (s.user?.id, s.user?.role, s.user?.isDemo),
        ),
      );
      return RemoteStudentInstitutionCodeRepository(ref.watch(dioProvider));
    });
