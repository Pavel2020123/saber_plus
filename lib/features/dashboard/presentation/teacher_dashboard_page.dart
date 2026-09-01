import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_error.dart';
import '../../auth/presentation/session_controller.dart';
import '../../institutions/domain/teacher_institution_models.dart';
import '../../institutions/presentation/teacher_institution_providers.dart';

class TeacherDashboardPage extends ConsumerStatefulWidget {
  const TeacherDashboardPage({super.key});

  @override
  ConsumerState<TeacherDashboardPage> createState() =>
      _TeacherDashboardPageState();
}

class _TeacherDashboardPageState extends ConsumerState<TeacherDashboardPage> {
  var _working = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(sessionControllerProvider).user;
    final institution = ref.watch(teacherInstitutionControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Espacio del profesor'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _working
                ? null
                : () => ref
                      .read(teacherInstitutionControllerProvider.notifier)
                      .reload(),
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: _working
                ? null
                : () async {
                    await ref
                        .read(sessionControllerProvider.notifier)
                        .signOut();
                    if (context.mounted) context.go('/welcome');
                  },
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: institution.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _LoadError(
          message: _message(error),
          onRetry: () =>
              ref.read(teacherInstitutionControllerProvider.notifier).reload(),
        ),
        data: (data) => RefreshIndicator(
          onRefresh: () =>
              ref.read(teacherInstitutionControllerProvider.notifier).reload(),
          child: ListView(
            key: const Key('teacher-institution-list'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
            children: [
              Text(
                'Hola, ${user?.firstName ?? 'profe'}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              const Text(
                'Tu cuenta es personal. No compartas la contraseña con otros docentes ni con la institución.',
              ),
              const SizedBox(height: 20),
              if (data.invitations.isNotEmpty) ...[
                _IncomingInvitations(
                  invitations: data.invitations,
                  working: _working,
                  onRespond: _respondInvitation,
                ),
                const SizedBox(height: 16),
              ],
              switch (data.status) {
                TeacherInstitutionStatus.noInstitution => _NoInstitution(
                  working: _working,
                  onCreate: _createInstitution,
                  onRequest: _requestJoin,
                ),
                TeacherInstitutionStatus.pendingRequest => _PendingRequest(
                  request: data.joinRequest!,
                  working: _working,
                  onCancel: _cancelRequest,
                ),
                TeacherInstitutionStatus.linked => _LinkedInstitution(
                  institution: data.institution!,
                  role: data.memberRole ?? InstitutionMemberRole.teacher,
                  onGroups: () => context.push('/teacher/groups'),
                  onManage:
                      (data.memberRole ?? InstitutionMemberRole.teacher)
                          .canManage
                      ? () => context.push('/teacher/administration')
                      : null,
                ),
              },
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createInstitution() async {
    final values = await showDialog<({String name, String welcome})>(
      context: context,
      builder: (_) => const _CreateInstitutionDialog(),
    );
    if (values == null || !mounted) return;
    await _run(
      () => ref
          .read(teacherInstitutionControllerProvider.notifier)
          .createInstitution(name: values.name, welcomeMessage: values.welcome),
      success: 'Institución creada. Ahora eres su propietario.',
    );
  }

  Future<void> _requestJoin() async {
    final values = await showDialog<({String code, String message})>(
      context: context,
      builder: (_) => const _RequestJoinDialog(),
    );
    if (values == null || !mounted) return;
    await _run(
      () => ref
          .read(teacherInstitutionControllerProvider.notifier)
          .requestJoin(institutionCode: values.code, message: values.message),
      success: 'Solicitud enviada. Debe aprobarla un responsable.',
    );
  }

  Future<void> _cancelRequest() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancelar solicitud'),
        content: const Text(
          'Podrás enviar otra solicitud o crear una institución después.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Volver'),
          ),
          FilledButton(
            key: const Key('confirm-cancel-institution-request'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Cancelar solicitud'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _run(
      () => ref
          .read(teacherInstitutionControllerProvider.notifier)
          .cancelJoinRequest(),
      success: 'Solicitud cancelada.',
    );
  }

  Future<void> _respondInvitation(
    IncomingInstitutionInvitation invitation,
    bool accept,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(accept ? 'Aceptar invitación' : 'Rechazar invitación'),
        content: Text(
          accept
              ? 'Te vincularás a ${invitation.institutionName} como ${invitation.role.label.toLowerCase()}.'
              : 'La invitación de ${invitation.institutionName} dejará de estar disponible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Volver'),
          ),
          FilledButton(
            key: Key(
              accept
                  ? 'confirm-accept-institution-invitation'
                  : 'confirm-reject-institution-invitation',
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(accept ? 'Aceptar' : 'Rechazar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _run(
      () => ref
          .read(teacherInstitutionControllerProvider.notifier)
          .respondInvitation(invitationId: invitation.id, accept: accept),
      success: accept
          ? 'Ya perteneces a ${invitation.institutionName}.'
          : 'Invitación rechazada.',
    );
  }

  Future<void> _run(
    Future<void> Function() action, {
    required String success,
  }) async {
    setState(() => _working = true);
    try {
      await action();
      if (mounted) _snack(success);
    } on Object catch (error) {
      if (mounted) _snack(_message(error));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  void _snack(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));
}

class _NoInstitution extends StatelessWidget {
  const _NoInstitution({
    required this.working,
    required this.onCreate,
    required this.onRequest,
  });

  final bool working;
  final VoidCallback onCreate;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Card(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.school_outlined, size: 38),
              const SizedBox(height: 12),
              Text(
                'Configura tu espacio institucional',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                'Crea una institución si serás responsable de administrarla, o solicita acceso usando el código que te compartieron.',
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      _ActionCard(
        key: const Key('teacher-create-institution'),
        icon: Icons.add_business_rounded,
        title: 'Crear una institución',
        description:
            'Serás el propietario inicial y podrás organizar el equipo docente en la siguiente etapa.',
        buttonLabel: 'Crear institución',
        onPressed: working ? null : onCreate,
      ),
      const SizedBox(height: 12),
      _ActionCard(
        key: const Key('teacher-request-institution'),
        icon: Icons.meeting_room_outlined,
        title: 'Ya existe mi institución',
        description:
            'Solicita ingreso con su código. La solicitud no te da acceso hasta que sea aprobada.',
        buttonLabel: 'Solicitar ingreso',
        onPressed: working ? null : onRequest,
      ),
    ],
  );
}

class _PendingRequest extends StatelessWidget {
  const _PendingRequest({
    required this.request,
    required this.working,
    required this.onCancel,
  });

  final InstitutionJoinRequest request;
  final bool working;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Card(
        color: Theme.of(context).colorScheme.tertiaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.hourglass_top_rounded, size: 36),
              const SizedBox(height: 12),
              Text(
                'Solicitud pendiente',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                request.institutionName,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text('Código: ${request.institutionCode}'),
              const SizedBox(height: 8),
              Text('Enviada ${_formatDate(request.createdAt)}'),
              if (request.message case final message?
                  when message.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text('Mensaje: $message'),
              ],
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      const Text(
        'Todavía no puedes consultar estudiantes ni estadísticas. Un propietario o administrador deberá aprobar la solicitud.',
      ),
      const SizedBox(height: 16),
      OutlinedButton.icon(
        key: const Key('cancel-institution-request'),
        onPressed: working ? null : onCancel,
        icon: const Icon(Icons.close_rounded),
        label: const Text('Cancelar solicitud'),
      ),
    ],
  );
}

class _LinkedInstitution extends StatelessWidget {
  const _LinkedInstitution({
    required this.institution,
    required this.role,
    required this.onGroups,
    required this.onManage,
  });

  final TeacherInstitution institution;
  final InstitutionMemberRole role;
  final VoidCallback onGroups;
  final VoidCallback? onManage;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Card(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Icon(Icons.account_balance_outlined, size: 34),
                  Chip(label: Text(role.label)),
                  Chip(label: Text('Plan ${institution.plan.toLowerCase()}')),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                institution.name,
                key: const Key('teacher-institution-name'),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (institution.welcomeMessage case final message?
                  when message.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(message),
              ],
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.25,
        children: [
          _Metric(
            icon: Icons.people_outline_rounded,
            value: '${institution.totalStudents}',
            label: 'Estudiantes',
          ),
          _Metric(
            icon: Icons.groups_2_outlined,
            value: '${institution.totalGroups}',
            label: 'Grupos',
          ),
          _Metric(
            icon: Icons.co_present_outlined,
            value: '${institution.totalTeachers}',
            label: 'Docentes',
          ),
          _Metric(
            icon: Icons.person_add_alt_rounded,
            value: institution.studentLimit?.toString() ?? '—',
            label: 'Cupo del plan',
          ),
        ],
      ),
      const SizedBox(height: 18),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Código para docentes',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              const Text(
                'Compártelo únicamente con profesores que deban solicitar ingreso. No es el código de un grupo estudiantil.',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      institution.teacherCode,
                      key: const Key('teacher-institution-code'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Copiar código',
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: institution.teacherCode),
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Código copiado.')),
                        );
                      }
                    },
                    icon: const Icon(Icons.copy_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.groups_2_outlined),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Grupos y códigos temporales',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      role.canManage
                          ? 'Crea grupos, asigna profesores y genera accesos para estudiantes.'
                          : 'Gestiona los grupos que te asignaron y genera accesos para tus estudiantes.',
                    ),
                    const SizedBox(height: 12),
                    FilledButton.tonalIcon(
                      key: const Key('open-institution-groups'),
                      onPressed: onGroups,
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: const Text('Abrir grupos'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.admin_panel_settings_outlined),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role.canManage ? 'Administración' : 'Tu acceso docente',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      role.canManage
                          ? 'Revisa solicitudes, invita al equipo y consulta la auditoría de cambios.'
                          : 'El propietario o un administrador gestiona los integrantes y permisos.',
                    ),
                    if (onManage != null) ...[
                      const SizedBox(height: 12),
                      FilledButton.tonalIcon(
                        key: const Key('open-institution-administration'),
                        onPressed: onManage,
                        icon: const Icon(Icons.manage_accounts_outlined),
                        label: const Text('Administrar equipo'),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

class _IncomingInvitations extends StatelessWidget {
  const _IncomingInvitations({
    required this.invitations,
    required this.working,
    required this.onRespond,
  });

  final List<IncomingInstitutionInvitation> invitations;
  final bool working;
  final void Function(IncomingInstitutionInvitation, bool) onRespond;

  @override
  Widget build(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.secondaryContainer,
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Invitaciones recibidas',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          for (final invitation in invitations) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.mark_email_unread_outlined),
              title: Text(invitation.institutionName),
              subtitle: Text(
                '${invitation.role.label} · Invitó ${invitation.invitedBy}\nExpira ${_formatDate(invitation.expiresAt)}',
              ),
              isThreeLine: true,
            ),
            Wrap(
              spacing: 8,
              children: [
                FilledButton(
                  key: Key('accept-invitation-${invitation.id}'),
                  onPressed: working ? null : () => onRespond(invitation, true),
                  child: const Text('Aceptar'),
                ),
                TextButton(
                  onPressed: working
                      ? null
                      : () => onRespond(invitation, false),
                  child: const Text('Rechazar'),
                ),
              ],
            ),
          ],
        ],
      ),
    ),
  );
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String description;
  final String buttonLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 30),
          const SizedBox(height: 10),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(description),
          const SizedBox(height: 14),
          FilledButton.tonal(onPressed: onPressed, child: Text(buttonLabel)),
        ],
      ),
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const Spacer(),
          Text(value, style: Theme.of(context).textTheme.headlineSmall),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    ),
  );
}

class _CreateInstitutionDialog extends StatefulWidget {
  const _CreateInstitutionDialog();

  @override
  State<_CreateInstitutionDialog> createState() =>
      _CreateInstitutionDialogState();
}

class _CreateInstitutionDialogState extends State<_CreateInstitutionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _welcome = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _welcome.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Crear institución'),
    content: Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              key: const Key('institution-name-field'),
              controller: _name,
              autofocus: true,
              maxLength: 120,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nombre'),
              validator: (value) => (value?.trim().length ?? 0) < 2
                  ? 'Escribe el nombre de la institución.'
                  : null,
            ),
            TextFormField(
              key: const Key('institution-welcome-field'),
              controller: _welcome,
              maxLength: 500,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Mensaje de bienvenida (opcional)',
              ),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        key: const Key('confirm-create-institution'),
        onPressed: () {
          if (!(_formKey.currentState?.validate() ?? false)) return;
          Navigator.pop(context, (
            name: _name.text.trim(),
            welcome: _welcome.text.trim(),
          ));
        },
        child: const Text('Crear'),
      ),
    ],
  );
}

class _RequestJoinDialog extends StatefulWidget {
  const _RequestJoinDialog();

  @override
  State<_RequestJoinDialog> createState() => _RequestJoinDialogState();
}

class _RequestJoinDialogState extends State<_RequestJoinDialog> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _message = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Solicitar ingreso'),
    content: Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              key: const Key('institution-code-field'),
              controller: _code,
              autofocus: true,
              maxLength: 50,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9-]')),
                _UpperCaseFormatter(),
              ],
              decoration: const InputDecoration(
                labelText: 'Código de institución',
                hintText: 'INST-ABC123',
              ),
              validator: (value) => (value?.trim().length ?? 0) < 6
                  ? 'Revisa el código de la institución.'
                  : null,
            ),
            TextFormField(
              key: const Key('institution-request-message-field'),
              controller: _message,
              maxLength: 500,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Mensaje para el responsable (opcional)',
              ),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        key: const Key('confirm-request-institution'),
        onPressed: () {
          if (!(_formKey.currentState?.validate() ?? false)) return;
          Navigator.pop(context, (
            code: _code.text.trim(),
            message: _message.text.trim(),
          ));
        },
        child: const Text('Enviar solicitud'),
      ),
    ],
  );
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => newValue.copyWith(
    text: newValue.text.toUpperCase(),
    selection: newValue.selection,
    composing: TextRange.empty,
  );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 42),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: onRetry,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    ),
  );
}

String _message(Object error) => switch (error) {
  ApiError value => value.message,
  _ => 'No pudimos actualizar tu vínculo institucional.',
};

String _formatDate(DateTime date) {
  const months = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];
  return 'el ${date.day} ${months[date.month - 1]} ${date.year}';
}
