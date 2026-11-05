import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
import '../../auth/domain/session.dart';
import '../../auth/presentation/session_controller.dart';
import '../data/remote_private_profile_photo_repository.dart';
import '../domain/private_profile_photo.dart';
import 'private_profile_photo_board.dart';
import '../../institutions/data/private_document_access.dart';

const privateProfilePhotosEnabled = bool.fromEnvironment(
  'PRIVATE_PROFILE_PHOTO_ENABLED',
);

final _privatePhotoDocumentsProvider = Provider.autoDispose
    .family<PrivateDocumentAccess, String>((ref, owner) {
      final access = PrivateDocumentAccess(
        enabled: privateProfilePhotosEnabled,
        isCurrent: () {
          final user = ref.read(sessionControllerProvider).user;
          return user?.id == owner &&
              user?.isDemo == false &&
              user?.mustChangePassword == false;
        },
      );
      ref.onDispose(access.dispose);
      return access;
    });

final privateProfilePhotoRepositoryProvider = Provider.autoDispose
    .family<PrivateProfilePhotoRepository, String>((ref, owner) {
      final remote = RemotePrivateProfilePhotoRepository(
        ref.watch(dioProvider),
      );
      ref.onDispose(remote.dispose);
      return _OwnedPhotoRepository(remote, () {
        final user = ref.read(sessionControllerProvider).user;
        return user?.id == owner &&
            user?.isDemo == false &&
            user?.mustChangePassword == false;
      });
    });

// The server derives ownership from JWT. This additional client boundary also
// discards late data if a route survives an account switch or session refresh.
class _OwnedPhotoRepository implements PrivateProfilePhotoRepository {
  _OwnedPhotoRepository(this._remote, this._current);
  final PrivateProfilePhotoRepository _remote;
  final bool Function() _current;
  Future<T> _run<T>(Future<T> Function() work) async {
    void check() {
      if (!_current()) {
        throw const ApiError(
          code: 'session_changed',
          message: 'La sesión cambió. Vuelve a abrir tu foto privada.',
        );
      }
    }

    check();
    final value = await work();
    check();
    return value;
  }

  @override
  Future<PrivateProfilePhoto> load() => _run(_remote.load);
  @override
  Future<Uint8List> content(PrivateProfilePhoto photo) =>
      _run(() => _remote.content(photo));
  @override
  Future<PrivatePhotoReceipt> upload(
    String operation,
    int revision,
    Uint8List bytes,
  ) => _run(() => _remote.upload(operation, revision, bytes));
  @override
  Future<PrivatePhotoReceipt> operation(String operation) =>
      _run(() => _remote.operation(operation));
  @override
  Future<PrivatePhotoReceipt> cancel(String operation) =>
      _run(() => _remote.cancel(operation));
  @override
  Future<PrivatePhotoRemoval> remove(int revision) =>
      _run(() => _remote.remove(revision));
}

class PrivateProfilePhotoPage extends ConsumerWidget {
  const PrivateProfilePhotoPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionControllerProvider).user;
    if (!privateProfilePhotosEnabled ||
        user == null ||
        user.isDemo ||
        user.mustChangePassword ||
        ![AppRole.student, AppRole.teacher].contains(user.role)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mi foto privada')),
        body: const SafeArea(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'La foto privada requiere una cuenta real y una instalación de pruebas habilitada.',
            ),
          ),
        ),
      );
    }
    final repository = ref.watch(
      privateProfilePhotoRepositoryProvider(user.id),
    );
    final native = !kIsWeb && defaultTargetPlatform == TargetPlatform.android
        ? ref.watch(_privatePhotoDocumentsProvider(user.id))
        : null;
    return PrivateProfilePhotoBoard(
      key: ValueKey((user.id, repository)),
      userId: user.id,
      repository: repository,
      pick: () async {
        if (native != null) return native.pickImage();
        final file = await ImagePicker().pickImage(
          source: ImageSource.gallery,
          requestFullMetadata: false,
        );
        if (file == null) return null;
        if (ref.read(sessionControllerProvider).user?.id != user.id) {
          throw const ApiError(
            code: 'session_changed',
            message: 'La sesión cambió. Vuelve a abrir tu foto privada.',
          );
        }
        if (await file.length() > 5 * 1024 * 1024) {
          throw const ApiError(
            code: 'selection',
            message: 'Selecciona una imagen de hasta 5 MiB.',
          );
        }
        return file.readAsBytes();
      },
    );
  }
}

class PrivateProfilePhotoShortcut extends ConsumerWidget {
  const PrivateProfilePhotoShortcut({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionControllerProvider).user;
    if (!privateProfilePhotosEnabled ||
        user == null ||
        user.isDemo ||
        user.mustChangePassword ||
        ![AppRole.student, AppRole.teacher].contains(user.role)) {
      return const SizedBox.shrink();
    }
    return ListTile(
      key: const Key('open-private-profile-photo'),
      leading: const Icon(Icons.account_circle_outlined),
      title: const Text('Mi foto privada'),
      subtitle: const Text('Solo tú puedes verla · no aparece en rankings'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).push<void>(
        MaterialPageRoute(builder: (_) => const PrivateProfilePhotoPage()),
      ),
    );
  }
}
