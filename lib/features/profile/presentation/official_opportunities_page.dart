import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/official_opportunity.dart';
import 'official_opportunities_providers.dart';

class OfficialOpportunitiesPage extends ConsumerStatefulWidget {
  const OfficialOpportunitiesPage({super.key});

  @override
  ConsumerState<OfficialOpportunitiesPage> createState() =>
      _OfficialOpportunitiesPageState();
}

class _OfficialOpportunitiesPageState
    extends ConsumerState<OfficialOpportunitiesPage> {
  OpportunityCategory _category = OpportunityCategory.all;

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(officialOpportunitiesProvider);
    final visible = filterOfficialOpportunities(catalog, _category);
    return Scaffold(
      appBar: AppBar(title: const Text('Becas y oportunidades')),
      body: ListView(
        key: const Key('official-opportunities-list'),
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 32),
        children: [
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.volunteer_activism_outlined, size: 30),
                  const SizedBox(height: 10),
                  Text(
                    'Encuentra apoyos oficiales',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Explora oportunidades verificadas y confirma siempre requisitos, fechas y disponibilidad en la entidad responsable.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Filtrar oportunidades',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final category in OpportunityCategory.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      key: Key('opportunity-filter-${category.name}'),
                      label: Text(category.label),
                      selected: _category == category,
                      onSelected: (_) => setState(() => _category = category),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (visible.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Text('No hay oportunidades en este filtro.'),
              ),
            )
          else
            for (final opportunity in visible)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _OpportunityCard(
                  opportunity: opportunity,
                  onOpen: () => _openOfficial(opportunity.officialUri),
                ),
              ),
          const SizedBox(height: 4),
          Card(
            key: const Key('opportunity-safety-notice'),
            color: Theme.of(context).colorScheme.tertiaryContainer,
            child: const Padding(
              padding: EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.security_outlined),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'SaberPlus no entrega becas ni confirma beneficiarios. No compartas contraseñas ni pagues a intermediarios: realiza el proceso únicamente en la fuente oficial.',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openOfficial(Uri uri) async {
    if (!isTrustedOfficialOpportunityUri(uri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('La fuente no es un sitio autorizado.')),
        );
      }
      return;
    }
    var opened = false;
    try {
      opened = await ref.read(officialOpportunityLinkOpenerProvider)(uri);
    } on Object {
      opened = false;
    }
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pudimos abrir la fuente oficial.')),
      );
    }
  }
}

class _OpportunityCard extends StatelessWidget {
  const _OpportunityCard({required this.opportunity, required this.onOpen});

  final OfficialOpportunity opportunity;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => Card(
    key: Key('official-opportunity-${opportunity.id}'),
    child: ExpansionTile(
      leading: Icon(_iconFor(opportunity.category)),
      title: Text(opportunity.title),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Text(opportunity.provider),
      ),
      childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(opportunity.summary),
        const SizedBox(height: 14),
        Text(
          'Quién debería revisarla',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 6),
        for (final requirement in opportunity.eligibility)
          _Bullet(text: requirement),
        const SizedBox(height: 10),
        Text(
          'Qué apoyo puede ofrecer',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 6),
        for (final item in opportunity.support) _Bullet(text: item),
        const SizedBox(height: 12),
        Text(
          'Fuente verificada: ${_formatDate(opportunity.verifiedOn)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.tonalIcon(
            key: Key('open-official-opportunity-${opportunity.id}'),
            onPressed: onOpen,
            icon: const Icon(Icons.open_in_new_rounded),
            label: const Text('Revisar fuente oficial'),
          ),
        ),
      ],
    ),
  );
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('•  '),
        Expanded(child: Text(text)),
      ],
    ),
  );
}

IconData _iconFor(OpportunityCategory category) => switch (category) {
  OpportunityCategory.merit => Icons.workspace_premium_outlined,
  OpportunityCategory.publicTuition => Icons.account_balance_outlined,
  OpportunityCategory.international => Icons.public_rounded,
  OpportunityCategory.specialFunds => Icons.groups_outlined,
  OpportunityCategory.all => Icons.volunteer_activism_outlined,
};

String _formatDate(String isoDate) {
  final parts = isoDate.split('-');
  if (parts.length != 3) return isoDate;
  const months = <String>[
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];
  final month = int.tryParse(parts[1]);
  if (month == null || month < 1 || month > 12) return isoDate;
  return '${int.parse(parts[2])} ${months[month - 1]} ${parts[0]}';
}
