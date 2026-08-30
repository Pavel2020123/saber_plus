import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../academic/domain/academic_models.dart';
import '../../auth/presentation/session_controller.dart';
import '../data/practice_draft_store.dart';
import '../domain/practice_models.dart';

class TimeTrialSetupPage extends ConsumerStatefulWidget {
  const TimeTrialSetupPage({super.key});

  @override
  ConsumerState<TimeTrialSetupPage> createState() => _TimeTrialSetupPageState();
}

class _TimeTrialSetupPageState extends ConsumerState<TimeTrialSetupPage> {
  final _selectedAreas = <AcademicArea>{AcademicArea.mathematics};
  var _preset = TimeTrialPreset.challenge;
  PracticeDifficulty? _difficulty;
  PracticeDraft? _activeDraft;

  @override
  void initState() {
    super.initState();
    _loadActiveDraft();
  }

  Future<void> _loadActiveDraft() async {
    final userId = ref.read(sessionControllerProvider).user?.id;
    if (userId == null) return;
    final store = ref.read(practiceDraftStoreProvider);
    final draft = await store.read(userId, 'time-trial');
    if (draft != null && draft.isExpiredAt(DateTime.now())) {
      await store.clear(userId, 'time-trial');
      return;
    }
    if (!mounted) return;
    setState(
      () => _activeDraft = draft?.session.isTimeTrial == true ? draft : null,
    );
  }

  TimeTrialConfig get _config => TimeTrialConfig(
    areas: AcademicArea.values
        .where(_selectedAreas.contains)
        .toList(growable: false),
    questionCount: _preset.questionCount,
    minutes: _preset.minutes,
    difficulty: _difficulty,
  );

  Future<void> _start() async {
    if (_selectedAreas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos un área.')),
      );
      return;
    }
    if (_activeDraft != null) {
      final replace = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Reemplazar contrarreloj guardado'),
          content: const Text(
            'Tienes un reto sin terminar. Si continúas, se descartará su copia local y comenzará un tiempo nuevo.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              key: const Key('confirm-replace-time-trial-button'),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Crear nuevo'),
            ),
          ],
        ),
      );
      if (replace != true || !mounted) return;
      final userId = ref.read(sessionControllerProvider).user?.id;
      if (userId != null) {
        await ref.read(practiceDraftStoreProvider).clear(userId, 'time-trial');
      }
      if (!mounted) return;
    }
    await context.push(_config.routeLocation);
    if (mounted) await _loadActiveDraft();
  }

  void _resume() {
    final draft = _activeDraft;
    if (draft == null) return;
    context.push(
      TimeTrialConfig(
        areas: draft.session.areas,
        questionCount: draft.session.questions.length,
        minutes: draft.session.timeTrialMinutes ?? 10,
      ).routeLocation,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Prueba contrarreloj')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
      children: [
        Text(
          'Entrena tu velocidad',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text(
          'Tendrás un minuto por pregunta. El reloj sigue avanzando aunque cierres la app y el intento conserva las respuestas correctas protegidas.',
        ),
        const SizedBox(height: 14),
        const Card(
          child: ListTile(
            leading: CircleAvatar(child: Icon(Icons.timer_outlined)),
            title: Text('Tiempo estricto'),
            subtitle: Text(
              'Al terminar, se enviará automáticamente si respondiste todo. La app nunca inventará respuestas pendientes.',
            ),
          ),
        ),
        if (_activeDraft case final draft?) ...[
          const SizedBox(height: 14),
          Card(
            child: ListTile(
              key: const Key('resume-time-trial-card'),
              leading: const CircleAvatar(child: Icon(Icons.restore_rounded)),
              title: const Text('Continuar reto activo'),
              subtitle: Text(
                '${draft.selectedAnswers.length} de ${draft.session.questions.length} respondidas · ${_remainingLabel(draft)}',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: _resume,
            ),
          ),
        ],
        const SizedBox(height: 22),
        Text('Formato', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        for (final preset in TimeTrialPreset.values) ...[
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: _preset == preset
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outlineVariant,
                width: _preset == preset ? 2 : 1,
              ),
            ),
            child: ListTile(
              key: Key('time-trial-preset-${preset.name}'),
              title: Text(
                '${preset.label} · ${preset.questionCount} preguntas',
              ),
              subtitle: Text('${preset.minutes} min · ${preset.description}'),
              trailing: _preset == preset
                  ? const Icon(Icons.check_circle_rounded)
                  : const Icon(Icons.circle_outlined),
              onTap: () => setState(() => _preset = preset),
            ),
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 14),
        Text('Áreas', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final area in AcademicArea.values)
          CheckboxListTile(
            key: Key('time-trial-area-${area.slug}'),
            value: _selectedAreas.contains(area),
            title: Text(area.label),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            onChanged: (selected) => setState(() {
              if (selected ?? false) {
                _selectedAreas.add(area);
              } else {
                _selectedAreas.remove(area);
              }
            }),
          ),
        const SizedBox(height: 14),
        DropdownButtonFormField<PracticeDifficulty?>(
          key: const Key('time-trial-difficulty'),
          initialValue: _difficulty,
          decoration: const InputDecoration(labelText: 'Dificultad'),
          items: [
            const DropdownMenuItem(value: null, child: Text('Todas')),
            for (final difficulty in PracticeDifficulty.values)
              DropdownMenuItem(
                value: difficulty,
                child: Text(difficulty.label),
              ),
          ],
          onChanged: (value) => setState(() => _difficulty = value),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          key: const Key('start-time-trial-button'),
          onPressed: _start,
          icon: const Icon(Icons.bolt_rounded),
          label: const Text('Comenzar contrarreloj'),
        ),
      ],
    ),
  );
}

String _remainingLabel(PracticeDraft draft) {
  final remaining = draft.expiresAt.difference(DateTime.now());
  if (remaining.isNegative) return 'tiempo agotado';
  final minutes = remaining.inMinutes;
  final seconds = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds restantes';
}
