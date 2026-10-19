import 'dart:math';

import '../../auth/domain/session.dart';

enum QuestionReportReason {
  statement('ENUNCIADO_CONFUSO', 'Enunciado confuso'),
  answer('RESPUESTA_INCORRECTA', 'Respuesta incorrecta'),
  explanation('EXPLICACION_INCORRECTA', 'Explicación incorrecta'),
  image('IMAGEN_NO_CARGA', 'La imagen no carga'),
  other('OTRO', 'Otro problema');

  const QuestionReportReason(this.value, this.label);
  final String value, label;
}

const questionReportStates = {
  'PENDIENTE': 'Pendiente',
  'EN_REVISION': 'En revisión',
  'RESUELTO': 'Resuelto',
  'DESCARTADO': 'Descartado',
};

bool canReportQuestions(UserSession? user) =>
    user != null &&
    user.role == AppRole.student &&
    !user.isDemo &&
    user.emailVerified &&
    !user.requiresEmailVerification &&
    !user.mustChangePassword;

bool reportUuid(Object? value) =>
    value is String &&
    RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      caseSensitive: false,
    ).hasMatch(value);

String newReportOperation() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 15) | 64;
  bytes[8] = (bytes[8] & 63) | 128;
  final hex = bytes.map((n) => n.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

String? reportDetailError(String text, QuestionReportReason reason) {
  final value = text.trim();
  if (value.runes.length > 500) return 'Escribe hasta 500 caracteres.';
  if (value.runes.any(
    (r) =>
        (r < 32 && ![9, 10, 13].contains(r)) ||
        r == 127 ||
        (r >= 0xd800 && r <= 0xdfff),
  )) {
    return 'El detalle contiene caracteres no válidos.';
  }
  if (reason == QuestionReportReason.other && value.runes.length < 10) {
    return 'Describe el problema con al menos 10 caracteres.';
  }
  return null;
}

/// Immutable payload. An uncertain attempt must never receive a new UUID or text.
class QuestionReportAttempt {
  QuestionReportAttempt({
    required this.operationId,
    required this.questionId,
    required this.reason,
    required String detail,
  }) : detail = detail.trim() {
    if (!reportUuid(operationId) ||
        questionId.isEmpty ||
        questionId.length > 120 ||
        RegExp(r'\s').hasMatch(questionId) ||
        reportDetailError(this.detail, reason) != null) {
      throw const FormatException('Revisa el motivo y el detalle del reporte.');
    }
  }
  final String operationId, questionId, detail;
  final QuestionReportReason reason;
  Map<String, dynamic> toJson() => {
    'operacionId': operationId,
    'preguntaId': questionId,
    'motivo': reason.value,
    'detalle': detail,
  };
}

class QuestionReport {
  const QuestionReport({
    required this.id,
    required this.questionId,
    required this.reason,
    required this.detail,
    required this.status,
    required this.revision,
    required this.createdAt,
    required this.updatedAt,
    this.duplicate,
  });
  final String id, questionId, status;
  final QuestionReportReason reason;
  final String? detail;
  final int revision;
  final DateTime createdAt, updatedAt;
  final bool? duplicate;

  factory QuestionReport.fromJson(
    Map<String, dynamic> json, {
    bool receipt = false,
  }) {
    final reason = QuestionReportReason.values.where(
      (r) => r.value == json['motivo'],
    );
    final created = DateTime.tryParse(json['fechaCreacion']?.toString() ?? '');
    final updated = DateTime.tryParse(
      json['fechaActualizacion']?.toString() ?? '',
    );
    final questionId = json['preguntaId'];
    final revision = json['revision'];
    final detail = json['detalle'];
    if (!reportUuid(json['id']) ||
        questionId is! String ||
        questionId.isEmpty ||
        questionId.length > 120 ||
        RegExp(r'\s').hasMatch(questionId) ||
        reason.length != 1 ||
        !questionReportStates.containsKey(json['estado']) ||
        revision is! int ||
        revision < 0 ||
        revision > 2147483647 ||
        created == null ||
        updated == null ||
        updated.isBefore(created) ||
        (detail != null && (detail is! String || detail.runes.length > 500)) ||
        (receipt && json['duplicado'] is! bool)) {
      throw const FormatException(
        'Respuesta de reporte incompleta. Consulta el recibo.',
      );
    }
    return QuestionReport(
      id: json['id'] as String,
      questionId: questionId,
      reason: reason.single,
      detail: detail as String?,
      status: json['estado'] as String,
      revision: revision,
      createdAt: created,
      updatedAt: updated,
      duplicate: receipt ? json['duplicado'] as bool : null,
    );
  }
}

class QuestionReportPage {
  const QuestionReportPage(this.items, this.page, this.hasMore);
  final List<QuestionReport> items;
  final int page;
  final bool hasMore;
}

/// status null denotes unknown transport/response outcome, not a rejected write.
class QuestionReportFailure implements Exception {
  const QuestionReportFailure(this.message, {this.status});
  final String message;
  final int? status;
  bool get definitelyRejected => [400, 404, 422, 429].contains(status);
}

abstract interface class QuestionReportRepository {
  Future<QuestionReport> send(QuestionReportAttempt attempt);
  Future<QuestionReport> receipt(String operationId);
  Future<QuestionReportPage> own(int page);
}
