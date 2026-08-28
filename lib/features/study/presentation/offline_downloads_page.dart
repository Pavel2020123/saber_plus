import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';

import '../../../core/network/api_error.dart';
import '../../academic/domain/academic_models.dart';
import '../../auth/presentation/session_controller.dart';
import '../data/local_offline_content_repository.dart';
import '../domain/offline_content_models.dart';
import 'offline_content_providers.dart';

class OfflineDownloadsPage extends ConsumerStatefulWidget {
  const OfflineDownloadsPage({super.key});

  @override
  ConsumerState<OfflineDownloadsPage> createState() =>
      _OfflineDownloadsPageState();
}

class _OfflineDownloadsPageState extends ConsumerState<OfflineDownloadsPage> {
  final Set<String> _deleting = {};
  bool _clearing = false;

  Future<void> _open(OfflineThemeDownload download) async {
    if (!await File(download.localPath).exists()) {
      await ref.read(offlineContentRepositoryProvider).deleteDownload(download);
      if (!mounted) return;
      _showMessage('El archivo ya no estaba en el dispositivo.');
      return;
    }
    final result = await OpenFilex.open(
      download.localPath,
      type: 'application/pdf',
    );
    if (mounted && result.type != ResultType.done) {
      _showMessage('No encontramos una aplicación para abrir archivos PDF.');
    }
  }

  Future<void> _delete(OfflineThemeDownload download) async {
    if (_deleting.contains(download.themeId)) return;
    setState(() => _deleting.add(download.themeId));
    try {
      await ref.read(offlineContentRepositoryProvider).deleteDownload(download);
      if (mounted) _showMessage('Descarga eliminada.');
    } on Object catch (error) {
      if (mounted) _showMessage(_messageFor(error));
    } finally {
      if (mounted) setState(() => _deleting.remove(download.themeId));
    }
  }

  Future<void> _clearAll() async {
    final userId = ref.read(sessionControllerProvider).user?.id;
    if (userId == null || _clearing) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar todas las descargas'),
        content: const Text(
          'Los PDF dejarán de estar disponibles sin conexión. Podrás descargarlos nuevamente cuando tengas internet.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _clearing = true);
    try {
      await ref.read(offlineContentRepositoryProvider).deleteAll(userId);
      if (mounted) _showMessage('Se liberó el espacio de las descargas.');
    } on Object catch (error) {
      if (mounted) _showMessage(_messageFor(error));
    } finally {
      if (mounted) setState(() => _clearing = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final downloads = ref.watch(offlineDownloadsProvider);
    final summary = ref.watch(offlineStorageSummaryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Descargas')),
      body: downloads.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _DownloadsError(message: _messageFor(error)),
        data: (items) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            _StorageCard(
              summary: summary,
              clearing: _clearing,
              onClear: items.isEmpty ? null : _clearAll,
            ),
            const SizedBox(height: 18),
            const Text(
              'Los PDF descargados se pueden abrir sin conexión. Los videos externos no se guardan en el dispositivo.',
            ),
            const SizedBox(height: 18),
            if (items.isEmpty)
              const _EmptyDownloads()
            else
              for (final download in items) ...[
                _DownloadCard(
                  download: download,
                  deleting: _deleting.contains(download.themeId),
                  onOpen: () => _open(download),
                  onDelete: () => _delete(download),
                ),
                const SizedBox(height: 10),
              ],
          ],
        ),
      ),
    );
  }
}

class _StorageCard extends StatelessWidget {
  const _StorageCard({
    required this.summary,
    required this.clearing,
    required this.onClear,
  });

  final OfflineStorageSummary summary;
  final bool clearing;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.storage_rounded),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Espacio sin conexión',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(formatStorageSize(summary.totalBytes)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${summary.count} ${summary.count == 1 ? 'tema descargado' : 'temas descargados'}',
          ),
          if (onClear != null) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              key: const Key('clear-offline-downloads'),
              onPressed: clearing ? null : onClear,
              icon: clearing
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_sweep_outlined),
              label: const Text('Liberar todo el espacio'),
            ),
          ],
        ],
      ),
    ),
  );
}

class _DownloadCard extends StatelessWidget {
  const _DownloadCard({
    required this.download,
    required this.deleting,
    required this.onOpen,
    required this.onDelete,
  });

  final OfflineThemeDownload download;
  final bool deleting;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final area = _areaFromSlug(download.areaSlug);
    final date = download.downloadedAt.toLocal();
    return Card(
      child: ListTile(
        key: Key('offline-download-${download.themeId}'),
        contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        leading: const CircleAvatar(child: Icon(Icons.picture_as_pdf_outlined)),
        title: Text(download.themeName),
        subtitle: Text(
          '${area?.label ?? download.areaSlug} · ${formatStorageSize(download.byteSize)}\nDescargado ${_formatDate(date)}',
        ),
        isThreeLine: true,
        onTap: onOpen,
        trailing: IconButton(
          tooltip: 'Eliminar descarga',
          onPressed: deleting ? null : onDelete,
          icon: deleting
              ? const SizedBox.square(
                  dimension: 19,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.delete_outline_rounded),
        ),
      ),
    );
  }
}

class _EmptyDownloads extends StatelessWidget {
  const _EmptyDownloads();

  @override
  Widget build(BuildContext context) => const Card(
    child: Padding(
      padding: EdgeInsets.all(28),
      child: Column(
        children: [
          Icon(Icons.cloud_download_outlined, size: 54),
          SizedBox(height: 12),
          Text('Aún no tienes temas descargados.'),
          SizedBox(height: 4),
          Text(
            'Entra a un área y toca el botón de descarga de un tema.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

class _DownloadsError extends StatelessWidget {
  const _DownloadsError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Text(message, textAlign: TextAlign.center),
    ),
  );
}

AcademicArea? _areaFromSlug(String slug) {
  for (final area in AcademicArea.values) {
    if (area.slug == slug) return area;
  }
  return null;
}

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

String _messageFor(Object error) => error is ApiError
    ? error.message
    : 'No pudimos administrar las descargas en este momento.';
