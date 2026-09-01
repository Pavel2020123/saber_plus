import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_error.dart';
import '../../auth/presentation/session_controller.dart';
import '../domain/teacher_institution_models.dart';
import 'teacher_institution_providers.dart';

class InstitutionAdministrationPage extends ConsumerStatefulWidget {
  const InstitutionAdministrationPage({super.key});

  @override
  ConsumerState<InstitutionAdministrationPage> createState() =>
      _InstitutionAdministrationPageState();
}

class _InstitutionAdministrationPageState
    extends ConsumerState<InstitutionAdministrationPage> {
  var _working = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(institutionAdministrationControllerProvider);
    final userId = ref.watch(sessionControllerProvider).user?.id;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administrar institución'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _working
                ? null
                : () => ref
                      .read(
                        institutionAdministrationControllerProvider.notifier,
                      )
                      .reload(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _AdministrationError(
          message: _message(error),
          onRetry: () => ref
              .read(institutionAdministrationControllerProvider.notifier)
              .reload(),
        ),
        data: (data) => RefreshIndicator(
          onRefresh: () => ref
              .read(institutionAdministrationControllerProvider.notifier)
              .reload(),
          child: ListView(
            key: const Key('institution-administration-list'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _AdministrationHeader(data: data),
              const SizedBox(height: 14),
              _RequestsSection(
                requests: data.requests,
                working: _working,
                onReview: _reviewRequest,
              ),
              const SizedBox(height: 14),
              _InvitationsSection(
                invitations: data.invitations,
                permissions: data.permissions,
                working: _working,
                onInvite: () => _invite(data.permissions),
                onCancel: _cancelInvitation,
              ),
              const SizedBox(height: 14),
              _MembersSection(
                members: data.members,
                myRole: data.myRole,
                currentUserId: userId,
                permissions: data.permissions,
                working: _working,
                onChangeRole: _changeRole,
                onRemove: _removeMember,
                onTransfer: (member) => _transfer(data, member),
              ),
              const SizedBox(height: 14),
              _AuditSection(entries: data.audit),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _reviewRequest(
    InstitutionManagementRequest request,
    bool approve,
  ) async {
    final confirmed = await _confirm(
      approve ? 'Aprobar solicitud' : 'Rechazar solicitud',
      approve
          ? '${request.name} ingresará como profesor. La acción quedará registrada.'
          : 'La solicitud de ${request.name} dejará de estar disponible.',
      approve ? 'Aprobar' : 'Rechazar',
    );
    if (!confirmed) return;
    await _run(
      () => ref
          .read(institutionAdministrationControllerProvider.notifier)
          .reviewRequest(requestId: request.id, approve: approve),
      approve ? 'Profesor vinculado.' : 'Solicitud rechazada.',
    );
  }

  Future<void> _invite(InstitutionPermissionSet permissions) async {
    final result =
        await showDialog<({String email, InstitutionMemberRole role})>(
          context: context,
          builder: (_) => _InviteMemberDialog(
            canInviteAdministrator: permissions.manageAdministrators,
          ),
        );
    if (result == null || !mounted) return;
    await _run(
      () => ref
          .read(institutionAdministrationControllerProvider.notifier)
          .inviteMember(email: result.email, role: result.role),
      'Invitación creada por siete días.',
    );
  }

  Future<void> _cancelInvitation(InstitutionSentInvitation invitation) async {
    final confirmed = await _confirm(
      'Cancelar invitación',
      '${invitation.email} ya no podrá aceptarla.',
      'Cancelar invitación',
    );
    if (!confirmed) return;
    await _run(
      () => ref
          .read(institutionAdministrationControllerProvider.notifier)
          .cancelInvitation(invitation.id),
      'Invitación cancelada.',
    );
  }

  Future<void> _changeRole(
    InstitutionTeamMember member,
    InstitutionMemberRole role,
  ) async {
    if (member.role == role) return;
    final confirmed = await _confirm(
      'Cambiar rol',
      '${member.name} pasará de ${member.role.label.toLowerCase()} a ${role.label.toLowerCase()}.',
      'Cambiar rol',
    );
    if (!confirmed) return;
    await _run(
      () => ref
          .read(institutionAdministrationControllerProvider.notifier)
          .changeMemberRole(membershipId: member.membershipId, role: role),
      'Rol actualizado.',
    );
  }

  Future<void> _removeMember(InstitutionTeamMember member) async {
    final confirmed = await _confirm(
      'Retirar profesor',
      '${member.name} perderá el acceso a esta institución. Su cuenta personal no se eliminará.',
      'Retirar',
    );
    if (!confirmed) return;
    await _run(
      () => ref
          .read(institutionAdministrationControllerProvider.notifier)
          .removeMember(member.membershipId),
      'Miembro retirado.',
    );
  }

  Future<void> _transfer(
    InstitutionAdministration data,
    InstitutionTeamMember member,
  ) async {
    final code = await showDialog<String>(
      context: context,
      builder: (_) => _TransferOwnershipDialog(
        memberName: member.name,
        institutionCode: data.institutionCode,
      ),
    );
    if (code == null || !mounted) return;
    await _run(
      () => ref
          .read(institutionAdministrationControllerProvider.notifier)
          .transferOwnership(
            membershipId: member.membershipId,
            confirmationCode: code,
          ),
      'Propiedad transferida. Ahora eres administrador.',
    );
  }

  Future<bool> _confirm(String title, String message, String action) async =>
      await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Volver'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _run(Future<void> Function() operation, String success) async {
    setState(() => _working = true);
    try {
      await operation();
      ref.invalidate(teacherInstitutionControllerProvider);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(success)));
      }
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_message(error))));
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }
}

class _AdministrationHeader extends StatelessWidget {
  const _AdministrationHeader({required this.data});

  final InstitutionAdministration data;

  @override
  Widget build(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.primaryContainer,
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.institutionName,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text(data.myRole.label)),
              Chip(label: Text('${data.members.length} miembros')),
              Chip(label: Text('${data.requests.length} solicitudes')),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Las acciones sensibles quedan registradas. Cada docente conserva su propia cuenta y contraseña.',
          ),
        ],
      ),
    ),
  );
}

class _RequestsSection extends StatelessWidget {
  const _RequestsSection({
    required this.requests,
    required this.working,
    required this.onReview,
  });

  final List<InstitutionManagementRequest> requests;
  final bool working;
  final void Function(InstitutionManagementRequest, bool) onReview;

  @override
  Widget build(BuildContext context) => _SectionCard(
    icon: Icons.how_to_reg_outlined,
    title: 'Solicitudes pendientes',
    child: requests.isEmpty
        ? const Text('No hay solicitudes por revisar.')
        : Column(
            children: [
              for (final request in requests)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(request.name),
                  subtitle: Text(
                    '${request.email}${request.message?.isNotEmpty == true ? '\n${request.message}' : ''}',
                  ),
                  isThreeLine: request.message?.isNotEmpty == true,
                  trailing: PopupMenuButton<bool>(
                    enabled: !working,
                    tooltip: 'Revisar solicitud',
                    onSelected: (approve) => onReview(request, approve),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: true, child: Text('Aprobar')),
                      PopupMenuItem(value: false, child: Text('Rechazar')),
                    ],
                  ),
                ),
            ],
          ),
  );
}

class _InvitationsSection extends StatelessWidget {
  const _InvitationsSection({
    required this.invitations,
    required this.permissions,
    required this.working,
    required this.onInvite,
    required this.onCancel,
  });

  final List<InstitutionSentInvitation> invitations;
  final InstitutionPermissionSet permissions;
  final bool working;
  final VoidCallback onInvite;
  final void Function(InstitutionSentInvitation) onCancel;

  @override
  Widget build(BuildContext context) => _SectionCard(
    icon: Icons.outgoing_mail,
    title: 'Invitaciones',
    action: FilledButton.tonalIcon(
      key: const Key('invite-institution-member'),
      onPressed: working || !permissions.inviteTeachers ? null : onInvite,
      icon: const Icon(Icons.person_add_alt_1_rounded),
      label: const Text('Invitar'),
    ),
    child: invitations.isEmpty
        ? const Text('No hay invitaciones pendientes.')
        : Column(
            children: [
              for (final invitation in invitations)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(invitation.email),
                  subtitle: Text(
                    '${invitation.role.label} · Expira ${_shortDate(invitation.expiresAt)}',
                  ),
                  trailing: IconButton(
                    tooltip: 'Cancelar invitación',
                    onPressed: working ? null : () => onCancel(invitation),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ),
            ],
          ),
  );
}

class _MembersSection extends StatelessWidget {
  const _MembersSection({
    required this.members,
    required this.myRole,
    required this.currentUserId,
    required this.permissions,
    required this.working,
    required this.onChangeRole,
    required this.onRemove,
    required this.onTransfer,
  });

  final List<InstitutionTeamMember> members;
  final InstitutionMemberRole myRole;
  final String? currentUserId;
  final InstitutionPermissionSet permissions;
  final bool working;
  final void Function(InstitutionTeamMember, InstitutionMemberRole)
  onChangeRole;
  final void Function(InstitutionTeamMember) onRemove;
  final void Function(InstitutionTeamMember) onTransfer;

  @override
  Widget build(BuildContext context) => _SectionCard(
    icon: Icons.groups_2_outlined,
    title: 'Equipo docente',
    child: Column(
      children: [
        for (final member in members)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              child: Text(
                member.name.trim().isEmpty
                    ? '?'
                    : member.name.trim()[0].toUpperCase(),
              ),
            ),
            title: Text(member.name),
            subtitle: Text('${member.email}\n${member.role.label}'),
            isThreeLine: true,
            trailing: _memberMenu(member),
          ),
      ],
    ),
  );

  Widget? _memberMenu(InstitutionTeamMember member) {
    final isCurrent = currentUserId == member.userId;
    if (member.role == InstitutionMemberRole.owner || isCurrent || working) {
      return null;
    }
    final canManageThisMember =
        myRole == InstitutionMemberRole.owner ||
        member.role == InstitutionMemberRole.teacher;
    if (!canManageThisMember) return null;
    return PopupMenuButton<String>(
      tooltip: 'Administrar miembro',
      onSelected: (action) {
        switch (action) {
          case 'teacher':
            onChangeRole(member, InstitutionMemberRole.teacher);
          case 'administrator':
            onChangeRole(member, InstitutionMemberRole.administrator);
          case 'transfer':
            onTransfer(member);
          case 'remove':
            onRemove(member);
        }
      },
      itemBuilder: (_) => [
        if (permissions.manageAdministrators &&
            member.role != InstitutionMemberRole.teacher)
          const PopupMenuItem(value: 'teacher', child: Text('Hacer profesor')),
        if (permissions.manageAdministrators &&
            member.role != InstitutionMemberRole.administrator)
          const PopupMenuItem(
            value: 'administrator',
            child: Text('Hacer administrador'),
          ),
        if (permissions.transferOwnership)
          const PopupMenuItem(
            value: 'transfer',
            child: Text('Transferir propiedad'),
          ),
        if (permissions.removeTeachers)
          const PopupMenuItem(value: 'remove', child: Text('Retirar')),
      ],
    );
  }
}

class _AuditSection extends StatelessWidget {
  const _AuditSection({required this.entries});

  final List<InstitutionAuditEntry> entries;

  @override
  Widget build(BuildContext context) => _SectionCard(
    icon: Icons.history_rounded,
    title: 'Auditoría reciente',
    child: entries.isEmpty
        ? const Text('Aún no hay acciones registradas.')
        : Column(
            children: [
              for (final entry in entries)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: const Icon(Icons.verified_user_outlined),
                  title: Text(_auditLabel(entry.action)),
                  subtitle: Text(
                    '${entry.actorName}${entry.affectedName == null ? '' : ' · ${entry.affectedName}'}\n${_shortDate(entry.createdAt)}',
                  ),
                ),
            ],
          ),
  );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
    this.action,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              ?action,
            ],
          ),
          const Divider(height: 24),
          child,
        ],
      ),
    ),
  );
}

class _InviteMemberDialog extends StatefulWidget {
  const _InviteMemberDialog({required this.canInviteAdministrator});

  final bool canInviteAdministrator;

  @override
  State<_InviteMemberDialog> createState() => _InviteMemberDialogState();
}

class _InviteMemberDialogState extends State<_InviteMemberDialog> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  var _role = InstitutionMemberRole.teacher;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Invitar docente'),
    content: Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            key: const Key('institution-invitation-email'),
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Correo de su cuenta'),
            validator: (value) {
              final email = value?.trim() ?? '';
              if (!email.contains('@') || !email.contains('.')) {
                return 'Escribe un correo válido.';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<InstitutionMemberRole>(
            initialValue: _role,
            decoration: const InputDecoration(labelText: 'Rol'),
            items: [
              const DropdownMenuItem(
                value: InstitutionMemberRole.teacher,
                child: Text('Profesor'),
              ),
              if (widget.canInviteAdministrator)
                const DropdownMenuItem(
                  value: InstitutionMemberRole.administrator,
                  child: Text('Administrador'),
                ),
            ],
            onChanged: (value) =>
                setState(() => _role = value ?? InstitutionMemberRole.teacher),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        key: const Key('confirm-invite-institution-member'),
        onPressed: () {
          if (!(_formKey.currentState?.validate() ?? false)) return;
          Navigator.pop(context, (
            email: _email.text.trim().toLowerCase(),
            role: _role,
          ));
        },
        child: const Text('Crear invitación'),
      ),
    ],
  );
}

class _TransferOwnershipDialog extends StatefulWidget {
  const _TransferOwnershipDialog({
    required this.memberName,
    required this.institutionCode,
  });

  final String memberName;
  final String institutionCode;

  @override
  State<_TransferOwnershipDialog> createState() =>
      _TransferOwnershipDialogState();
}

class _TransferOwnershipDialogState extends State<_TransferOwnershipDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Transferir propiedad'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${widget.memberName} será el nuevo propietario y tú quedarás como administrador.',
        ),
        const SizedBox(height: 12),
        Text('Para confirmar escribe: ${widget.institutionCode}'),
        const SizedBox(height: 8),
        TextField(
          key: const Key('transfer-ownership-code'),
          controller: _controller,
          autocorrect: false,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(labelText: 'Código institucional'),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        key: const Key('confirm-transfer-ownership'),
        onPressed: () => Navigator.pop(context, _controller.text),
        child: const Text('Transferir'),
      ),
    ],
  );
}

class _AdministrationError extends StatelessWidget {
  const _AdministrationError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_outline_rounded, size: 44),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: onRetry,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    ),
  );
}

String _auditLabel(String action) => switch (action) {
  'INSTITUCION_CREADA' => 'Institución creada',
  'SOLICITUD_APROBADA' => 'Solicitud aprobada',
  'SOLICITUD_RECHAZADA' => 'Solicitud rechazada',
  'INVITACION_CREADA' => 'Invitación creada',
  'INVITACION_CANCELADA' => 'Invitación cancelada',
  'INVITACION_ACEPTADA' => 'Invitación aceptada',
  'INVITACION_RECHAZADA' => 'Invitación rechazada',
  'ROL_ACTUALIZADO' => 'Rol actualizado',
  'MIEMBRO_RETIRADO' => 'Miembro retirado',
  'PROPIEDAD_TRANSFERIDA' => 'Propiedad transferida',
  _ => action.toLowerCase().replaceAll('_', ' '),
};

String _shortDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

String _message(Object error) => switch (error) {
  ApiError() => error.message,
  StateError() => error.message,
  _ => 'No pudimos completar la acción. Inténtalo nuevamente.',
};
