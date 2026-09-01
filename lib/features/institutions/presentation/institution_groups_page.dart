import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_error.dart';
import '../domain/institution_group_models.dart';
import '../domain/teacher_institution_models.dart';
import 'institution_group_providers.dart';
import 'teacher_institution_providers.dart';

class InstitutionGroupsPage extends ConsumerStatefulWidget {
  const InstitutionGroupsPage({super.key});

  @override
  ConsumerState<InstitutionGroupsPage> createState() =>
      _InstitutionGroupsPageState();
}

class _InstitutionGroupsPageState extends ConsumerState<InstitutionGroupsPage> {
  var _working = false;

  @override
  Widget build(BuildContext context) {
    final groupsState = ref.watch(institutionGroupsControllerProvider);
    final teacherContext = ref
        .watch(teacherInstitutionControllerProvider)
        .valueOrNull;
    final role = teacherContext?.memberRole;
    final groupLimit = teacherContext?.institution?.groupLimit;
    final groupCount =
        groupsState.valueOrNull?.length ??
        teacherContext?.institution?.totalGroups ??
        0;
    final groupLimitReached = groupLimit != null && groupCount >= groupLimit;
    final administrationState = role?.canManage == true
        ? ref.watch(institutionAdministrationControllerProvider)
        : null;
    final members = administrationState?.valueOrNull?.members ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Grupos de la institución'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _working ? null : _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
          if (role?.canManage == true)
            IconButton(
              key: const Key('create-institution-group'),
              tooltip: groupLimitReached
                  ? 'Alcanzaste el límite de $groupLimit grupo(s)'
                  : 'Crear grupo',
              onPressed: _working || groupLimitReached ? null : _createGroup,
              icon: const Icon(Icons.add_rounded),
            ),
        ],
      ),
      body: groupsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            _GroupsError(message: _message(error), onRetry: _reload),
        data: (groups) => RefreshIndicator(
          onRefresh: _reload,
          child: ListView(
            key: const Key('institution-groups-list'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.groups_2_outlined, size: 36),
                      const SizedBox(height: 10),
                      const Text(
                        'Acceso por códigos temporales',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'El estudiante verá el nombre de la institución y del grupo antes de aceptar. El código completo solo se muestra al crearlo.',
                      ),
                      if (groupLimit != null) ...[
                        const SizedBox(height: 10),
                        Chip(
                          avatar: Icon(
                            groupLimitReached
                                ? Icons.lock_outline_rounded
                                : Icons.check_circle_outline_rounded,
                          ),
                          label: Text(
                            '$groupCount de $groupLimit grupo(s) del plan',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (administrationState?.hasError == true) ...[
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.info_outline_rounded),
                    title: const Text('No se pudo cargar el equipo docente'),
                    subtitle: Text(_message(administrationState!.error!)),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              if (groups.isEmpty)
                _EmptyGroups(
                  canCreate: role?.canManage == true && !groupLimitReached,
                )
              else
                for (final group in groups) ...[
                  _GroupCard(
                    group: group,
                    role: role ?? InstitutionMemberRole.teacher,
                    members: members,
                    working: _working,
                    onCreateCode: () => _createCode(group),
                    onRevokeCode: (code) => _revokeCode(group, code),
                    onAssignTeacher: (member) => _assignTeacher(group, member),
                    onRemoveTeacher: (teacher) =>
                        _removeTeacher(group, teacher),
                    onDelete: () => _deleteGroup(group),
                  ),
                  const SizedBox(height: 12),
                ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _reload() async {
    await ref.read(institutionGroupsControllerProvider.notifier).reload();
    final role = ref.read(teacherInstitutionControllerProvider).valueOrNull;
    if (role?.memberRole?.canManage == true) {
      await ref
          .read(institutionAdministrationControllerProvider.notifier)
          .reload();
    }
  }

  Future<void> _createGroup() async {
    final result = await showDialog<({String name, InstitutionGrade grade})>(
      context: context,
      builder: (_) => const _CreateGroupDialog(),
    );
    if (result == null || !mounted) return;
    await _run(
      () => ref
          .read(institutionGroupsControllerProvider.notifier)
          .createGroup(name: result.name, grade: result.grade),
      'Grupo creado.',
    );
  }

  Future<void> _deleteGroup(InstitutionGroup group) async {
    final confirmed = await _confirm(
      'Eliminar ${group.name}',
      'El grupo se eliminará únicamente si no tiene estudiantes vinculados. Esta acción no elimina cuentas.',
      'Eliminar grupo',
    );
    if (!confirmed) return;
    await _run(
      () => ref
          .read(institutionGroupsControllerProvider.notifier)
          .deleteGroup(group.id),
      'Grupo eliminado.',
    );
  }

  Future<void> _createCode(InstitutionGroup group) async {
    final settings = await showDialog<({int duration, int uses})>(
      context: context,
      builder: (_) => _CreateCodeDialog(groupName: group.name),
    );
    if (settings == null || !mounted) return;
    setState(() => _working = true);
    try {
      final code = await ref
          .read(institutionGroupsControllerProvider.notifier)
          .createTemporaryCode(
            groupId: group.id,
            durationMinutes: settings.duration,
            maximumUses: settings.uses,
          );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _CreatedCodeDialog(code: code, groupName: group.name),
      );
    } on Object catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _revokeCode(
    InstitutionGroup group,
    TemporaryGroupCode code,
  ) async {
    final confirmed = await _confirm(
      'Revocar código ••••${code.suffix}',
      'Dejará de funcionar inmediatamente. Los estudiantes ya vinculados conservarán su grupo.',
      'Revocar',
    );
    if (!confirmed) return;
    await _run(
      () => ref
          .read(institutionGroupsControllerProvider.notifier)
          .revokeTemporaryCode(groupId: group.id, codeId: code.id),
      'Código revocado.',
    );
  }

  Future<void> _assignTeacher(
    InstitutionGroup group,
    InstitutionTeamMember member,
  ) => _run(
    () => ref
        .read(institutionGroupsControllerProvider.notifier)
        .assignTeacher(groupId: group.id, membershipId: member.membershipId),
    '${member.name} fue asignado al grupo.',
  );

  Future<void> _removeTeacher(
    InstitutionGroup group,
    AssignedGroupTeacher teacher,
  ) async {
    final confirmed = await _confirm(
      'Retirar del grupo',
      '${teacher.name} dejará de gestionar ${group.name}, pero seguirá perteneciendo a la institución.',
      'Retirar',
    );
    if (!confirmed) return;
    await _run(
      () => ref
          .read(institutionGroupsControllerProvider.notifier)
          .removeTeacher(groupId: group.id, membershipId: teacher.membershipId),
      'Profesor retirado del grupo.',
    );
  }

  Future<bool> _confirm(String title, String body, String action) async =>
      await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: Text(body),
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
      _showError(error);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(_message(error))));
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.group,
    required this.role,
    required this.members,
    required this.working,
    required this.onCreateCode,
    required this.onRevokeCode,
    required this.onAssignTeacher,
    required this.onRemoveTeacher,
    required this.onDelete,
  });

  final InstitutionGroup group;
  final InstitutionMemberRole role;
  final List<InstitutionTeamMember> members;
  final bool working;
  final VoidCallback onCreateCode;
  final void Function(TemporaryGroupCode) onRevokeCode;
  final void Function(InstitutionTeamMember) onAssignTeacher;
  final void Function(AssignedGroupTeacher) onRemoveTeacher;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final assigned = group.teachers.map((item) => item.membershipId).toSet();
    final availableTeachers = members
        .where((member) => !assigned.contains(member.membershipId))
        .toList(growable: false);
    return Card(
      key: Key('institution-group-${group.id}'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        '${group.grade.label} · ${group.studentCount} estudiantes',
                      ),
                    ],
                  ),
                ),
                if (role.canManage)
                  IconButton(
                    tooltip: 'Eliminar grupo',
                    onPressed: working ? null : onDelete,
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
              ],
            ),
            const Divider(height: 26),
            Text(
              'Equipo asignado',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (group.teachers.isEmpty)
              const Text('No hay profesores asignados.')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final teacher in group.teachers)
                    InputChip(
                      label: Text('${teacher.name} · ${teacher.role.label}'),
                      onDeleted:
                          role.canManage &&
                              teacher.role != InstitutionMemberRole.owner &&
                              !working
                          ? () => onRemoveTeacher(teacher)
                          : null,
                    ),
                ],
              ),
            if (role.canManage && availableTeachers.isNotEmpty) ...[
              const SizedBox(height: 8),
              PopupMenuButton<InstitutionTeamMember>(
                key: Key('assign-teacher-${group.id}'),
                enabled: !working,
                onSelected: onAssignTeacher,
                itemBuilder: (_) => [
                  for (final member in availableTeachers)
                    PopupMenuItem(
                      value: member,
                      child: Text('${member.name} · ${member.role.label}'),
                    ),
                ],
                child: const Chip(
                  avatar: Icon(Icons.person_add_alt_1_rounded, size: 18),
                  label: Text('Asignar profesor'),
                ),
              ),
            ],
            const Divider(height: 26),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Códigos activos',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                FilledButton.tonalIcon(
                  key: Key('create-group-code-${group.id}'),
                  onPressed: working ? null : onCreateCode,
                  icon: const Icon(Icons.key_rounded),
                  label: const Text('Generar'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (group.codes.isEmpty)
              const Text('No hay códigos temporales disponibles.')
            else
              for (final code in group.codes)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.password_rounded),
                  title: Text('••••${code.suffix}'),
                  subtitle: Text(
                    '${code.availableUses} usos disponibles · vence ${_dateTime(code.expiresAt)}',
                  ),
                  trailing: IconButton(
                    tooltip: 'Revocar código',
                    onPressed: working ? null : () => onRevokeCode(code),
                    icon: const Icon(Icons.block_rounded),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _CreateGroupDialog extends StatefulWidget {
  const _CreateGroupDialog();

  @override
  State<_CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<_CreateGroupDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  var _grade = InstitutionGrade.eleventh;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Crear grupo'),
    content: Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            key: const Key('institution-group-name'),
            controller: _name,
            decoration: const InputDecoration(labelText: 'Nombre del grupo'),
            maxLength: 60,
            validator: (value) => (value?.trim().length ?? 0) < 2
                ? 'Escribe al menos dos caracteres.'
                : null,
          ),
          DropdownButtonFormField<InstitutionGrade>(
            initialValue: _grade,
            decoration: const InputDecoration(labelText: 'Grado'),
            items: [
              for (final grade in InstitutionGrade.values)
                DropdownMenuItem(value: grade, child: Text(grade.label)),
            ],
            onChanged: (value) =>
                setState(() => _grade = value ?? InstitutionGrade.eleventh),
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
        key: const Key('confirm-create-institution-group'),
        onPressed: () {
          if (!(_formKey.currentState?.validate() ?? false)) return;
          Navigator.pop(context, (name: _name.text.trim(), grade: _grade));
        },
        child: const Text('Crear'),
      ),
    ],
  );
}

class _CreateCodeDialog extends StatefulWidget {
  const _CreateCodeDialog({required this.groupName});

  final String groupName;

  @override
  State<_CreateCodeDialog> createState() => _CreateCodeDialogState();
}

class _CreateCodeDialogState extends State<_CreateCodeDialog> {
  final _uses = TextEditingController(text: '40');
  final _formKey = GlobalKey<FormState>();
  var _duration = 1440;

  @override
  void dispose() {
    _uses.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('Código para ${widget.groupName}'),
    content: Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<int>(
            key: const Key('group-code-duration'),
            initialValue: _duration,
            decoration: const InputDecoration(labelText: 'Vigencia'),
            items: const [
              DropdownMenuItem(value: 60, child: Text('1 hora')),
              DropdownMenuItem(value: 1440, child: Text('24 horas')),
              DropdownMenuItem(value: 10080, child: Text('7 días')),
            ],
            onChanged: (value) => setState(() => _duration = value ?? 1440),
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('group-code-maximum-uses'),
            controller: _uses,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Usos máximos'),
            validator: (value) {
              final uses = int.tryParse(value ?? '');
              return uses == null || uses < 1 || uses > 200
                  ? 'Elige entre 1 y 200 usos.'
                  : null;
            },
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
        key: const Key('confirm-create-group-code'),
        onPressed: () {
          if (!(_formKey.currentState?.validate() ?? false)) return;
          Navigator.pop(context, (
            duration: _duration,
            uses: int.parse(_uses.text),
          ));
        },
        child: const Text('Generar'),
      ),
    ],
  );
}

class _CreatedCodeDialog extends StatelessWidget {
  const _CreatedCodeDialog({required this.code, required this.groupName});

  final CreatedTemporaryGroupCode code;
  final String groupName;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Código creado'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Compártelo con estudiantes de $groupName.'),
        const SizedBox(height: 12),
        SelectableText(
          code.code,
          key: const Key('created-group-code-value'),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text(
          'Guárdalo ahora: por seguridad, SaberPlus no volverá a mostrar el código completo.',
        ),
        const SizedBox(height: 8),
        Text('${code.maximumUses} usos · vence ${_dateTime(code.expiresAt)}'),
      ],
    ),
    actions: [
      TextButton.icon(
        key: const Key('copy-created-group-code'),
        onPressed: () async {
          await Clipboard.setData(ClipboardData(text: code.code));
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Código copiado.')));
          }
        },
        icon: const Icon(Icons.copy_rounded),
        label: const Text('Copiar'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Listo'),
      ),
    ],
  );
}

class _EmptyGroups extends StatelessWidget {
  const _EmptyGroups({required this.canCreate});

  final bool canCreate;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
    child: Column(
      children: [
        const Icon(Icons.group_off_outlined, size: 52),
        const SizedBox(height: 12),
        Text(
          canCreate
              ? 'Aún no hay grupos. Créalo desde el botón +.'
              : 'Aún no tienes grupos asignados.',
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

class _GroupsError extends StatelessWidget {
  const _GroupsError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, size: 48),
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

String _dateTime(DateTime value) {
  final date =
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  final time =
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  return '$date $time';
}

String _message(Object error) => switch (error) {
  ApiError() => error.message,
  StateError() => error.message,
  _ => 'No pudimos completar la acción. Inténtalo nuevamente.',
};
