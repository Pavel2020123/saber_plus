import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
import '../../auth/presentation/session_controller.dart';
import '../data/learning_evidence_repository.dart';
import '../domain/learning_evidence.dart';

final learningEvidenceProvider = FutureProvider.autoDispose<LearningEvidence>((
  ref,
) async {
  final user = ref.watch(sessionControllerProvider).user;
  if (user == null) {
    throw const ApiError(
      code: 'session_required',
      message: 'Inicia sesión para ver tu progreso.',
    );
  }
  if (user.isDemo) return demoLearningEvidence();
  final cancel = CancelToken();
  ref.onDispose(() => cancel.cancel());
  return LearningEvidenceRepository(
    ref.watch(dioProvider),
  ).load(cancelToken: cancel);
});

class LearningEvidencePage extends ConsumerWidget {
  const LearningEvidencePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(learningEvidenceProvider);
    void reload() => ref.invalidate(learningEvidenceProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnóstico por temas'),
        actions: [
          IconButton(
            tooltip: 'Actualizar diagnóstico',
            onPressed: reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: report.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_outlined),
                  const SizedBox(height: 12),
                  Text(
                    error is ApiError
                        ? error.message
                        : 'No pudimos cargar el diagnóstico. No se han reemplazado tus datos.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: reload,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          ),
          data: (data) => ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            itemCount: data.topics.length + 1,
            itemBuilder: (context, index) => index == 0
                ? _Explanation(report: data)
                : _TopicCard(topic: data.topics[index - 1]),
          ),
        ),
      ),
    );
  }
}

class _Explanation extends StatelessWidget {
  const _Explanation({required this.report});
  final LearningEvidence report;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (report.isDemo)
        const Card(
          child: ListTile(
            leading: Icon(Icons.science_outlined),
            title: Text('Demostración: datos de ejemplo'),
            subtitle: Text('No representan resultados de tu cuenta.'),
          ),
        ),
      Text(
        'Qué conviene reforzar',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 8),
      Text(
        'Revisamos los últimos ${report.policy.windowDays} días. Un error aislado no significa que tengas una falencia.',
      ),
      const SizedBox(height: 8),
      Text(
        'Para orientar un subtema necesitamos ${report.policy.subtopicMinimum} preguntas distintas; '
        'para un tema, ${report.policy.themeMinimum}. En ambos casos: al menos '
        '${report.policy.sessionsMinimum} sesiones y ${report.policy.daysMinimum} días diferentes (hora de Colombia).',
      ),
      const SizedBox(height: 8),
      const Text(
        'Cuenta tu primera respuesta a cada pregunta dentro de ese período. Repetirla sirve para practicar, '
        'pero no añade evidencia nueva. Menos del 60% orienta a refuerzo y desde el 80% a fortaleza, solo cuando hay evidencia suficiente.',
      ),
      const SizedBox(height: 8),
      const Text(
        'Es una orientación sobre los contenidos evaluados, no una certificación de dominio de toda la materia.',
      ),
      if (report.partial)
        const Card(
          child: ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Informe parcial'),
            subtitle: Text(
              'El historial supera el límite de consulta. No emitimos conclusiones con esta muestra incompleta.',
            ),
          ),
        ),
      if (report.excluded > 0 || report.repeated > 0)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            '${report.repeated} repeticiones no contabilizadas. ${report.excluded} registros excluidos por clasificación o disponibilidad del contenido.',
          ),
        ),
      if (report.topics.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Text(
            'Todavía no hay respuestas evaluables por tema. Completa prácticas o simulacros con contenido publicado para reunir evidencia.',
          ),
        ),
      const SizedBox(height: 18),
    ],
  );
}

class _TopicCard extends StatelessWidget {
  const _TopicCard({required this.topic});
  final EvidenceItem topic;

  @override
  Widget build(BuildContext context) => Card(
    child: ExpansionTile(
      key: PageStorageKey(topic.id),
      title: Text(topic.name),
      subtitle: Text(
        '${topic.area.label}\n${topic.level.label}\n${topic.questions} preguntas distintas · ${topic.subtopics.length} subtemas evaluados',
      ),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Metrics(item: topic),
        for (final subtopic in topic.subtopics) ...[
          const Divider(height: 24),
          Text(subtopic.name, style: Theme.of(context).textTheme.titleMedium),
          Text(subtopic.level.label),
          const SizedBox(height: 6),
          _Metrics(item: subtopic),
          if (subtopic.level == EvidenceLevel.insufficient)
            const Text(
              'Sigue practicando con preguntas nuevas en distintos días; aún no podemos concluir una fortaleza o falencia.',
            )
          else if (subtopic.level == EvidenceLevel.needsReview)
            const Text(
              'Revisa la lección de este subtema y los errores explicados en tu cuaderno.',
            ),
        ],
      ],
    ),
  );
}

class _Metrics extends StatelessWidget {
  const _Metrics({required this.item});
  final EvidenceItem item;

  @override
  Widget build(BuildContext context) => Text(
    '${item.correct}/${item.questions} aciertos '
    '(${item.percentage.toStringAsFixed(1)}%) · ${item.sessions} sesiones · ${item.days} días',
  );
}
