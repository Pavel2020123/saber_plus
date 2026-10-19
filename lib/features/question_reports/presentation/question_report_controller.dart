import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../auth/presentation/session_controller.dart';
import '../data/remote_question_report_repository.dart';
import '../domain/question_report.dart';

final questionReportRepositoryProvider = Provider<QuestionReportRepository>(
  (ref) => RemoteQuestionReportRepository(ref.watch(dioProvider)),
);

// Non-autoDispose intentionally keeps uncertain UUID/payload while navigating
// within this login. Changing eligibility/account destroys the previous draft.
final questionReportControllerProvider =
    StateNotifierProvider.family<QuestionReportController, ReportDraft, String>(
      (ref, questionId) {
        final identity = ref.watch(
          sessionControllerProvider.select(
            (s) => (s.user?.id, canReportQuestions(s.user)),
          ),
        );
        return QuestionReportController(
          identity.$2 ? ref.watch(questionReportRepositoryProvider) : null,
          questionId,
        );
      },
    );

class ReportDraft {
  const ReportDraft({
    this.reason = QuestionReportReason.statement,
    this.detail = '',
    this.attempt,
    this.receipt,
    this.busy = false,
    this.message = '',
  });
  final QuestionReportReason reason;
  final String detail, message;
  final QuestionReportAttempt? attempt;
  final QuestionReport? receipt;
  final bool busy;
  bool get locked => attempt != null || receipt != null || busy;
}

class QuestionReportController extends StateNotifier<ReportDraft> {
  QuestionReportController(
    this.repository,
    this.questionId, {
    this.operationId = newReportOperation,
  }) : super(const ReportDraft());
  final QuestionReportRepository? repository;
  final String questionId;
  final String Function() operationId;

  void edit({QuestionReportReason? reason, String? detail}) {
    if (state.locked) return;
    state = ReportDraft(
      reason: reason ?? state.reason,
      detail: detail ?? state.detail,
    );
  }

  void anotherReason() {
    if (state.receipt == null || state.busy) return;
    state = ReportDraft(
      reason: QuestionReportReason.values.firstWhere(
        (reason) => reason != state.reason,
      ),
    );
  }

  Future<void> submit({bool consult = false}) async {
    if (repository == null || state.busy || state.receipt != null) return;
    final previous = state;
    final error = reportDetailError(previous.detail, previous.reason);
    if (error != null) {
      state = ReportDraft(
        reason: previous.reason,
        detail: previous.detail,
        message: error,
      );
      return;
    }
    final attempt =
        previous.attempt ??
        QuestionReportAttempt(
          operationId: operationId(),
          questionId: questionId,
          reason: previous.reason,
          detail: previous.detail,
        );
    state = ReportDraft(
      reason: previous.reason,
      detail: previous.detail,
      attempt: attempt,
      busy: true,
    );
    try {
      final report = consult
          ? await repository!.receipt(attempt.operationId)
          : await repository!.send(attempt);
      if (!mounted) return;
      if (report.questionId != questionId ||
          report.reason != attempt.reason ||
          (report.duplicate == false &&
              (report.detail ?? '') != attempt.detail)) {
        throw const QuestionReportFailure(
          'El recibo no corresponde a este intento.',
        );
      }
      state = ReportDraft(
        reason: previous.reason,
        detail: previous.detail,
        attempt: attempt,
        receipt: report,
        message: report.duplicate == true
            ? 'Este problema ya estaba reportado. No se creó otro ni se cambió el detalle original.'
            : 'Reporte recibido. Gracias por ayudarnos a mejorar.',
      );
    } on Object catch (error) {
      if (!mounted) return;
      final rejected =
          !consult &&
          previous.attempt == null &&
          error is QuestionReportFailure &&
          error.definitelyRejected;
      state = ReportDraft(
        reason: previous.reason,
        detail: previous.detail,
        attempt: rejected ? null : attempt,
        message:
            consult && error is QuestionReportFailure && error.status == 404
            ? 'Todavía no hay recibo. Conservamos el intento: puedes reintentar el mismo envío.'
            : error is QuestionReportFailure
            ? error.message
            : 'No se pudo confirmar la operación. Consulta el recibo o reintenta el mismo envío.',
      );
    }
  }
}
