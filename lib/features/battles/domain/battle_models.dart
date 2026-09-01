import '../../academic/domain/academic_models.dart';

enum BattleMode {
  ghostRace('CARRERA_FANTASMA', 'Carrera fantasma'),
  lightningDuel('DUELO_RELAMPAGO', 'Duelo relámpago'),
  survival('SUPERVIVENCIA', 'Supervivencia');

  const BattleMode(this.backendValue, this.label);

  final String backendValue;
  final String label;

  String get description => switch (this) {
    BattleMode.ghostRace => 'Gana por aciertos y, en empate, por velocidad.',
    BattleMode.lightningDuel => 'Ocho preguntas cortas para decidir el duelo.',
    BattleMode.survival => 'Conserva tus tres vidas y supera al rival.',
  };

  static BattleMode fromBackend(Object? value) => values.firstWhere(
    (mode) => mode.backendValue == value,
    orElse: () => throw const FormatException('Modo de batalla inválido.'),
  );
}

enum BattleStatus {
  searching('BUSCANDO', 'Buscando rival'),
  pending('PENDIENTE', 'Esperando invitado'),
  active('ACTIVA', 'En curso'),
  finished('FINALIZADA', 'Finalizada'),
  expired('EXPIRADA', 'Vencida'),
  cancelled('CANCELADA', 'Cancelada');

  const BattleStatus(this.backendValue, this.label);

  final String backendValue;
  final String label;

  bool get canCancel => this == searching || this == pending;
  bool get isClosed => this == finished || this == expired || this == cancelled;

  static BattleStatus fromBackend(Object? value) => values.firstWhere(
    (status) => status.backendValue == value,
    orElse: () => throw const FormatException('Estado de batalla inválido.'),
  );
}

enum BattleResult {
  victory('VICTORIA', 'Victoria'),
  defeat('DERROTA', 'Derrota'),
  draw('EMPATE', 'Empate');

  const BattleResult(this.backendValue, this.label);

  final String backendValue;
  final String label;

  static BattleResult? maybeFromBackend(Object? value) {
    if (value == null) return null;
    return values.firstWhere(
      (result) => result.backendValue == value,
      orElse: () => throw const FormatException('Resultado inválido.'),
    );
  }
}

enum BattleReportReason {
  inappropriateConduct('CONDUCTA_INAPROPIADA', 'Conducta inapropiada'),
  inappropriateName('NOMBRE_INAPROPIADO', 'Nombre inapropiado'),
  cheating('TRAMPA', 'Posible trampa'),
  other('OTRO', 'Otro motivo');

  const BattleReportReason(this.backendValue, this.label);

  final String backendValue;
  final String label;
}

class BattlePrivacy {
  const BattlePrivacy();

  factory BattlePrivacy.fromJson(Map<String, dynamic> json) {
    if (json['identidadesProtegidas'] != true ||
        json['chatHabilitado'] == true) {
      throw const FormatException(
        'SaberPlus rechazó una batalla sin protección de identidad.',
      );
    }
    return const BattlePrivacy();
  }
}

class BattleStats {
  const BattleStats({
    required this.played,
    required this.wins,
    required this.losses,
    required this.draws,
    required this.currentStreak,
    required this.bestStreak,
    required this.xp,
  });

  final int played;
  final int wins;
  final int losses;
  final int draws;
  final int currentStreak;
  final int bestStreak;
  final int xp;

  factory BattleStats.fromJson(Map<String, dynamic> json) => BattleStats(
    played: _nonNegative(json['jugadas']),
    wins: _nonNegative(json['victorias']),
    losses: _nonNegative(json['derrotas']),
    draws: _nonNegative(json['empates']),
    currentStreak: _nonNegative(json['rachaActual']),
    bestStreak: _nonNegative(json['mejorRacha']),
    xp: _nonNegative(json['xpBatallas']),
  );
}

class BattleProgress {
  const BattleProgress({
    required this.answered,
    required this.total,
    required this.lives,
    required this.finished,
    this.correct,
    this.energy,
  });

  final int answered;
  final int? correct;
  final int total;
  final int? energy;
  final int lives;
  final bool finished;

  factory BattleProgress.fromJson(Map<String, dynamic> json) => BattleProgress(
    answered: _nonNegative(json['respondidas']),
    correct: _nullableNonNegative(json['correctas']),
    total: _nonNegative(json['totalPreguntas']),
    energy: _nullableNonNegative(json['energia']),
    lives: _nonNegative(json['vidas']),
    finished: json['finalizo'] == true,
  );
}

class BattleSummary {
  const BattleSummary({
    required this.id,
    required this.mode,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    required this.isCreator,
    required this.ownProgress,
    required this.identitiesProtected,
    this.area,
    this.rivalAlias,
    this.invitationCode,
    this.rivalProgress,
    this.result,
    this.xpEarned = 0,
  });

  final String id;
  final BattleMode mode;
  final AcademicArea? area;
  final BattleStatus status;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String? rivalAlias;
  final bool isCreator;
  final String? invitationCode;
  final BattleProgress ownProgress;
  final BattleProgress? rivalProgress;
  final BattleResult? result;
  final int xpEarned;
  final bool identitiesProtected;

  factory BattleSummary.fromJson(Map<String, dynamic> json) {
    const forbiddenIdentityKeys = {
      'creadorId',
      'rivalId',
      'retadorId',
      'ganadorId',
    };
    if (json.keys.any(forbiddenIdentityKeys.contains)) {
      throw const FormatException(
        'La batalla contiene identificadores personales no permitidos.',
      );
    }
    BattlePrivacy.fromJson(_map(json['privacidad']));
    final id = (json['id'] as String? ?? '').trim();
    final createdAt = DateTime.tryParse(json['creadaEn'] as String? ?? '');
    final expiresAt = DateTime.tryParse(json['expiraEn'] as String? ?? '');
    if (id.isEmpty || createdAt == null || expiresAt == null) {
      throw const FormatException('Batalla incompleta.');
    }
    final rawRival = json['rival'];
    String? rivalAlias;
    if (rawRival != null) {
      final rival = _map(rawRival);
      if (rival.keys.any((key) => key != 'alias')) {
        throw const FormatException(
          'La identidad del rival no está protegida.',
        );
      }
      rivalAlias = (rival['alias'] as String? ?? '').trim();
      if (rivalAlias.isEmpty) {
        throw const FormatException('Alias de rival inválido.');
      }
    }
    final status = BattleStatus.fromBackend(json['estado']);
    final ownProgress = BattleProgress.fromJson(_map(json['progresoPropio']));
    final rivalProgress = json['progresoRival'] == null
        ? null
        : BattleProgress.fromJson(_map(json['progresoRival']));
    if (status != BattleStatus.finished &&
        (ownProgress.correct != null ||
            ownProgress.energy != null ||
            rivalProgress?.correct != null ||
            rivalProgress?.energy != null)) {
      throw const FormatException(
        'La batalla reveló puntuación antes de finalizar.',
      );
    }
    return BattleSummary(
      id: id,
      mode: BattleMode.fromBackend(json['modo']),
      area: json['area'] == null
          ? null
          : AcademicArea.fromBackend(json['area'] as String),
      status: status,
      createdAt: createdAt.toLocal(),
      expiresAt: expiresAt.toLocal(),
      rivalAlias: rivalAlias,
      isCreator: json['soyCreador'] == true,
      invitationCode: (json['codigoInvitacion'] as String?)?.trim(),
      ownProgress: ownProgress,
      rivalProgress: rivalProgress,
      result: BattleResult.maybeFromBackend(json['resultado']),
      xpEarned: _nonNegative(json['xpGanado']),
      identitiesProtected: true,
    );
  }
}

class BattleDashboard {
  const BattleDashboard({
    required this.stats,
    required this.battles,
    required this.identitiesProtected,
  });

  final BattleStats stats;
  final List<BattleSummary> battles;
  final bool identitiesProtected;

  factory BattleDashboard.fromJson(Map<String, dynamic> json) {
    BattlePrivacy.fromJson(_map(json['privacidad']));
    return BattleDashboard(
      stats: BattleStats.fromJson(_map(json['resumen'])),
      battles: _list(json['batallas'])
          .map((item) => BattleSummary.fromJson(_map(item)))
          .toList(growable: false),
      identitiesProtected: true,
    );
  }
}

class BattleAnswerOption {
  const BattleAnswerOption({required this.id, required this.text});

  final String id;
  final String text;

  factory BattleAnswerOption.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String? ?? '';
    final text = json['texto'] as String? ?? '';
    if (id.isEmpty || text.isEmpty) {
      throw const FormatException('Opción de batalla inválida.');
    }
    return BattleAnswerOption(id: id, text: text);
  }
}

class BattleQuestion {
  const BattleQuestion({
    required this.id,
    required this.statement,
    required this.options,
    this.context,
    this.imageUrl,
    this.ownAnswerId,
    this.isCorrect,
    this.correctAnswerId,
    this.explanation,
  });

  final String id;
  final String statement;
  final String? context;
  final String? imageUrl;
  final List<BattleAnswerOption> options;
  final String? ownAnswerId;
  final bool? isCorrect;
  final String? correctAnswerId;
  final String? explanation;

  bool get answered => ownAnswerId != null;

  factory BattleQuestion.fromJson(Map<String, dynamic> json) => BattleQuestion(
    id: json['id'] as String? ?? '',
    statement: json['enunciado'] as String? ?? '',
    context: json['contexto'] as String?,
    imageUrl: json['imagenUrl'] as String?,
    options: _list(json['opciones'])
        .map((item) => BattleAnswerOption.fromJson(_map(item)))
        .toList(growable: false),
    ownAnswerId: json['respuestaPropiaId'] as String?,
    isCorrect: json['esCorrecta'] as bool?,
    correctAnswerId: json['respuestaCorrectaId'] as String?,
    explanation: json['explicacion'] as String?,
  );
}

class BattleDetail {
  const BattleDetail({
    required this.summary,
    required this.totalQuestions,
    required this.questions,
    required this.badges,
    this.startedAt,
    this.finishedAt,
  });

  final BattleSummary summary;
  final int totalQuestions;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final List<BattleQuestion> questions;
  final List<BattleBadge> badges;

  BattleQuestion? get currentQuestion {
    for (final question in questions) {
      if (!question.answered) return question;
    }
    return null;
  }

  factory BattleDetail.fromJson(Map<String, dynamic> json) {
    final summary = BattleSummary.fromJson(json);
    return BattleDetail(
      summary: summary,
      totalQuestions: _nonNegative(json['totalPreguntas']),
      startedAt: _optionalDate(json['iniciadaEn']),
      finishedAt: _optionalDate(json['finalizadaEn']),
      questions: _list(json['preguntas'])
          .map((item) => BattleQuestion.fromJson(_map(item)))
          .toList(growable: false),
      badges: _list(
        json['insigniasDesbloqueadas'],
      ).map((item) => BattleBadge.fromJson(_map(item))).toList(growable: false),
    );
  }
}

class BattleBadge {
  const BattleBadge({
    required this.id,
    required this.title,
    required this.description,
  });

  final String id;
  final String title;
  final String description;

  factory BattleBadge.fromJson(Map<String, dynamic> json) => BattleBadge(
    id: json['id'] as String? ?? '',
    title: json['titulo'] as String? ?? '',
    description: json['descripcion'] as String? ?? '',
  );
}

class BlockedRival {
  const BlockedRival({
    required this.id,
    required this.alias,
    required this.createdAt,
  });

  final String id;
  final String alias;
  final DateTime createdAt;

  factory BlockedRival.fromJson(Map<String, dynamic> json) {
    const allowedKeys = {'id', 'alias', 'creadoEn'};
    if (json.keys.any((key) => !allowedKeys.contains(key))) {
      throw const FormatException(
        'La lista de bloqueos contiene datos personales no permitidos.',
      );
    }
    return BlockedRival(
      id: json['id'] as String? ?? '',
      alias: json['alias'] as String? ?? 'Rival bloqueado',
      createdAt: DateTime.parse(json['creadoEn'] as String).toLocal(),
    );
  }
}

int _nonNegative(Object? value) =>
    ((value as num?)?.toInt() ?? 0).clamp(0, 100000000);

int? _nullableNonNegative(Object? value) =>
    value == null ? null : _nonNegative(value);

DateTime? _optionalDate(Object? value) =>
    value is String ? DateTime.tryParse(value)?.toLocal() : null;

Map<String, dynamic> _map(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : const {};

List<Object?> _list(Object? value) =>
    value is List ? List<Object?>.from(value) : const [];
