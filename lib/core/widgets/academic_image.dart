import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/session_controller.dart';
import '../config/environment.dart';
import '../config/resource_url.dart';
import '../media/editorial_image_reference.dart';
import '../media/remote_editorial_image_repository.dart';
import '../network/access_token_store.dart';
import '../network/api_client.dart';
import 'academic_image_viewer.dart';

final editorialImageProvider = FutureProvider.autoDispose
    .family<ui.Image, String>((ref, path) async {
      final user = ref.watch(sessionControllerProvider.select((s) => s.user));
      if (user == null || user.isDemo) {
        throw StateError('Esta imagen requiere una sesión remota.');
      }
      final reference = EditorialImageReference.parse(path);
      final tokens = ref.watch(accessTokenStoreProvider);
      final revision = tokens.revision;
      final cancel = CancelToken();
      var disposed = false;
      ui.Image? image;
      ref.onDispose(() {
        disposed = true;
        cancel.cancel();
        image?.dispose();
      });
      final bytes = await RemoteEditorialImageRepository(
        ref.watch(dioProvider),
        tokens,
      ).load(reference, cancelToken: cancel);
      if (disposed || tokens.revision != revision) {
        throw StateError('La sesión cambió durante la descarga.');
      }
      final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      ui.ImageDescriptor? descriptor;
      ui.Codec? codec;
      try {
        descriptor = await ui.ImageDescriptor.encoded(buffer);
        if (descriptor.width > 2560 || descriptor.height > 2560) {
          throw const FormatException('Dimensiones de imagen inválidas.');
        }
        codec = await descriptor.instantiateCodec();
        if (codec.frameCount != 1) {
          throw const FormatException('La imagen debe ser estática.');
        }
        final frame = await codec.getNextFrame();
        if (disposed || tokens.revision != revision) {
          frame.image.dispose();
          throw StateError('La sesión cambió durante la descarga.');
        }
        return image = frame.image;
      } finally {
        codec?.dispose();
        descriptor?.dispose();
        buffer.dispose();
      }
    });

/// One consumer for both authenticated editorial bytes and legacy public URLs.
/// Private images use RawImage: no global ImageCache, tokens in URLs or disk.
class AcademicImage extends ConsumerStatefulWidget {
  const AcademicImage({
    super.key,
    required this.value,
    this.label = 'Imagen del contenido',
    this.borderRadius = BorderRadius.zero,
    this.maxImageHeight,
    this.enableZoom = true,
  });

  final String value;
  final String label;
  final BorderRadius borderRadius;
  // Bound decoded pixels only: error/retry text must remain unconstrained.
  final double? maxImageHeight;
  final bool enableZoom;

  @override
  ConsumerState<AcademicImage> createState() => _AcademicImageState();
}

class _AcademicImageState extends ConsumerState<AcademicImage> {
  int _retry = 0;

  @override
  Widget build(BuildContext context) {
    final reference = EditorialImageReference.tryParse(widget.value);
    if (reference != null) {
      return ref
          .watch(editorialImageProvider(reference.path))
          .when(
            skipLoadingOnReload: false,
            skipLoadingOnRefresh: false,
            data: (image) => Semantics(
              image: true,
              label: widget.label,
              child: _pixels(RawImage(image: image, fit: BoxFit.contain)),
            ),
            loading: () => const Text('Cargando imagen…'),
            error: (error, _) => _failure(
              () => ref.invalidate(editorialImageProvider(reference.path)),
              unavailable:
                  error is DioException &&
                  [403, 404, 410].contains(error.response?.statusCode),
            ),
          );
    }
    final config = ref.watch(appConfigProvider);
    final value = resolveResourceUrl(config, widget.value);
    final uri = Uri.tryParse(value);
    if (widget.value.startsWith('/recursos/editoriales') ||
        uri == null ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasFragment ||
        !(uri.scheme == 'https' ||
            (config.environment == AppEnvironment.dev &&
                uri.scheme == 'http'))) {
      return const Text(
        'La imagen no tiene una dirección válida. No respondas sin su contexto.',
      );
    }
    // Never pass API headers to a public/external image server.
    return Image.network(
      value,
      key: ValueKey((value, _retry)),
      semanticLabel: widget.label,
      fit: BoxFit.contain,
      // Round only decoded image pixels, not loading/error messages.
      frameBuilder: (_, child, frame, loaded) =>
          frame == null && !loaded ? child : _pixels(child),
      loadingBuilder: (_, child, progress) =>
          progress == null ? child : const Text('Cargando imagen…'),
      errorBuilder: (_, _, _) => _failure(() async {
        await NetworkImage(value).evict();
        if (mounted) setState(() => _retry++);
      }),
    );
  }

  Widget _pixels(Widget child) {
    final rounded = ClipRRect(borderRadius: widget.borderRadius, child: child);
    final bounded = widget.maxImageHeight == null
        ? rounded
        : ConstrainedBox(
            constraints: BoxConstraints(maxHeight: widget.maxImageHeight!),
            child: rounded,
          );
    if (!widget.enableZoom) return bounded;
    return Tooltip(
      message: 'Toca para ampliar',
      child: Semantics(
        button: true,
        label: 'Ampliar ${widget.label}',
        child: InkWell(
          onTap: () => showDialog<void>(
            context: context,
            useSafeArea: false,
            builder: (_) => AcademicImageViewer(
              label: widget.label,
              // Keep the authenticated provider live: logout/revocation must
              // remove private pixels in the viewer as well as the thumbnail.
              child: AcademicImage(
                value: widget.value,
                label: widget.label,
                enableZoom: false,
              ),
            ),
          ),
          borderRadius: widget.borderRadius,
          child: bounded,
        ),
      ),
    );
  }

  Widget _failure(VoidCallback onRetry, {bool unavailable = false}) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        unavailable
            ? '${widget.label}: no está disponible. Si la necesitas para comprender la pregunta, no respondas todavía; puedes salir y retomar la actividad.'
            : '${widget.label}: no se pudo cargar. Reintenta antes de responder; puedes salir y retomar la actividad.',
      ),
      TextButton(
        onPressed: onRetry,
        child: Text(
          unavailable ? 'Consultar imagen de nuevo' : 'Reintentar imagen',
        ),
      ),
    ],
  );
}
