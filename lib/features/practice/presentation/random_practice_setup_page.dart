import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../academic/domain/academic_models.dart';
import '../../auth/presentation/session_controller.dart';
import '../data/practice_draft_store.dart';
import '../domain/practice_models.dart';

class RandomPracticeSetupPage extends ConsumerStatefulWidget {
  const RandomPracticeSetupPage({super.key});

  @override
  ConsumerState<RandomPracticeSetupPage> createState() =>
      _RandomPracticeSetupPageState();
}

class _RandomPracticeSetupPageState
    extends ConsumerState<RandomPracticeSetupPage> {
  final _selectedAreas = <AcademicArea>{AcademicArea.mathematics};
  var _questionCount = 10;
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
    final draft = await store.read(userId, 'random');
    if (draft != null && draft.isExpiredAt(DateTime.now())) {
      await store.clear(userId, 'random');
      return;
    }
    if (!mounted || draft?.session.isRandom != true) return;
    setState(() => _activeDraft = draft);
  }

  Future<void> _start() async {
    if (_selectedAreas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos un área.')),
      );
      return;
    }
    final config = RandomPracticeConfig(
      areas: AcademicArea.values
          .where(_selectedAreas.contains)
          .toList(growable: false),
      questionCount: _questionCount,
      difficulty: _difficulty,
    );
    final active = _activeDraft;
    if (active != null && !_sameAreas(active.session.areas, config.areas)) {
      final replace = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Reemplazar intento guardado'),
          content: const Text(
            'Tienes una sesión aleatoria sin terminar. Si continúas, se descartará su copia local y se abrirá un intento nuevo.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              key: const Key('confirm-replace-random-practice-button'),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Crear nueva'),
            ),
          ],
        ),
      );
      if (replace != true || !mounted) return;
      final userId = ref.read(sessionControllerProvider).user?.id;
      if (userId != null) {
        await ref.read(practiceDraftStoreProvider).clear(userId, 'random');
      }
      if (!mounted) return;
    }
    await context.push(config.routeLocation);
    if (mounted) await _loadActiveDraft();
  }

  void _resume() {
    final draft = _activeDraft;
    if (draft == null) return;
    final config = RandomPracticeConfig(
      areas: draft.session.areas,
      questionCount: draft.session.questions.length,
    );
    context.push(config.routeLocation);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Preguntas aleatorias')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
      children: [
        Text(
          'Configura tu sesión',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text(
          'Combina una o varias áreas. Las preguntas se mezclan y la respuesta correcta permanece protegida hasta finalizar.',
        ),
        if (_activeDraft case final draft?) ...[
          const SizedBox(height: 18),
          Card(
            child: ListTile(
              key: const Key('resume-random-practice-card'),
              leading: const CircleAvatar(child: Icon(Icons.restore_rounded)),
              title: const Text('Tienes un intento sin terminar'),
              subtitle: Text(
                '${draft.selectedAnswers.length} de ${draft.session.questions.length} respondidas',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: _resume,
            ),
          ),
        ],
        const SizedBox(height: 22),
        Text('Áreas', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        for (final area in AcademicArea.values)
          CheckboxListTile(
            key: Key('random-area-${area.slug}'),
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
        DropdownButtonFormField<int>(
          key: const Key('random-question-count'),
          initialValue: _questionCount,
          decoration: const InputDecoration(labelText: 'Cantidad solicitada'),
          items: const [
            DropdownMenuItem(value: 5, child: Text('5 preguntas')),
            DropdownMenuItem(value: 10, child: Text('10 preguntas')),
            DropdownMenuItem(value: 20, child: Text('20 preguntas')),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _questionCount = value);
          },
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<PracticeDifficulty?>(
          key: const Key('random-difficulty'),
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
          key: const Key('start-random-practice-button'),
          onPressed: _start,
          icon: const Icon(Icons.shuffle_rounded),
          label: const Text('Comenzar sesión'),
        ),
      ],
    ),
  );
}

bool _sameAreas(List<AcademicArea> first, List<AcademicArea> second) {
  final left = first.toSet();
  final right = second.toSet();
  return left.length == right.length && left.containsAll(right);
}
