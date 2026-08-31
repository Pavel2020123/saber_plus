import '../../../academic/domain/academic_models.dart';
import 'tug_of_war_models.dart';

enum TugOnlineMatchStatus {
  searching,
  preparing,
  active,
  finished,
  cancelled,
  expired;

  factory TugOnlineMatchStatus.fromBackend(String value) => switch (value) {
    'BUSCANDO' => searching,
    'PREPARANDO' => preparing,
    'ACTIVA' => active,
    'FINALIZADA' => finished,
    'CANCELADA' => cancelled,
    'EXPIRADA' => expired,
    _ => throw FormatException('Estado de partida desconocido: $value'),
  };
}

class TugOnlinePlayer {
  const TugOnlinePlayer({required this.id, required this.name, this.avatarUrl});

  final String id;
  final String name;
  final String? avatarUrl;

  factory TugOnlinePlayer.fromJson(Map<String, dynamic> json) =>
      TugOnlinePlayer(
        id: json['id'] as String,
        name: json['nombre'] as String,
        avatarUrl: json['fotoPerfil'] as String?,
      );
}

class TugOnlineOption {
  const TugOnlineOption({required this.id, required this.text});

  final String id;
  final String text;

  factory TugOnlineOption.fromJson(Map<String, dynamic> json) =>
      TugOnlineOption(id: json['id'] as String, text: json['texto'] as String);
}

class TugOnlineQuestion {
  const TugOnlineQuestion({
    required this.id,
    required this.statement,
    required this.area,
    required this.theme,
    required this.subtopic,
    required this.options,
    required this.timeLimitSeconds,
    this.imageUrl,
  });

  final String id;
  final String statement;
  final AcademicArea area;
  final String theme;
  final String subtopic;
  final List<TugOnlineOption> options;
  final int timeLimitSeconds;
  final String? imageUrl;

  factory TugOnlineQuestion.fromJson(
    Map<String, dynamic> json,
  ) => TugOnlineQuestion(
    id: json['id'] as String,
    statement: json['enunciado'] as String,
    imageUrl: json['imagenUrl'] as String?,
    area: AcademicArea.fromBackend(json['area'] as String),
    theme: json['tema'] as String,
    subtopic: json['subtema'] as String,
    options: (json['opciones'] as List<dynamic>? ?? const [])
        .map(
          (item) =>
              TugOnlineOption.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(growable: false),
    timeLimitSeconds: json['tiempoLimiteSegundos'] as int? ?? 10,
  );
}

class TugOnlineEvent {
  const TugOnlineEvent({
    required this.version,
    required this.type,
    required this.data,
    required this.date,
  });

  final int version;
  final String type;
  final Map<String, dynamic> data;
  final DateTime date;

  factory TugOnlineEvent.fromJson(Map<String, dynamic> json) => TugOnlineEvent(
    version: json['version'] as int,
    type: json['tipo'] as String,
    data: Map<String, dynamic>.from(json['datos'] as Map? ?? const {}),
    date: DateTime.parse(json['fecha'] as String).toUtc(),
  );
}

class TugOnlineSnapshot {
  const TugOnlineSnapshot({
    required this.id,
    required this.status,
    required this.side,
    required this.version,
    required this.rulesVersion,
    required this.ropePosition,
    required this.round,
    required this.totalQuestions,
    required this.readyA,
    required this.readyB,
    required this.me,
    required this.alreadyAnswered,
    required this.events,
    required this.serverOffset,
    this.area,
    this.result,
    this.rival,
    this.winnerId,
    this.roundStartsAt,
    this.roundEndsAt,
    this.question,
  });

  final String id;
  final TugOnlineMatchStatus status;
  final String? result;
  final AcademicArea? area;
  final String side;
  final int version;
  final int rulesVersion;

  /// Positivo siempre favorece al estudiante que usa este dispositivo.
  final int ropePosition;
  final int round;
  final int totalQuestions;
  final bool readyA;
  final bool readyB;
  final DateTime? roundStartsAt;
  final DateTime? roundEndsAt;
  final TugOnlinePlayer me;
  final TugOnlinePlayer? rival;
  final String? winnerId;
  final bool alreadyAnswered;
  final TugOnlineQuestion? question;
  final List<TugOnlineEvent> events;
  final Duration serverOffset;

  bool get iAmReady => side == 'A' ? readyA : readyB;

  DateTime get estimatedServerNow => DateTime.now().toUtc().add(serverOffset);

  Duration get timeUntilRoundStarts =>
      (roundStartsAt ?? estimatedServerNow).difference(estimatedServerNow);

  Duration get timeUntilRoundEnds =>
      (roundEndsAt ?? estimatedServerNow).difference(estimatedServerNow);

  TugWinner? get winner {
    if (status != TugOnlineMatchStatus.finished) return null;
    if (result == 'EMPATE') return TugWinner.draw;
    return winnerId == me.id ? TugWinner.player : TugWinner.cpu;
  }

  factory TugOnlineSnapshot.fromJson(Map<String, dynamic> json) {
    final receivedAt = DateTime.now().toUtc();
    final serverNow = DateTime.parse(json['servidorAhora'] as String).toUtc();
    final match = Map<String, dynamic>.from(json['partida'] as Map);
    final area = match['area'] as String?;
    final question = match['pregunta'];
    final rival = match['rival'];
    return TugOnlineSnapshot(
      id: match['id'] as String,
      status: TugOnlineMatchStatus.fromBackend(match['estado'] as String),
      result: match['resultado'] as String?,
      area: area == null ? null : AcademicArea.fromBackend(area),
      side: match['lado'] as String,
      version: match['version'] as int,
      rulesVersion: match['versionReglas'] as int? ?? 1,
      ropePosition: match['posicionDesdeMiLado'] as int,
      round: match['rondaActual'] as int,
      totalQuestions: match['totalPreguntas'] as int,
      readyA: match['listoA'] as bool,
      readyB: match['listoB'] as bool,
      roundStartsAt: _date(match['rondaIniciaEn']),
      roundEndsAt: _date(match['rondaVenceEn']),
      me: TugOnlinePlayer.fromJson(
        Map<String, dynamic>.from(match['yo'] as Map),
      ),
      rival: rival == null
          ? null
          : TugOnlinePlayer.fromJson(Map<String, dynamic>.from(rival as Map)),
      winnerId: match['ganadorId'] as String?,
      alreadyAnswered: match['yaRespondi'] as bool,
      question: question == null
          ? null
          : TugOnlineQuestion.fromJson(
              Map<String, dynamic>.from(question as Map),
            ),
      events: (json['eventos'] as List<dynamic>? ?? const [])
          .map(
            (item) =>
                TugOnlineEvent.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(growable: false),
      serverOffset: serverNow.difference(receivedAt),
    );
  }
}

DateTime? _date(Object? value) =>
    value is String ? DateTime.parse(value).toUtc() : null;
