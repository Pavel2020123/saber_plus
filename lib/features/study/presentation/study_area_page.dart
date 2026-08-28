import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_filex/open_filex.dart';

import '../../../core/network/api_error.dart';
import '../../academic/domain/academic_models.dart';
import '../../auth/presentation/session_controller.dart';
import '../data/local_offline_content_repository.dart';
import '../domain/offline_content_models.dart';
import '../domain/study_models.dart';
import 'offline_content_providers.dart';
import 'study_providers.dart';

class StudyAreaPage extends ConsumerStatefulWidget {
  const StudyAreaPage({super.key, required this.area});

  final AcademicArea area;

  @override
  ConsumerState<StudyAreaPage> createState() => _StudyAreaPageState();
}

class _StudyAreaPageState extends ConsumerState<StudyAreaPage> {
  String? _downloadingThemeId;

  Future<void> _downloadTheme(StudyTheme theme) async {
    if (_downloadingThemeId != null) return;
    final userId = ref.read(sessionControllerProvider).user?.id;
    if (userId == null) return;
    setState(() => _downloadingThemeId = theme.id);
    try {
      final download = await ref
          .read(offlineContentRepositoryProvider)
          .downloadTheme(userId: userId, area: widget.area, theme: theme);
      final result = await OpenFilex.open(
        download.localPath,
        type: 'application/pdf',
      );
      if (!mounted) return;
      if (result.type != ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'El PDF se guardó como ${download.fileName}, pero no encontramos una aplicación para abrirlo.',
            ),
          ),
        );
      }
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorMessage(error))));
    } finally {
      if (mounted) setState(() => _downloadingThemeId = null);
    }
  }

  Future<void> _openTheme(OfflineThemeDownload download) async {
    final available = await ref
        .read(offlineContentRepositoryProvider)
        .findDownload(download.userId, download.themeId);
    if (!mounted) return;
    if (available == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El archivo ya no estaba en el dispositivo.'),
        ),
      );
      return;
    }
    final result = await OpenFilex.open(
      available.localPath,
      type: 'application/pdf',
    );
    if (mounted && result.type != ResultType.done) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No encontramos una aplicación para abrir el PDF.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(studyCatalogProvider(widget.area));
    final progress = ref.watch(studyProgressProvider).valueOrNull;
    final downloads =
        ref.watch(offlineDownloadsProvider).valueOrNull ?? const [];
    final downloadsByTheme = {
      for (final download in downloads) download.themeId: download,
    };
    final demo = ref.watch(sessionControllerProvider).user?.isDemo ?? false;
    return Scaffold(
      appBar: AppBar(title: Text(widget.area.label)),
      body: catalog.when(
        data: (value) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(studyProgressProvider);
            ref.invalidate(studyCatalogProvider(widget.area));
            await ref.read(studyCatalogProvider(widget.area).future);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Text(
                '${value.themes.length} temas · ${value.totalSubtopics} subtemas',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 18),
              if (value.themes.isEmpty)
                const _EmptyArea()
              else
                for (final theme in value.themes) ...[
                  _ThemeCard(
                    area: widget.area,
                    theme: theme,
                    progress: progress,
                    downloading: _downloadingThemeId == theme.id,
                    downloaded: downloadsByTheme.containsKey(theme.id),
                    onDownload: demo
                        ? null
                        : () {
                            final download = downloadsByTheme[theme.id];
                            if (download == null) {
                              _downloadTheme(theme);
                            } else {
                              _openTheme(download);
                            }
                          },
                  ),
                  const SizedBox(height: 12),
                ],
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _StudyError(
          message: _errorMessage(error),
          onRetry: () => ref.invalidate(studyCatalogProvider(widget.area)),
        ),
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.area,
    required this.theme,
    required this.progress,
    required this.downloading,
    required this.downloaded,
    required this.onDownload,
  });

  final AcademicArea area;
  final StudyTheme theme;
  final StudyProgress? progress;
  final bool downloading;
  final bool downloaded;
  final VoidCallback? onDownload;

  @override
  Widget build(BuildContext context) => Card(
    child: ExpansionTile(
      key: Key('study-theme-${theme.id}'),
      initiallyExpanded: true,
      shape: const Border(),
      leading: const Icon(Icons.folder_open_rounded),
      title: Text(theme.name),
      subtitle: Text('${theme.subtopics.length} subtemas'),
      trailing: onDownload == null
          ? null
          : IconButton(
              key: Key('download-theme-${theme.id}'),
              tooltip: downloaded
                  ? 'Abrir PDF descargado'
                  : 'Descargar tema en PDF',
              onPressed: downloading ? null : onDownload,
              icon: downloading
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      downloaded
                          ? Icons.download_done_rounded
                          : Icons.download_rounded,
                    ),
            ),
      children: [
        if (theme.subtopics.isEmpty)
          const ListTile(title: Text('Este tema aún no tiene subtemas.')),
        for (final subtopic in theme.subtopics)
          ListTile(
            key: Key('study-subtopic-${subtopic.id}'),
            contentPadding: const EdgeInsets.fromLTRB(20, 4, 16, 4),
            leading: _ProgressCircle(
              percentage: progress?.percentageFor(subtopic.id) ?? 0,
            ),
            title: Text(subtopic.name),
            subtitle: Text(
              subtopic.hasLearningResource
                  ? '${subtopic.totalQuestions} preguntas disponibles'
                  : 'Contenido pendiente',
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(
              '/student/study/${area.slug}/${Uri.encodeComponent(theme.id)}/${Uri.encodeComponent(subtopic.id)}',
            ),
          ),
      ],
    ),
  );
}

class _ProgressCircle extends StatelessWidget {
  const _ProgressCircle({required this.percentage});

  final int percentage;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 36,
    child: Stack(
      alignment: Alignment.center,
      children: [
        CircularProgressIndicator(
          value: percentage / 100,
          strokeWidth: 3,
          backgroundColor: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest,
        ),
        Text('$percentage', style: Theme.of(context).textTheme.labelSmall),
      ],
    ),
  );
}

class _EmptyArea extends StatelessWidget {
  const _EmptyArea();

  @override
  Widget build(BuildContext context) => const Card(
    child: Padding(
      padding: EdgeInsets.all(26),
      child: Column(
        children: [
          Icon(Icons.menu_book_outlined, size: 52),
          SizedBox(height: 12),
          Text('Todavía no hay contenido disponible en esta área.'),
        ],
      ),
    ),
  );
}

class _StudyError extends StatelessWidget {
  const _StudyError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 58),
          const SizedBox(height: 14),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: onRetry,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    ),
  );
}

String _errorMessage(Object error) => error is ApiError
    ? error.message
    : 'No pudimos cargar el contenido académico.';
