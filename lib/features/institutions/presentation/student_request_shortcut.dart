import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/session_controller.dart';
import '../domain/student_institution_request.dart';
import 'institution_group_providers.dart';
import 'student_institution_request_providers.dart';
import 'student_institution_requests_page.dart';

/// Acceso contextual. No ocupa espacio si no hay nada por gestionar.
class StudentRequestShortcut extends ConsumerStatefulWidget {
  const StudentRequestShortcut({super.key});
  @override
  ConsumerState<StudentRequestShortcut> createState() =>
      _StudentRequestShortcutState();
}

class _StudentRequestShortcutState extends ConsumerState<StudentRequestShortcut>
    with WidgetsBindingObserver {
  bool? _active;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final active =
        TickerMode.valuesOf(context).enabled &&
        (ModalRoute.of(context)?.isCurrent ?? true);
    if (_active == false && active) {
      Future.microtask(() {
        if (mounted) ref.invalidate(studentRequestMenuProvider);
      });
    }
    _active = active;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted && _active == true) {
      ref.invalidate(studentRequestMenuProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(studentRequestMenuProvider);
    ref.listen(studentRequestMenuProvider, (previous, next) {
      final result = next.asData?.value.latest;
      final user = ref.read(sessionControllerProvider).user;
      if (result?.status == StudentRequestStatus.approved &&
          user?.institutionId == null) {
        unawaited(
          ref.read(sessionControllerProvider.notifier).refreshProfile(),
        );
        ref.invalidate(studentGroupsControllerProvider);
      }
    });
    return state.when(
      skipLoadingOnRefresh: false,
      loading: () => const SizedBox.shrink(),
      error: (_, _) => ListTile(
        leading: const Icon(Icons.sync_problem_outlined),
        title: const Text('No pudimos consultar el ingreso'),
        trailing: IconButton(
          tooltip: 'Reintentar consulta de ingreso',
          icon: const Icon(Icons.refresh),
          onPressed: () => ref.invalidate(studentRequestMenuProvider),
        ),
      ),
      data: (data) {
        if (!data.visible) return const SizedBox.shrink();
        final pending = data.latest!.status == StudentRequestStatus.pending;
        return ListTile(
          key: const Key('open-student-institution-requests'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          leading: Icon(
            pending
                ? Icons.hourglass_top_rounded
                : Icons.mark_email_unread_outlined,
          ),
          title: Text(
            pending
                ? 'Solicitud de ingreso · Pendiente'
                : 'Respuesta a tu solicitud de ingreso',
          ),
          subtitle: Text(
            pending
                ? data.latest!.institutionName
                : 'Rechazada · ${data.latest!.institutionName}',
          ),
          trailing: IconButton(
            tooltip: 'Actualizar estado de ingreso',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(studentRequestMenuProvider),
          ),
          onTap: () async {
            await Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => const StudentInstitutionRequestsPage(),
              ),
            );
            if (mounted) ref.invalidate(studentRequestMenuProvider);
          },
        );
      },
    );
  }
}
