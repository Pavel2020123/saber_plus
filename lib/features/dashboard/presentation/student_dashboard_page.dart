import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_error.dart';
import '../../academic/domain/academic_models.dart';
import '../../academic/presentation/academic_home_controller.dart';
import '../../auth/presentation/session_controller.dart';
import '../../auth/presentation/institutional_access_notice.dart';
import '../../resume/domain/learning_resume_models.dart';
import '../../resume/presentation/learning_resume_providers.dart';
import 'widgets/electric_xp_icon.dart';
import 'widgets/home_design.dart';

class StudentDashboardPage extends ConsumerWidget {
  const StudentDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionControllerProvider).user;
    final academic = ref.watch(academicHomeControllerProvider);
    final resume = ref.watch(learningResumeProvider).valueOrNull;

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.light
          ? HomeDesign.canvas
          : Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref
                .read(sessionControllerProvider.notifier)
                .revalidateInstitutionalAccess();
            if (context.mounted) {
              await ref.read(academicHomeControllerProvider.notifier).reload();
            }
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                sliver: SliverList.list(
                  children: [
                    _Header(
                      name: user?.firstName ?? 'estudiante',
                      xpTotal: user?.xpTotal ?? 0,
                    ),
                    const SizedBox(height: 16),
                    const InstitutionalAccessNotice(),
                    academic.when(
                      data: (data) => _AcademicDashboard(
                        data: data,
                        resume: resume,
                        isDemo: user?.isDemo ?? false,
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
  const _Header({required this.name, required this.xpTotal});
  final String name;
  final int xpTotal;

  @override
  Widget build(BuildContext context) {
    final brand = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: HomeDesign.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'S+',
              textScaler: TextScaler.noScaling,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            'SaberPlus',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: HomeDesign.action(context),
            ),
          ),
        ),
      ],
    );
    final xp = TextButton.icon(
      key: const Key('open-gamification-from-home'),
      onPressed: () => context.push('/student/more/gamification'),
      icon: ElectricXpIcon(xp: xpTotal, size: 18),
      label: Text('${_formatInteger(xpTotal)} XP'),
      style: TextButton.styleFrom(
        foregroundColor: HomeDesign.foreground(context),
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        textStyle: Theme.of(context).textTheme.labelMedium,
      ),
    );
    final preferences = IconButton(
      key: const Key('home-preferences'),
      onPressed: () => context.push('/student/more/preferences'),
      tooltip: 'Preferencias',
      color: HomeDesign.action(context),
      icon: const Icon(LucideIcons.slidersHorizontal),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked =
                constraints.maxWidth < 330 ||
                MediaQuery.textScalerOf(context).scale(1) > 1.15;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: brand),
                    if (!stacked) xp,
                    preferences,
                  ],
                ),
                if (stacked) xp,
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        Text(
          'Hola, $name',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: HomeDesign.foreground(context),
            fontSize: 24,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Un paso a la vez. Sigamos aprendiendo.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: HomeDesign.secondaryText(context),
          ),
        ),
      ],
    );
  }
}

class _AcademicDashboard extends StatelessWidget {
  const _AcademicDashboard({
    required this.data,
    required this.resume,
    required this.isDemo,
  });

  final AcademicHomeData data;
  final LearningResume? resume;
  final bool isDemo;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (resume case final entry?) ...[
          _ContinueCard(entry: entry),
          const SizedBox(height: 12),
        ],
        _PrimaryActionCard(data: data),
        const SizedBox(height: 16),
        const _LearningShortcuts(),
        const SizedBox(height: 16),
        _WeeklyPlanCard(plan: data.plan),
        if (data.diagnostic.status == DiagnosticStatus.completed) ...[
          const SizedBox(height: 26),
          Text('Tu diagnóstico', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          _DiagnosticResultCard(diagnostic: data.diagnostic),
        ],
        if (isDemo) ...[
          const SizedBox(height: 20),
          Text(
            'Datos de demostración',
            key: const Key('home-demo-label'),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: HomeDesign.secondaryText(context),
            ),
          ),
        ],
      ],
    );
  }
}

class _LearningShortcuts extends StatelessWidget {
  const _LearningShortcuts();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final items = [
        _LearningShortcut(
          key: const Key('home-study-shortcut'),
          icon: LucideIcons.bookOpenText,
          title: 'Estudiar por temas',
          detail: 'Explicaciones y ejemplos',
          onTap: () => context.go('/student/study'),
        ),
        _LearningShortcut(
          key: const Key('home-practice-shortcut'),
          icon: LucideIcons.gamepad2,
          title: 'Ponerme a prueba',
          detail: 'Preguntas y retos',
          onTap: () => context.go('/student/practice'),
        ),
      ];
      if (constraints.maxWidth < 330 ||
          MediaQuery.textScalerOf(context).scale(1) > 1.3) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [items[0], const SizedBox(height: 10), items[1]],
        );
      }
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: items[0]),
            const SizedBox(width: 16),
            Expanded(child: items[1]),
          ],
        ),
      );
    },
  );
}

class _LearningShortcut extends StatelessWidget {
  const _LearningShortcut({
    super.key,
    required this.icon,
    required this.title,
    required this.detail,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: HomeDesign.dark(context)
          ? colors.surfaceContainerLow
          : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(HomeDesign.radius),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: HomeDesign.action(context), size: 24),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: HomeDesign.foreground(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                detail,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: HomeDesign.secondaryText(context),
                ),
              ),
            ],
          ),
        ),
      ),
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
                child: const Icon(LucideIcons.play),
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

    final description = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          diagnostic.status == DiagnosticStatus.completed
              ? 'SIGUIENTE ACTIVIDAD'
              : 'PRIMER PASO',
          style: TextStyle(color: HomeDesign.action(context), fontSize: 12),
        ),
        const SizedBox(height: 5),
        Text(
          title,
          key: const Key('home-primary-title'),
          style: TextStyle(
            color: HomeDesign.foreground(context),
            fontSize: 24,
            height: 1.2,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          detail,
          style: TextStyle(
            color: HomeDesign.secondaryText(context),
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
    Widget mascot(double size) => Image.asset(
      'assets/images/Sabi_Inicio_Refuerzo.png',
      key: const Key('home-sabi'),
      width: size,
      height: size * 1.06,
      fit: BoxFit.contain,
      excludeFromSemantics: true,
      cacheWidth: 360,
    );
    return Container(
      key: const Key('home-primary-action-card'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HomeDesign.hero(context),
        borderRadius: BorderRadius.circular(HomeDesign.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 270 &&
                  MediaQuery.textScalerOf(context).scale(1) <= 1.3) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: description),
                    const SizedBox(width: 12),
                    mascot(constraints.maxWidth >= 310 ? 132 : 110),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  description,
                  const SizedBox(height: 12),
                  Align(alignment: Alignment.centerRight, child: mascot(110)),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            iconAlignment: IconAlignment.end,
            style: FilledButton.styleFrom(
              backgroundColor: HomeDesign.primary,
              foregroundColor: Colors.white,
              textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(HomeDesign.radius),
              ),
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
            icon: Icon(
              diagnostic.status == DiagnosticStatus.completed
                  ? LucideIcons.arrowRight
                  : LucideIcons.clipboardCheck,
            ),
            label: Text(label),
          ),
        ],
      ),
    );
  }
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
      color: HomeDesign.dark(context)
          ? Theme.of(context).colorScheme.surfaceContainerLow
          : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(HomeDesign.radius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Tu semana',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    '${plan.completedSessions} de ${plan.targetSessions} sesiones · ${plan.percentage}%',
                    style: TextStyle(
                      color: HomeDesign.action(context),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: plan.percentage / 100,
              color: HomeDesign.action(context),
              backgroundColor: HomeDesign.hero(context),
              minHeight: 6,
              borderRadius: BorderRadius.circular(9),
            ),
            const SizedBox(height: 10),
            Text(
              '${plan.targetMinutes} minutos planeados esta semana',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: HomeDesign.secondaryText(context),
              ),
            ),
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

String _formatInteger(int value) {
  final digits = value.toString();
  final output = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) output.write('.');
    output.write(digits[index]);
  }
  return output.toString();
}
