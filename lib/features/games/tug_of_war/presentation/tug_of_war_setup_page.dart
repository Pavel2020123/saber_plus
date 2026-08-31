import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../academic/domain/academic_models.dart';
import '../domain/tug_of_war_models.dart';

class TugOfWarSetupPage extends StatefulWidget {
  const TugOfWarSetupPage({super.key});

  @override
  State<TugOfWarSetupPage> createState() => _TugOfWarSetupPageState();
}

class _TugOfWarSetupPageState extends State<TugOfWarSetupPage> {
  AcademicArea? _area;
  TugCpuDifficulty _difficulty = TugCpuDifficulty.balanced;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Tira y afloja')),
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
                Icon(Icons.sports_kabaddi_rounded, size: 40),
                SizedBox(height: 12),
                Text(
                  'Acertar importa; responder rápido también',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 8),
                Text(
                  'Los dos reciben la misma pregunta. Un acierto contra un error da un tirón fuerte; si ambos aciertan, tira quien responda primero.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.animation_rounded),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Duelo animado contra la CPU con tensión, tirones y celebración. El multijugador llegará con el backend autoritativo.',
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
                key: const Key('tug-area-mixed'),
                label: const Text('Todas las áreas'),
                selected: _area == null,
                onSelected: (_) => setState(() => _area = null),
              ),
              for (final area in AcademicArea.values)
                ChoiceChip(
                  key: Key('tug-area-${area.slug}'),
                  label: Text(area.label),
                  selected: _area == area,
                  onSelected: (_) => setState(() => _area = area),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Rival CPU', style: theme.textTheme.titleLarge),
          const SizedBox(height: 10),
          for (final difficulty in TugCpuDifficulty.values) ...[
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                key: Key('tug-cpu-${difficulty.queryValue}'),
                onTap: () => setState(() => _difficulty = difficulty),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        _difficulty == difficulty
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              difficulty.label,
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 2),
                            Text(difficulty.description),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Gana quien lleve primero la cuerda hasta la cuarta marca. No hay potenciadores ni anuncios durante la partida.',
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const Key('start-tug-of-war'),
            onPressed: () {
              final config = TugOfWarConfig(
                areas: _area == null ? AcademicArea.values : [_area!],
                cpuDifficulty: _difficulty,
              );
              context.push(config.routeLocation);
            },
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Comenzar partida local'),
          ),
        ],
      ),
    );
  }
}
