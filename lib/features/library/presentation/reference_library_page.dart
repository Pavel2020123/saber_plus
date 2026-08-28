import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../academic/domain/academic_models.dart';
import '../domain/reference_library_models.dart';
import 'reference_library_providers.dart';

class ReferenceLibraryPage extends ConsumerWidget {
  const ReferenceLibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => DefaultTabController(
    length: 3,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Biblioteca académica'),
        bottom: const TabBar(
          isScrollable: true,
          tabs: [
            Tab(icon: Icon(Icons.functions_rounded), text: 'Fórmulas'),
            Tab(icon: Icon(Icons.abc_rounded), text: 'Glosario'),
            Tab(icon: Icon(Icons.route_rounded), text: 'Estrategia'),
          ],
        ),
      ),
      body: ref
          .watch(referenceLibraryProvider)
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _LibraryError(
              onRetry: () => ref.invalidate(referenceLibraryProvider),
            ),
            data: (library) => TabBarView(
              children: [
                _FormulasTab(areas: library.formulas),
                _GlossaryTab(terms: library.glossary),
                _StrategyTab(strategy: library.strategy),
              ],
            ),
          ),
    ),
  );
}

class _FormulasTab extends StatefulWidget {
  const _FormulasTab({required this.areas});

  final List<FormulaArea> areas;

  @override
  State<_FormulasTab> createState() => _FormulasTabState();
}

class _FormulasTabState extends State<_FormulasTab> {
  AcademicArea _selectedArea = AcademicArea.mathematics;
  var _query = '';

  @override
  Widget build(BuildContext context) {
    final area = widget.areas.firstWhere(
      (item) => item.area == _selectedArea,
      orElse: () => widget.areas.first,
    );
    final sections = [
      for (final section in area.sections)
        FormulaSection(
          id: section.id,
          title: section.title,
          items: section.items
              .where((item) => item.matches(_query))
              .toList(growable: false),
        ),
    ].where((section) => section.items.isNotEmpty).toList(growable: false);

    return ListView(
      key: const Key('formula-library-list'),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
      children: [
        Text(
          'Formulario por área',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 6),
        const Text(
          'Consulta relaciones, usos, variables y alertas frecuentes del examen.',
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<AcademicArea>(
          initialValue: _selectedArea,
          decoration: const InputDecoration(labelText: 'Área ICFES'),
          items: [
            for (final item in widget.areas)
              DropdownMenuItem(value: item.area, child: Text(item.name)),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _selectedArea = value);
          },
        ),
        const SizedBox(height: 10),
        TextField(
          key: const Key('formula-search-field'),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search_rounded),
            labelText: 'Buscar fórmula o concepto',
          ),
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: 18),
        Text(area.tagline, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(area.description),
        const SizedBox(height: 14),
        if (sections.isEmpty)
          const _EmptyResults(
            message: 'No encontramos fórmulas con esa búsqueda.',
          )
        else
          for (final section in sections) ...[
            Card(
              child: ExpansionTile(
                key: ValueKey('formula-section-${section.id}-$_query'),
                initiallyExpanded: _query.trim().isNotEmpty,
                title: Text(section.title),
                subtitle: Text('${section.items.length} referencias'),
                childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                children: [
                  for (final item in section.items) ...[
                    _FormulaCard(item: item),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}

class _FormulaCard extends StatelessWidget {
  const _FormulaCard({required this.item});

  final FormulaReference item;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(item.name, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        SelectableText(
          item.expression,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(item.use),
        if (item.variables case final variables?) ...[
          const SizedBox(height: 7),
          Text('Variables: $variables'),
        ],
        if (item.warning case final warning?) ...[
          const SizedBox(height: 9),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 19),
              const SizedBox(width: 7),
              Expanded(child: Text(warning)),
            ],
          ),
        ],
      ],
    ),
  );
}

class _GlossaryTab extends StatefulWidget {
  const _GlossaryTab({required this.terms});

  final List<GlossaryTerm> terms;

  @override
  State<_GlossaryTab> createState() => _GlossaryTabState();
}

class _GlossaryTabState extends State<_GlossaryTab> {
  AcademicArea? _area;
  var _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.terms
        .where((term) {
          if (_area != null && term.area != _area) return false;
          return term.matches(_query);
        })
        .toList(growable: false);

    return ListView(
      key: const Key('glossary-library-list'),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
      children: [
        Text(
          'Glosario ICFES',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 6),
        const Text(
          'Busca conceptos, ejemplos y términos relacionados de las cinco áreas.',
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<AcademicArea?>(
          initialValue: _area,
          decoration: const InputDecoration(labelText: 'Área'),
          items: [
            const DropdownMenuItem(value: null, child: Text('Todas las áreas')),
            for (final area in AcademicArea.values)
              DropdownMenuItem(value: area, child: Text(area.label)),
          ],
          onChanged: (value) => setState(() => _area = value),
        ),
        const SizedBox(height: 10),
        TextField(
          key: const Key('glossary-search-field'),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search_rounded),
            labelText: 'Buscar término o definición',
          ),
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: 14),
        Text('${filtered.length} términos encontrados'),
        const SizedBox(height: 10),
        if (filtered.isEmpty)
          const _EmptyResults(
            message: 'No encontramos términos con esos filtros.',
          )
        else
          for (final term in filtered) ...[
            Card(
              child: ExpansionTile(
                key: ValueKey('glossary-${term.area.name}-${term.term}'),
                leading: CircleAvatar(child: Text(term.term[0].toUpperCase())),
                title: Text(term.term),
                subtitle: Text(term.area.label),
                childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(term.definition),
                  const SizedBox(height: 10),
                  Text(
                    'Ejemplo',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 3),
                  Text(term.example),
                  if (term.related.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        for (final related in term.related)
                          Chip(label: Text(related)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
      ],
    );
  }
}

class _StrategyTab extends StatefulWidget {
  const _StrategyTab({required this.strategy});

  final ExamStrategy strategy;

  @override
  State<_StrategyTab> createState() => _StrategyTabState();
}

class _StrategyTabState extends State<_StrategyTab> {
  late final TextEditingController _questions;
  late final TextEditingController _minutes;
  late final TextEditingController _review;
  AcademicArea _area = AcademicArea.criticalReading;
  final _checked = <int>{};

  @override
  void initState() {
    super.initState();
    _questions = TextEditingController(text: '100');
    _minutes = TextEditingController(text: '240');
    _review = TextEditingController(text: '20');
  }

  @override
  void dispose() {
    _questions.dispose();
    _minutes.dispose();
    _review.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final plan = ExamTimePlan.calculate(
      questionCount: int.tryParse(_questions.text) ?? 100,
      availableMinutes: int.tryParse(_minutes.text) ?? 240,
      reviewMinutes: int.tryParse(_review.text) ?? 20,
    );
    final tactic = widget.strategy.areaTactics.firstWhere(
      (item) => item.area == _area,
      orElse: () => widget.strategy.areaTactics.first,
    );
    return ListView(
      key: const Key('strategy-library-list'),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
      children: [
        Text(
          'Estrategia de examen',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 6),
        const Text(
          'Organiza el tiempo y toma decisiones con evidencia durante cada sesión.',
        ),
        const SizedBox(height: 18),
        Text(
          'Planificador de tiempo',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _NumberField(
                key: const Key('strategy-question-count'),
                controller: _questions,
                label: 'Preguntas',
                onChanged: () => setState(() {}),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _NumberField(
                controller: _minutes,
                label: 'Minutos',
                onChanged: () => setState(() {}),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _NumberField(
                controller: _review,
                label: 'Revisión',
                onChanged: () => setState(() {}),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(17),
            child: Column(
              children: [
                Text(
                  '${plan.secondsPerQuestion} segundos por pregunta',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 5),
                Text(
                  '${plan.workMinutes} min de trabajo · ${plan.reviewMinutes} min de revisión',
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final checkpoint in plan.checkpoints)
                      Chip(
                        label: Text(
                          'P${checkpoint.question} · min ${checkpoint.minute}',
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        Text('Las cuatro fases', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        for (final phase in widget.strategy.phases) ...[
          Card(
            child: ExpansionTile(
              leading: CircleAvatar(child: Text('${phase.number}')),
              title: Text(phase.title),
              subtitle: Text(phase.moment),
              childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(phase.objective),
                const SizedBox(height: 9),
                for (final action in phase.actions) _BulletText(text: action),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 14),
        Text('Táctica por área', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        DropdownButtonFormField<AcademicArea>(
          initialValue: _area,
          decoration: const InputDecoration(labelText: 'Área ICFES'),
          items: [
            for (final item in widget.strategy.areaTactics)
              DropdownMenuItem(value: item.area, child: Text(item.name)),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _area = value);
          },
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tactic.focus,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                for (final step in tactic.steps) _BulletText(text: step),
                const SizedBox(height: 9),
                Text(
                  tactic.controlQuestion,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'Distractores frecuentes',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        for (final distractor in widget.strategy.distractors) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(17),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    distractor.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(distractor.signal),
                  const SizedBox(height: 7),
                  Text(
                    'Respuesta: ${distractor.response}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Text(
                'Checklist del examen',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Text('${_checked.length}/${widget.strategy.checklist.length}'),
          ],
        ),
        const SizedBox(height: 10),
        Card(
          child: Column(
            children: [
              for (
                var index = 0;
                index < widget.strategy.checklist.length;
                index++
              )
                CheckboxListTile(
                  value: _checked.contains(index),
                  title: Text(widget.strategy.checklist[index]),
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (value) {
                    setState(() {
                      if (value ?? false) {
                        _checked.add(index);
                      } else {
                        _checked.remove(index);
                      }
                    });
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.onChanged,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    decoration: InputDecoration(labelText: label),
    onChanged: (_) => onChanged(),
  );
}

class _BulletText extends StatelessWidget {
  const _BulletText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('• '),
        Expanded(child: Text(text)),
      ],
    ),
  );
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Text(message, textAlign: TextAlign.center),
    ),
  );
}

class _LibraryError extends StatelessWidget {
  const _LibraryError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.menu_book_outlined, size: 48),
          const SizedBox(height: 12),
          const Text(
            'No pudimos abrir la biblioteca académica.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          FilledButton.tonal(
            onPressed: onRetry,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    ),
  );
}
