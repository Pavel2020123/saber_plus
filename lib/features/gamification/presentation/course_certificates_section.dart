import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';

import '../../../core/network/api_error.dart';
import '../../auth/presentation/session_controller.dart';
import '../domain/course_certificate.dart';
import 'gamification_providers.dart';

class CourseCertificatesSection extends ConsumerStatefulWidget {
  const CourseCertificatesSection({super.key});

  @override
  ConsumerState<CourseCertificatesSection> createState() =>
      _CourseCertificatesSectionState();
}

class _CourseCertificatesSectionState
    extends ConsumerState<CourseCertificatesSection> {
  bool _downloading = false;

  Future<void> _download(CourseCertificate item) async {
    final userId = ref.read(sessionControllerProvider).user?.id;
    if (_downloading || userId == null || !item.available) return;
    setState(() => _downloading = true);
    try {
      // Always ask the server again: progress/catalog and registered name can change.
      final pdf = await ref
          .read(gamificationRepositoryProvider)
          .downloadCertificate(userId: userId, certificate: item);
      if (!mounted || ref.read(sessionControllerProvider).user?.id != userId) {
        return;
      }
      final result = await OpenFilex.open(
        pdf.localPath,
        type: 'application/pdf',
      );
      if (!mounted || ref.read(sessionControllerProvider).user?.id != userId) {
        return;
      }
      _message(
        result.type == ResultType.done
            ? 'Certificado guardado: ${pdf.fileName}'
            : 'El PDF quedó guardado, pero necesitas una aplicación para abrirlo.',
      );
    } catch (error) {
      if (!mounted || ref.read(sessionControllerProvider).user?.id != userId) {
        return;
      }
      _message(
        error is ApiError
            ? error.message
            : 'No pudimos descargar el certificado. Intenta nuevamente.',
      );
      ref.invalidate(courseCertificatesProvider);
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) {
    final certificates = ref.watch(courseCertificatesProvider);
    final demo = ref.watch(
      sessionControllerProvider.select((state) => state.user?.isDemo ?? false),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tus certificados', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        Text(
          demo
              ? 'Hay cinco certificados de áreas y uno de curso completo. La demostración no emite certificados personales.'
              : 'Completa todas las lecciones publicadas de cada área. Al terminar las cinco, obtendrás el certificado del curso.',
        ),
        const SizedBox(height: 12),
        certificates.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'No pudimos consultar tus certificados. Comprueba la conexión y que el backend esté actualizado.',
                  ),
                  TextButton(
                    onPressed: () => ref.invalidate(courseCertificatesProvider),
                    child: const Text('Reintentar certificados'),
                  ),
                ],
              ),
            ),
          ),
          data: (items) => Column(
            children: [
              for (final item in items)
                Card(
                  key: Key('course-certificate-${item.id}'),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          item.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.available
                              ? 'Disponible'
                              : item.total == 0
                              ? 'Pendiente de contenido publicado'
                              : '${item.completed} de ${item.total} ${item.unit} completadas',
                        ),
                        if (!demo && item.total > 0) ...[
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: item.completed / item.total,
                          ),
                        ],
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          key: Key('download-course-certificate-${item.id}'),
                          onPressed: demo || !item.available || _downloading
                              ? null
                              : () => _download(item),
                          icon: Icon(
                            item.available
                                ? Icons.picture_as_pdf_outlined
                                : Icons.lock_outline,
                          ),
                          label: Text(
                            _downloading
                                ? 'Preparando PDF…'
                                : 'Descargar certificado',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
