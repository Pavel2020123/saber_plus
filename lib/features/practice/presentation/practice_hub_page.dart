import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../academic/domain/academic_models.dart';

class PracticeHubPage extends StatelessWidget {
  const PracticeHubPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Practicar'),
      actions: [
        IconButton(
          key: const Key('open-practice-search'),
          tooltip: 'Buscar preguntas por tema',
          onPressed: () => context.go('/student/study/search'),
          icon: const Icon(Icons.search_rounded),
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
      children: [
        Text(
          'Simulacro completo',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text(
          'Entrena con el formato de 150 preguntas o enfócate en una sola área.',
        ),
        const SizedBox(height: 14),
        Card(
          child: ListTile(
            key: const Key('open-official-simulation'),
            leading: const CircleAvatar(child: Icon(Icons.fact_check_outlined)),
            title: const Text('Simulacro 150 · AM/PM'),
            subtitle: const Text('Dos jornadas de 75 preguntas'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/student/practice/official'),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            key: const Key('open-historical-simulations'),
            leading: const CircleAvatar(
              child: Icon(Icons.inventory_2_outlined),
            ),
            title: const Text('Simulacros por año'),
            subtitle: const Text('Solo contenido propio o autorizado'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/student/practice/past'),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            key: const Key('open-area-simulation'),
            leading: const CircleAvatar(child: Icon(Icons.assignment_rounded)),
            title: const Text('Simulacro por área'),
            subtitle: const Text('Hasta 25 preguntas por área'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/student/practice/simulation'),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            key: const Key('open-time-trial'),
            leading: const CircleAvatar(child: Icon(Icons.bolt_rounded)),
            title: const Text('Prueba contrarreloj'),
            subtitle: const Text('5, 10 o 20 preguntas con tiempo estricto'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/student/practice/time-trial'),
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
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            key: const Key('open-daily-mistakes'),
            leading: const CircleAvatar(child: Icon(Icons.fact_check_outlined)),
            title: const Text('Repasar errores de hoy'),
            subtitle: const Text('Explicaciones y progreso del día'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/student/practice/daily-review'),
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
        const SizedBox(height: 18),
        Text(
          'Retos entre estudiantes',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text(
          'Compite de forma anónima. Cada estudiante responde cuando pueda dentro de 24 horas.',
        ),
        const SizedBox(height: 14),
        Card(
          child: ListTile(
            key: const Key('open-async-battles'),
            leading: const CircleAvatar(
              child: Icon(Icons.sports_esports_outlined),
            ),
            title: const Text('Batallas asíncronas'),
            subtitle: const Text('Rival al azar o invitación privada'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/student/practice/battles'),
          ),
        ),
        const SizedBox(height: 26),
        Text(
          'Juegos individuales',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text(
          'Entrena velocidad y precisión sin afectar tu progreso académico.',
        ),
        const SizedBox(height: 14),
        Card(
          child: ListTile(
            key: const Key('open-trivia-rush'),
            leading: const CircleAvatar(
              child: Icon(Icons.rocket_launch_rounded),
            ),
            title: const Text('Trivia Rush'),
            subtitle: const Text('Tiempo, combos y potenciadores opcionales'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/student/practice/trivia-rush'),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            key: const Key('open-memory-match'),
            leading: const CircleAvatar(child: Icon(Icons.grid_view_rounded)),
            title: const Text('Memoria académica'),
            subtitle: const Text('Une fórmulas, conceptos y definiciones'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/student/practice/memory-match'),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            key: const Key('open-ghost-duel'),
            leading: const CircleAvatar(
              child: Icon(Icons.sports_martial_arts_rounded),
            ),
            title: const Text('Duelo fantasma'),
            subtitle: const Text('Supera la evolución de tu mejor partida'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/student/practice/ghost-duel'),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            key: const Key('open-tug-of-war'),
            leading: const CircleAvatar(
              child: Icon(Icons.sports_kabaddi_rounded),
            ),
            title: const Text('Tira y afloja'),
            subtitle: const Text('Preguntas rápidas contra un rival CPU'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/student/practice/tug-of-war'),
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
