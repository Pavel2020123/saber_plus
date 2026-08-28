import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_error.dart';
import '../../academic/domain/academic_models.dart';
import '../domain/practice_history_models.dart';
import 'practice_providers.dart';

class PracticeHistoryPage extends ConsumerStatefulWidget {
  const PracticeHistoryPage({super.key});

  @override
  ConsumerState<PracticeHistoryPage> createState() =>
      _PracticeHistoryPageState();
}

class _PracticeHistoryPageState extends ConsumerState<PracticeHistoryPage> {
  AcademicArea? _area;
  var _outcome = AnswerOutcomeFilter.all;
  late Future<SimulationHistory> _simulationHistory;
  late Future<AnswerHistory> _answerHistory;

  @override
  void initState() {
    super.initState();
    _simulationHistory = _loadSimulations();
    _answerHistory = _loadAnswers();
  }

  Future<SimulationHistory> _loadSimulations() =>
      ref.read(practiceRepositoryProvider).loadSimulationHistory();

  Future<AnswerHistory> _loadAnswers() => ref
      .read(practiceRepositoryProvider)
      .loadAnswerHistory(
        AnswerHistoryFilter(area: _area, outcome: _outcome, limit: 100),
      );

  void _reloadAnswers() {
    setState(() => _answerHistory = _loadAnswers());
  }

  Future<void> _refresh() async {
    setState(() {
      _simulationHistory = _loadSimulations();
      _answerHistory = _loadAnswers();
    });
    await Future.wait([_simulationHistory, _answerHistory]);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Historial')),
    body: RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        key: const Key('practice-history-list'),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
        children: [
          Text(
            'Resultados recientes',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Consulta tus simulacros y revisa cada respuesta para decidir qué reforzar.',
          ),
          const SizedBox(height: 18),
          FutureBuilder<SimulationHistory>(
            future: _simulationHistory,
            builder: (context, snapshot) => switch (snapshot) {
              AsyncSnapshot(hasData: true, data: final history?) =>
                _SimulationResults(history: history),
              AsyncSnapshot(hasError: true, error: final error?) =>
                _InlineError(
                  message: _messageFor(error),
                  onRetry: () =>
                      setState(() => _simulationHistory = _loadSimulations()),
                ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
          const SizedBox(height: 28),
          Text(
            'Historial de respuestas',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<AcademicArea?>(
            key: const Key('history-area-filter'),
            initialValue: _area,
            decoration: const InputDecoration(labelText: 'Área'),
            items: [
              const DropdownMenuItem(value: null, child: Text('Todas')),
              for (final area in AcademicArea.values)
                DropdownMenuItem(value: area, child: Text(area.label)),
            ],
            onChanged: (value) {
              _area = value;
              _reloadAnswers();
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<AnswerOutcomeFilter>(
            key: const Key('history-outcome-filter'),
            initialValue: _outcome,
            decoration: const InputDecoration(labelText: 'Resultado'),
            items: const [
              DropdownMenuItem(
                value: AnswerOutcomeFilter.all,
                child: Text('Todas'),
              ),
              DropdownMenuItem(
                value: AnswerOutcomeFilter.correct,
                child: Text('Solo correctas'),
              ),
              DropdownMenuItem(
                value: AnswerOutcomeFilter.incorrect,
                child: Text('Solo incorrectas'),
              ),
            ],
            onChanged: (value) {
              if (value == null) return;
              _outcome = value;
              _reloadAnswers();
            },
          ),
          const SizedBox(height: 18),
          FutureBuilder<AnswerHistory>(
            future: _answerHistory,
            builder: (context, snapshot) => switch (snapshot) {
              AsyncSnapshot(hasData: true, data: final history?) =>
                _AnswerResults(history: history),
              AsyncSnapshot(hasError: true, error: final error?) =>
                _InlineError(
                  message: _messageFor(error),
                  onRetry: _reloadAnswers,
                ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
        ],
      ),
    ),
  );
}

class _SimulationResults extends StatelessWidget {
  const _SimulationResults({required this.history});

  final SimulationHistory history;

  @override
  Widget build(BuildContext context) {
    if (history.results.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('Aún no has completado simulacros.'),
        ),
      );
    }
    return Column(
      children: [
        for (final result in history.results) ...[
          Card(
            child: ListTile(
              leading: CircleAvatar(
                child: Text('${result.percentage.round()}%'),
              ),
              title: Text(result.area.label),
              subtitle: Text(
                '${result.correctAnswers}/${result.totalQuestions} correctas · ${_date(result.completedAt)}',
              ),
              trailing: Text('+${result.earnedXp} XP'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _AnswerResults extends StatelessWidget {
  const _AnswerResults({required this.history});

  final AnswerHistory history;

  @override
  Widget build(BuildContext context) {
    final summary = history.summary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(label: Text('${summary.total} respondidas')),
            Chip(label: Text('${summary.correct} correctas')),
            Chip(label: Text('${summary.incorrect} incorrectas')),
            Chip(label: Text('${summary.successPercentage.round()}% acierto')),
          ],
        ),
        const SizedBox(height: 14),
        if (history.answers.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('No hay respuestas que coincidan con estos filtros.'),
            ),
          )
        else
          for (final answer in history.answers) ...[
            _AnswerHistoryCard(answer: answer),
            const SizedBox(height: 9),
          ],
      ],
    );
  }
}

class _AnswerHistoryCard extends StatelessWidget {
  const _AnswerHistoryCard({required this.answer});

  final AnswerHistoryItem answer;

  @override
  Widget build(BuildContext context) => Card(
    child: ExpansionTile(
      key: Key('history-answer-${answer.id}'),
      leading: Icon(
        answer.isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
        color: answer.isCorrect ? Colors.green.shade700 : Colors.red.shade700,
      ),
      title: Text(answer.subtopic),
      subtitle: Text('${answer.area.label} · ${answer.origin.label}'),
      childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_dateTime(answer.answeredAt)),
        if (answer.responseTimeSeconds case final seconds?)
          Text('Tiempo de respuesta: $seconds segundos'),
        if (answer.caseTitle case final title?) ...[
          const SizedBox(height: 8),
          Text('Caso: $title'),
        ],
        const SizedBox(height: 12),
        Text(answer.statement),
        const SizedBox(height: 12),
        Text('Tu respuesta: ${answer.selectedAnswer?.text ?? 'No disponible'}'),
        if (!answer.isCorrect)
          Text(
            'Respuesta correcta: ${answer.correctAnswer?.text ?? 'No disponible'}',
          ),
        if (!answer.isCorrect) ...[
          if (answer.explanation case final explanation?) ...[
            const SizedBox(height: 10),
            Text('Explicación', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(explanation),
          ],
        ],
      ],
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
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 10),
          FilledButton.tonal(
            onPressed: onRetry,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    ),
  );
}

String _date(DateTime value) {
  const months = [
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
  return '${value.day} ${months[value.month - 1]} ${value.year}';
}

String _dateTime(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '${_date(value)} · $hour:$minute';
}

String _messageFor(Object error) => error is ApiError
    ? error.message
    : 'No pudimos cargar el historial. Intenta nuevamente.';
