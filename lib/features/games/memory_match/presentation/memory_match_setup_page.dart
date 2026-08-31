import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../academic/domain/academic_models.dart';
import '../domain/memory_match_models.dart';

class MemoryMatchSetupPage extends StatefulWidget {
  const MemoryMatchSetupPage({super.key});

  @override
  State<MemoryMatchSetupPage> createState() => _MemoryMatchSetupPageState();
}

class _MemoryMatchSetupPageState extends State<MemoryMatchSetupPage> {
  MemoryMatchKind _kind = MemoryMatchKind.mixed;
  MemoryMatchDifficulty _difficulty = MemoryMatchDifficulty.easy;
  AcademicArea? _area;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Memoria académica')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.grid_view_rounded, size: 38),
                SizedBox(height: 12),
                Text(
                  'Encuentra cada concepto y su pareja',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 8),
                Text(
                  'Relaciona una fórmula con su expresión o un término con su definición. El contenido funciona sin conexión.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Contenido', style: theme.textTheme.titleLarge),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final kind in MemoryMatchKind.values)
                ChoiceChip(
                  key: Key('memory-kind-${kind.queryValue}'),
                  label: Text(kind.label),
                  selected: _kind == kind,
                  onSelected: (_) => setState(() => _kind = kind),
                ),
            ],
          ),
          const SizedBox(height: 22),
          Text('Área', style: theme.textTheme.titleLarge),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                key: const Key('memory-area-all'),
                label: const Text('Todas'),
                selected: _area == null,
                onSelected: (_) => setState(() => _area = null),
              ),
              for (final area in AcademicArea.values)
                ChoiceChip(
                  key: Key('memory-area-${area.slug}'),
                  label: Text(area.label),
                  selected: _area == area,
                  onSelected: (_) => setState(() => _area = area),
                ),
            ],
          ),
          const SizedBox(height: 22),
          Text('Dificultad', style: theme.textTheme.titleLarge),
          const SizedBox(height: 10),
          for (final difficulty in MemoryMatchDifficulty.values)
            Card(
              clipBehavior: Clip.antiAlias,
              margin: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                key: Key('memory-difficulty-${difficulty.queryValue}'),
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
                        child: Text(
                          difficulty.label,
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      Text('${difficulty.pairCount} parejas'),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const Key('start-memory-match'),
            onPressed: () {
              final config = MemoryMatchConfig(
                kind: _kind,
                difficulty: _difficulty,
                area: _area,
              );
              context.push(config.routeLocation);
            },
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Comenzar partida'),
          ),
        ],
      ),
    );
  }
}
