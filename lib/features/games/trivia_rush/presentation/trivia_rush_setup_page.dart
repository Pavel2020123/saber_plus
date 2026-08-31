import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../academic/domain/academic_models.dart';
import '../domain/trivia_rush_models.dart';

class TriviaRushSetupPage extends StatefulWidget {
  const TriviaRushSetupPage({super.key});

  @override
  State<TriviaRushSetupPage> createState() => _TriviaRushSetupPageState();
}

class _TriviaRushSetupPageState extends State<TriviaRushSetupPage> {
  TriviaRushDuration _duration = TriviaRushDuration.standard;
  AcademicArea? _area;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Trivia Rush')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.rocket_launch_rounded, size: 38),
                SizedBox(height: 12),
                Text(
                  'Responde rápido, construye combos',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 8),
                Text(
                  'Cada acierto suma 100 puntos multiplicados por tu combo. Un error lo reinicia, salvo que uses protección.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Elige el contenido', style: theme.textTheme.titleLarge),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                key: const Key('trivia-area-mixed'),
                label: const Text('Todas las áreas'),
                selected: _area == null,
                onSelected: (_) => setState(() => _area = null),
              ),
              for (final area in AcademicArea.values)
                ChoiceChip(
                  key: Key('trivia-area-${area.slug}'),
                  label: Text(area.label),
                  selected: _area == area,
                  onSelected: (_) => setState(() => _area = area),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Duración', style: theme.textTheme.titleLarge),
          const SizedBox(height: 10),
          for (final duration in TriviaRushDuration.values) ...[
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                key: Key('trivia-duration-${duration.seconds}'),
                onTap: () => setState(() => _duration = duration),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        _duration == duration
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              duration.label,
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 2),
                            Text(duration.description),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.shield_outlined),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Las respuestas se validan una por una. La app no descarga la clave correcta del banco antes de responder.',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const Key('start-trivia-rush'),
            onPressed: () {
              final config = TriviaRushConfig(
                areas: _area == null ? AcademicArea.values : [_area!],
                duration: _duration,
              );
              context.push(config.routeLocation);
            },
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Comenzar ronda'),
          ),
        ],
      ),
    );
  }
}
