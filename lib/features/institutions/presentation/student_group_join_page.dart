import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_error.dart';
import '../../auth/presentation/session_controller.dart';
import '../domain/institution_group_models.dart';
import 'institution_group_providers.dart';

class StudentGroupJoinPage extends ConsumerStatefulWidget {
  const StudentGroupJoinPage({super.key});

  @override
  ConsumerState<StudentGroupJoinPage> createState() =>
      _StudentGroupJoinPageState();
}

class _StudentGroupJoinPageState extends ConsumerState<StudentGroupJoinPage> {
  final _code = TextEditingController();
  StudentGroupPreview? _preview;
  var _accepted = false;
  var _working = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(studentGroupsControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi institución y grupos'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _working
                ? null
                : () => ref
                      .read(studentGroupsControllerProvider.notifier)
                      .reload(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _JoinError(
          message: _message(error),
          onRetry: () =>
              ref.read(studentGroupsControllerProvider.notifier).reload(),
        ),
        data: (groups) => ListView(
          key: const Key('student-institution-groups-list'),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _CurrentGroups(groups: groups),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Unirme a un grupo',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Pide al profesor un código temporal. Consultarlo no te vincula automáticamente.',
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      key: const Key('student-group-code'),
                      controller: _code,
                      enabled: !_working,
                      textCapitalization: TextCapitalization.characters,
                      autocorrect: false,
                      maxLength: 12,
                      decoration: const InputDecoration(
                        labelText: 'Código temporal',
                        hintText: 'GRP-XXXXXXXX',
                        prefixIcon: Icon(Icons.key_rounded),
                      ),
                      onChanged: (_) {
                        if (_preview != null || _accepted) {
                          setState(() {
                            _preview = null;
                            _accepted = false;
                          });
                        }
                      },
                      onSubmitted: (_) => _previewCode(),
                    ),
                    FilledButton.icon(
                      key: const Key('preview-student-group-code'),
                      onPressed: _working ? null : _previewCode,
                      icon: const Icon(Icons.search_rounded),
                      label: const Text('Consultar código'),
                    ),
                  ],
                ),
              ),
            ),
            if (_preview case final preview?) ...[
              const SizedBox(height: 16),
              _PreviewCard(
                preview: preview,
                accepted: _accepted,
                working: _working,
                onAcceptanceChanged: (value) =>
                    setState(() => _accepted = value ?? false),
                onAccept: _acceptCode,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _previewCode() async {
    final code = _code.text.trim();
    if (code.isEmpty) {
      _show('Escribe el código que te entregó tu profesor.');
      return;
    }
    setState(() {
      _working = true;
      _preview = null;
      _accepted = false;
    });
    try {
      final preview = await ref
          .read(studentGroupsControllerProvider.notifier)
          .previewCode(code);
      if (mounted) setState(() => _preview = preview);
    } on Object catch (error) {
      _show(_message(error));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _acceptCode() async {
    final preview = _preview;
    if (preview == null || !preview.canJoin || !_accepted) return;
    setState(() => _working = true);
    try {
      await ref
          .read(studentGroupsControllerProvider.notifier)
          .acceptCode(_code.text);
      await ref.read(sessionControllerProvider.notifier).refreshProfile();
      if (!mounted) return;
      setState(() {
        _code.clear();
        _preview = null;
        _accepted = false;
      });
      _show('Te vinculaste al grupo correctamente.');
    } on Object catch (error) {
      _show(_message(error));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  void _show(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _CurrentGroups extends StatelessWidget {
  const _CurrentGroups({required this.groups});

  final StudentInstitutionGroups groups;

  @override
  Widget build(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.primaryContainer,
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.account_balance_outlined, size: 36),
          const SizedBox(height: 10),
          Text(
            groups.groups.isEmpty ? 'Sin institución vinculada' : 'Tus grupos',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          if (groups.groups.isEmpty)
            const Text(
              'Puedes seguir usando SaberPlus normalmente. Vincularte es opcional y requiere tu aceptación.',
            )
          else
            for (final group in groups.groups)
              ListTile(
                key: Key('student-group-${group.id}'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.school_outlined),
                title: Text(group.name),
                subtitle: Text(
                  '${group.institutionName} · ${group.grade.label}\nIngreso ${_shortDate(group.joinedAt)}',
                ),
                isThreeLine: true,
                trailing: group.explicitlyAccepted
                    ? const Tooltip(
                        message: 'Vinculación aceptada',
                        child: Icon(Icons.verified_user_outlined),
                      )
                    : null,
              ),
        ],
      ),
    ),
  );
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.preview,
    required this.accepted,
    required this.working,
    required this.onAcceptanceChanged,
    required this.onAccept,
  });

  final StudentGroupPreview preview;
  final bool accepted;
  final bool working;
  final ValueChanged<bool?> onAcceptanceChanged;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    final statusMessage = switch (preview.status) {
      StudentGroupPreviewStatus.available => null,
      StudentGroupPreviewStatus.alreadyLinked => 'Ya perteneces a este grupo.',
      StudentGroupPreviewStatus.anotherInstitution =>
        'Tu cuenta ya está vinculada a otra institución. No se hizo ningún cambio.',
    };
    return Card(
      key: const Key('student-group-preview'),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.visibility_outlined),
                const SizedBox(width: 8),
                Text(
                  'Confirma los datos',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              preview.institutionName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text('${preview.groupName} · ${preview.grade.label}'),
            const SizedBox(height: 8),
            Text(
              '${preview.availableUses} usos disponibles · vence ${_dateTime(preview.expiresAt)}',
            ),
            if (statusMessage != null) ...[
              const SizedBox(height: 14),
              Text(
                statusMessage,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (preview.canJoin) ...[
              const SizedBox(height: 10),
              CheckboxListTile(
                key: const Key('accept-student-group-link'),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: accepted,
                onChanged: working ? null : onAcceptanceChanged,
                title: Text(
                  'Acepto vincular mi cuenta con ${preview.institutionName} y el grupo ${preview.groupName}.',
                ),
                subtitle: const Text(
                  'Los docentes asignados podrán consultar el progreso académico permitido para este grupo.',
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const Key('confirm-student-group-link'),
                  onPressed: working || !accepted ? null : onAccept,
                  icon: const Icon(Icons.group_add_rounded),
                  label: const Text('Aceptar y unirme'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _JoinError extends StatelessWidget {
  const _JoinError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 48),
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

String _shortDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

String _dateTime(DateTime value) =>
    '${_shortDate(value)} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

String _message(Object error) => switch (error) {
  ApiError() => error.message,
  StateError() => error.message,
  _ => 'No pudimos completar la acción. Inténtalo nuevamente.',
};
