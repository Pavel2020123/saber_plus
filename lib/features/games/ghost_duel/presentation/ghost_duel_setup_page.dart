import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../academic/domain/academic_models.dart';
import '../../trivia_rush/domain/trivia_rush_models.dart';
import '../domain/ghost_duel_models.dart';

class GhostDuelSetupPage extends StatefulWidget {
  const GhostDuelSetupPage({super.key});

  @override
  State<GhostDuelSetupPage> createState() => _GhostDuelSetupPageState();
}

class _GhostDuelSetupPageState extends State<GhostDuelSetupPage> {
  TriviaRushDuration _duration = TriviaRushDuration.standard;
  AcademicArea? _area;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Duelo fantasma')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.sports_martial_arts_rounded, size: 38),
                SizedBox(height: 12),
                Text(
                  'Compite contra tu mejor versión',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 8),
                Text(
                  'El fantasma reproduce el puntaje que llevabas en cada momento de tu mejor ronda limpia de Trivia Rush.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.balance_rounded),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Los potenciadores están desactivados. Si todavía no existe un récord para esta configuración, la primera partida creará el fantasma.',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Contenido', style: theme.textTheme.titleLarge),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                key: const Key('ghost-area-mixed'),
                label: const Text('Todas las áreas'),
                selected: _area == null,
                onSelected: (_) => setState(() => _area = null),
              ),
              for (final area in AcademicArea.values)
                ChoiceChip(
                  key: Key('ghost-area-${area.slug}'),
                  label: Text(area.label),
                  selected: _area == area,
                  onSelected: (_) => setState(() => _area = area),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Duración', style: theme.textTheme.titleLarge),
          const SizedBox(height: 10),
          for (final duration in TriviaRushDuration.values)
            Card(
              clipBehavior: Clip.antiAlias,
              margin: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                key: Key('ghost-duration-${duration.seconds}'),
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
                            Text(duration.description),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const Key('start-ghost-duel'),
            onPressed: () {
              final config = GhostDuelConfig(
                areas: _area == null ? AcademicArea.values : [_area!],
                duration: _duration,
              );
              context.push(config.routeLocation);
            },
            icon: const Icon(Icons.sports_martial_arts_rounded),
            label: const Text('Iniciar duelo'),
          ),
        ],
      ),
    );
  }
}
