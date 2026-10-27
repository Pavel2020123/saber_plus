import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/remote_auth_repository.dart';
import '../../auth/domain/session.dart';
import '../../auth/presentation/session_controller.dart';
import '../domain/teacher_institution_models.dart';
import 'institution_group_providers.dart';
import 'institution_student_code_entry.dart';
import 'institution_student_code_owner.dart';
import 'student_institution_code_providers.dart';
import 'student_institution_request_providers.dart';
import 'student_institution_requests_page.dart';
import 'teacher_institution_providers.dart';

class StudentInstitutionCodePage extends ConsumerWidget {
  const StudentInstitutionCodePage({super.key, this.owner = false});
  final bool owner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionControllerProvider.select((s) => s.user));
    Widget unavailable(String message, {VoidCallback? retry}) => Scaffold(
      appBar: AppBar(
        title: Text(
          owner ? 'Código de estudiantes' : 'Unirme a una institución',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(message),
          if (retry != null)
            TextButton(
              onPressed: retry,
              child: const Text('Reintentar consulta de permisos'),
            ),
        ],
      ),
    );
    if (user == null) {
      return unavailable('Inicia sesión para usar un código institucional.');
    }
    if (user.isDemo) {
      return unavailable(
        'Los códigos institucionales requieren una cuenta real de SaberPlus. No se generan ni se usan en la demostración.',
      );
    }
    if (user.role != (owner ? AppRole.teacher : AppRole.student)) {
      return unavailable('Esta cuenta no tiene acceso a esta pantalla.');
    }
    final repository = ref.watch(studentInstitutionCodeRepositoryProvider);
    if (owner) {
      return ref
          .watch(teacherInstitutionControllerProvider)
          .when(
            skipLoadingOnRefresh: false,
            loading: () => unavailable('Consultando permisos institucionales…'),
            error: (_, _) => unavailable(
              'No pudimos consultar los permisos.',
              retry: () => ref.invalidate(teacherInstitutionControllerProvider),
            ),
            data: (data) =>
                data.status == TeacherInstitutionStatus.linked &&
                    data.memberRole == InstitutionMemberRole.owner &&
                    data.institution?.verificationState == 'APROBADA'
                ? InstitutionStudentCodeOwner(
                    key: ValueKey((user.id, data.institution!.id, repository)),
                    repository: repository,
                    copy: (code) =>
                        Clipboard.setData(ClipboardData(text: code)),
                  )
                : unavailable(
                    'Solo el propietario de una institución aprobada puede administrar este código.',
                  ),
          );
    }
    bool sameAccount() =>
        context.mounted &&
        ref.read(sessionControllerProvider).user?.id == user.id &&
        ref.read(sessionControllerProvider).user?.isDemo == false;
    Future<void> refresh() async {
      if (!sameAccount()) return;
      await ref.read(sessionControllerProvider.notifier).refreshProfile();
      if (!sameAccount()) return;
      ref.invalidate(studentGroupsControllerProvider);
      ref.invalidate(studentRequestMenuProvider);
    }

    return InstitutionStudentCodeEntry(
      key: ValueKey((user.id, repository)),
      repository: repository,
      linkedInstitutionId: user.institutionId,
      consultMembership: () async {
        // refreshProfile tolera fallos de red para otros flujos. Aquí la consulta
        // debe fallar explícitamente antes de habilitar un reintento incierto.
        final profile = await ref.read(authRepositoryProvider).profile();
        if (!sameAccount() ||
            profile.id != user.id ||
            profile.role != AppRole.student) {
          throw const FormatException('La sesión cambió.');
        }
        await refresh();
        return profile.institutionId;
      },
      onJoined: refresh,
      onRequests: () => Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => const StudentInstitutionRequestsPage(),
        ),
      ),
    );
  }
}
