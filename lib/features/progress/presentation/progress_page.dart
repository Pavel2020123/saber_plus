import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/network/api_error.dart';
import '../../academic/domain/academic_models.dart';
import '../../auth/presentation/session_controller.dart';
import '../../practice/domain/practice_history_models.dart';
import '../../study/domain/study_models.dart';
import '../domain/progress_models.dart';
import 'progress_providers.dart';

class ProgressPage extends ConsumerStatefulWidget {
  const ProgressPage({super.key});

  @override
  ConsumerState<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends ConsumerState<ProgressPage> {
  late Future<ProgressDashboard> _dashboard;
  late Future<ErrorNotebook> _notebook;
  AcademicArea? _area;
  NotebookStatus? _status;

  @override
  void initState() {
    super.initState();
    _dashboard = _loadDashboard();
    _notebook = _loadNotebook();
  }

  Future<ProgressDashboard> _loadDashboard() =>
      ref.read(progressRepositoryProvider).loadDashboard();

  Future<ErrorNotebook> _loadNotebook() => ref
      .read(progressRepositoryProvider)
      .loadNotebook(NotebookFilter(area: _area, status: _status));

  void _reloadAll() {
    setState(() {
      _dashboard = _loadDashboard();
      _notebook = _loadNotebook();
    });
  }

  void _reloadNotebook() => setState(() => _notebook = _loadNotebook());

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Tu progreso'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _reloadAll,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
        bottom: const TabBar(
          tabs: [
            Tab(text: 'Resumen', icon: Icon(Icons.insights_rounded)),
            Tab(text: 'Cuaderno', icon: Icon(Icons.book_outlined)),
          ],
        ),
      ),
      body: TabBarView(
        children: [
          _DashboardTab(future: _dashboard, onRetry: _reloadAll),
          _NotebookTab(
            future: _notebook,
            area: _area,
            status: _status,
            onAreaChanged: (area) {
              _area = area;
              _reloadNotebook();
            },
            onStatusChanged: (status) {
              _status = status;
              _reloadNotebook();
            },
            onRetry: _reloadNotebook,
            onSave: _saveEntry,
          ),
        ],
      ),
    ),
  );

  Future<bool> _saveEntry(
    ErrorNotebookItem item,
    String note,
    NotebookStatus status,
  ) async {
    try {
      await ref
          .read(progressRepositoryProvider)
          .updateNotebookEntry(
            questionId: item.questionId,
            note: note,
            status: status,
          );
      if (!mounted) return true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cambio guardado en tu cuaderno.')),
      );
      _reloadNotebook();
      return true;
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_messageFor(error))));
      }
      return false;
    }
  }
}

class _DashboardTab extends ConsumerWidget {
  const _DashboardTab({required this.future, required this.onRetry});

  final Future<ProgressDashboard> future;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) => FutureBuilder(
    future: future,
    builder: (context, snapshot) => switch (snapshot) {
      AsyncSnapshot(hasData: true, data: final data?) => _DashboardContent(
        data: data,
        xp: ref.watch(sessionControllerProvider).user?.xpTotal ?? 0,
      ),
      AsyncSnapshot(hasError: true, error: final error?) => _FullError(
        message: _messageFor(error),
        onRetry: onRetry,
      ),
      _ => const Center(child: CircularProgressIndicator()),
    },
  );
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.data, required this.xp});

  final ProgressDashboard data;
  final int xp;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
    children: [
      Text(
        'Así vas en SaberPlus',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 6),
      Text(
        'Tus datos se calculan con las respuestas y lecciones guardadas por el servidor.',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      const SizedBox(height: 18),
      _LearningProgressCard(progress: data.study),
      const SizedBox(height: 14),
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.55,
        children: [
          _MetricCard(
            icon: Icons.bolt_rounded,
            label: 'XP acumulados',
            value: '$xp',
          ),
          _MetricCard(
            icon: Icons.task_alt_rounded,
            label: 'Respondidas',
            value: '${data.answers.total}',
          ),
          _MetricCard(
            icon: Icons.track_changes_rounded,
            label: 'Acierto global',
            value: '${data.answers.successPercentage.round()}%',
          ),
          _MetricCard(
            icon: Icons.menu_book_rounded,
            label: 'Lecciones listas',
            value:
                '${data.study.completedSubtopics}/${data.study.totalSubtopics}',
          ),
        ],
      ),
      const SizedBox(height: 24),
      Text(
        'Rendimiento por área',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 12),
      for (final area in AcademicArea.values) ...[
        _AreaPerformanceCard(area: area, summary: data.performanceFor(area)),
        const SizedBox(height: 10),
      ],
    ],
  );
}

class _LearningProgressCard extends StatelessWidget {
  const _LearningProgressCard({required this.progress});

  final StudyProgress progress;

  @override
  Widget build(BuildContext context) {
    final percentage = progress.overallPercentage;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_stories_rounded),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Avance de aprendizaje',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text('$percentage%'),
              ],
            ),
            const SizedBox(height: 14),
            LinearProgressIndicator(
              value: (percentage / 100).clamp(0, 1).toDouble(),
              minHeight: 10,
              borderRadius: BorderRadius.circular(20),
            ),
            const SizedBox(height: 10),
            Text(
              '${progress.viewedSubtopics} vistos · ${progress.completedSubtopics} completados',
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const Spacer(),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    ),
  );
}

class _AreaPerformanceCard extends StatelessWidget {
  const _AreaPerformanceCard({required this.area, required this.summary});

  final AcademicArea area;
  final AnswerHistorySummary summary;

  @override
  Widget build(BuildContext context) {
    final percentage = summary.successPercentage;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    area.label,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  summary.total == 0
                      ? 'Sin respuestas'
                      : '${percentage.round()}%',
                ),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: summary.total == 0
                  ? 0
                  : (percentage / 100).clamp(0, 1).toDouble(),
              minHeight: 8,
              borderRadius: BorderRadius.circular(20),
            ),
            const SizedBox(height: 7),
            Text(
              summary.total == 0
                  ? 'Practica esta área para empezar a medirla.'
                  : '${summary.correct} correctas de ${summary.total} respuestas',
            ),
          ],
        ),
      ),
    );
  }
}

class _NotebookTab extends StatelessWidget {
  const _NotebookTab({
    required this.future,
    required this.area,
    required this.status,
    required this.onAreaChanged,
    required this.onStatusChanged,
    required this.onRetry,
    required this.onSave,
  });

  final Future<ErrorNotebook> future;
  final AcademicArea? area;
  final NotebookStatus? status;
  final ValueChanged<AcademicArea?> onAreaChanged;
  final ValueChanged<NotebookStatus?> onStatusChanged;
  final VoidCallback onRetry;
  final Future<bool> Function(
    ErrorNotebookItem item,
    String note,
    NotebookStatus status,
  )
  onSave;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
    children: [
      Text(
        'Cuaderno de errores',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 6),
      const Text(
        'Revisa lo que fallaste, escribe tus apuntes y marca lo que ya dominas.',
      ),
      const SizedBox(height: 18),
      DropdownButtonFormField<AcademicArea?>(
        initialValue: area,
        decoration: const InputDecoration(labelText: 'Área'),
        items: [
          const DropdownMenuItem(value: null, child: Text('Todas las áreas')),
          for (final item in AcademicArea.values)
            DropdownMenuItem(value: item, child: Text(item.label)),
        ],
        onChanged: onAreaChanged,
      ),
      const SizedBox(height: 10),
      DropdownButtonFormField<NotebookStatus?>(
        initialValue: status,
        decoration: const InputDecoration(labelText: 'Estado'),
        items: [
          const DropdownMenuItem(value: null, child: Text('Todos los estados')),
          for (final item in NotebookStatus.values)
            DropdownMenuItem(value: item, child: Text(item.label)),
        ],
        onChanged: onStatusChanged,
      ),
      const SizedBox(height: 18),
      FutureBuilder(
        future: future,
        builder: (context, snapshot) => switch (snapshot) {
          AsyncSnapshot(hasData: true, data: final notebook?) =>
            _NotebookContent(notebook: notebook, onSave: onSave),
          AsyncSnapshot(hasError: true, error: final error?) => _InlineError(
            message: _messageFor(error),
            onRetry: onRetry,
          ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    ],
  );
}

class _NotebookContent extends StatelessWidget {
  const _NotebookContent({required this.notebook, required this.onSave});

  final ErrorNotebook notebook;
  final Future<bool> Function(
    ErrorNotebookItem item,
    String note,
    NotebookStatus status,
  )
  onSave;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          Chip(label: Text('${notebook.summary.total} errores')),
          Chip(label: Text('${notebook.summary.pending} pendientes')),
          Chip(label: Text('${notebook.summary.reviewing} en repaso')),
          Chip(label: Text('${notebook.summary.mastered} dominados')),
        ],
      ),
      const SizedBox(height: 14),
      if (notebook.errors.isEmpty)
        const Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'No hay errores que coincidan con estos filtros. Sigue practicando para alimentar tu cuaderno.',
            ),
          ),
        )
      else
        for (final item in notebook.errors) ...[
          _NotebookEntryCard(
            key: ValueKey(item.questionId),
            item: item,
            onSave: onSave,
          ),
          const SizedBox(height: 10),
        ],
    ],
  );
}

class _NotebookEntryCard extends StatefulWidget {
  const _NotebookEntryCard({
    required this.item,
    required this.onSave,
    super.key,
  });

  final ErrorNotebookItem item;
  final Future<bool> Function(
    ErrorNotebookItem item,
    String note,
    NotebookStatus status,
  )
  onSave;

  @override
  State<_NotebookEntryCard> createState() => _NotebookEntryCardState();
}

class _NotebookEntryCardState extends State<_NotebookEntryCard> {
  late final TextEditingController _note;
  late NotebookStatus _status;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _note = TextEditingController(text: widget.item.note);
    _status = widget.item.status;
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Card(
    child: ExpansionTile(
      leading: CircleAvatar(child: Text('${widget.item.timesFailed}×')),
      title: Text(widget.item.subtopic),
      subtitle: Text('${widget.item.area.label} · ${widget.item.status.label}'),
      childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.item.theme, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 10),
        Text(widget.item.statement),
        if (widget.item.caseTitle case final title?) ...[
          const SizedBox(height: 8),
          Text('Caso: $title'),
        ],
        const SizedBox(height: 14),
        _AnswerBox(
          title: 'Tu respuesta',
          text: widget.item.selectedAnswer?.text ?? 'No disponible',
          color: Theme.of(context).colorScheme.errorContainer,
        ),
        const SizedBox(height: 8),
        _AnswerBox(
          title: 'Respuesta correcta',
          text: widget.item.correctAnswer?.text ?? 'No disponible',
          color: SaberPlusColors.success.withValues(alpha: 0.12),
        ),
        if (widget.item.explanation case final explanation?) ...[
          const SizedBox(height: 14),
          Text('Explicación', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(explanation),
        ],
        const SizedBox(height: 16),
        DropdownButtonFormField<NotebookStatus>(
          initialValue: _status,
          decoration: const InputDecoration(labelText: 'Estado de repaso'),
          items: [
            for (final status in NotebookStatus.values)
              DropdownMenuItem(value: status, child: Text(status.label)),
          ],
          onChanged: _saving
              ? null
              : (value) {
                  if (value != null) setState(() => _status = value);
                },
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _note,
          enabled: !_saving,
          minLines: 2,
          maxLines: 5,
          maxLength: 1600,
          decoration: const InputDecoration(
            labelText: 'Mi apunte',
            hintText: 'Escribe qué debes recordar la próxima vez.',
          ),
        ),
        const SizedBox(height: 4),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined),
          label: Text(_saving ? 'Guardando...' : 'Guardar cambios'),
        ),
      ],
    ),
  );

  Future<void> _save() async {
    setState(() => _saving = true);
    await widget.onSave(widget.item, _note.text, _status);
    if (mounted) setState(() => _saving = false);
  }
}

class _AnswerBox extends StatelessWidget {
  const _AnswerBox({
    required this.title,
    required this.text,
    required this.color,
  });

  final String title;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 3),
        Text(text),
      ],
    ),
  );
}

class _FullError extends StatelessWidget {
  const _FullError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: _InlineError(message: message, onRetry: onRetry),
    ),
  );
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, size: 34),
          const SizedBox(height: 10),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: onRetry,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    ),
  );
}

String _messageFor(Object error) => error is ApiError
    ? error.message
    : 'No pudimos cargar tu progreso. Intenta nuevamente.';
