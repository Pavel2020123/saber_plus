import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/presentation/session_controller.dart';

class MorePage extends ConsumerWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('Más')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        const _MenuTile(icon: Icons.person_outline_rounded, title: 'Mi perfil'),
        const _MenuTile(
          icon: Icons.emoji_events_outlined,
          title: 'Logros e insignias',
        ),
        const _MenuTile(icon: Icons.leaderboard_outlined, title: 'Ranking'),
        const _MenuTile(icon: Icons.campaign_outlined, title: 'Anuncios'),
        const _MenuTile(icon: Icons.help_outline_rounded, title: 'Soporte'),
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

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon),
    title: Text(title),
    trailing: const Icon(Icons.chevron_right_rounded),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    onTap: () {},
  );
}
