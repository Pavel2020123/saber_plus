import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/sync/sync_providers.dart';
import '../../auth/presentation/session_controller.dart';
import '../../gamification/presentation/gamification_providers.dart';

class MorePage extends ConsumerWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(syncOperationsProvider).valueOrNull ?? const [];
    final gamification = ref.watch(gamificationSummaryProvider).valueOrNull;
    return Scaffold(
      appBar: AppBar(title: const Text('Más')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          const _MenuTile(
            icon: Icons.person_outline_rounded,
            title: 'Mi perfil',
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
          const _MenuTile(icon: Icons.leaderboard_outlined, title: 'Ranking'),
          const _MenuTile(icon: Icons.campaign_outlined, title: 'Anuncios'),
          const _MenuTile(icon: Icons.help_outline_rounded, title: 'Soporte'),
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
