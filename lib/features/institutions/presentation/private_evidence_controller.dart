import 'package:flutter/foundation.dart';
import '../../../core/network/api_error.dart';
import '../domain/private_institution_evidence.dart';
import '../domain/student_institution_request.dart';

/// One screen/session owns this state. Unknown acknowledgements retain identity.
class PrivateEvidenceController extends ChangeNotifier {
  PrivateEvidenceController(this.repository, {required this.isCurrent});
  final PrivateInstitutionEvidenceRepository repository;
  final bool Function() isCurrent;
  InstitutionEvidenceList? listing;
  InstitutionEvidenceDraft? draft;
  String? operationId, message;
  int? operationRevision;
  InstitutionEvidenceFile? withdrawing;
  final _cleanup = <String, InstitutionEvidenceFile>{};
  List<InstitutionEvidenceFile> get cleanupPending =>
      List.unmodifiable(_cleanup.values);
  bool busy = false, uncertain = false, _closed = false;
  bool get pending =>
      draft != null || operationId != null || withdrawing != null;
  bool get alive => !_closed && isCurrent();

  Future<void> _run(Future<void> Function() action) async {
    if (!alive || busy) return;
    busy = true;
    message = null;
    notifyListeners();
    try {
      await action();
    } on Object catch (error) {
      if (alive) {
        message = error is ApiError
            ? error.message
            : 'No pudimos confirmar la operación. Consulta su estado antes de continuar.';
      }
    } finally {
      if (alive) {
        busy = false;
        notifyListeners();
      }
    }
  }

  Future<void> refresh() => _run(() async {
    final value = await repository.load();
    if (alive) listing = value;
    // A list without the file is not proof that an uncertain operation failed.
  });

  void select(InstitutionEvidenceDraft value) {
    if (!alive ||
        busy ||
        operationId != null ||
        withdrawing != null ||
        listing?.canUpload != true) {
      return;
    }
    draft = value;
    message = null;
    notifyListeners();
  }

  void discardSelection() {
    if (!alive || busy || operationId != null || withdrawing != null) return;
    draft = null;
    notifyListeners();
  }

  Future<void> _accept(InstitutionEvidenceFile file) async {
    if (!alive) return;
    if (file.operationId != operationId) {
      throw const FormatException('El recibo no corresponde al envío.');
    }
    if (file.state == InstitutionEvidenceState.prepared) {
      message =
          'El envío sigue preparado. Puedes consultar o reenviar la misma selección.';
      return;
    }
    _rememberCleanup(file);
    draft = null;
    operationId = null;
    operationRevision = null;
    uncertain = false;
    message = file.state == InstitutionEvidenceState.active
        ? 'Adjunto privado guardado.'
        : file.cleanupPending
        ? 'Adjunto retirado. La limpieza física sigue pendiente.'
        : 'Adjunto retirado.';
    final value = await repository.load();
    if (alive) listing = value;
  }

  Future<void> upload() => _run(() async {
    final selected = draft;
    if (selected == null || withdrawing != null || listing == null) return;
    if (operationId == null && !listing!.canUpload) return;
    operationId ??= newStudentRequestId();
    operationRevision ??= listing!.revision;
    uncertain = true; // Set before IO: any failure can hide a committed write.
    final value = await repository.upload(
      operationId!,
      operationRevision!,
      selected,
    );
    await _accept(value);
  });

  Future<void> reconcile() => _run(() async {
    final operation = operationId;
    if (operation != null) {
      await _accept(await repository.operation(operation));
      return;
    }
    final previous = withdrawing;
    if (previous == null) return;
    final receipt = await repository.operation(previous.operationId);
    if (!alive) return;
    if (receipt.id != previous.id) {
      throw const FormatException('La retirada no corresponde al adjunto.');
    }
    if (receipt.state != InstitutionEvidenceState.retired) {
      withdrawing = receipt;
      message =
          'La retirada no está confirmada. Puedes reintentar con su revisión actual.';
      return;
    }
    _rememberCleanup(receipt);
    withdrawing = null;
    uncertain = false;
    message = receipt.cleanupPending
        ? 'Retirada confirmada. La limpieza física sigue pendiente.'
        : 'Retirada confirmada.';
    final value = await repository.load();
    if (alive) listing = value;
  });

  /// Query first: an absent receipt is not permission to forget a pending send.
  /// The screen must explicitly confirm cancellation/withdrawal before calling.
  Future<void> cancelUpload() => _run(() async {
    final operation = operationId;
    if (operation == null) return;
    final receipt = await repository.operation(operation);
    if (!alive) return;
    if (receipt.operationId != operation) {
      throw const FormatException('El recibo no corresponde al envío.');
    }
    if (receipt.state != InstitutionEvidenceState.prepared) {
      await _accept(receipt);
      return;
    }
    final retired = await repository.remove(receipt.id, receipt.revision);
    if (!alive) return;
    if (retired.id != receipt.id ||
        retired.state != InstitutionEvidenceState.retired) {
      throw const FormatException('No se confirmó la cancelación.');
    }
    await _accept(retired);
  });

  void _rememberCleanup(InstitutionEvidenceFile receipt) {
    if (receipt.state != InstitutionEvidenceState.retired) return;
    if (receipt.cleanupPending) {
      _cleanup[receipt.id] = receipt;
    } else {
      _cleanup.remove(receipt.id);
    }
  }

  /// Only retries an already retired file; never targets a new/active attachment.
  Future<void> retryCleanup(String id) => _run(() async {
    final previous = _cleanup[id];
    if (previous == null) return;
    final receipt = await repository.remove(previous.id, previous.revision);
    if (!alive) return;
    if (receipt.id != previous.id ||
        receipt.operationId != previous.operationId ||
        receipt.state != InstitutionEvidenceState.retired) {
      throw const FormatException(
        'No se confirmó la limpieza del adjunto retirado.',
      );
    }
    _rememberCleanup(receipt);
    message = receipt.cleanupPending
        ? 'El adjunto sigue retirado. La limpieza física continúa pendiente.'
        : 'Limpieza física confirmada por el servidor.';
  });

  /// Call only after the screen obtains explicit withdrawal confirmation.
  Future<void> withdraw(InstitutionEvidenceFile file) => _run(() async {
    if (operationId != null ||
        draft != null ||
        (withdrawing != null && withdrawing!.id != file.id)) {
      return;
    }
    if (withdrawing == null && listing?.canUpload != true) return;
    final target = withdrawing ?? file;
    withdrawing = target;
    uncertain = true;
    final receipt = await repository.remove(target.id, target.revision);
    if (!alive) return;
    if (receipt.id != target.id ||
        receipt.state != InstitutionEvidenceState.retired) {
      throw const FormatException('No se confirmó la retirada.');
    }
    _rememberCleanup(receipt);
    withdrawing = null;
    uncertain = false;
    message = receipt.cleanupPending
        ? 'Retirada confirmada. La limpieza física sigue pendiente.'
        : 'Retirada confirmada.';
    final value = await repository.load();
    if (alive) listing = value;
  });

  @override
  void dispose() {
    _closed = true;
    _cleanup.clear();
    draft = null;
    listing = null;
    withdrawing = null;
    operationId = null;
    super.dispose();
  }
}
