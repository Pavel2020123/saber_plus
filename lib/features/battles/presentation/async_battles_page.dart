import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_error.dart';
import '../../academic/domain/academic_models.dart';
import '../domain/battle_models.dart';
import 'battle_providers.dart';

class AsyncBattlesPage extends ConsumerWidget {
  const AsyncBattlesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(battleDashboardProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Batallas asíncronas'),
        actions: [
          IconButton(
            key: const Key('open-blocked-rivals'),
            tooltip: 'Rivales bloqueados',
            onPressed: () => context.push('/student/practice/battles/blocked'),
            icon: const Icon(Icons.block_rounded),
          ),
          IconButton(
            tooltip: 'Actualizar',
            onPressed: () => ref.invalidate(battleDashboardProvider),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: dashboard.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _LoadError(
          message: _message(error),
          onRetry: () => ref.invalidate(battleDashboardProvider),
        ),
        data: (data) => RefreshIndicator(
          onRefresh: () => ref.refresh(battleDashboardProvider.future),
          child: ListView(
            key: const Key('async-battles-list'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              const _PrivacyCard(),
              const SizedBox(height: 16),
              _StatsCard(stats: data.stats),
              const SizedBox(height: 20),
              Text(
                'Comenzar un reto',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Cada persona responde cuando pueda dentro de las próximas 24 horas.',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      key: const Key('find-anonymous-rival'),
                      onPressed: () => _createBattle(context, ref),
                      icon: const Icon(Icons.casino_outlined),
                      label: const Text('Rival al azar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('create-private-invitation'),
                      onPressed: () =>
                          _createBattle(context, ref, privateInvitation: true),
                      icon: const Icon(Icons.key_rounded),
                      label: const Text('Crear código'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                key: const Key('join-private-invitation'),
                onPressed: () => _joinInvitation(context, ref),
                icon: const Icon(Icons.group_add_outlined),
                label: const Text('Tengo un código de invitación'),
              ),
              const SizedBox(height: 24),
              Text(
                'Tus batallas',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              if (data.battles.isEmpty)
                const _EmptyBattles()
              else
                ...data.battles.map(
                  (battle) => _BattleCard(
                    battle: battle,
                    onTap: () async {
                      await context.push(
                        '/student/practice/battles/${battle.id}',
                      );
                      ref.invalidate(battleDashboardProvider);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createBattle(
    BuildContext context,
    WidgetRef ref, {
    bool privateInvitation = false,
  }) async {
    final config = await showDialog<({BattleMode mode, AcademicArea? area})>(
      context: context,
      builder: (_) => _BattleConfigDialog(privateInvitation: privateInvitation),
    );
    if (config == null || !context.mounted) return;
    _showWorking(context, 'Creando batalla…');
    try {
      final detail = await ref
          .read(battleRepositoryProvider)
          .create(
            mode: config.mode,
            area: config.area,
            privateInvitation: privateInvitation,
          );
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ref.invalidate(battleDashboardProvider);
      await context.push('/student/practice/battles/${detail.summary.id}');
    } catch (error) {
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      _snack(context, _message(error));
    }
  }

  Future<void> _joinInvitation(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Unirse con código'),
        content: TextField(
          key: const Key('battle-invitation-code'),
          controller: controller,
          autofocus: true,
          maxLength: 8,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp('[A-Za-z2-9]')),
            _UpperCaseFormatter(),
          ],
          decoration: const InputDecoration(
            labelText: 'Código de 8 caracteres',
            hintText: 'SABER123',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('confirm-join-battle'),
            onPressed: () {
              final value = controller.text.trim().toUpperCase();
              if (value.length == 8) Navigator.pop(dialogContext, value);
            },
            child: const Text('Unirme'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (code == null || !context.mounted) return;
    _showWorking(context, 'Validando invitación…');
    try {
      final detail = await ref
          .read(battleRepositoryProvider)
          .joinInvitation(code);
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ref.invalidate(battleDashboardProvider);
      await context.push('/student/practice/battles/${detail.summary.id}');
    } catch (error) {
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      _snack(context, _message(error));
    }
  }
}

class _BattleConfigDialog extends StatefulWidget {
  const _BattleConfigDialog({required this.privateInvitation});

  final bool privateInvitation;

  @override
  State<_BattleConfigDialog> createState() => _BattleConfigDialogState();
}

class _BattleConfigDialogState extends State<_BattleConfigDialog> {
  BattleMode _mode = BattleMode.ghostRace;
  AcademicArea? _area;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.privateInvitation ? 'Crear invitación' : 'Buscar rival'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<BattleMode>(
            key: const Key('battle-mode-selector'),
            initialValue: _mode,
            decoration: const InputDecoration(labelText: 'Modo'),
            items: BattleMode.values
                .map(
                  (mode) =>
                      DropdownMenuItem(value: mode, child: Text(mode.label)),
                )
                .toList(growable: false),
            onChanged: (value) => setState(() => _mode = value ?? _mode),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<AcademicArea?>(
            key: const Key('battle-area-selector'),
            initialValue: _area,
            decoration: const InputDecoration(labelText: 'Área'),
            items: [
              const DropdownMenuItem<AcademicArea?>(
                value: null,
                child: Text('Todas las áreas'),
              ),
              ...AcademicArea.values.map(
                (area) => DropdownMenuItem<AcademicArea?>(
                  value: area,
                  child: Text(area.label),
                ),
              ),
            ],
            onChanged: (value) => setState(() => _area = value),
          ),
          const SizedBox(height: 12),
          Text(_mode.description, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        key: const Key('confirm-create-battle'),
        onPressed: () => Navigator.pop(context, (mode: _mode, area: _area)),
        child: Text(widget.privateInvitation ? 'Crear código' : 'Buscar'),
      ),
    ],
  );
}

class _PrivacyCard extends StatelessWidget {
  const _PrivacyCard();

  @override
  Widget build(BuildContext context) => Card(
    key: const Key('battle-privacy-card'),
    color: Theme.of(context).colorScheme.secondaryContainer,
    child: const Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Competencia segura y anónima',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 4),
                Text(
                  'No mostramos nombres, correos, fotos ni institución. Tampoco hay chat entre estudiantes.',
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.stats});

  final BattleStats stats;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _Metric(value: '${stats.played}', label: 'Retos'),
              ),
              Expanded(
                child: _Metric(value: '${stats.wins}', label: 'Victorias'),
              ),
              Expanded(
                child: _Metric(value: '${stats.xp}', label: 'XP'),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              const Icon(Icons.local_fire_department_outlined),
              const SizedBox(width: 8),
              Text('Racha actual: ${stats.currentStreak}'),
              const Spacer(),
              Text('Mejor: ${stats.bestStreak}'),
            ],
          ),
        ],
      ),
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(value, style: Theme.of(context).textTheme.titleLarge),
      Text(label),
    ],
  );
}

class _BattleCard extends StatelessWidget {
  const _BattleCard({required this.battle, required this.onTap});

  final BattleSummary battle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      key: Key('battle-${battle.id}'),
      onTap: onTap,
      leading: CircleAvatar(child: Icon(_modeIcon(battle.mode))),
      title: Text(battle.mode.label),
      subtitle: Text(
        '${battle.area?.label ?? 'Todas las áreas'} · ${battle.status.label}',
      ),
      trailing: battle.result == null
          ? const Icon(Icons.chevron_right_rounded)
          : Text(
              battle.result!.label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
    ),
  );
}

class _EmptyBattles extends StatelessWidget {
  const _EmptyBattles();

  @override
  Widget build(BuildContext context) => const Card(
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(Icons.sports_esports_outlined, size: 42),
          SizedBox(height: 10),
          Text('Todavía no tienes batallas.'),
          SizedBox(height: 4),
          Text(
            'Busca un rival anónimo o comparte un código privado.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
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
          const Icon(Icons.cloud_off_outlined, size: 48),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    ),
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

IconData _modeIcon(BattleMode mode) => switch (mode) {
  BattleMode.ghostRace => Icons.directions_run_rounded,
  BattleMode.lightningDuel => Icons.bolt_rounded,
  BattleMode.survival => Icons.favorite_rounded,
};

void _showWorking(BuildContext context, String message) {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      content: Row(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(width: 20),
          Expanded(child: Text(message)),
        ],
      ),
    ),
  );
}

void _snack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

String _message(Object error) {
  if (error is ApiError) return error.message;
  if (error is StateError) return error.message;
  return 'No fue posible completar la acción. Intenta nuevamente.';
}
