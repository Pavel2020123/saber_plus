import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/presentation/session_controller.dart';

class TeacherDashboardPage extends ConsumerWidget {
  const TeacherDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumen institucional'),
        actions: [
          IconButton(
            tooltip: 'Cerrar demostración',
            onPressed: () async {
              await ref.read(sessionControllerProvider.notifier).signOut();
              if (context.mounted) context.go('/welcome');
            },
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            'Buenos días, profe',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(
            'Institución Educativa SaberPlus',
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.25,
            children: const [
              _TeacherMetric(
                icon: Icons.school_outlined,
                value: '128',
                label: 'Estudiantes',
              ),
              _TeacherMetric(
                icon: Icons.groups_2_outlined,
                value: '6',
                label: 'Grupos',
              ),
              _TeacherMetric(
                icon: Icons.trending_up_rounded,
                value: '67%',
                label: 'Progreso medio',
              ),
              _TeacherMetric(
                icon: Icons.warning_amber_rounded,
                value: '9',
                label: 'Alertas',
              ),
            ],
          ),
          const SizedBox(height: 26),
          Text(
            'Atención esta semana',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          const _RiskTile(
            name: 'Juan P.',
            detail: '12 días sin actividad',
            level: 'Alta',
          ),
          const SizedBox(height: 10),
          const _RiskTile(
            name: 'Laura M.',
            detail: 'Lectura crítica por debajo de 35%',
            level: 'Crítica',
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            onPressed: () {},
            icon: const Icon(Icons.people_outline_rounded),
            label: const Text('Ver todos los estudiantes'),
          ),
        ],
      ),
    );
  }
}

class _TeacherMetric extends StatelessWidget {
  const _TeacherMetric({
    required this.icon,
    required this.value,
    required this.label,
  });
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: colors.primary),
            const Spacer(),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _RiskTile extends StatelessWidget {
  const _RiskTile({
    required this.name,
    required this.detail,
    required this.level,
  });
  final String name;
  final String detail;
  final String level;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: colors.errorContainer,
          child: Icon(Icons.person_outline_rounded, color: colors.error),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(detail),
        trailing: Text(
          level,
          style: TextStyle(color: colors.error, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
