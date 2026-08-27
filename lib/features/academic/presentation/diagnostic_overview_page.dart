import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_error.dart';
import '../domain/academic_models.dart';
import 'academic_home_controller.dart';

class DiagnosticOverviewPage extends ConsumerWidget {
  const DiagnosticOverviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final academic = ref.watch(academicHomeControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Diagnóstico inicial')),
      body: SafeArea(
        top: false,
        child: academic.when(
          data: (data) => _DiagnosticContent(diagnostic: data.diagnostic),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _DiagnosticError(
            message: _messageFor(error),
            onRetry: () =>
                ref.read(academicHomeControllerProvider.notifier).reload(),
          ),
        ),
      ),
    );
  }
}

class _DiagnosticContent extends ConsumerWidget {
  const _DiagnosticContent({required this.diagnostic});

  final DiagnosticSummary diagnostic;

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) => switch (diagnostic.status) {
    DiagnosticStatus.notStarted => _DiagnosticIntroduction(
      onStart: () =>
          ref.read(academicHomeControllerProvider.notifier).startDiagnostic(),
    ),
    DiagnosticStatus.inProgress => _DiagnosticReady(diagnostic: diagnostic),
    DiagnosticStatus.completed => _DiagnosticResults(diagnostic: diagnostic),
  };
}

class _DiagnosticIntroduction extends StatelessWidget {
  const _DiagnosticIntroduction({required this.onStart});

  final Future<bool> Function() onStart;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
    children: [
      Icon(
        Icons.explore_rounded,
        size: 88,
        color: Theme.of(context).colorScheme.primary,
      ),
      const SizedBox(height: 22),
      Text(
        'Descubre tu punto de partida',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 10),
      Text(
        'Responderás una muestra de las cinco áreas. El resultado organizará las prioridades de tu plan de estudio.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.45),
      ),
      const SizedBox(height: 28),
      const Row(
        children: [
          Expanded(
            child: _FactCard(value: '15', label: 'preguntas'),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _FactCard(value: '5', label: 'áreas ICFES'),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _FactCard(value: '∞', label: 'sin límite'),
          ),
        ],
      ),
      const SizedBox(height: 24),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.tips_and_updates_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Respóndelo sin consultar apuntes. Las respuestas correctas se mantienen ocultas hasta finalizar.',
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 24),
      FilledButton.icon(
        key: const Key('start-diagnostic-button'),
        onPressed: () async {
          final success = await onStart();
          if (!success && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No se pudo iniciar el diagnóstico.'),
              ),
            );
          }
        },
        icon: const Icon(Icons.play_arrow_rounded),
        label: const Text('Preparar diagnóstico'),
      ),
    ],
  );
}

class _DiagnosticReady extends StatelessWidget {
  const _DiagnosticReady({required this.diagnostic});

  final DiagnosticSummary diagnostic;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
    children: [
      Icon(
        Icons.assignment_turned_in_outlined,
        size: 88,
        color: Theme.of(context).colorScheme.primary,
      ),
      const SizedBox(height: 22),
      Text(
        'Tu diagnóstico está preparado',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 10),
      Text(
        '${diagnostic.totalQuestions} preguntas quedaron reservadas de forma segura. Podrás continuar la misma sesión aunque cierres la app.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.45),
      ),
      const SizedBox(height: 28),
      Card(
        child: ListTile(
          leading: const Icon(Icons.lock_outline_rounded),
          title: const Text('Sesión protegida'),
          subtitle: const Text(
            'La interfaz para responder las preguntas se construirá en la Etapa 3B.',
          ),
        ),
      ),
    ],
  );
}

class _DiagnosticResults extends StatelessWidget {
  const _DiagnosticResults({required this.diagnostic});

  final DiagnosticSummary diagnostic;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 36),
    children: [
      Card(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tu línea base',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 6),
              Text(
                '${_number(diagnostic.percentage)}%',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              Text(
                '${diagnostic.correctAnswers} de ${diagnostic.totalQuestions} respuestas correctas · ${diagnostic.level?.label ?? ''}',
              ),
              if (diagnostic.priorityArea case final area?) ...[
                const SizedBox(height: 14),
                Text('Área prioritaria: ${area.label}'),
              ],
            ],
          ),
        ),
      ),
      const SizedBox(height: 22),
      Text('Resultado por área', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 10),
      for (final result in diagnostic.resultsByArea)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        result.area.label,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Text(result.level.label),
                  ],
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: result.percentage / 100,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(8),
                ),
                const SizedBox(height: 7),
                Text(
                  '${result.correctAnswers}/${result.totalQuestions} · ${_number(result.percentage)}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
    ],
  );
}

class _FactCard extends StatelessWidget {
  const _FactCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        children: [
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    ),
  );
}

class _DiagnosticError extends StatelessWidget {
  const _DiagnosticError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 18),
          FilledButton.tonal(
            onPressed: onRetry,
            child: const Text('Intentar nuevamente'),
          ),
        ],
      ),
    ),
  );
}

String _messageFor(Object error) => error is ApiError
    ? error.message
    : 'No pudimos cargar la información académica.';

String _number(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(1);
