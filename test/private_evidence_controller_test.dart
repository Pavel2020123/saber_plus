import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/institutions/domain/private_institution_evidence.dart';
import 'package:saber_plus/features/institutions/presentation/private_evidence_controller.dart';

const request = 'd9ac5e51-de18-46ce-b596-b62a97d1ac91';
const id = 'e902e956-dbb5-4c91-ae4f-425ee6bc7db8';
InstitutionEvidenceFile file(
  String operation, {
  InstitutionEvidenceState state = InstitutionEvidenceState.active,
  bool cleanupPending = true,
}) => InstitutionEvidenceFile(
  requestId: request,
  id: id,
  operationId: operation,
  revision: 2,
  state: state,
  mime: 'application/pdf',
  bytes: 5,
  available: state == InstitutionEvidenceState.active,
  cleanupPending: state == InstitutionEvidenceState.retired && cleanupPending,
);

class Repository implements PrivateInstitutionEvidenceRepository {
  final operations = <String>[];
  bool lose = false;
  bool prepared = false, loseRemovalAcknowledgement = false, cleaned = false;
  int removals = 0, downloads = 0;
  List<InstitutionEvidenceFile> files = [];
  Completer<InstitutionEvidenceFile>? deferred;
  InstitutionEvidenceFile? receipt;
  @override
  Future<InstitutionEvidenceList> load() async =>
      InstitutionEvidenceList(revision: 1, canUpload: true, files: files);
  @override
  Future<InstitutionEvidenceFile> upload(
    String op,
    int revision,
    InstitutionEvidenceDraft draft,
  ) async {
    operations.add(op);
    receipt = file(
      op,
      state: prepared
          ? InstitutionEvidenceState.prepared
          : InstitutionEvidenceState.active,
    );
    if (deferred != null) return deferred!.future;
    if (lose) throw StateError('Lost acknowledgement');
    return receipt!;
  }

  @override
  Future<InstitutionEvidenceFile> operation(String op) async {
    if (lose) throw StateError('Unknown, not a failed upload');
    return receipt!;
  }

  @override
  Future<InstitutionEvidenceFile> remove(String fileId, int revision) async {
    removals++;
    if (lose) throw StateError('Unknown removal');
    receipt = file(
      receipt!.operationId,
      state: InstitutionEvidenceState.retired,
      cleanupPending: !cleaned,
    );
    if (loseRemovalAcknowledgement) {
      throw StateError('Retired but acknowledgement lost');
    }
    return receipt!;
  }

  @override
  Future<Uint8List> content(InstitutionEvidenceFile file) async {
    downloads++;
    return Uint8List(5);
  }
}

void main() {
  late Repository repository;
  late PrivateEvidenceController controller;
  setUp(() {
    repository = Repository();
    controller = PrivateEvidenceController(repository, isCurrent: () => true);
  });
  tearDown(() => controller.dispose());
  Future<void> select() async {
    await controller.refresh();
    controller.select(
      InstitutionEvidenceDraft(Uint8List.fromList([37, 80, 68, 70, 45])),
    );
  }

  test('selection does not upload and can be discarded', () async {
    await select();
    expect(repository.operations, isEmpty);
    expect(controller.pending, isTrue);
    controller.discardSelection();
    expect(controller.pending, isFalse);
  });
  test(
    'lost acknowledgement and unknown query preserve the same upload',
    () async {
      await select();
      repository.lose = true;
      await controller.upload();
      final operation = controller.operationId;
      final draft = controller.draft;
      await controller.reconcile();
      controller.discardSelection();
      await controller.refresh();
      expect(controller.operationId, operation);
      expect(controller.draft, same(draft));
      await controller.upload();
      expect(repository.operations, [operation, operation]);
      repository.lose = false;
      await controller.reconcile();
      expect(controller.pending, isFalse);
      expect(controller.uncertain, isFalse);
    },
  );
  test('double tap cannot create another operation', () async {
    await select();
    repository.deferred = Completer();
    final sending = controller.upload();
    await controller.upload();
    expect(repository.operations, hasLength(1));
    repository.deferred!.complete(repository.receipt);
    await sending;
  });
  test(
    'physical cleanup remains visible until server confirms erasure',
    () async {
      await select();
      await controller.upload();
      await controller.withdraw(repository.receipt!);
      expect(controller.cleanupPending, hasLength(1));
      expect(controller.pending, isFalse);
      await controller.refresh();
      expect(controller.cleanupPending, hasLength(1));
      repository.lose = true;
      await controller.retryCleanup(id);
      expect(controller.cleanupPending, hasLength(1));
      repository.lose = false;
      repository.cleaned = true;
      await controller.retryCleanup(id);
      expect(controller.cleanupPending, isEmpty);
      expect(controller.message, contains('confirmada'));
    },
  );
  test(
    'prepared cancellation with lost acknowledgement reconciles without another upload',
    () async {
      await select();
      repository.prepared = true;
      await controller.upload();
      final operation = controller.operationId;
      expect(controller.pending, isTrue);
      repository.loseRemovalAcknowledgement = true;
      await controller.cancelUpload();
      expect(controller.operationId, operation);
      expect(controller.draft, isNotNull);
      await controller.reconcile();
      expect(controller.pending, isFalse);
      expect(repository.operations, hasLength(1));
      expect(repository.removals, 1);
    },
  );
  test('cancel never withdraws an upload that is already active', () async {
    await select();
    repository.lose = true;
    await controller.upload();
    repository.lose = false;
    await controller.cancelUpload();
    expect(controller.pending, isFalse);
    expect(repository.removals, 0);
    expect(controller.message, contains('guardado'));
  });
  test(
    'unknown cancellation receipt cannot discard the original operation',
    () async {
      await select();
      repository.lose = true;
      await controller.upload();
      final operation = controller.operationId;
      await controller.cancelUpload();
      expect(controller.operationId, operation);
      expect(controller.draft, isNotNull);
      expect(repository.removals, 0);
    },
  );
  test(
    'withdrawal uncertainty blocks selection until receipt confirms retirement',
    () async {
      await select();
      await controller.upload();
      final active = repository.receipt!;
      repository.lose = true;
      await controller.withdraw(active);
      controller.select(InstitutionEvidenceDraft(Uint8List(1)));
      expect(controller.draft, isNull);
      expect(controller.withdrawing, same(active));
      repository.lose = false;
      repository.receipt = file(
        active.operationId,
        state: InstitutionEvidenceState.retired,
      );
      await controller.reconcile();
      expect(controller.pending, isFalse);
      expect(controller.message, contains('limpieza física'));
    },
  );
  test('session replacement rejects late state from upload', () async {
    bool current = true;
    final local = PrivateEvidenceController(
      repository,
      isCurrent: () => current,
    );
    await local.refresh();
    local.select(InstitutionEvidenceDraft(Uint8List(1)));
    repository.deferred = Completer();
    final sending = local.upload();
    current = false;
    repository.deferred!.complete(repository.receipt);
    await sending;
    expect(local.message, isNull);
    expect(local.operationId, isNotNull);
    local.dispose();
    expect(local.draft, isNull);
  });
}
