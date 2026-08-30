import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/career_orientation.dart';
import 'academic_profile_providers.dart';
import 'career_orientation_providers.dart';

class CareerOrientationPage extends ConsumerWidget {
  const CareerOrientationPage({super.key});

  static final programsUri = Uri.parse(
    'https://hecaa.mineducacion.gov.co/consultaspublicas/programas',
  );
  static final institutionsUri = Uri.parse(
    'https://hecaa.mineducacion.gov.co/consultaspublicas/ies',
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orientation = ref.watch(careerOrientationProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carreras y universidades'),
        actions: [
          IconButton(
            key: const Key('refresh-career-orientation'),
            tooltip: 'Actualizar orientación',
            onPressed: () => _refresh(ref),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: orientation.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _LoadError(onRetry: () => _refresh(ref)),
        data: (data) => _OrientationContent(
          orientation: data,
          onOpenPrograms: () => _openOfficial(context, ref, programsUri),
          onOpenInstitutions: () =>
              _openOfficial(context, ref, institutionsUri),
        ),
      ),
    );
  }

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(academicProfileProgressProvider);
    ref.invalidate(scoreProjectionProvider);
    ref.invalidate(careerOrientationProvider);
    try {
      await ref.read(careerOrientationProvider.future);
    } on Object {
      // El error queda representado por la pantalla con opción de reintento.
    }
  }

  Future<void> _openOfficial(
    BuildContext context,
    WidgetRef ref,
    Uri uri,
  ) async {
    var opened = false;
    try {
      opened = await ref.read(officialOrientationLinkOpenerProvider)(uri);
    } on Object {
      opened = false;
    }
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pudimos abrir la consulta oficial.')),
      );
    }
  }
}

class _OrientationContent extends StatelessWidget {
  const _OrientationContent({
    required this.orientation,
    required this.onOpenPrograms,
    required this.onOpenInstitutions,
  });

  final CareerOrientation orientation;
  final VoidCallback onOpenPrograms;
  final VoidCallback onOpenInstitutions;

  @override
  Widget build(BuildContext context) => ListView(
    key: const Key('career-orientation-list'),
    padding: const EdgeInsets.fromLTRB(18, 10, 18, 32),
    children: [
      Card(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.explore_outlined, size: 30),
              const SizedBox(height: 10),
              Text(
                'Explora caminos posibles',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              const Text(
                'Relacionamos tu desempeño académico con familias de carrera. Tus intereses, habilidades y contexto también deben hacer parte de la decisión.',
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 22),
      Text(
        'Afinidades académicas',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 5),
      const Text('No son una prueba vocacional ni una garantía de admisión.'),
      const SizedBox(height: 12),
      if (orientation.recommendations.isEmpty)
        const Card(
          child: Padding(
            padding: EdgeInsets.all(18),
            child: Text(
              'Completa actividades en varias materias para recibir orientaciones académicas.',
            ),
          ),
        )
      else
        for (final recommendation in orientation.recommendations)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _CareerCard(recommendation: recommendation),
          ),
      const SizedBox(height: 12),
      Text(
        'Consulta la oferta oficial',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 5),
      const Text(
        'El SNIES mantiene el registro oficial de instituciones y programas autorizados en Colombia.',
      ),
      const SizedBox(height: 12),
      _OfficialLinkCard(
        key: const Key('open-official-programs'),
        icon: Icons.school_outlined,
        title: 'Buscar programas académicos',
        subtitle: 'Revisa institución, ciudad, modalidad y registro calificado',
        onTap: onOpenPrograms,
      ),
      const SizedBox(height: 10),
      _OfficialLinkCard(
        key: const Key('open-official-institutions'),
        icon: Icons.account_balance_outlined,
        title: 'Consultar instituciones',
        subtitle: 'Verifica reconocimiento, sector y acreditación',
        onTap: onOpenInstitutions,
      ),
      const SizedBox(height: 16),
      Card(
        key: const Key('admission-safety-notice'),
        color: Theme.of(context).colorScheme.tertiaryContainer,
        child: const Padding(
          padding: EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.verified_user_outlined),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Cada institución define su proceso de admisión. Confirma directamente fechas, costos, documentos, pruebas adicionales y puntajes exigidos antes de postularte.',
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

class _CareerCard extends StatelessWidget {
  const _CareerCard({required this.recommendation});

  final CareerRecommendation recommendation;

  @override
  Widget build(BuildContext context) => Card(
    key: Key('career-path-${recommendation.path.id}'),
    child: ExpansionTile(
      leading: Icon(_iconFor(recommendation.path.id)),
      title: Text(recommendation.path.title),
      subtitle: Text(recommendation.affinity.label),
      childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(recommendation.path.description),
        const SizedBox(height: 10),
        Text(
          'Áreas relacionadas: ${recommendation.path.relatedAreas.map((area) => area.label).join(', ')}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            for (final example in recommendation.path.examples)
              Chip(label: Text(example)),
          ],
        ),
      ],
    ),
  );
}

class _OfficialLinkCard extends StatelessWidget {
  const _OfficialLinkCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.open_in_new_rounded),
      onTap: onTap,
    ),
  );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 44),
          const SizedBox(height: 12),
          const Text('No pudimos preparar la orientación académica.'),
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

IconData _iconFor(String id) => switch (id) {
  'engineering-data' => Icons.memory_rounded,
  'health-life' => Icons.biotech_outlined,
  'law-society' => Icons.gavel_outlined,
  'business-economy' => Icons.business_center_outlined,
  'languages-global' => Icons.language_rounded,
  _ => Icons.menu_book_outlined,
};
