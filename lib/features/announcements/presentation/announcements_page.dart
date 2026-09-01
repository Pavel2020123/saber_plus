import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_error.dart';
import '../domain/announcement_models.dart';
import 'announcement_providers.dart';

class AnnouncementsPage extends ConsumerStatefulWidget {
  const AnnouncementsPage({super.key});

  @override
  ConsumerState<AnnouncementsPage> createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends ConsumerState<AnnouncementsPage> {
  var _onlyPending = false;
  var _saving = false;

  @override
  Widget build(BuildContext context) {
    final board = ref.watch(announcementControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tablón de anuncios'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _saving
                ? null
                : () => ref
                      .read(announcementControllerProvider.notifier)
                      .reload(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: board.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _LoadError(
          message: _message(error),
          onRetry: () =>
              ref.read(announcementControllerProvider.notifier).reload(),
        ),
        data: (data) {
          final visible = _onlyPending
              ? data.items.where((item) => !item.isRead).toList()
              : data.items;
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(announcementControllerProvider.notifier).reload(),
            child: ListView(
              key: const Key('announcements-list'),
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: const Padding(
                    padding: EdgeInsets.all(18),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.campaign_outlined),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Aquí verás novedades de SaberPlus y, si perteneces a una institución, los comunicados de tus profesores.',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(value: false, label: Text('Todos')),
                          ButtonSegment(value: true, label: Text('Pendientes')),
                        ],
                        selected: {_onlyPending},
                        onSelectionChanged: (selection) =>
                            setState(() => _onlyPending = selection.first),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      '${data.pendingCount} pendiente${data.pendingCount == 1 ? '' : 's'}',
                    ),
                    const Spacer(),
                    TextButton(
                      key: const Key('mark-all-announcements-read'),
                      onPressed: data.pendingCount == 0 || _saving
                          ? null
                          : _markAll,
                      child: const Text('Marcar todo como leído'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (visible.isEmpty)
                  _EmptyAnnouncements(onlyPending: _onlyPending)
                else
                  for (final announcement in visible)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _AnnouncementCard(
                        announcement: announcement,
                        saving: _saving,
                        onRead: () => _markRead(announcement.id),
                      ),
                    ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _markRead(String id) async {
    setState(() => _saving = true);
    try {
      await ref.read(announcementControllerProvider.notifier).markRead(id);
    } on Object catch (error) {
      if (mounted) _snack(_message(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _markAll() async {
    setState(() => _saving = true);
    try {
      await ref.read(announcementControllerProvider.notifier).markAllRead();
    } on Object catch (error) {
      if (mounted) _snack(_message(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({
    required this.announcement,
    required this.saving,
    required this.onRead,
  });

  final Announcement announcement;
  final bool saving;
  final VoidCallback onRead;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = switch (announcement.type) {
      AnnouncementType.information => colors.primary,
      AnnouncementType.important => colors.error,
      AnnouncementType.event => colors.tertiary,
    };
    return Card(
      key: Key('announcement-${announcement.id}'),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                Chip(
                  avatar: Icon(Icons.circle, size: 10, color: color),
                  label: Text(announcement.type.label),
                ),
                Chip(label: Text(announcement.origin.label)),
                if (announcement.isFeatured)
                  const Chip(label: Text('Destacado')),
                if (!announcement.isRead) const Chip(label: Text('Nuevo')),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              announcement.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(announcement.content),
            const SizedBox(height: 14),
            Text(
              'Publicado ${_formatDate(announcement.startsAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (!announcement.isRead) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  key: Key('mark-announcement-${announcement.id}-read'),
                  onPressed: saving ? null : onRead,
                  icon: const Icon(Icons.done_rounded),
                  label: const Text('Marcar como leído'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyAnnouncements extends StatelessWidget {
  const _EmptyAnnouncements({required this.onlyPending});

  final bool onlyPending;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Text(
          onlyPending
              ? 'Estás al día. No tienes anuncios pendientes.'
              : 'No hay anuncios vigentes en este momento.',
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 42),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: onRetry,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    ),
  );
}

String _message(Object error) => switch (error) {
  ApiError value => value.message,
  _ => 'No pudimos cargar los anuncios. Intenta nuevamente.',
};

String _formatDate(DateTime date) {
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
  final minute = date.minute.toString().padLeft(2, '0');
  return '${date.day} ${months[date.month - 1]} · ${date.hour}:$minute';
}
