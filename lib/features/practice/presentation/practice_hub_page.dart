import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../academic/domain/academic_models.dart';

class PracticeHubPage extends StatelessWidget {
  const PracticeHubPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Practicar')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
      children: [
        Text(
          'Simulacro completo',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text('Resuelve una prueba completa enfocada en una sola área.'),
        const SizedBox(height: 14),
        Card(
          child: ListTile(
            key: const Key('open-area-simulation'),
            leading: const CircleAvatar(child: Icon(Icons.assignment_rounded)),
            title: const Text('Comenzar simulacro'),
            subtitle: const Text('Hasta 25 preguntas por área'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/student/practice/simulation'),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            key: const Key('open-practice-history'),
            leading: const CircleAvatar(child: Icon(Icons.history_rounded)),
            title: const Text('Ver historial'),
            subtitle: const Text('Resultados y revisión de respuestas'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/student/practice/history'),
          ),
        ),
        const SizedBox(height: 26),
        Text(
          'Sesión aleatoria',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text(
          'Combina áreas, cantidad y dificultad en un intento protegido.',
        ),
        const SizedBox(height: 14),
        Card(
          child: ListTile(
            key: const Key('open-random-practice'),
            leading: const CircleAvatar(child: Icon(Icons.shuffle_rounded)),
            title: const Text('Configurar preguntas aleatorias'),
            subtitle: const Text('Una o varias áreas'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/student/practice/random'),
          ),
        ),
        const SizedBox(height: 26),
        Text(
          'Práctica por subtema',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text(
          'Elige un área, abre una lección y responde sus preguntas. La calificación y las explicaciones se muestran al finalizar.',
        ),
        const SizedBox(height: 20),
        for (final area in AcademicArea.values) ...[
          Card(
            child: ListTile(
              key: Key('practice-area-${area.slug}'),
              leading: CircleAvatar(child: Icon(_iconFor(area))),
              title: Text(area.label),
              subtitle: const Text('Ver temas y subtemas'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.go('/student/study/${area.slug}'),
            ),
          ),
          const SizedBox(height: 8),
        ],
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
