import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/domain/session.dart';
import '../../auth/presentation/session_controller.dart';
import '../../gamification/domain/gamification_models.dart';
import '../../gamification/presentation/gamification_providers.dart';
import '../../progress/domain/progress_models.dart';
import '../../study_time/domain/study_time_models.dart';
import '../../study_time/presentation/study_time_providers.dart';
import 'academic_profile_providers.dart';

class AcademicProfilePage extends ConsumerWidget {
  const AcademicProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionControllerProvider).user;
    final progress = ref.watch(academicProfileProgressProvider);
    final gamification = ref.watch(gamificationSummaryProvider);
    final studyTime = ref.watch(studyTimeSummaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi perfil académico'),
        actions: [
          IconButton(
            key: const Key('refresh-academic-profile'),
            tooltip: 'Actualizar perfil',
            onPressed: () => _refresh(ref),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _refresh(ref),
        child: ListView(
          key: const Key('academic-profile-list'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 32),
          children: [
            _IdentityCard(user: user),
            const SizedBox(height: 20),
            Text('Tu panorama', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            _MetricGrid(
              xp: user?.xpTotal ?? 0,
              progress: progress.valueOrNull,
              gamification: gamification.valueOrNull,
            ),
            const SizedBox(height: 14),
            _StudyTimeCard(summary: studyTime.valueOrNull),
            if (progress.hasError ||
                gamification.hasError ||
                studyTime.hasError)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: _PartialDataNotice(),
              ),
            const SizedBox(height: 22),
            Text(
              'Resumen académico',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            _AcademicSummaryCard(progress: progress),
            const SizedBox(height: 22),
            Text(
              'Explora tus datos',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            Card(
              child: Column(
                children: [
                  _ProfileLink(
                    key: const Key('profile-open-progress'),
                    icon: Icons.insights_rounded,
                    title: 'Progreso y cuaderno de errores',
                    subtitle:
                        'Revisa materias, respuestas y temas por reforzar',
                    onTap: () => context.push('/student/progress'),
                  ),
                  const Divider(height: 1, indent: 64),
                  _ProfileLink(
                    key: const Key('profile-open-gamification'),
                    icon: Icons.emoji_events_outlined,
                    title: 'Logros y racha',
                    subtitle: 'Consulta tu actividad, XP y certificados',
                    onTap: () => context.push('/student/more/gamification'),
                  ),
                  const Divider(height: 1, indent: 64),
                  _ProfileLink(
                    key: const Key('profile-open-study-time'),
                    icon: Icons.schedule_rounded,
                    title: 'Tiempo estudiado',
                    subtitle: 'Mira el detalle por día, semana y actividad',
                    onTap: () => context.push('/student/more/study-time'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(academicProfileProgressProvider);
    ref.invalidate(gamificationSummaryProvider);
    ref.invalidate(studyTimeRecordsProvider);
    try {
      await Future.wait([
        ref.read(academicProfileProgressProvider.future),
        ref.read(gamificationSummaryProvider.future),
        ref.read(studyTimeRecordsProvider.future),
      ]);
    } on Object {
      // Cada sección conserva su propio estado de error y las demás siguen visibles.
    }
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.user});

  final UserSession? user;

  @override
  Widget build(BuildContext context) {
    final name = user?.firstName.trim();
    final displayName = name == null || name.isEmpty ? 'Estudiante' : name;
    final initial = displayName.characters.first.toUpperCase();
    final email = user?.email?.trim();
    final accountLabel = user?.isDemo ?? false
        ? 'Perfil de demostración'
        : 'Estudiante SaberPlus';

    return Card(
      key: const Key('academic-profile-identity'),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                initial,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 3),
                  Text(email == null || email.isEmpty ? accountLabel : email),
                  if (email != null && email.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      accountLabel,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({
    required this.xp,
    required this.progress,
    required this.gamification,
  });

  final int xp;
  final ProgressDashboard? progress;
  final GamificationSummary? gamification;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 650 ? 4 : 2;
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: columns,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: columns == 4 ? 1.45 : 1.25,
        children: [
          _MetricCard(
            key: const Key('academic-profile-xp'),
            icon: Icons.bolt_rounded,
            label: 'XP acumulado',
            value: _formatInteger(xp),
          ),
          _MetricCard(
            key: const Key('academic-profile-progress'),
            icon: Icons.menu_book_rounded,
            label: 'Avance',
            value: progress == null
                ? '—'
                : '${progress!.study.overallPercentage.clamp(0, 100)}%',
          ),
          _MetricCard(
            key: const Key('academic-profile-accuracy'),
            icon: Icons.task_alt_rounded,
            label: 'Aciertos',
            value: progress == null
                ? '—'
                : '${progress!.answers.successPercentage.clamp(0, 100).round()}%',
          ),
          _MetricCard(
            key: const Key('academic-profile-streak'),
            icon: Icons.local_fire_department_rounded,
            label: 'Racha actual',
            value: gamification == null
                ? '—'
                : '${gamification!.streak.current} días',
          ),
        ],
      );
    },
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    super.key,
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
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const Spacer(),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    ),
  );
}

class _StudyTimeCard extends StatelessWidget {
  const _StudyTimeCard({required this.summary});

  final StudyTimeSummary? summary;

  @override
  Widget build(BuildContext context) => Card(
    key: const Key('academic-profile-study-time'),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      leading: const Icon(Icons.timer_outlined),
      title: const Text('Tiempo total estudiado'),
      subtitle: Text(
        summary == null
            ? 'Calculando actividad…'
            : '${formatStudyDuration(summary!.totalSeconds)} en ${summary!.sessionCount} sesiones',
      ),
    ),
  );
}

class _AcademicSummaryCard extends StatelessWidget {
  const _AcademicSummaryCard({required this.progress});

  final AsyncValue<ProgressDashboard> progress;

  @override
  Widget build(BuildContext context) => Card(
    key: const Key('academic-profile-summary'),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: progress.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(18),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (_, _) => const Text(
          'No pudimos cargar el resumen. Desliza hacia abajo para intentarlo otra vez.',
        ),
        data: (data) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Contenido completado',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text('${data.study.overallPercentage.clamp(0, 100)}%'),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: data.study.overallPercentage.clamp(0, 100) / 100,
              minHeight: 8,
              borderRadius: BorderRadius.circular(99),
            ),
            const SizedBox(height: 12),
            Text(
              '${data.study.completedSubtopics} de ${data.study.totalSubtopics} subtemas completados',
            ),
            const Divider(height: 26),
            Text(
              '${data.answers.correct} correctas de ${data.answers.total} respuestas registradas',
            ),
          ],
        ),
      ),
    ),
  );
}

class _PartialDataNotice extends StatelessWidget {
  const _PartialDataNotice();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.errorContainer,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(
            Icons.cloud_off_outlined,
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Algunos datos no están disponibles. Conservamos visible el resto de tu perfil.',
            ),
          ),
        ],
      ),
    ),
  );
}

class _ProfileLink extends StatelessWidget {
  const _ProfileLink({
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
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
    leading: Icon(icon),
    title: Text(title),
    subtitle: Text(subtitle),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: onTap,
  );
}

String _formatInteger(int value) {
  final digits = value.clamp(0, 999999999).toString();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) buffer.write('.');
    buffer.write(digits[index]);
  }
  return buffer.toString();
}
