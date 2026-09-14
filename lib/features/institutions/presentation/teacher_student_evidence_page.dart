import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_error.dart';
import '../../academic/domain/academic_models.dart';
import '../../learning_evidence/domain/learning_evidence.dart';
import '../domain/teacher_student_evidence.dart';
import 'teacher_student_evidence_providers.dart';

class TeacherStudentEvidencePage extends ConsumerStatefulWidget {
  const TeacherStudentEvidencePage({super.key, required this.studentId});
  final String studentId;

  @override
  ConsumerState<TeacherStudentEvidencePage> createState() =>
      _TeacherStudentEvidencePageState();
}

class _TeacherStudentEvidencePageState
    extends ConsumerState<TeacherStudentEvidencePage> {
  AcademicArea? _area;

  @override
  void didUpdateWidget(covariant TeacherStudentEvidencePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.studentId != widget.studentId) _area = null;
  }

  @override
  Widget build(BuildContext context) {
    final provider = teacherStudentEvidenceProvider(widget.studentId);
    final state = ref.watch(provider);
    void reload() => ref.invalidate(provider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seguimiento individual'),
        actions: [
          IconButton(
            tooltip: 'Actualizar ficha',
            onPressed: reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: state.when(
          skipLoadingOnRefresh: false,
          skipLoadingOnReload: false,
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
                        : 'No pudimos cargar la ficha. Intenta de nuevo.',
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
          data: (data) => ListView(
            key: ValueKey('student-evidence-${widget.studentId}'),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              _StudentHeader(data: data),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: const Key('open-student-evolution'),
                onPressed: () => context.push(
                  '/teacher/students/${Uri.encodeComponent(widget.studentId)}/evolution',
                ),
                icon: const Icon(Icons.schedule),
                label: const Text('Ver tiempo y evolución'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<AcademicArea>(
                key: ValueKey('student-evidence-filter-${widget.studentId}'),
                initialValue: _area,
                hint: const Text('Todas las áreas'),
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Filtrar por área',
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Todas las áreas'),
                  ),
                  for (final area in AcademicArea.values)
                    DropdownMenuItem(value: area, child: Text(area.label)),
                ],
                onChanged: (value) => setState(() => _area = value),
              ),
              const SizedBox(height: 16),
              for (final area in AcademicArea.values.where(
                (value) => _area == null || value == _area,
              ))
                _AreaCard(
                  area: area,
                  topics: data.evidence.topics
                      .where((topic) => topic.area == area)
                      .toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StudentHeader extends StatelessWidget {
  const _StudentHeader({required this.data});
  final TeacherStudentEvidence data;

  @override
  Widget build(BuildContext context) {
    final report = data.evidence;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (report.isDemo)
          const Card(
            child: ListTile(
              leading: Icon(Icons.science_outlined),
              title: Text('Demostración: datos de ejemplo'),
              subtitle: Text('No son resultados reales del estudiante.'),
            ),
          ),
        Text(data.name, style: Theme.of(context).textTheme.headlineSmall),
        Text(
          data.groups.isEmpty
              ? 'Sin grupos en este alcance.'
              : data.groups.join(' · '),
        ),
        const SizedBox(height: 12),
        Text('Evidencia del ${_date(report.since)} al ${_date(report.until)}.'),
        const SizedBox(height: 8),
        Text(
          'Se necesitan ${report.policy.subtopicMinimum} preguntas distintas por subtema y ${report.policy.themeMinimum} por tema, en al menos ${report.policy.sessionsMinimum} sesiones y ${report.policy.daysMinimum} días. Un solo error no demuestra una falencia.',
        ),
        const SizedBox(height: 8),
        const Text(
          'Se cuenta la primera respuesta por pregunta en el período. Solo con evidencia suficiente: menos del 60% orienta a refuerzo; desde el 80%, a fortaleza en lo evaluado. No es una calificación oficial ni dominio de toda el área.',
        ),
        if (report.partial)
          const Card(
            child: ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('Informe parcial'),
              subtitle: Text(
                'Se alcanzó el límite de consulta. No se emiten conclusiones con una muestra incompleta.',
              ),
            ),
          ),
        if (report.excluded > 0 || report.repeated > 0)
          Text(
            '${report.repeated} repeticiones ignoradas; ${report.excluded} registros excluidos por clasificación o disponibilidad.',
          ),
        if (report.topics.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              'Todavía no hay respuestas evaluables por tema. Esto no significa que el estudiante tenga dificultades.',
            ),
          ),
      ],
    );
  }
}

class _AreaCard extends StatelessWidget {
  const _AreaCard({required this.area, required this.topics});
  final AcademicArea area;
  final List<EvidenceItem> topics;

  @override
  Widget build(BuildContext context) => Card(
    child: ExpansionTile(
      key: PageStorageKey('evidence-area-${area.name}'),
      title: Text(area.label),
      subtitle: Text(
        topics.isEmpty
            ? 'Sin respuestas evaluables en esta área.'
            : '${topics.length} tema(s) con evidencia',
      ),
      children: [
        for (final topic in topics)
          ExpansionTile(
            key: PageStorageKey('evidence-topic-${topic.id}'),
            title: Text(topic.name),
            subtitle: Text(topic.level.label),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _EvidenceMetrics(item: topic),
              for (final subtopic in topic.subtopics) ...[
                const Divider(height: 24),
                Text(
                  subtopic.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(subtopic.level.label),
                _EvidenceMetrics(item: subtopic),
                if (subtopic.level == EvidenceLevel.insufficient)
                  const Text(
                    'Faltan preguntas distintas o práctica en más sesiones/días; no se concluye fortaleza ni falencia.',
                  ),
              ],
            ],
          ),
      ],
    ),
  );
}

class _EvidenceMetrics extends StatelessWidget {
  const _EvidenceMetrics({required this.item});
  final EvidenceItem item;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '${item.correct} aciertos · ${item.questions - item.correct} errores · ${item.questions} preguntas distintas',
      ),
      Text(
        '${item.percentage.toStringAsFixed(1)}% · ${item.sessions} sesiones · ${item.days} días',
      ),
      Text(
        item.lastEvidence == null
            ? 'Fecha de última evidencia no disponible.'
            : 'Última evidencia: ${_date(item.lastEvidence!)}.',
      ),
    ],
  );
}

String _date(DateTime value) {
  // El contrato académico cuenta los días en Colombia (UTC-5).
  final day = value.toUtc().subtract(const Duration(hours: 5));
  return '${day.day.toString().padLeft(2, '0')}/${day.month.toString().padLeft(2, '0')}/${day.year}';
}
