import 'package:flutter/material.dart';

import '../domain/vocational_orientation.dart';
import 'sabi_profession_illustration.dart';

/// Owner-approved editorial examples for the demo, not career recommendations.
/// Independent of scoring, persistence and the catalog of official programs.
const vocationalRelatedProfessions = <String, List<SabiProfession>>{
  'TECNOLOGIA_INGENIERIA': [
    SabiProfession.software,
    SabiProfession.industrialEngineering,
    SabiProfession.civilEngineering,
  ],
  'SALUD_CIENCIAS_VIDA': [
    SabiProfession.medicine,
    SabiProfession.nursing,
    SabiProfession.psychology,
  ],
  'SOCIEDAD_DERECHO_COMUNICACION': [
    SabiProfession.law,
    SabiProfession.psychology,
    SabiProfession.design,
  ],
  'NEGOCIOS_ORGANIZACION_EMPRENDIMIENTO': [
    SabiProfession.administration,
    SabiProfession.accounting,
    SabiProfession.industrialEngineering,
  ],
  'EDUCACION_HUMANIDADES_IDIOMAS': [
    SabiProfession.education,
    SabiProfession.psychology,
    SabiProfession.law,
  ],
  'CREATIVIDAD_DISENO_ENTORNO': [
    SabiProfession.design,
    SabiProfession.environmentalAgro,
    SabiProfession.civilEngineering,
  ],
};

String _score(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toString().replaceAll('.', ',');

class VocationalResultOverview extends StatelessWidget {
  const VocationalResultOverview({super.key, required this.result});
  final VocationalResult result;

  @override
  Widget build(BuildContext context) {
    final byId = {for (final f in result.families) f.id: f};
    final maximum = result.mainFamilies
        .map((id) => byId[id]!.score)
        .reduce((a, b) => a > b ? a : b);
    final leaders = result.mainFamilies
        .where((id) => byId[id]!.score == maximum)
        .toList();
    final theme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            'Tus intereses se orientan principalmente hacia:',
            style: theme.headlineSmall,
          ),
        ),
        const SizedBox(height: 12),
        for (final id in result.mainFamilies)
          Card(
            key: Key('vocational-family-$id'),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Semantics(
                key: Key('vocational-family-heading-$id'),
                container: true,
                header: true,
                excludeSemantics: true,
                label: vocationalFamilyNames[id]!,
                child: Text(
                  vocationalFamilyNames[id]!,
                  style: theme.titleMedium,
                ),
              ),
            ),
          ),
        const SizedBox(height: 8),
        const Text(
          'Estas áreas reflejan las actividades que más despertaron tu interés en esta exploración. Son intereses declarados, no un diagnóstico ni una garantía. No miden aptitud ni predicen éxito o admisión, y no son una decisión profesional definitiva. Tu resultado es privado.',
        ),
        const SizedBox(height: 8),
        Text(
          'Respuestas válidas: ${result.validCount} de ${result.totalQuestions}. “No sé” no entra en el puntaje y reduce la cobertura.',
        ),
        const SizedBox(height: 20),
        Semantics(
          header: true,
          child: Text('Un ámbito que puedes explorar', style: theme.titleLarge),
        ),
        if (leaders.length > 1) ...[
          const SizedBox(height: 8),
          const Text(
            'Hay empate en el mayor puntaje. Estas familias tienen la misma prioridad; los ejemplos no eligen una ganadora.',
          ),
          for (final id in leaders) Text('• ${vocationalFamilyNames[id]!}'),
        ],
        const Text(
          'Esta ilustración representa uno de los ámbitos que puedes explorar. No es una recomendación de carrera.',
        ),
        _RelatedExplorer(
          key: ObjectKey(result),
          families: leaders,
          prefix: 'featured',
        ),
        ExpansionTile(
          key: const Key('vocational-related-toggle'),
          title: const Text('Explora ámbitos relacionados'),
          subtitle: const Text(
            'Ejemplos de todas tus familias principales, sin orden de preferencia profesional.',
          ),
          children: [
            _RelatedExplorer(
              key: ValueKey(result),
              families: result.mainFamilies,
              prefix: 'related',
            ),
          ],
        ),
        const SizedBox(height: 20),
        Semantics(
          header: true,
          child: Text('Interés en las seis familias', style: theme.titleLarge),
        ),
        const Text(
          'Índice normalizado de interés de 0 a 100. No es un porcentaje ni una probabilidad. Los puntajes iguales tienen la misma prioridad.',
        ),
        for (final f in result.families)
          Padding(
            key: result.mainFamilies.contains(f.id)
                ? null
                : Key('vocational-other-family-${f.id}'),
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Semantics(
              key: Key('vocational-score-${f.id}'),
              container: true,
              excludeSemantics: true,
              label:
                  '${vocationalFamilyNames[f.id]}. Puntaje de interés: ${_score(f.score)} de 100. Cobertura: ${f.validCount} de ${f.totalQuestions}.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(vocationalFamilyNames[f.id]!, style: theme.titleMedium),
                  Text('Puntaje de interés: ${_score(f.score)} de 100'),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(value: f.score / 100),
                  const SizedBox(height: 4),
                  Text(
                    'Respondiste ${f.validCount} de ${f.totalQuestions} preguntas de esta familia.',
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),
        ExpansionTile(
          key: const Key('vocational-result-details'),
          title: const Text('Detalle de tus respuestas'),
          subtitle: const Text(
            'Cobertura y actividades que marcaste con interés.',
          ),
          children: [
            for (final f in result.families)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      vocationalFamilyNames[f.id]!,
                      style: theme.titleMedium,
                    ),
                    Text(
                      'Respondiste ${f.validCount} de ${f.totalQuestions} preguntas de esta familia.',
                    ),
                    for (final q in result.questions.where(
                      (q) =>
                          q.family == f.id &&
                          {
                            VocationalAnswer.quite,
                            VocationalAnswer.much,
                          }.contains(result.answers[q.id]),
                    ))
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text('Marcaste interés en: ${q.text}'),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _RelatedExplorer extends StatefulWidget {
  const _RelatedExplorer({
    super.key,
    required this.families,
    required this.prefix,
  });
  final List<String> families;
  final String prefix;
  @override
  State<_RelatedExplorer> createState() => _RelatedExplorerState();
}

class _RelatedExplorerState extends State<_RelatedExplorer> {
  int _index = 0;
  @override
  Widget build(BuildContext context) {
    // Catalog order is editorial only. All tied families remain reachable.
    final professions = {
      for (final id in widget.families) ...vocationalRelatedProfessions[id]!,
    }.toList();
    final selected = professions[_index];
    final families = widget.families.where(
      (id) => vocationalRelatedProfessions[id]!.contains(selected),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            liveRegion: true,
            child: Text(
              selected.displayName,
              key: Key('vocational-${widget.prefix}-name'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          for (final id in families)
            Text('Relacionado con ${vocationalFamilyNames[id]!}'),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 210),
              child: SabiProfessionIllustration(profession: selected),
            ),
          ),
          Text(
            'Ejemplo visual ${_index + 1} de ${professions.length}. No es una recomendación de carrera.',
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              OutlinedButton(
                key: Key('vocational-${widget.prefix}-previous'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(48, 48),
                ),
                onPressed: _index == 0 ? null : () => setState(() => _index--),
                child: const Text('Ámbito anterior'),
              ),
              OutlinedButton(
                key: Key('vocational-${widget.prefix}-next'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(48, 48),
                ),
                onPressed: _index == professions.length - 1
                    ? null
                    : () => setState(() => _index++),
                child: const Text('Ámbito siguiente'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
