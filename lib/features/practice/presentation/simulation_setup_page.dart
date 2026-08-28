import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../academic/domain/academic_models.dart';

class SimulationSetupPage extends StatefulWidget {
  const SimulationSetupPage({super.key});

  @override
  State<SimulationSetupPage> createState() => _SimulationSetupPageState();
}

class _SimulationSetupPageState extends State<SimulationSetupPage> {
  var _area = AcademicArea.mathematics;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Simulacro completo')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
      children: [
        Text('Elige un área', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        const Text(
          'El backend seleccionará hasta 25 preguntas. Si una pregunta pertenece a un caso compartido, el caso se conserva completo.',
        ),
        const SizedBox(height: 14),
        const Card(
          child: ListTile(
            leading: CircleAvatar(child: Icon(Icons.timer_outlined)),
            title: Text('Intento protegido'),
            subtitle: Text(
              'Tendrás hasta 2 horas. Tus respuestas y tiempos se guardan en este dispositivo.',
            ),
          ),
        ),
        const SizedBox(height: 18),
        for (final area in AcademicArea.values) ...[
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: _area == area
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outlineVariant,
                width: _area == area ? 2 : 1,
              ),
            ),
            child: ListTile(
              key: Key('simulation-area-${area.slug}'),
              leading: CircleAvatar(child: Icon(_iconFor(area))),
              title: Text(area.label),
              trailing: _area == area
                  ? const Icon(Icons.check_circle_rounded)
                  : const Icon(Icons.circle_outlined),
              onTap: () => setState(() => _area = area),
            ),
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 16),
        FilledButton.icon(
          key: const Key('start-area-simulation-button'),
          onPressed: () =>
              context.push('/student/practice/simulation/${_area.slug}'),
          icon: const Icon(Icons.assignment_rounded),
          label: const Text('Comenzar simulacro'),
        ),
      ],
    ),
  );
}

IconData _iconFor(AcademicArea area) => switch (area) {
  AcademicArea.criticalReading => Icons.menu_book_rounded,
  AcademicArea.mathematics => Icons.calculate_rounded,
  AcademicArea.naturalSciences => Icons.science_rounded,
  AcademicArea.socialSciences => Icons.public_rounded,
  AcademicArea.english => Icons.translate_rounded,
};
