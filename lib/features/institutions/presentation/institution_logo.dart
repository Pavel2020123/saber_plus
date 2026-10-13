import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../auth/presentation/session_controller.dart';
import '../domain/institution_profile.dart';

final institutionLogoBytesProvider = FutureProvider.autoDispose
    .family<Uint8List, String>((ref, path) async {
      final user = ref.watch(sessionControllerProvider.select((s) => s.user));
      if (user == null || user.isDemo) throw StateError('Sin sesión remota.');
      institutionLogoPath(path);
      final cancel = CancelToken();
      ref.onDispose(cancel.cancel);
      final result = await ref
          .watch(dioProvider)
          .get<List<int>>(
            path,
            cancelToken: cancel,
            options: Options(
              responseType: ResponseType.bytes,
              headers: {'Accept': 'image/webp'},
            ),
          );
      if (result.data == null || result.data!.length > 204800) {
        throw const FormatException('Logo inválido.');
      }
      return Uint8List.fromList(result.data!);
    });

class InstitutionLogo extends ConsumerWidget {
  const InstitutionLogo({super.key, required this.path, this.size = 56});
  final String? path;
  final double size;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fallback = Icon(Icons.school_outlined, size: size * .65);
    final image = path == null
        ? fallback
        : ref
              .watch(institutionLogoBytesProvider(path!))
              .when(
                data: (bytes) => Image.memory(
                  bytes,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => fallback,
                ),
                error: (_, _) => IconButton(
                  tooltip: 'Reintentar cargar logo',
                  onPressed: () =>
                      ref.invalidate(institutionLogoBytesProvider(path!)),
                  icon: fallback,
                ),
                loading: () => fallback,
              );
    return Semantics(
      label: 'Logo institucional',
      image: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(width: size, height: size, child: image),
      ),
    );
  }
}
