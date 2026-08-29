import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_error.dart';
import '../../academic/domain/academic_models.dart';
import '../../academic/presentation/academic_home_controller.dart';
import '../../auth/presentation/session_controller.dart';
import '../../resume/domain/learning_resume_models.dart';
import '../../resume/presentation/learning_resume_providers.dart';

class StudentDashboardPage extends ConsumerWidget {
  const StudentDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionControllerProvider).user;
    final academic = ref.watch(academicHomeControllerProvider);
    final resume = ref.watch(learningResumeProvider).valueOrNull;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () =>
              ref.read(academicHomeControllerProvider.notifier).reload(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
                sliver: SliverList.list(
                  children: [
                    _Header(name: user?.firstName ?? 'estudiante'),
                    const SizedBox(height: 22),
                    academic.when(
                      data: (data) => _AcademicDashboard(
                        data: data,
                        xpTotal: user?.xpTotal ?? 0,
                        resume: resume,
                      ),
                      loading: () => const _LoadingDashboard(),
                      error: (error, _) => _ErrorDashboard(
                        message: error is ApiError
                            ? error.message
                            : 'No pudimos cargar tu inicio académico.',
                        onRetry: () => ref
                            .read(academicHomeControllerProvider.notifier)
                            .reload(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hola, $name 👋',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 3),
              Text(
                'Tu preparación empieza con una acción clara.',
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          onPressed: () => context.push('/student/more/preferences'),
          tooltip: 'Notificaciones',
          icon: const Icon(Icons.notifications_none_rounded),
        ),
      ],
    );
  }
}

class _AcademicDashboard extends StatelessWidget {
  const _AcademicDashboard({
    required this.data,
    required this.xpTotal,
    required this.resume,
  });

  final AcademicHomeData data;
  final int xpTotal;
  final LearningResume? resume;

  @override
  Widget build(BuildContext context) {
    final days = data.activeExam?.daysRemaining(DateTime.now());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PrimaryActionCard(data: data),
        if (resume case final entry?) ...[
          const SizedBox(height: 12),
          _ContinueCard(entry: entry),
        ],
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.event_available_rounded,
                value: days == null ? 'Sin fecha' : '$days días',
                label: data.activeExam == null
                    ? 'Convocatoria'
                    : 'Calendario ${data.activeExam!.calendar}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                key: const Key('open-gamification-from-home'),
                icon: Icons.bolt_rounded,
                value: _formatInteger(xpTotal),
                label: 'XP total',
                onTap: () => context.push('/student/more/gamification'),
              ),
            ),
          ],
        ),
        if (data.activeExam case final exam?) ...[
          const SizedBox(height: 12),
          _ExamDateCard(exam: exam),
        ],
        const SizedBox(height: 26),
        Text('Tu semana', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        _WeeklyPlanCard(plan: data.plan),
        if (data.diagnostic.status == DiagnosticStatus.completed) ...[
          const SizedBox(height: 26),
          Text('Tu diagnóstico', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          _DiagnosticResultCard(diagnostic: data.diagnostic),
        ],
      ],
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.entry});

  final LearningResume entry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: colors.secondaryContainer.withValues(alpha: 0.55),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: const Key('continue-last-lesson'),
        onTap: () => context.go(entry.route),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: colors.secondaryContainer,
                foregroundColor: colors.onSecondaryContainer,
                child: const Icon(Icons.play_arrow_rounded),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CONTINÚA DONDE QUEDASTE',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.secondary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text('${entry.area.label} · ${entry.parentTitle}'),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryActionCard extends StatelessWidget {
  const _PrimaryActionCard({required this.data});

  final AcademicHomeData data;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final diagnostic = data.diagnostic;
    final activity = data.plan.nextActivity;
    final title = switch (diagnostic.status) {
      DiagnosticStatus.notStarted => 'Descubre tu punto de partida',
      DiagnosticStatus.inProgress => 'Continúa tu diagnóstico',
      DiagnosticStatus.completed =>
        activity?.title ?? 'Tu diagnóstico está completo',
    };
    final detail = switch (diagnostic.status) {
      DiagnosticStatus.notStarted => '15 preguntas · 5 áreas ICFES',
      DiagnosticStatus.inProgress =>
        '${diagnostic.totalQuestions} preguntas reservadas',
      DiagnosticStatus.completed =>
        activity?.detail ?? 'Ya podemos priorizar tu preparación.',
    };
    final label = switch (diagnostic.status) {
      DiagnosticStatus.notStarted => 'Ver diagnóstico',
      DiagnosticStatus.inProgress => 'Retomar',
      DiagnosticStatus.completed =>
        activity == null
            ? 'Ver resultado'
            : activity.type == StudyActivityType.mockExam
            ? 'Ir a practicar'
            : 'Ir a estudiar',
    };

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.primary, const Color(0xFF243EAE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: Color(0xFFFFD66B),
                size: 19,
              ),
              const SizedBox(width: 7),
              Text(
                diagnostic.status == DiagnosticStatus.completed
                    ? 'SIGUIENTE ACTIVIDAD'
                    : 'PRIMER PASO',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.7,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            detail,
            style: const TextStyle(color: Colors.white70, fontSize: 15),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: colors.primary,
              minimumSize: const Size(0, 48),
              padding: const EdgeInsets.symmetric(horizontal: 18),
            ),
            onPressed: () {
              if (diagnostic.status != DiagnosticStatus.completed ||
                  activity == null) {
                context.push('/student/diagnostic');
              } else if (activity.type == StudyActivityType.mockExam) {
                context.go('/student/practice');
              } else {
                context.go('/student/study');
              }
            },
            icon: const Icon(Icons.arrow_forward_rounded),
            label: Text(label),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: colors.primaryContainer,
                foregroundColor: colors.primary,
                child: Icon(icon),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value, style: Theme.of(context).textTheme.titleMedium),
                    Text(label, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExamDateCard extends StatelessWidget {
  const _ExamDateCard({required this.exam});

  final ActiveExam exam;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: const Icon(Icons.calendar_month_outlined),
      title: Text('ICFES ${exam.year} · Calendario ${exam.calendar}'),
      subtitle: Text('Fecha del examen: ${_formatDate(exam.examDate)}'),
    ),
  );
}

class _WeeklyPlanCard extends StatelessWidget {
  const _WeeklyPlanCard({required this.plan});

  final StudyPlanSummary plan;

  @override
  Widget build(BuildContext context) {
    if (plan.status != StudyPlanStatus.ready) {
      final message = switch (plan.status) {
        StudyPlanStatus.diagnosticPending =>
          'Completa el diagnóstico para generar tu primera semana.',
        StudyPlanStatus.datePending =>
          'Falta configurar la convocatoria ICFES activa.',
        StudyPlanStatus.examFinished => 'La convocatoria activa ya finalizó.',
        StudyPlanStatus.noContent =>
          'Todavía no hay contenido académico para generar actividades.',
        StudyPlanStatus.allCompleted =>
          'Completaste todos los contenidos disponibles.',
        StudyPlanStatus.ready => '',
      };
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              const Icon(Icons.route_outlined),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${plan.completedSessions} de ${plan.targetSessions} sesiones',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  '${plan.percentage}%',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: plan.percentage / 100,
              minHeight: 9,
              borderRadius: BorderRadius.circular(9),
            ),
            const SizedBox(height: 10),
            Text('${plan.targetMinutes} minutos planeados esta semana'),
          ],
        ),
      ),
    );
  }
}

class _DiagnosticResultCard extends StatelessWidget {
  const _DiagnosticResultCard({required this.diagnostic});

  final DiagnosticSummary diagnostic;

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => context.push('/student/diagnostic'),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(child: Text('${diagnostic.percentage.round()}%')),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    diagnostic.level?.label ?? 'Resultado disponible',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (diagnostic.priorityArea case final area?)
                    Text('Prioridad: ${area.label}'),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    ),
  );
}

class _LoadingDashboard extends StatelessWidget {
  const _LoadingDashboard();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 80),
    child: Center(child: CircularProgressIndicator()),
  );
}

class _ErrorDashboard extends StatelessWidget {
  const _ErrorDashboard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: 52,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: onRetry,
            child: const Text('Intentar nuevamente'),
          ),
        ],
      ),
    ),
  );
}

String _formatDate(DateTime date) {
  const months = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];
  return '${date.day} de ${months[date.month - 1]} de ${date.year}';
}

String _formatInteger(int value) {
  final digits = value.toString();
  final output = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) output.write('.');
    output.write(digits[index]);
  }
  return output.toString();
}
