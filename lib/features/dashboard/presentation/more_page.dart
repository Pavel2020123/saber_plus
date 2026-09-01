import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/sync/sync_providers.dart';
import '../../announcements/presentation/announcement_providers.dart';
import '../../auth/presentation/session_controller.dart';
import '../../gamification/presentation/gamification_providers.dart';
import '../../study_time/domain/study_time_models.dart';
import '../../study_time/presentation/study_time_providers.dart';

class MorePage extends ConsumerWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(syncOperationsProvider).valueOrNull ?? const [];
    final gamification = ref.watch(gamificationSummaryProvider).valueOrNull;
    final studyTime = ref.watch(studyTimeSummaryProvider).valueOrNull;
    final announcements = ref.watch(announcementControllerProvider).valueOrNull;
    return Scaffold(
      appBar: AppBar(title: const Text('Más')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          _MenuTile(
            key: const Key('open-academic-profile'),
            icon: Icons.person_outline_rounded,
            title: 'Mi perfil',
            subtitle: 'Tu panorama académico en un solo lugar',
            onTap: () => context.push('/student/more/profile'),
          ),
          _MenuTile(
            key: const Key('open-student-institution'),
            icon: Icons.account_balance_outlined,
            title: 'Mi institución y grupos',
            subtitle: 'Consulta y acepta códigos temporales de tus profesores',
            onTap: () => context.push('/student/more/institution'),
          ),
          _MenuTile(
            key: const Key('open-favorites'),
            icon: Icons.bookmarks_outlined,
            title: 'Mis favoritos',
            subtitle: 'Lecciones guardadas en este dispositivo',
            onTap: () => context.push('/student/more/favorites'),
          ),
          _MenuTile(
            key: const Key('open-difficult-questions'),
            icon: Icons.outlined_flag_rounded,
            title: 'Preguntas difíciles',
            subtitle: 'Subtemas marcados para reforzar',
            onTap: () => context.push('/student/more/difficult-questions'),
          ),
          _MenuTile(
            key: const Key('open-gamification'),
            icon: Icons.emoji_events_outlined,
            title: 'Logros e insignias',
            subtitle: gamification == null
                ? 'XP, racha y actividad'
                : '${gamification.streak.current} días de racha · '
                      '${gamification.totals.unlocked}/${gamification.totals.total} logros',
            onTap: () => context.push('/student/more/gamification'),
          ),
          _MenuTile(
            key: const Key('open-study-time'),
            icon: Icons.schedule_rounded,
            title: 'Tiempo estudiado',
            subtitle: studyTime == null
                ? 'Pomodoros y evaluaciones confirmadas'
                : '${formatStudyDuration(studyTime.totalSeconds)} de estudio',
            onTap: () => context.push('/student/more/study-time'),
          ),
          _MenuTile(
            key: const Key('open-ranking'),
            icon: Icons.leaderboard_outlined,
            title: 'Ranking',
            subtitle: 'Posiciones con identidades protegidas',
            onTap: () => context.push('/student/more/ranking'),
          ),
          _MenuTile(
            key: const Key('open-announcements'),
            icon: Icons.campaign_outlined,
            title: 'Anuncios',
            subtitle: announcements == null
                ? 'Novedades de SaberPlus y tu institución'
                : announcements.pendingCount == 0
                ? 'Estás al día'
                : '${announcements.pendingCount} pendiente${announcements.pendingCount == 1 ? '' : 's'}',
            onTap: () => context.push('/student/more/announcements'),
          ),
          _MenuTile(
            key: const Key('open-score-calculator'),
            icon: Icons.calculate_outlined,
            title: 'Calculadora de puntaje',
            subtitle: 'Calcula el global con tus cinco resultados',
            onTap: () => context.push('/student/more/score-calculator'),
          ),
          _MenuTile(
            key: const Key('open-referrals'),
            icon: Icons.group_add_outlined,
            title: 'Invitar a estudiar',
            subtitle: 'Comparte tu código sin revelar datos privados',
            onTap: () => context.push('/student/more/referrals'),
          ),
          _MenuTile(
            key: const Key('open-support'),
            icon: Icons.help_outline_rounded,
            title: 'Soporte',
            subtitle: 'Ayuda con tu cuenta o con la aplicación',
            onTap: () => context.push('/student/more/support'),
          ),
          _MenuTile(
            key: const Key('open-preferences'),
            icon: Icons.tune_rounded,
            title: 'Preferencias',
            subtitle: 'Apariencia y recordatorio diario',
            onTap: () => context.push('/student/more/preferences'),
          ),
          _MenuTile(
            key: const Key('open-sync-queue'),
            icon: pending.isEmpty
                ? Icons.cloud_done_outlined
                : Icons.sync_problem_rounded,
            title: 'Sincronización',
            subtitle: pending.isEmpty
                ? 'Sin cambios pendientes'
                : '${pending.length} cambios pendientes',
            onTap: () => context.push('/student/more/sync'),
          ),
          const Divider(height: 28),
          ListTile(
            leading: const Icon(Icons.logout_rounded),
            title: const Text('Cerrar demostración'),
            onTap: () async {
              await ref.read(sessionControllerProvider.notifier).signOut();
              if (context.mounted) context.go('/welcome');
            },
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon),
    title: Text(title),
    subtitle: subtitle == null ? null : Text(subtitle!),
    trailing: const Icon(Icons.chevron_right_rounded),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    onTap: onTap ?? () {},
  );
}
