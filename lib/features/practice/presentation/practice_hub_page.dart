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
        const SizedBox(height: 14),
        const Card(
          child: ListTile(
            leading: CircleAvatar(child: Icon(Icons.lock_clock_rounded)),
            title: Text('Siguientes modalidades'),
            subtitle: Text(
              'La sesión aleatoria y el simulacro completo llegarán en las próximas partes de la Etapa 4.',
            ),
          ),
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
