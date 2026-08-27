import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../auth/presentation/session_controller.dart';

class StudentDashboardPage extends ConsumerWidget {
  const StudentDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionControllerProvider).user;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
              sliver: SliverList.list(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hola, ${user?.firstName ?? 'estudiante'} 👋',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Hoy cuenta. Hagamos una sesión corta.',
                              style: TextStyle(color: colors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      IconButton.filledTonal(
                        onPressed: () {},
                        tooltip: 'Notificaciones',
                        icon: const Icon(Icons.notifications_none_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const _NextActivityCard(),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: _MetricCard(
                          icon: Icons.local_fire_department_rounded,
                          value: '7 días',
                          label: 'Racha',
                          color: colors.tertiary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MetricCard(
                          icon: Icons.bolt_rounded,
                          value: '1.240',
                          label: 'XP total',
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  _SectionTitle(
                    title: 'Tu semana',
                    action: 'Ver plan',
                    onTap: () {},
                  ),
                  const SizedBox(height: 12),
                  const _WeeklyProgressCard(),
                  const SizedBox(height: 26),
                  _SectionTitle(
                    title: 'Continúa por áreas',
                    action: 'Ver todas',
                    onTap: () => context.go('/student/study'),
                  ),
                  const SizedBox(height: 12),
                  const _SubjectCard(
                    icon: Icons.calculate_outlined,
                    title: 'Matemáticas',
                    subtitle: 'Funciones y gráficas',
                    progress: 0.68,
                    color: Color(0xFF4C63D2),
                  ),
                  const SizedBox(height: 12),
                  const _SubjectCard(
                    icon: Icons.biotech_outlined,
                    title: 'Ciencias naturales',
                    subtitle: 'Ecosistemas',
                    progress: 0.42,
                    color: SaberPlusColors.secondary,
                  ),
                  const SizedBox(height: 12),
                  const _SubjectCard(
                    icon: Icons.article_outlined,
                    title: 'Lectura crítica',
                    subtitle: 'Textos argumentativos',
                    progress: 0.55,
                    color: Color(0xFFD66A32),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NextActivityCard extends StatelessWidget {
  const _NextActivityCard();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
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
          const Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                color: Color(0xFFFFD66B),
                size: 19,
              ),
              SizedBox(width: 7),
              Text(
                'SIGUIENTE ACTIVIDAD',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.7,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Refuerzo de matemáticas',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Funciones lineales · 12 preguntas',
            style: TextStyle(color: Colors.white70, fontSize: 15),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: colors.primary,
              minimumSize: const Size(0, 48),
              padding: const EdgeInsets.symmetric(horizontal: 18),
            ),
            onPressed: () {},
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Empezar · 15 min'),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.14),
            foregroundColor: color,
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
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.action,
    required this.onTap,
  });
  final String title;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      ),
      TextButton(onPressed: onTap, child: Text(action)),
    ],
  );
}

class _WeeklyProgressCard extends StatelessWidget {
  const _WeeklyProgressCard();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '3 de 5 sesiones',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Text(
                  '60%',
                  style: TextStyle(
                    color: colors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Semantics(
              label: 'Progreso semanal: 60 por ciento',
              child: LinearProgressIndicator(
                value: 0.6,
                minHeight: 10,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _DayStatus(day: 'L', completed: true),
                _DayStatus(day: 'M', completed: true),
                _DayStatus(day: 'X', completed: true),
                _DayStatus(day: 'J'),
                _DayStatus(day: 'V'),
                _DayStatus(day: 'S', muted: true),
                _DayStatus(day: 'D', muted: true),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DayStatus extends StatelessWidget {
  const _DayStatus({
    required this.day,
    this.completed = false,
    this.muted = false,
  });
  final String day;
  final bool completed;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(day, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 7),
        CircleAvatar(
          radius: 15,
          backgroundColor: completed
              ? SaberPlusColors.success
              : colors.surfaceContainerHighest,
          foregroundColor: completed
              ? Colors.white
              : colors.onSurfaceVariant.withValues(alpha: muted ? 0.35 : 1),
          child: Icon(
            completed ? Icons.check_rounded : Icons.circle_outlined,
            size: 17,
          ),
        ),
      ],
    );
  }
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.color,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 3),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 9),
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    ),
  );
}
