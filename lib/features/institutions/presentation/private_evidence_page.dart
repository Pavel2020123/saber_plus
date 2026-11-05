import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../auth/presentation/session_controller.dart';
import '../data/private_document_access.dart';
import '../data/private_institution_evidence_repository.dart';
import '../domain/private_institution_evidence.dart';
import 'private_evidence_board.dart';
import 'private_evidence_controller.dart';

final _evidenceControllerProvider = Provider.autoDispose
    .family<PrivateEvidenceController, (String, String)>((ref, identity) {
      bool current() {
        final user = ref.read(sessionControllerProvider).user;
        return user?.id == identity.$1 &&
            user?.isDemo == false &&
            user?.mustChangePassword == false;
      }

      final repository = RemotePrivateInstitutionEvidenceRepository(
        ref.watch(dioProvider),
        identity.$2,
        isCurrent: current,
      );
      final controller = PrivateEvidenceController(
        repository,
        isCurrent: current,
      );
      ref.onDispose(() {
        controller.dispose();
        repository.dispose();
      });
      return controller;
    });

final _documentsProvider = Provider.autoDispose
    .family<PrivateDocumentAccess, (String, String)>((ref, identity) {
      final access = PrivateDocumentAccess(
        isCurrent: () {
          final user = ref.read(sessionControllerProvider).user;
          return user?.id == identity.$1 &&
              user?.isDemo == false &&
              user?.mustChangePassword == false;
        },
      );
      ref.onDispose(access.dispose);
      return access;
    });

class PrivateEvidencePage extends ConsumerWidget {
  const PrivateEvidencePage({super.key, required this.requestId});
  final String requestId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionControllerProvider).user;
    if (!privateInstitutionEvidenceEnabled ||
        !isInstitutionEvidenceId(requestId) ||
        user == null ||
        user.isDemo ||
        user.mustChangePassword) {
      return Scaffold(
        appBar: AppBar(title: const Text('Adjuntos privados')),
        body: const SafeArea(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Se requiere una cuenta real y una instalación de pruebas habilitada.',
            ),
          ),
        ),
      );
    }
    final identity = (user.id, requestId);
    final controller = ref.watch(_evidenceControllerProvider(identity));
    final access = ref.watch(_documentsProvider(identity));
    return PrivateEvidenceBoard(
      key: ValueKey(identity),
      controller: controller,
      pick: access.pick,
      export: (file, bytes) => access.exportFile(file, bytes, confirmed: true),
    );
  }
}
